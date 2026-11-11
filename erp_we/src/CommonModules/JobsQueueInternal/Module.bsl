// @strict-types

#Region Internal

// The routine task handler will delete the processing of the BTS task queue.
//
// Parameters:
//	JobParameters - CatalogRef.JobsQueueHandlers - task parameters.
//
Procedure STLJobQueueProcessing(JobParameters) Export
	
	Raise NStr("vi = 'Không sử dụng thủ tục';
				|ru = 'Процедура не используется';
				|en = 'The procedure is not used'; fa = 'The procedure is not used';
				|it = 'Procedura non utilizzata';
				|pl = 'Procedura nie jest używana';
				|tr = 'Prosedür kullanılmıyor'");
	
EndProcedure

// Performs task execution planning from the Task Queue PC.
// @skip-check module-empty-method - a feature of the implementation.
// 
Procedure JobsProcessingPlanning() Export
	
EndProcedure

// The procedure executes a task from the Task Queue Catalog.
// @skip-check module-empty-method - a feature of the implementation. 
// 
// Parameters: 
//  JobParameters - Structure - parameters required to complete the task
//
Procedure RoutineTaskQueueProcessing(JobParameters) Export
	
EndProcedure

// Returns possible methods to use in the job queue.
// Returns:
//	Array of String - array of method names.
Function PossibleMethods() Export
	
	Return New Array;
	
EndFunction

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
// @skip-check module-empty-method - a feature of the implementation.
//
Procedure OnEnableSeparationByDataAreas() Export
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport
// @skip-check module-empty-method - a feature of the implementation.
//
// Parameters:
//	CatalogsToImport - ValueTable -
//
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-check module-empty-method - a feature of the implementation.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
EndProcedure

// Handler for the routine task of starting task processing.
// @skip-check module-empty-method - a feature of the implementation.
//
Procedure JobsProcessingStart() Export
	
EndProcedure


#EndRegion
