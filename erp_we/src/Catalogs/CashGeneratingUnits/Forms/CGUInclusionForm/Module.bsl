#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Organization = Parameters.Organization;
	CGU = Parameters.CGU;

	SetParametersForDynamicLists();
	
	VisibilityManagement();

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "Write_ChangeFixedAssetFinancialDetails2_4" Then
		FAShoppingCart.Clear();
	ElsIf EventName = "Write_ChangeIntangibleAssetFinancialDetails2_4" Then
		IAShoppingCart.Clear();
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FASelect(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Catalog.CashGeneratingUnits.Form.CGUInclusionForm.OSAddingToListOfSelected");
		
	AddSelectedFA(Items.FA.SelectedRows);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IASelect(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Catalog.CashGeneratingUnits.Form.CGUInclusionForm.HMAAddingToListOfSelected");
		
	AddSelectedIA(Items.IA.SelectedRows);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFAShoppingCart

&AtClient
Procedure FAShoppingCartDrag(Item, DragParameters, StandardProcessing, String, Field)

	AddSelectedFA(DragParameters.Value);

EndProcedure

// Add the selected OS.
//
// Parameters:
// FAHighlightedLines - Array
&AtClient
Procedure AddSelectedFA(FAHighlightedLines)

	For Each FAString In FAHighlightedLines Do

		CurFAData = Items.FA.RowData(FAString);

		FASearchFilter = New Structure;
		FASearchFilter.Insert("FixedAsset", CurFAData.Ref);

		If FAShoppingCart.FindRows(FASearchFilter).Count() = 0 Then
			StringOfSelectedFA = FAShoppingCart.Add();
			StringOfSelectedFA.FixedAsset = CurFAData.Ref;
			StringOfSelectedFA.Organization = CurFAData.Organization;
		EndIf;

	EndDo;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIAShoppingCart

&AtClient
Procedure IAShoppingCartDrag(Item, DragParameters, StandardProcessing, String, Field)

	AddSelectedIA(DragParameters.Value);

EndProcedure

// Add selected NMAs.
//
// Parameters:
// IAHighlightedLines - Array
&AtClient
Procedure AddSelectedIA(IAHighlightedLines)

	For Each IAString In IAHighlightedLines Do

		CurIAData = Items.IA.RowData(IAString);

		IASearchFilter = New Structure;
		IASearchFilter.Insert("IntangibleAsset", CurIAData.Ref);

		If IAShoppingCart.FindRows(IASearchFilter).Count() = 0 Then
			RowOfSelectedIA = IAShoppingCart.Add();
			RowOfSelectedIA.IntangibleAsset = CurIAData.Ref;
			RowOfSelectedIA.Organization = CurIAData.Organization;
		EndIf;

	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FAToIncludeInCGU(Command)
	
	QuestionAboutBindingKEGDS(FAShoppingCart);

EndProcedure

&AtClient
Procedure IAToIncludeInCGU(Command)

	QuestionAboutBindingKEGDS(IAShoppingCart);

EndProcedure

&AtClient
Procedure QuestionAboutBindingKEGDS(SelectedAssets)

	If SelectedAssets.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn đối tượng để đưa vào đơn vị tạo tiền.';
										|ru = 'Объекты для включения в ЕГДС не выбраны.';
										|en = 'Objects to be included in the cash-generating unit are not selected.'; fa = 'Objects to be included in the cash-generating unit are not selected.';
										|it = 'Gli oggetti da includere nell''unità generatrice di cassa non sono selezionati.';
										|pl = 'Nie wybrano obiektów do włączenia do jednostki generującej środki pieniężne.';
										|tr = 'NYB''ye dahil edilmek üzere hiçbir nesne seçilmemiştir.'"));
		Return;
	EndIf;

	QueryText = NStr("vi = 'Đưa các đối tượng đã chọn vào %1?';
					|ru = 'Включить выбранные объекты в %1?';
					|en = 'Include selected objects in %1?'; fa = 'Include selected objects in %1?';
					|it = 'Includere gli oggetti selezionati in %1?';
					|pl = 'Włączyć wybrane obiekty do %1?';
					|tr = 'Seçilen nesneler %1''e dahil edilsin mi?'");
	QuestionTextWithParameter = StrTemplate(QueryText, CGU);

	FingerprintParameters = New Structure;
	FingerprintParameters.Insert("SelectedAssets", SelectedAssets);

	UserAnswer = New CallbackDescription("ContinueLinkingVNA", ThisForm, FingerprintParameters);

	ShowQueryBox(UserAnswer, QuestionTextWithParameter, QuestionDialogMode.YesNo);

EndProcedure

// Continue linking the HPA.
//
// Parameters:
// QuestionResult - DialogReturnCode - The result of the question
// FingerprintParameters - Structure - Binding Parameters:
// * SelectedAssets - ValueTable - Table of selected assets
&AtClient
Procedure ContinueLinkingVNA(QuestionResult, FingerprintParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
	"Catalog.CashGeneratingUnits.Form.CGUInclusionForm.CreatingDocuments");	

	ChangeBinding(FingerprintParameters);

EndProcedure

// Change the binding.
//
// Parameters:
// FingerprintParameters - Structure - Binding Parameters:
// * SelectedAssets - FormDataCollection -
&AtClient
Procedure ChangeBinding(FingerprintParameters)

	CompaniesList = New Array;
	For Each RowOfSelectedAssets In FingerprintParameters.SelectedAssets Do
		CompaniesList.Add(RowOfSelectedAssets.Organization);
	EndDo;

	For Each Organization In CompaniesList Do
		
		ListOfOrganizationSAssets = FingerprintParameters.SelectedAssets.FindRows(New Structure("Organization", Organization));
		
		FirstAsset = ListOfOrganizationSAssets.Get(0);
		IsFA = FirstAsset.Property("FixedAsset");
		If IsFA Then
			FieldName = "FixedAsset";
			TheTableNameOfTheDocument = "FA";
			NameOfDocumentForm = "Document.ChangeFixedAssetFinancialDetails2_4.Form.DocumentForm";
		Else
			FieldName = "IntangibleAsset";
			TheTableNameOfTheDocument = "IA";
			NameOfDocumentForm = "Document.ChangeIntangibleAssetFinancialDetails2_4.Form.DocumentForm";
		EndIf;
		
		ListOfAssets = New Array;
		For Each AssetLine In ListOfOrganizationSAssets Do
			ListOfAssets.Add(New Structure( FieldName, AssetLine[FieldName]));
			
		EndDo;
		
		FillingValues = New Structure;
		FillingValues.Insert("OperationKind", "ChangingCGU");
		FillingValues.Insert("Date", GetSessionDateOnServer());
		FillingValues.Insert("Organization", Organization);
		FillingValues.Insert("CGUFlag", True);
		FillingValues.Insert("CGU", CGU);

		FillingValues.Insert(TheTableNameOfTheDocument, ListOfAssets);
		OpeningParameters = New Structure("FillingValues", FillingValues);
		
		OpenForm(NameOfDocumentForm, OpeningParameters, ThisObject, New UUID());

	EndDo;

EndProcedure

&AtServer
Function GetSessionDateOnServer()

	Return CurrentSessionDate();
	
EndFunction

#EndRegion

#Region Private

&AtServer
Procedure VisibilityManagement()
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	Items.Organization.Visible = UseMultipleCompanies;
	
EndProcedure

&AtServer
Procedure SetParametersForDynamicLists()
	CompaniesList = ImpairmentFAServer.GetOrganizationsForImpairment(Organization);
	
	FA.Parameters.SetParameterValue("Organization", CompaniesList);
	IA.Parameters.SetParameterValue("Organization", CompaniesList);

EndProcedure

#EndRegion
