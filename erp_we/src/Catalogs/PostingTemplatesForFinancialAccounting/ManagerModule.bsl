#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes the linker for data layout settings,
// based on the data source for getting business transaction data.
//
// Parameters:
//	Form - Form - object form.
//	BusinessOperation - CatalogRef.BusinessTransactionsSettings - a business operation
//							that determines the source of data acquisition.
//
Procedure InitializeComposer(Form, BusinessOperation) Export

	Form.AddressOfDataCompositionSchema = GetDataLayoutDiagram(Form, BusinessOperation);
	If ValueIsFilled(Form.AddressOfDataCompositionSchema) Then
		Form.Composer.Initialize(New DataCompositionAvailableSettingsSource(Form.AddressOfDataCompositionSchema));
	EndIf;

EndProcedure

// Loads settings in the settings Builder.
//
// Parameters:
//	Form - Form - object form.
//	Settings - DataCompositionSettings - downloadable settings.
//
Procedure LoadSettings(Form, Settings) Export

	If Settings <> Undefined Then
		Form.Composer.LoadSettings(Settings);
	EndIf;

EndProcedure

// Records information about additional selection set in the object.
// Called in the "pre-write Server" events in the directory forms.
//
// Parameters:
//	Form - Form - object form.
//	Object - CatalogObject.PostingTemplatesForFinancialAccounting - the object being recorded.  
//
Procedure RecordAdditionalSelection(Form, Object) Export

	Object.AdditionalSelection = New ValueStorage(Form.Composer.GetSettings());
	Object.FilterPresentation = String(Form.Composer.Settings.Filter);

EndProcedure

// Generates an image index for the directory object.
//
// Parameters:
//	PostingTemplate - CatalogObject.PostingTemplatesForFinancialAccounting - the wiring pattern.
//
// Returns:
//	Number - index of the image.
//
Function PictureIndex(PostingTemplate) Export

	If PostingTemplate.ThisIsTemplateGroup Then
		If PostingTemplate.JointApplicationOption = Enums.OptionsOfJointApplicationOfPostingTemplates.All Then
			Result = 0;
		Else
			Result = 1;
		EndIf;
	Else
		Result = 2;
	EndIf;
	
	If PostingTemplate.DeletionMark Then
		Result = Result + 3
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		StandardProcessing = False;
		ThisIsTemplateGroup = False;
		PostingTemplate = Undefined;
		If Parameters.Property("Key", PostingTemplate) And ValueIsFilled(PostingTemplate)
			Or Parameters.Property("CopyingValue", PostingTemplate) And ValueIsFilled(PostingTemplate) Then
			ThisIsTemplateGroup = InternationalReportingServerCall.ThisIsTemplateGroup(PostingTemplate);
		ElsIf Parameters.Property("AdditionalParameters") Then
			If Parameters.AdditionalParameters.Property("ThisIsTemplateGroup") Then
				ThisIsTemplateGroup = Parameters.AdditionalParameters.ThisIsTemplateGroup;
			EndIf;
		EndIf;
		
		SelectedForm = "Catalog.PostingTemplatesForFinancialAccounting.Form." + ?(ThisIsTemplateGroup, "FolderForm", "ItemForm");
	EndIf;

EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function GetDataLayoutDiagram(Form, BusinessOperation)

	DCSAddress = Undefined;
	DataCompositionSchema = DataSourcesCached.DataAcquisitionScheme(BusinessOperation);
	If DataCompositionSchema <> Undefined Then
		DCSAddress = PutToTempStorage(DataCompositionSchema, Form.UUID);
	EndIf;
	
	Return DCSAddress;

EndFunction

#EndRegion

#EndIf
