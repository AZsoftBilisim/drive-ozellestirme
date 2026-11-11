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
	"Catalog.CashGeneratingUnits.Form.CGUExclusionForm.AddToSelected");
	
	AddSelectedFA(Items.FA.SelectedRows);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IASelect(Command)

	PerformanceMonitorClient.TimeMeasurement(
	"Catalog.CashGeneratingUnits.Form.CGUExclusionForm.AddToSelected");
	
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
		FASearchFilter.Insert("FixedAsset", CurFAData.FixedAsset);

		If FAShoppingCart.FindRows(FASearchFilter).Count() = 0 Then
			StringOfSelectedFA = FAShoppingCart.Add();
			StringOfSelectedFA.FixedAsset = CurFAData.FixedAsset;
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
		IASearchFilter.Insert("IntangibleAsset", CurIAData.IntangibleAsset);

		If IAShoppingCart.FindRows(IASearchFilter).Count() = 0 Then
			RowOfSelectedIA = IAShoppingCart.Add();
			RowOfSelectedIA.IntangibleAsset = CurIAData.IntangibleAsset;
			RowOfSelectedIA.Organization = CurIAData.Organization;
		EndIf;

	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FAExcludeFromCGU(Command)

	QuestionAboutBindingKEGDS(FAShoppingCart);

EndProcedure

&AtClient
Procedure ExcludeIAFromCGU(Command)

	QuestionAboutBindingKEGDS(IAShoppingCart);

EndProcedure

&AtClient
Procedure QuestionAboutBindingKEGDS(SelectedAssets)

	If SelectedAssets.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn đối tượng để loại bỏ khỏi đơn vị tạo tiền.';
										|ru = 'Объекты для исключения из ЕГДС не выбраны.';
										|en = 'Objects to be excluded from the cash-generating unit are not selected.'; fa = 'Objects to be excluded from the cash-generating unit are not selected.';
										|it = 'Gli oggetti per l''esclusione dall''unità generatrice di cassa non sono selezionati.';
										|pl = 'Nie wybrano obiektów do wykluczenia z jednostki generującej środki pieniężne.';
										|tr = 'NYB''den çıkarılmak üzere hiçbir nesne seçilmemiştir.'"));
		Return;
	EndIf;

	QueryText = NStr("vi = 'Loại trừ các đối tượng đã chọn khỏi %1?';
					|ru = 'Исключить выбранные объекты из %1?';
					|en = 'Exclude selected objects from %1?'; fa = 'Exclude selected objects from %1?';
					|it = 'Escludere gli oggetti selezionati da %1?';
					|pl = 'Wykluczyć wybrane obiekty z %1?';
					|tr = 'Seçilen nesneler %1''den hariç tutulsun mu?'");
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
	"Catalog.CashGeneratingUnits.Form.CGUExclusionForm.CreatingDocuments");

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
		FillingValues.Insert("CGU", PredefinedValue("Catalog.CashGeneratingUnits.EmptyRef"));

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

	FA.Parameters.SetParameterValue("CGU", CGU);

	IA.Parameters.SetParameterValue("CGU", CGU);

EndProcedure

#EndRegion
