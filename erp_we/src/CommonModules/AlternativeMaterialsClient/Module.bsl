//////////////////////////////////////////////////////////////////////
// The Analogimaterialclient module contains procedures and functions for 
// working with the mechanism of replacing materials with analogues.
//
//////////////////////////////////////////////////////////////////////
//

#Region Public

#Region OpeningForms

// Opens the analog selection form
//
// Parameters:
//	AnalogSelectionParameters - Structure         - parameters required for selecting analogs See AlternativeMaterials.AnalogSelectionParameters
//  Form					 - ClientApplicationForm - the form in which the selection of analogs is performed (after the selection, the selection Processing () event will be called).
//
Procedure OpenSelectionOfAnalogues(AnalogSelectionParameters, Form) Export
	
	OpenForm("Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials", AnalogSelectionParameters, Form);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#EndRegion
