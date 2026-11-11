#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetValuesForFormParameters(Parameters);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryTextImportApplicationsForRegistration();
	Common.SetDynamicListProperties(Items.ListOrders, ListProperties);
	
	SetSelectionsByOrganization();
	SetSelectionByImportDocumentType();
	SetSelectionByPeriod();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_PaymentRequest"
		Or EventName = "Write_BankAccountIssue"
		Or EventName = "Write_ApplicationForImportationOfGoods"
		Or EventName = "Write_VendorInvoice"
		Or EventName = "Write_SubcontractorReport2_5"
		Or EventName = "Write_SigningOfLeaseContract"
		Or EventName = "Write_LeaseTermAdjustment"
		Or EventName = "Write_LeaseTermination"
		Or EventName = "Write_VendorInvoiceLeasedAssets" Then
		
		Items.ListOrders.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	If CompanySavedValue <> Organization Then
		
		SetSelectionsByOrganization();
		CompanySavedValue = Organization;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkPurchaseHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.OpenLog(LogParameters());
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOrders

&AtClient
Procedure ListOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	Value = Item.CurrentData.ReferenceOrder;
	ShowValue(Undefined, Value);
	
EndProcedure  

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToFormStatementOnImportOfGoods(Command)
	
	List = Items.ListOrders;
	SelectedRows = List.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows,LogParameters()) Then
		Return;
	EndIf;
	
	If SelectedRows.Count() = 1
		And TypeOf(List.CurrentRow) = Type("DynamicListGroupRow") Then
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
							|ru = 'Команда не может быть выполнена для указанного объекта!';
							|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
							|it = 'Il comando non può essere eseguito per oggetto indicato!';
							|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
		
	ReferencesArrray = New Array();
		
	For Each SelectedRow In SelectedRows Do
		If TypeOf(SelectedRow) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		ReferencesArrray.Add(List.RowData(SelectedRow));
	EndDo;
	
	If ReferencesArrray.Count() = 0 Then
		WarningText = NStr("vi = 'Chưa chọn chứng từ nào để nhập trên cơ sở!';
							|ru = 'Не выбрано ни одного документа для ввода на основании!';
							|en = 'No document for entering on the basis is selected.'; fa = 'No document for entering on the basis is selected.';
							|it = 'Non è selezionato nessun documento per l''inserimento nel documento di base!';
							|pl = 'Nie wybrano żadnego dokumentu do wprowadzenia na podstawie!';
							|tr = 'Giriş için hiçbir belge seçilmemiştir!'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	ClearMessages();
	
	For Each ApplicationForm_ In ReferencesArrray Do
		
		If TypeOf(ApplicationForm_.ReferenceOrder) = Type("DocumentRef.VendorInvoice") Then
			OpenForm("Document.ApplicationForImportationOfGoods.ObjectForm", New Structure("Basis", ApplicationForm_.ReferenceOrder), , True);
			
		ElsIf TypeOf(ApplicationForm_.ReferenceOrder) = Type("DocumentRef.SigningOfLeaseContract") Then 
			OpenForm("Document.ApplicationForImportationOfGoods.ObjectForm", New Structure("Basis", GeneralPurposeTMServerCall.ObjectAttributeValue(ApplicationForm_.ReferenceOrder, "Contract")), , True);
			
		Else
			OpenForm("Document.ApplicationForImportationOfGoods.ObjectForm", New Structure("Basis", ApplicationForm_.ReferenceOrder), , True);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListOrders.Date", "ListOrdersDate");
	
EndProcedure

&AtServer
Procedure SetSelectionsByOrganization()
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If ValueIsFilled(Organization)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOrders,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Organization));
		
	Items.ListOrdersOrganization.Visible = Not ValueIsFilled(Organization);
	
EndProcedure

&AtServer
Procedure SetSelectionByImportDocumentType()
	
	ListOrders.Parameters.SetParameterValue("TypeImportStatement", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	ListOrders.Parameters.SetParameterValue("RemainderPeriod_", EndOfDay(CurrentSessionDate()));
	
EndProcedure

&AtServer
Procedure SetValuesForFormParameters(Var_Parameters)
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		Var_Parameters.QuickFilterStructure.Property("Organization", Organization);
	EndIf;
	
EndProcedure

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",QuickFilterStructure);
	LogParameters.Insert("FormAssignmentKey", "ImportApplicationsForRegistration");
	LogParameters.Insert("WorkplaceName","LogOfPurchaseDocuments");
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ mua hàng';
												|ru = 'Документы закупки';
												|en = 'Purchase documents'; fa = 'اسناد خرید';
												|it = 'Documenti d''acquisto';
												|pl = 'Dokument zakupu';
												|tr = 'Satın alma belgeleri'"));
	
	Return LogParameters;
	
EndFunction

&AtServer
Function QueryTextImportApplicationsForRegistration()

	BaseRequestTexts = TextOfRequestForTheseGroundsForProcessingApplicationsForImportOfGoods();
	
	ArrayOfRequestTexts = New Array;
	ArrayOfRequestTexts.Add(BaseRequestTexts.TextTT);
	QueryText = 
	"SELECT ALLOWED
	|	Data_For_Registration.Ref AS Ref,
	|	Data_For_Registration.ReferenceOrder AS ReferenceOrder,
	|	Data_For_Registration.Number AS Number,
	|	Data_For_Registration.Date AS Date,
	|	Data_For_Registration.Currency AS Currency,
	|	Data_For_Registration.Counterparty AS Counterparty,
	|	Data_For_Registration.DocumentAmount AS DocumentAmount,
	|	Data_For_Registration.Organization AS Organization,
	|	Data_For_Registration.Order AS Order
	|FROM
	|	#QueryTextBasis1 AS Data_For_Registration
	|";
	QueryText = StrReplace(QueryText, "#QueryTextBasis1", "(" + BaseRequestTexts.QueryText + ")");
	ArrayOfRequestTexts.Add(QueryText);
	QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Return QueryText;

EndFunction

&AtServer
Function TextOfRequestForTheseGroundsForProcessingApplicationsForImportOfGoods()
	
	ArrayOfRequestTexts = New Array;
	
	QueryTemplate = "
	|
	|SELECT
	|	&Ref AS Ref,
	|	TheseGrounds.Ref AS ReferenceOrder,
	|	CAST(TheseGrounds.Number AS STRING(12)) AS Number,
	|	TheseGrounds.Date AS Date,
	|	TheseGrounds.Currency AS Currency,
	|	TheseGrounds.Counterparty AS Counterparty,
	|	TheseGrounds.DocumentAmount AS DocumentAmount,
	|	TheseGrounds.Organization AS Organization,
	|	&Order AS Order
	|FROM
	|	#TheseGrounds AS TheseGrounds
	|		INNER JOIN #References AS TTOrder_
	|		ON TheseGrounds.Ref = TTOrder_.DocumentInflow
	|";
	
	TextTT = 
	"SELECT ALLOWED DISTINCT
	|	GoodsForRegistrationBalance.DocumentInflow AS DocumentInflow
	|INTO TTOrderForProcessingApplicationsForImportOfNewMechanics
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(, ImportDocumentType = &TypeImportStatement) AS GoodsForRegistrationBalance
	|WHERE
	|	GoodsForRegistrationBalance.CountBalance > 0
	|
	|INDEX BY
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	GoodsForRegistrationBalance.DocumentInflow AS DocumentInflow
	|INTO TTOrderForProcessingApplicationsForImportationByLease
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(&RemainderPeriod_, ImportDocumentType = &TypeImportStatement) AS GoodsForRegistrationBalance
	|WHERE
	|	GoodsForRegistrationBalance.SumBalance > 0 AND VALUETYPE(GoodsForRegistrationBalance.DocumentInflow) = TYPE(Document.SigningOfLeaseContract)
	|
	|INDEX BY
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	GoodsForRegistrationBalance.DocumentInflow AS DocumentInflow
	|INTO TTOrderForProcessingImportApplications
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfApplicationForImportFromEEUCountries.Balance AS GoodsForRegistrationBalance
	|WHERE
	|	GoodsForRegistrationBalance.ToRegisterBalance > 0	
	|
	|INDEX BY
	|	DocumentInflow";
	
	TypesArray = Documents.ApplicationForImportationOfGoods.TypesOfDocumentsGroundsForRegistration();
	
	QueryText = "";
	Order = 0;
	
	For Each TypeName In TypesArray Do
		
		If Not AccessRight("Read", Metadata.Documents[TypeName]) Then
			Continue;
		EndIf;
		
		Order = Order+1;
		
		RequestTextForType = StrReplace(QueryTemplate, "#TheseGrounds", "Document." + TypeName);
		RequestTextForType = StrReplace(RequestTextForType, "&Order", Order);
		
		If TypeName = "VendorInvoice" Then
			RequestTextForType = StrReplace(RequestTextForType, "&Ref", "TheseGrounds.Ref");
			RequestTextForType = StrReplace(RequestTextForType, "#References", "TTOrderForProcessingApplicationsForImportOfNewMechanics");
			ArrayOfRequestTexts.Add(RequestTextForType);
			
			Order = Order+1;
			RequestTextForType = StrReplace(QueryTemplate, "#TheseGrounds", "Document." + TypeName);
			RequestTextForType = StrReplace(RequestTextForType, "&Order", Order);
			RequestTextForType = StrReplace(RequestTextForType, "&Ref", "TheseGrounds.Ref");
			RequestTextForType = StrReplace(RequestTextForType, "#References", "TTOrderForProcessingImportApplications");
		ElsIf TypeName = "SubcontractorReport2_5" Then
			RequestTextForType = StrReplace(RequestTextForType, "&Ref", "TheseGrounds.Ref");
			RequestTextForType = StrReplace(RequestTextForType, "#References", "TTOrderForProcessingApplicationsForImportOfNewMechanics");
		ElsIf TypeName = "SigningOfLeaseContract" Then 
			RequestTextForType = StrReplace(RequestTextForType, "&Ref", "TheseGrounds.Contract");
			RequestTextForType = StrReplace(RequestTextForType, "#References", "TTOrderForProcessingApplicationsForImportationByLease");
		EndIf;
	
		ArrayOfRequestTexts.Add(RequestTextForType);

	EndDo;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ReturnStructure = New Structure("TextTT, QueryText", TextTT, QueryText);
	Return ReturnStructure;
	
EndFunction

#EndRegion