////////////////////////////////////////////////////////////////////////////////
// Overridable procedures called from form handlers, such as:
// "Joining the Server", "Joining the Server", "Before recording the Server", 
// "After recording", as well as when changing some of the details of the tabular part,
// such as "Nomenclature", "Characteristics".
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FillingInFormHandlers

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
// 	WriteParameters - Arbitrary - 
//
Procedure AfterWrite(Form, WriteParameters)Export
	
EndProcedure

#EndRegion

#Region FillingInProducts

// An overridden procedure that is called from the "Nomenclature" attribute handler in the table part.
//
// Parameters:
// 	CurrentRow - FormDataCollectionItem - current row of the table part.
// 	ActionParameters - Structure - valid actions for the table part.
//	CachedValues - Structure - Cached values of the table part.
Procedure ProductsOnChangeOverridable(CurrentRow,ActionParameters,CachedValues)Export


EndProcedure
  
#EndRegion 

#Region FillingInCharacteristics

// An overridden procedure that is called from the handler of the "Characteristic" attribute of the table part.
//
// Parameters:
// 	CurrentRow - FormDataCollectionItem - current row of the table part.
// 	ActionParameters - Structure - valid actions for the table part.
//	CachedValues - Structure - Cached values of the table part.
Procedure CharacteristicOnChangeOverridable(CurrentRow,ActionParameters,CachedValues)Export


EndProcedure
	
#EndRegion 

#Region Overall

// Checks whether the server should be called when processing a table part string.
//
// Parameters:
// 	PropertyName - String -  name of the property to pass.
// 	ActionParameters - Structure - valid actions for the table part.
//
// Returns:
//	Boolean - 
//
Function ProcessingTablePartRequiresServerCall(PropertyName,ActionParameters)Export

	Return True	

EndFunction   

// Called in forms when you select a command that was added programmatically
//
// Parameters:
//  Form					 - ClientApplicationForm - the form where the team is located
//  Command					 - FormCommand - the selected team
//  AdditionalParameters	 - Structure - advanced setting.
//
Procedure ExecuteOverridableCommand(Form, Command, AdditionalParameters) Export

	
EndProcedure

#EndRegion 

#EndRegion
