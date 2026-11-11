// @strict-types

#Region Internal

// Receives objects and their control modules for embedding in the mechanism of the formation of printed forms
//
// Returns:
//  FixedMap of KeyAndValue - Control modules of objects:
//   * Key     - String                        - Full name of the embedded object metadata
//   * Value - CommonModule, DocumentManager - The object in which the logic of integration with the mechanism of formation of printed forms is located
Function ControlModules() Export
	
	Result = New Map;
	
	PrintFormGeneration.WhenFillingControlModules(Result);
	
	For Each ControlModule In Result Do
		
		If ControlModule.Value = Undefined Then
			FullMetadataName = ControlModule.Key; // String
			
			If Metadata.FindByFullName(FullMetadataName) = Undefined Then
				Continue; // The object is missing from the configuration (clipping)
			EndIf;
			
			Module = Common.ObjectManagerByFullName(FullMetadataName);
			Result.Insert(ControlModule.Key, Module);
		EndIf;
		
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

#EndRegion