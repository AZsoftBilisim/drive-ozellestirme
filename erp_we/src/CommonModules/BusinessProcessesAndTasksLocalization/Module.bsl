
#Region Public

// SeeBusinessProcessesAndTasksOverridable.OnReceiveTaskExecutionForm
Procedure OnReceiveTaskExecutionForm(BusinessProcessName, TaskRef, BusinessProcessRoutePoint, FormParameters) Export
	
	
EndProcedure

// SeeBusinessProcessesAndTasksOverridable.OnDetermineBusinessProcesses
Procedure OnDetermineBusinessProcesses(AttachedBusinessProcesses) Export
	
	
EndProcedure

// It is called from the modules of the Business Process Task subsystem objects to
// be able to configure the constraint logic in the application solution.
//
// For an example of filling in access value sets, see in the comments
// to the Access control procedure.Fill in the set of access values.
//
// Parameters:
//  Object - BusinessProcessObject.Job - the object for which you need to fill sets.
//  
//  Table - ValueTable - returned by the access Control function.Tablecolorizingrenderer.
//
Procedure OnFillingAccessValuesSets(Object, Table) Export
	
	
EndProcedure

// SeeBusinessProcessesAndTasksOverridable.OnInitiallyFillPerformersRoles
Procedure OnInitiallyFillPerformersRoles(LanguagesCodes, Items, TabularSections) Export
	
	
EndProcedure

#EndRegion