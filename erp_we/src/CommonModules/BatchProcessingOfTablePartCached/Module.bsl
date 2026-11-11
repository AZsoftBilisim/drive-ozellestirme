#Region Internal

// Methods for execution.
// 
// Returns:
//  ValueTable - Methods For Implementation:
// * DataProcessor - String - The name of the action to be performed on the row of the table part.
// * Method - String - The path to the export method that performs the action specified in the Processing column. 
// * Order - Number - The priority of performing an action on a line.
//
Function MethodsForImplementation() Export

	Map 	= New ValueList();
	
	ComplianceWithVT 	= New ValueTable();
	ComplianceWithVT.Columns.Add("DataProcessor", New TypeDescription("String")); 
	ComplianceWithVT.Columns.Add("Method", New TypeDescription("String")); 
	ComplianceWithVT.Columns.Add("Order", New TypeDescription("Number")); 
	
	BatchProcessingOfTablePartServer.WhenAddingCollectionLineHandlers(Map);
		
	ComplianceWithVT.Indexes.Add("DataProcessor");
	
	Counter = 1;
	ParametersOfStringProcessingMethod = ParametersOfStringProcessingMethod();
	
	For Each DataProcessor In Map Do
		NewRow				= ComplianceWithVT.Add();
		NewRow.DataProcessor	= DataProcessor.Value;
		NewRow.Method		= DataProcessor.Presentation + ParametersOfStringProcessingMethod;
		NewRow.Order		= Counter;
		Counter					= Counter + 1;
	EndDo;
	
	Return ComplianceWithVT;
	
EndFunction

#EndRegion

#Region Private

Function ParametersOfStringProcessingMethod()
	
	LinesOfCode = New Array();
	
	LinesOfCode.Add("Parameters.CurrentRow");
	LinesOfCode.Add("Parameters.StructureOfActions");
	LinesOfCode.Add("Parameters.CachedValues");
	
	Return "(" + StrConcat(LinesOfCode, ",") + ");";
	
EndFunction

#EndRegion