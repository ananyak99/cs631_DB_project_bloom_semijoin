/*-------------------------------------------------------------------------
 *
 * nodeForeignscan.c
 *	  Routines to support scans of foreign tables
 *
 * Portions Copyright (c) 1996-2023, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/backend/executor/nodeForeignscan.c
 *
 *-------------------------------------------------------------------------
 */
/*
 * INTERFACE ROUTINES
 *
 *		ExecForeignScan			scans a foreign table.
 *		ExecInitForeignScan		creates and initializes state info.
 *		ExecReScanForeignScan	rescans the foreign relation.
 *		ExecEndForeignScan		releases any resources allocated.
 */
#include "postgres.h"

#include "executor/executor.h"
#include "executor/nodeForeignscan.h"
#include "foreign/fdwapi.h"
#include "utils/memutils.h"
#include "utils/rel.h"
#include "utils/lsyscache.h"

static TupleTableSlot *ForeignNext(ForeignScanState *node);
static bool ForeignRecheck(ForeignScanState *node, TupleTableSlot *slot);

/* ----------------------------------------------------------------
 *		ForeignNext
 *
 *		This is a workhorse for ExecForeignScan
 * ----------------------------------------------------------------
 */
static TupleTableSlot *
ForeignNext(ForeignScanState *node)
{
	TupleTableSlot *slot;
	ForeignScan *plan = (ForeignScan *) node->ss.ps.plan;
	ExprContext *econtext = node->ss.ps.ps_ExprContext;
	MemoryContext oldcontext;

	/* Call the Iterate function in short-lived context */
	oldcontext = MemoryContextSwitchTo(econtext->ecxt_per_tuple_memory);
	if (plan->operation != CMD_SELECT)
	{
		/*
		 * direct modifications cannot be re-evaluated, so shouldn't get here
		 * during EvalPlanQual processing
		 */
		Assert(node->ss.ps.state->es_epq_active == NULL);

		slot = node->fdwroutine->IterateDirectModify(node);
	}
	else
		slot = node->fdwroutine->IterateForeignScan(node);
	MemoryContextSwitchTo(oldcontext);

	/*
	 * Insert valid value into tableoid, the only actually-useful system
	 * column.
	 */
	if (plan->fsSystemCol && !TupIsNull(slot))
		slot->tts_tableOid = RelationGetRelid(node->ss.ss_currentRelation);

	return slot;
}

/*
 * ForeignRecheck -- access method routine to recheck a tuple in EvalPlanQual
 */
static bool
ForeignRecheck(ForeignScanState *node, TupleTableSlot *slot)
{
	FdwRoutine *fdwroutine = node->fdwroutine;
	ExprContext *econtext;

	/*
	 * extract necessary information from foreign scan node
	 */
	econtext = node->ss.ps.ps_ExprContext;

	/* Does the tuple meet the remote qual condition? */
	econtext->ecxt_scantuple = slot;

	ResetExprContext(econtext);

	/*
	 * If an outer join is pushed down, RecheckForeignScan may need to store a
	 * different tuple in the slot, because a different set of columns may go
	 * to NULL upon recheck.  Otherwise, it shouldn't need to change the slot
	 * contents, just return true or false to indicate whether the quals still
	 * pass.  For simple cases, setting fdw_recheck_quals may be easier than
	 * providing this callback.
	 */
	if (fdwroutine->RecheckForeignScan &&
		!fdwroutine->RecheckForeignScan(node, slot))
		return false;

	return ExecQual(node->fdw_recheck_quals, econtext);
}

static void appendSlotValuetoString(StringInfoData *result, CustomBloomFilter *filter , TupleTableSlot *slot)
{
	TupleDesc typeinfo = slot->tts_tupleDescriptor;
	int natts = typeinfo->natts;
	int i;
	Datum attr;
	char *value;
	bool isnull;
	Oid typoutput;
	bool typisvarlena;
	Oid attr_oid;

	StringInfoData composite_key;
	initStringInfo(&composite_key);

	for (i = 0; i < natts; i++)
	{
		attr = slot_getattr(slot, i + 1, &isnull);
		if (isnull)
			continue;
		getTypeOutputInfo(TupleDescAttr(typeinfo, i)->atttypid,
						  &typoutput, &typisvarlena);

		// Extract the attribute value (Datum)
		value = OidOutputFunctionCall(typoutput, attr);
		attr_oid = typeinfo->attrs[i].atttypid;

		// Use type-specific functions to convert to string
		switch (attr_oid)
		{
		case VARCHAROID:
		case TEXTOID:
		{
			appendStringInfoString(result, "'");
			appendStringInfoString(result, value);
			appendStringInfoString(result, "'");
			break;
		}
		case NUMERICOID:
		{
			appendStringInfoString(result, value);
			break;
		}
		case INT4OID:
		{
			int32 num = DatumGetInt32(attr);
			appendStringInfo(result, "%d", num);
			break;
		}
		case FLOAT4OID:
		{
			float4 num = DatumGetFloat4(attr);
			appendStringInfo(result, "%f", num);
			break;
		}
		}
		
		// Build composite key
		if (i > 0)
			appendStringInfoString(&composite_key, "|");
		appendStringInfoString(&composite_key, value);
	}
	
	// Add composite key to bloom filter
	elog(NOTICE, "Bloom Filter: Adding value: %s", composite_key.data);
	bloom_filter_add(filter, composite_key.data);
	pfree(composite_key.data);
}

static NameData get_scan_attribute(ForeignScanState *node)
{
	ForeignScan *foreignScan = (ForeignScan *)node->ss.ps.plan;
	ListCell *lc;
	NameData attname;

	memset(&attname, 0, sizeof(NameData));

	/* Iterate over the target list */
	foreach (lc, foreignScan->scan.plan.targetlist)
	{
		TargetEntry *tle = (TargetEntry *)lfirst(lc);

		/* Check if the TargetEntry is valid and contains a Var node */
		if (IsA(tle->expr, Var))
		{
			Var *var = (Var *)tle->expr;

			/* Access the attribute number and type */
			int attno = var->varattno;	/* Attribute number */
			attname = node->ss.ss_currentRelation->rd_att->attrs[attno-1].attname;
			return attname;
		}
		else
		{
			/* Handle other types of expressions in the target list if needed */
			elog(WARNING, "Unexpected node type in fdw_scan_tlist.");
		}
	}
	return attname;
}

/* ----------------------------------------------------------------
 *		ExecForeignScan(node)
 *
 *		Fetches the next tuple from the FDW, checks local quals, and
 *		returns it.
 *		We call the ExecScan() routine and pass it the appropriate
 *		access method functions.
 * ----------------------------------------------------------------
 */
static TupleTableSlot *
ExecForeignScan(PlanState *pstate)
{
	ForeignScanState *node = castNode(ForeignScanState, pstate);
	ForeignScan *plan = (ForeignScan *)node->ss.ps.plan;
	EState *estate = node->ss.ps.state;
	StringInfoData query;
	StringInfoData result;
	if (pstate->lefttree && !node->child_materialised) // If there is a child subtree, run only once for this query
	{
		// Safety check
		if (!pstate->lefttree->plan) {
			elog(WARNING, "Left tree plan is NULL, skipping bloom filter");
			goto skip_bloom_filter;
		}
		
		double estimated_rows = pstate->lefttree->plan->plan_rows;
		
		TupleTableSlot *slot;
		bool local_scan_done = false;
		char **query_ptr;
		
		// First pass: materialize all tuples and count them
		elog(NOTICE, "Dynamic Bloom Filter: Starting materialization...");
		int actual_tuple_count = 0;
		TupleTableSlot **materialized_slots = NULL;
		int slots_capacity = 100; // Initial capacity
		
		materialized_slots = (TupleTableSlot **)palloc(sizeof(TupleTableSlot *) * slots_capacity);
		
		while (!local_scan_done)
		{
			slot = ExecProcNode(outerPlanState(pstate));
			if (TupIsNull(slot))
			{
				local_scan_done = true;
			}
			else
			{
				// Expand array if needed
				if (actual_tuple_count >= slots_capacity) {
					slots_capacity *= 2;
					materialized_slots = (TupleTableSlot **)repalloc(materialized_slots, 
																	  sizeof(TupleTableSlot *) * slots_capacity);
				}
				
				// Store a copy of the slot
				materialized_slots[actual_tuple_count] = MakeSingleTupleTableSlot(slot->tts_tupleDescriptor, 
																				   &TTSOpsHeapTuple);
				ExecCopySlot(materialized_slots[actual_tuple_count], slot);
				actual_tuple_count++;
			}
		}
		
		// Now create bloom filter with the ACTUAL count
		size_t num_rows = actual_tuple_count > 0 ? actual_tuple_count : 10;
		CustomBloomFilter *filter = bloom_filter_create(num_rows, 0.01);
		
		elog(NOTICE, "Bloom Filter: actual: %d rows", 
			 actual_tuple_count);
		elog(NOTICE, "Bloom Filter: %lu bits, %d hash functions", 
			 filter->size, filter->hash_count);
		
		// Second pass: add all materialized tuples to the bloom filter
		initStringInfo(&result);
		bool not_first_slot = false;
		
		for (int i = 0; i < actual_tuple_count; i++)
		{
			if (not_first_slot)
			{
				appendStringInfoString(&result, ",");
			}
			appendSlotValuetoString(&result, filter, materialized_slots[i]);
			not_first_slot = true;
			
			// Clean up the slot
			ExecDropSingleTupleTableSlot(materialized_slots[i]);
		}
		
		// Free the array
		if (materialized_slots)
			pfree(materialized_slots);
		
		// elog(LOG, "Added %d tuples to bloom filter", actual_tuple_count);
		
		(void) get_scan_attribute(node);
		query_ptr = (char **)((char *)node->fdw_state + 24);
		initStringInfo(&query);
		appendStringInfoString(&query, *query_ptr);
		appendStringInfoString(&query, "#");
		appendStringInfoString(&query, bloom_filter_encode_hex_with_metadata(filter));
		*query_ptr = query.data;
		node->child_materialised = true; // set it such that for this block is not run anymore for this query
	}

skip_bloom_filter:
	/*
	 * Ignore direct modifications when EvalPlanQual is active --- they are
	 * irrelevant for EvalPlanQual rechecking
	 */
	if (estate->es_epq_active != NULL && plan->operation != CMD_SELECT)
		return NULL;

	return ExecScan(&node->ss,
					(ExecScanAccessMtd)ForeignNext,
					(ExecScanRecheckMtd)ForeignRecheck);
}


/* ----------------------------------------------------------------
 *		ExecInitForeignScan
 * ----------------------------------------------------------------
 */
ForeignScanState *
ExecInitForeignScan(ForeignScan *node, EState *estate, int eflags)
{
	ForeignScanState *scanstate;
	Relation	currentRelation = NULL;
	Index		scanrelid = node->scan.scanrelid;
	int			tlistvarno;
	FdwRoutine *fdwroutine;

	/* check for unsupported flags */
	Assert(!(eflags & (EXEC_FLAG_BACKWARD | EXEC_FLAG_MARK)));

	/*
	 * create state structure
	 */
	scanstate = makeNode(ForeignScanState);
	scanstate->ss.ps.plan = (Plan *) node;
	scanstate->ss.ps.state = estate;
	scanstate->child_materialised = false;
	scanstate->ss.ps.ExecProcNode = ExecForeignScan;

	/*
	 * Miscellaneous initialization
	 *
	 * create expression context for node
	 */
	ExecAssignExprContext(estate, &scanstate->ss.ps);

	/*
	 * open the scan relation, if any; also acquire function pointers from the
	 * FDW's handler
	 */
	if (scanrelid > 0)
	{
		currentRelation = ExecOpenScanRelation(estate, scanrelid, eflags);
		scanstate->ss.ss_currentRelation = currentRelation;
		fdwroutine = GetFdwRoutineForRelation(currentRelation, true);
	}
	else
	{
		/* We can't use the relcache, so get fdwroutine the hard way */
		fdwroutine = GetFdwRoutineByServerId(node->fs_server);
	}

	/*
	 * Determine the scan tuple type.  If the FDW provided a targetlist
	 * describing the scan tuples, use that; else use base relation's rowtype.
	 */
	if (node->fdw_scan_tlist != NIL || currentRelation == NULL)
	{
		TupleDesc	scan_tupdesc;

		scan_tupdesc = ExecTypeFromTL(node->fdw_scan_tlist);
		ExecInitScanTupleSlot(estate, &scanstate->ss, scan_tupdesc,
							  &TTSOpsHeapTuple);
		/* Node's targetlist will contain Vars with varno = INDEX_VAR */
		tlistvarno = INDEX_VAR;
	}
	else
	{
		TupleDesc	scan_tupdesc;

		/* don't trust FDWs to return tuples fulfilling NOT NULL constraints */
		scan_tupdesc = CreateTupleDescCopy(RelationGetDescr(currentRelation));
		ExecInitScanTupleSlot(estate, &scanstate->ss, scan_tupdesc,
							  &TTSOpsHeapTuple);
		/* Node's targetlist will contain Vars with varno = scanrelid */
		tlistvarno = scanrelid;
	}

	/* Don't know what an FDW might return */
	scanstate->ss.ps.scanopsfixed = false;
	scanstate->ss.ps.scanopsset = true;

	/*
	 * Initialize result slot, type and projection.
	 */
	ExecInitResultTypeTL(&scanstate->ss.ps);
	ExecAssignScanProjectionInfoWithVarno(&scanstate->ss, tlistvarno);

	/*
	 * initialize child expressions
	 */
	scanstate->ss.ps.qual =
		ExecInitQual(node->scan.plan.qual, (PlanState *) scanstate);
	scanstate->fdw_recheck_quals =
		ExecInitQual(node->fdw_recheck_quals, (PlanState *) scanstate);

	/*
	 * Determine whether to scan the foreign relation asynchronously or not;
	 * this has to be kept in sync with the code in ExecInitAppend().
	 */
	scanstate->ss.ps.async_capable = (((Plan *) node)->async_capable &&
									  estate->es_epq_active == NULL);

	/*
	 * Initialize FDW-related state.
	 */
	scanstate->fdwroutine = fdwroutine;
	scanstate->fdw_state = NULL;

	/*
	 * For the FDW's convenience, look up the modification target relation's
	 * ResultRelInfo.  The ModifyTable node should have initialized it for us,
	 * see ExecInitModifyTable.
	 *
	 * Don't try to look up the ResultRelInfo when EvalPlanQual is active,
	 * though.  Direct modifications cannot be re-evaluated as part of
	 * EvalPlanQual.  The lookup wouldn't work anyway because during
	 * EvalPlanQual processing, EvalPlanQual only initializes the subtree
	 * under the ModifyTable, and doesn't run ExecInitModifyTable.
	 */
	if (node->resultRelation > 0 && estate->es_epq_active == NULL)
	{
		if (estate->es_result_relations == NULL ||
			estate->es_result_relations[node->resultRelation - 1] == NULL)
		{
			elog(ERROR, "result relation not initialized");
		}
		scanstate->resultRelInfo = estate->es_result_relations[node->resultRelation - 1];
	}

	/* Initialize any outer plan. */
	if (outerPlan(node))
		outerPlanState(scanstate) =
			ExecInitNode(outerPlan(node), estate, eflags);

	/*
	 * Tell the FDW to initialize the scan.
	 */
	if (node->operation != CMD_SELECT)
	{
		/*
		 * Direct modifications cannot be re-evaluated by EvalPlanQual, so
		 * don't bother preparing the FDW.
		 *
		 * In case of an inherited UPDATE/DELETE with foreign targets there
		 * can be direct-modify ForeignScan nodes in the EvalPlanQual subtree,
		 * so we need to ignore such ForeignScan nodes during EvalPlanQual
		 * processing.  See also ExecForeignScan/ExecReScanForeignScan.
		 */
		if (estate->es_epq_active == NULL)
			fdwroutine->BeginDirectModify(scanstate, eflags);
	}
	else
		fdwroutine->BeginForeignScan(scanstate, eflags);

	return scanstate;
}

/* ----------------------------------------------------------------
 *		ExecEndForeignScan
 *
 *		frees any storage allocated through C routines.
 * ----------------------------------------------------------------
 */
void
ExecEndForeignScan(ForeignScanState *node)
{
	ForeignScan *plan = (ForeignScan *) node->ss.ps.plan;
	EState	   *estate = node->ss.ps.state;

	/* Let the FDW shut down */
	if (plan->operation != CMD_SELECT)
	{
		if (estate->es_epq_active == NULL)
			node->fdwroutine->EndDirectModify(node);
	}
	else
		node->fdwroutine->EndForeignScan(node);

	/* Shut down any outer plan. */
	if (outerPlanState(node))
		ExecEndNode(outerPlanState(node));

	/* Free the exprcontext */
	ExecFreeExprContext(&node->ss.ps);

	/* clean out the tuple table */
	if (node->ss.ps.ps_ResultTupleSlot)
		ExecClearTuple(node->ss.ps.ps_ResultTupleSlot);
	ExecClearTuple(node->ss.ss_ScanTupleSlot);
}

/* ----------------------------------------------------------------
 *		ExecReScanForeignScan
 *
 *		Rescans the relation.
 * ----------------------------------------------------------------
 */
void
ExecReScanForeignScan(ForeignScanState *node)
{
	ForeignScan *plan = (ForeignScan *) node->ss.ps.plan;
	EState	   *estate = node->ss.ps.state;
	PlanState  *outerPlan = outerPlanState(node);

	/*
	 * Ignore direct modifications when EvalPlanQual is active --- they are
	 * irrelevant for EvalPlanQual rechecking
	 */
	if (estate->es_epq_active != NULL && plan->operation != CMD_SELECT)
		return;

	node->fdwroutine->ReScanForeignScan(node);

	/*
	 * If chgParam of subnode is not null then plan will be re-scanned by
	 * first ExecProcNode.  outerPlan may also be NULL, in which case there is
	 * nothing to rescan at all.
	 */
	if (outerPlan != NULL && outerPlan->chgParam == NULL)
		ExecReScan(outerPlan);

	ExecScanReScan(&node->ss);
}

/* ----------------------------------------------------------------
 *		ExecForeignScanEstimate
 *
 *		Informs size of the parallel coordination information, if any
 * ----------------------------------------------------------------
 */
void
ExecForeignScanEstimate(ForeignScanState *node, ParallelContext *pcxt)
{
	FdwRoutine *fdwroutine = node->fdwroutine;

	if (fdwroutine->EstimateDSMForeignScan)
	{
		node->pscan_len = fdwroutine->EstimateDSMForeignScan(node, pcxt);
		shm_toc_estimate_chunk(&pcxt->estimator, node->pscan_len);
		shm_toc_estimate_keys(&pcxt->estimator, 1);
	}
}

/* ----------------------------------------------------------------
 *		ExecForeignScanInitializeDSM
 *
 *		Initialize the parallel coordination information
 * ----------------------------------------------------------------
 */
void
ExecForeignScanInitializeDSM(ForeignScanState *node, ParallelContext *pcxt)
{
	FdwRoutine *fdwroutine = node->fdwroutine;

	if (fdwroutine->InitializeDSMForeignScan)
	{
		int			plan_node_id = node->ss.ps.plan->plan_node_id;
		void	   *coordinate;

		coordinate = shm_toc_allocate(pcxt->toc, node->pscan_len);
		fdwroutine->InitializeDSMForeignScan(node, pcxt, coordinate);
		shm_toc_insert(pcxt->toc, plan_node_id, coordinate);
	}
}

/* ----------------------------------------------------------------
 *		ExecForeignScanReInitializeDSM
 *
 *		Reset shared state before beginning a fresh scan.
 * ----------------------------------------------------------------
 */
void
ExecForeignScanReInitializeDSM(ForeignScanState *node, ParallelContext *pcxt)
{
	FdwRoutine *fdwroutine = node->fdwroutine;

	if (fdwroutine->ReInitializeDSMForeignScan)
	{
		int			plan_node_id = node->ss.ps.plan->plan_node_id;
		void	   *coordinate;

		coordinate = shm_toc_lookup(pcxt->toc, plan_node_id, false);
		fdwroutine->ReInitializeDSMForeignScan(node, pcxt, coordinate);
	}
}

/* ----------------------------------------------------------------
 *		ExecForeignScanInitializeWorker
 *
 *		Initialization according to the parallel coordination information
 * ----------------------------------------------------------------
 */
void
ExecForeignScanInitializeWorker(ForeignScanState *node,
								ParallelWorkerContext *pwcxt)
{
	FdwRoutine *fdwroutine = node->fdwroutine;

	if (fdwroutine->InitializeWorkerForeignScan)
	{
		int			plan_node_id = node->ss.ps.plan->plan_node_id;
		void	   *coordinate;

		coordinate = shm_toc_lookup(pwcxt->toc, plan_node_id, false);
		fdwroutine->InitializeWorkerForeignScan(node, pwcxt->toc, coordinate);
	}
}

/* ----------------------------------------------------------------
 *		ExecShutdownForeignScan
 *
 *		Gives FDW chance to stop asynchronous resource consumption
 *		and release any resources still held.
 * ----------------------------------------------------------------
 */
void
ExecShutdownForeignScan(ForeignScanState *node)
{
	FdwRoutine *fdwroutine = node->fdwroutine;

	if (fdwroutine->ShutdownForeignScan)
		fdwroutine->ShutdownForeignScan(node);
}

/* ----------------------------------------------------------------
 *		ExecAsyncForeignScanRequest
 *
 *		Asynchronously request a tuple from a designed async-capable node
 * ----------------------------------------------------------------
 */
void
ExecAsyncForeignScanRequest(AsyncRequest *areq)
{
	ForeignScanState *node = (ForeignScanState *) areq->requestee;
	FdwRoutine *fdwroutine = node->fdwroutine;

	Assert(fdwroutine->ForeignAsyncRequest != NULL);
	fdwroutine->ForeignAsyncRequest(areq);
}

/* ----------------------------------------------------------------
 *		ExecAsyncForeignScanConfigureWait
 *
 *		In async mode, configure for a wait
 * ----------------------------------------------------------------
 */
void
ExecAsyncForeignScanConfigureWait(AsyncRequest *areq)
{
	ForeignScanState *node = (ForeignScanState *) areq->requestee;
	FdwRoutine *fdwroutine = node->fdwroutine;

	Assert(fdwroutine->ForeignAsyncConfigureWait != NULL);
	fdwroutine->ForeignAsyncConfigureWait(areq);
}

/* ----------------------------------------------------------------
 *		ExecAsyncForeignScanNotify
 *
 *		Callback invoked when a relevant event has occurred
 * ----------------------------------------------------------------
 */
void
ExecAsyncForeignScanNotify(AsyncRequest *areq)
{
	ForeignScanState *node = (ForeignScanState *) areq->requestee;
	FdwRoutine *fdwroutine = node->fdwroutine;

	Assert(fdwroutine->ForeignAsyncNotify != NULL);
	fdwroutine->ForeignAsyncNotify(areq);
}
