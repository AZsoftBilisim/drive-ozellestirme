#Region Public

// Returns a classifier table from A Template with predefined elements. It is used for classifiers (OKVED,
// OKOPF, etc.) Templates are stored in the Templates of THIS Catalog (see the general form "Code Selection Form").
//	Parameters:
//		NameOfTemplate - String - name of the layout that stores data with predefined classifier elements.
//		CurrentPeriod - Date - it is not used in this method, but it may be mandatory if you refer to other classifiers from the General form.
//	Returns:
//		Structure - a parameter structure with the following properties:
//			* ListOfCodes - ValueTable - classifier table with columns:
//				** Code - String - string representation of the classifier element code.
//				** Description - String - name of the classifier element.
//
Function GetSelectionFormParametersForCode(NameOfTemplate, CurrentPeriod) Export
	Classifier = New ValueTable;
	
	Classifier.Columns.Add("Code");
	Classifier.Columns.Add("Description");
	Classifier.Indexes.Add("Code");
	Parameters = New Structure;
	Parameters.Insert("ListOfCodes",	Classifier);
	
	Return Parameters;
	
EndFunction

// Returns whether the codes match the name specified in the layout. Used for classifiers (OKVED, OKOPF, etc.).
//
//	Parameters:
//		TemplateName - String - The name of the layout, as set in the Configurator. If it is not found, an empty match will be returned.
//		AreaName - String - Name of the layout area to analyze.
//
//	Returns:
//		FixedMap - consists of:
//			* Key - String -  code specified in the first column of the layout;
//			* Value - String - name specified in the second column of the layout.
//
Function MatchingCodesToNameFromTemplate(TemplateName, AreaName = "Classifier") Export
	
	CodeCompliance = New Map;
	
	Template = Catalogs.Companies.GetTemplate(TemplateName);
	If Template = Undefined Then
		Return New FixedMap(CodeCompliance);
	EndIf;
	
	TemplateArea = Template.GetArea(AreaName);
	
	For Nom = 1 To TemplateArea.TableHeight Do
		
		CurCode = TrimAll(TemplateArea.Area(Nom,1).Text);
		Cur_Name = TrimAll(TemplateArea.Area(Nom, 2).Text);
		
		If CurCode = "###" Then
			Break;
		ElsIf IsBlankString(CurCode) Then
			Continue;
		Else
			CodeCompliance.Insert(CurCode, Cur_Name);
		EndIf;
		
	EndDo;
	
	Return New FixedMap(CodeCompliance);
	
EndFunction

Procedure AddBusinessDetailsToList(Attributes) Export
EndProcedure

Procedure AddCompanyDetails(Organization, AttributesStructure1, SelectionByOrganization) Export
EndProcedure

// Determines whether the organization has separate divisions (allocated to a separate balance sheet).
//
// Parameters:
//  Organization - CatalogRef.Companies
// 
// Returns:
//  Boolean - True, if the information database keeps records
//           of separate divisions of the organization allocated to a separate balance sheet
//
Function CompanyHasBranchOffices(Organization) Export
	
	
	Return False;
	
EndFunction

// Returns the organization's checkpoint as of the specified date.
//
// Parameters:
//     Organization - CatalogRef.Companies - Organization.
//     DateOfLastEdit - Date - The date on which you need to get the organization's checkpoint.
//
// Returns:
//     String - Checkpoint.
//
Function CheckpointOnDate(Organization, DateOfLastEdit) Export
	
	
	Return Common.ObjectAttributeValue(Organization, "CRTR");

EndFunction

// Returns the Attributes of the largest taxpayer as of the specified date.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  DateOfLastEdit - Date - Date of information
// 
// Returns:
//  Structure - The Largest Taxpayer Values Of Attributes As Of The Date:
// * CompanyIsMajorTaxpayer - Boolean - 
// * MajorTaxpayerKPP - String - 
// * FullNameOfMajorTaxpayerTaxAuthority - String - 
// * LargestTaxpayerMunicipalTerritoriesClassifier - String - 
// * OKATOSLargestTaxpayer - String - 
// * IFTSCodeOfReportingRecipient - String - 
Function LargestTaxpayerValuesOfAttributesAsOfDate(Organization, DateOfLastEdit) Export
	
	Result = New Structure;
	Result.Insert("CompanyIsMajorTaxpayer", False);
	Result.Insert("MajorTaxpayerKPP", "");
	Result.Insert("FullNameOfMajorTaxpayerTaxAuthority", "");
	Result.Insert("LargestTaxpayerMunicipalTerritoriesClassifier", "");
	Result.Insert("OKATOSLargestTaxpayer", "");
	Result.Insert("IFTSCodeOfReportingRecipient", "");
	
	
	Return Result;

EndFunction


#Region AttachableCommands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region FormEventHandlers

// Event handler for adding a form To the server of the Business directory element.
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingElementFormOnServer(Form, Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Handler for the event occurrence in the Form server of the Organization Catalog element.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  CurrentObject - CatalogObject.Companies -
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	
EndProcedure

// Event handler for the completion Handler
// 
// Parameters:
// 	RecordObject_ - CatalogObject.Companies - a writable directory
// 	FillingData - Arbitrary - fill-in data
// 	StandardProcessing - Boolean - Flag for standard processing
//
Procedure ProcessingOrganizationFields(RecordObject_, FillingData, StandardProcessing) Export
EndProcedure

// Called when creating / reading a form on the server
// 
// Parameters:
// 	Form - ClientApplicationForm - handler form
//
Procedure OnCreatReadAtServer(Form) Export
	
EndProcedure

// Handler for the event before writing to the Server
// 
// Parameters:
// 	Cancel - Boolean -
// 	CurrentObject - CatalogObject.Companies -
// 	WriteParameters - Structure -
// 	Form - ClientApplicationForm -
//
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters, Form) Export
EndProcedure

// Event handler for recording in the server
// 
// Parameters:
// 	Cancel - Boolean -
// 	CurrentObject - CatalogObject.Companies -
// 	WriteParameters - Structure -
// 	Form - ClientApplicationForm -
//
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters, Form) Export
EndProcedure

// Event handler for processing the Fill check in the server
// 
// Parameters:
// 	Cancel - Boolean - a sign of failure.
// 	CheckedAttributes - Array - array of paths to the details being checked.
// 	Form - ClientApplicationForm - handler form
//
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes, Form) Export
EndProcedure

// Handler for the Post-recording event in the server
// 
// Parameters:
// 	CurrentObject - CatalogObject.Companies -
// 	WriteParameters - Structure -
// 	Form - ClientApplicationForm -
//
Procedure AfterWriteAtServer(CurrentObject, WriteParameters, Form) Export
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Form management on the server.
// 
// Parameters:
//  Form - ClientApplicationForm - Form of the Organization's Catalog
Procedure ManagingFormOnServer(Form) Export
	
EndProcedure

Procedure AccountingPolicyWhenServerChanges(Form) Export
EndProcedure

// At the end of the Attribute change.
// 
// Parameters:
//  TagName - String - element name
//  Form - ClientApplicationForm - Form of the Organization's Catalog
//  ProcessingParameters - Structure - processing parameters
Procedure AtEndOfChangeOfProps(TagName, Form, ProcessingParameters) Export
	If TypeOf(TagName) = Type("Array") Then
		For Each CurItem In TagName Do
			AtEndOfChangeOfProps(CurItem, Form, ProcessingParameters);
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Execute the localization command.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CommandName - Arbitrary - Command name
//  ProcessingParameters - Structure - processing parameters
Procedure ExecuteLocalizationCommand(Form, CommandName, ProcessingParameters) Export
	
	If TypeOf(CommandName) = Type("Array") Then
		For Each CurItem In CommandName Do
			ExecuteLocalizationCommand(Form, CurItem, ProcessingParameters);
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region ObjectModuleHandlers

// Pre-Recording Handler
//
// Parameters:
// 	Object - CatalogObject.Companies - 
// 	Cancel - Boolean - 
//
Procedure BeforeWrite(Object, Cancel) Export
	
	
EndProcedure

// Handler for the Recording event
// 
// Parameters:
// 	RecordObject_ - CatalogObject.Companies - a writable directory
// 	Cancel - Boolean - sign of failure
//
Procedure WhenRecordingOrganization(RecordObject_, Cancel) Export 
EndProcedure

Procedure FillCheckProcessing(OrganizationObject, Cancel, CheckedAttributes) Export
	
	
EndProcedure

#EndRegion

#Region OtherUtilityMethods

Procedure SupplementComplianceOfFormElementsWithTaxAccountingPolicyParameters(MatchingElements) Export
	
	ItemArray = New Array();
	ItemArray.Add("TheConfigurationGroupOfSystemOfTaxationIndent");
	ItemArray.Add("TaxSystemSettingsIndent");
	ItemArray.Add("TaxationSystemSettingsGroup");
	ItemArray.Add("DescriptionOfSettingUpTheTaxSystem");
	ItemArray.Add("ToOpenSystemConfigurationNet");

	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfSettingUpTheTaxSystem");
		
	MatchingElements.Insert("TaxationSystemSettings", StructureOfElements);
	
	ItemArray = New Array();
	ItemArray.Add("GroupAccountingPolicyAccountingBuhIndent");
	ItemArray.Add("IndentAccountingPolicyAccountingBoom");
	ItemArray.Add("GroupAccountingPolicyAccountingAccounting");
	ItemArray.Add("DescriptionOfAccountingPolicyOfBuhAccounting");
	ItemArray.Add("OpenAccountingPolicyBuhAccounting");
	
	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfAccountingPolicyOfBuhAccounting");
	
	MatchingElements.Insert("AccountingPolicyBuhAccounting", StructureOfElements);

	ItemArray = New Array();
	ItemArray.Add("GroupOfIncomeTaxAccountingSettings");
	ItemArray.Add("IncomeTaxAccountingSettings");
	ItemArray.Add("IncomeTaxAccountingSettingsGroup");
	ItemArray.Add("DescriptionOfSettingUpIncomeTaxAccounting");
	ItemArray.Add("OpenIncomeTaxAccountingSettings");
	
	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfSettingUpIncomeTaxAccounting");
		
	MatchingElements.Insert("ProfitTaxAccountingSettings", StructureOfElements);

	ItemArray = New Array();
	ItemArray.Add("UsnotAccountingSettingsGroup");
	ItemArray.Add("IndentSTSAccountingSettings");
	ItemArray.Add("STSAccountingSettingsGroup");
	ItemArray.Add("DescriptionOfUSNAccountingSettings");
	ItemArray.Add("ToAccessTheAccountingSetupUSN");

	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfUSNAccountingSettings");
		
	MatchingElements.Insert("STSAccountingSettings", StructureOfElements);
	
	ItemArray = New Array();
	ItemArray.Add("GroupPropertyTaxesIndent");
	ItemArray.Add("IndentPropertyTaxes");
	ItemArray.Add("PropertyTaxesGroup");
	ItemArray.Add("DescriptionOfThePropertyTaxRate");
	ItemArray.Add("OpenPropertyTaxRate");
	ItemArray.Add("TheGroupSPrincipalFunds");
	ItemArray.Add("SceneryRateOfTaxOnThePropertyOfTheMainMeans");
	ItemArray.Add("EstablishTheProcedureForPayingTaxesOnTheGround");
	
	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfThePropertyTaxRate");
	
	MatchingElements.Insert("PropertyTaxRates", StructureOfElements); 
	
	ItemArray = New Array();
	ItemArray.Add("VATAccountingSettingsGroupForUSN");
	ItemArray.Add("DescriptionOfVATAccountingSettingsForUSN");
	ItemArray.Add("OpenVATAccountingSettingsForUSN");
	ItemArray.Add("VATAccountingSettingsGroupForUSNIndentation");
	ItemArray.Add("IndentationOfVATAccountingSettingsForUSN");
	
	StructureOfElements = New Structure();
	StructureOfElements.Insert("ItemArray", ItemArray);
	StructureOfElements.Insert("DescriptionElement", "DescriptionOfVATAccountingSettingsForUSN");
	
	MatchingElements.Insert("VATAccountingSettingsForUSN", StructureOfElements);
	
EndProcedure

Procedure FillInDescriptionOfCurrentAccountingPolicyParametersWhenChangingParentOrganization(Form, RegisterName = "") Export
	MatchingElements = Catalogs.Companies.ComplianceOfFormElementsWithTaxAccountingPolicyParameters();
	AccountingPoliciesTaxSettings.ManagingVisibilityOfAccountingPolicyElements(Form, MatchingElements, Form.Object.ParentCompany);
	AccountingPoliciesTaxSettings.FillInDescriptionOfCurrentParameters(Form, Form.Object.ParentCompany, RegisterName);
	CompaniesLocalization.AccountingPolicyWhenServerChanges(Form);
EndProcedure


Function RegistrationForSeparateDivisionsIsPossible() Export
	Return False
EndFunction

Function FIURegistrationRepository(ObjectRef, UUID) Export
	PensionFundSavedValues = Undefined;
	Return PensionFundSavedValues
EndFunction

#EndRegion

#EndRegion

