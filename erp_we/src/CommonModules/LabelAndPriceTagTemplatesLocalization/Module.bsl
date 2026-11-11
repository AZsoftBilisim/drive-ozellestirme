////////////////////////////////////////////////////////////////////////////////
// Procedures and functions used in the processing of purchase log documents
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure WhenReceivingParametersForPrintingSampleLabelsExciseStamps(ForWhat, CodeType, UUID, PrintParameters) Export

	
EndProcedure

Procedure WhenReceivingParametersForPrintingSampleLabelBarcodesOfPackages(ForWhat, CodeType, UUID, PrintParameters) Export
	
	Return;
	
EndProcedure

Procedure WhenReceivingParametersForPrintingSampleLabelISMP(ForWhat, CodeType, UUID, PrintParameters) Export
	
	Return;
	
EndProcedure

Procedure WhenDefiningSourcesForRegistration(ArrayCalculationManagersSeeAlsoInWork) Export
	
	
EndProcedure

Procedure WhenFillingOutDataLayoutDiagram(DataCompositionSchema, Purpose) Export
	
	Return;
	
EndProcedure

Procedure WhenFillingInAvailableDataLayoutFields(FieldsNames, Purpose) Export
	
	Return;
	
EndProcedure

// When you change the assignment, the assistant is new.
// 
// Parameters:
//  Form - ClientApplicationForm
//  TypeSearchStrings - Array of String - Type search
//  TemplateAttributeForProducts - String - Template Attribute For Products
//  TypesArray - Array of CatalogRef - array of types
Procedure WhenYouChangeAssignmentToNewOne(Form, TypeSearchStrings, TemplateAttributeForProducts, TypesArray) Export
	
	
EndProcedure

#EndRegion

#Region Private

Procedure WhenCreatingTemplateSelectionFormOnServer(Form, Parameters, WhetherTemplateIsPredefined) Export
	
	
EndProcedure

// Setting the Attributes of the template form by default.
//
// Parameters:
//  Form - See Catalog.LabelAndPriceTagTemplates.Form.LabelAndPriceTagTemplateEditForm
//  Object - CatalogObject.LabelAndPriceTagTemplates
//  TemplateName - String
//
Procedure SetDefaultTemplate(Form, Object, TemplateName) Export
	
	If Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ExciseStampLabel Then
			
		Form.BarcodeType = Enums.BarcodeTypes.PDF417;
		Form.TextVisible = False;
			
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForBarcodesPackages Then
		
		Form.BarcodeType = Enums.BarcodeTypes.GS1_DataBarExpandedStacked;
		Form.TextVisible = False;
		
	ElsIf Object.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelShoesClothesTobacco Then
		
		Form.BarcodeType       = Enums.BarcodeTypes.GS1_DataMatrix;
		Form.TextVisible    = False;
		Form.Zoomable     = False;
		Form.MaintainAspectRatio = True;
		If StrFind(TemplateName, "Package") > 0 Then
			Form.BarcodeType = Enums.BarcodeTypes.GS1_128;
		EndIf;
			
	EndIf;

EndProcedure

Procedure PrepareStructureOfTemplateTemplate(Purpose, Zoomable, CodeType, TemplateBarcodeType) Export
	If Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ExciseStampLabel Then
		CodeType = 6;  // PDF417
		TemplateBarcodeType = Enums.BarcodeTypes.PDF417;
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelShoesClothesTobacco Then
		CodeType = 24;  // DataMatrix
		TemplateBarcodeType = Enums.BarcodeTypes.GS1_DataMatrix;
		Zoomable = False;
	EndIf;
EndProcedure


Procedure WhenChangingTemplateAssignmentInTemplateCatalog(Form, ClearingAssignment, TypesArray) Export
	
	
EndProcedure

#EndRegion