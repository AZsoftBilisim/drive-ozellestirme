
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not (Parameters.Property("PostingTemplate")
		And Parameters.Property("RecordType")) Then
	    MessageText = NStr("vi = 'Không thể mở trực tiếp biểu mẩu này';
							|ru = 'Непосредственное открытие этой формы не предусмотрено';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane';
							|tr = 'Bu formun doğrudan açılması sağlanamadı'");
	    Raise MessageText;
	EndIf;
	
	PostingTemplate = Parameters.PostingTemplate;
	AttributesEntryTemplate = Common.ObjectAttributesValues(PostingTemplate,
		"ChartOfAccounts, AccountSpecificationSourceTypeDr, DrAccountDefault, AccountSpecificationSourceTypeCr, CrAccountDefault");
	ChartOfAccounts = AttributesEntryTemplate.ChartOfAccounts;
	RecordType = Parameters.RecordType;

	If RecordType = Enums.AccountingMovementKinds.Debit Then
		AccountAttributesDr = Common.ObjectAttributesValues(AttributesEntryTemplate.DrAccountDefault, "Code, Description");
		AccountSpecificationSourceType = AttributesEntryTemplate.AccountSpecificationSourceTypeDr;
		DefaultAccountPresentation = AccountAttributesDr.Code + ", " + AccountAttributesDr.Description;
		Items.DefaultAccountPresentation.Title = NStr("vi = 'Tài khoản Nợ (mặc định)';
														|ru = 'Счет Дт (по умолчанию)';
														|en = 'Dr account (default)'; fa = 'حساب بدهکار (پیش‌فرض)';
														|it = 'Conto a debito (predefinito)';
														|pl = 'Konto Wn (domyślne)';
														|tr = 'Borç hesabı (varsayılan)'");
	Else
		AccountAttributesCr = Common.ObjectAttributesValues(AttributesEntryTemplate.CrAccountDefault, "Code, Description");
		AccountSpecificationSourceType = AttributesEntryTemplate.AccountSpecificationSourceTypeCr;
		DefaultAccountPresentation = AccountAttributesCr.Code + ", " + AccountAttributesCr.Description;
		Items.DefaultAccountPresentation.Title = NStr("vi = 'Tài khoản Có (mặc định)';
														|ru = 'Счет Кт (по умолчанию)';
														|en = 'Cr account (default)'; fa = 'حساب بستانکار (پیش‌فرض)';
														|it = 'Conto a credito (predefinito)';
														|pl = 'Konto Ma (domyślne)';
														|tr = 'Alacak hesabı (varsayılan)'");
	EndIf;
	
	Items.FinancialAccountingGroupsDescription.Title = AccountSpecificationSourceType;
	
	FinancialAccountingGroupFilter = "All";
	
	ShowAccountingInvoices();
		
	If Parameters.Property("FinancialAccountingGroup") Then
		SetCurRowOfInvoiceTable(Parameters.FinancialAccountingGroup);				
	EndIf;
	
	SetAvailabilityVisibilityOfItemsOnServer();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	ArrayOfSelectedRows = Items.FinancialAccountingGroups.SelectedRows;
	If ArrayOfSelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If ValueIsFilled(ValueSelected) Then
		FillInAccountingInvoices(ArrayOfSelectedRows, ValueSelected);		
	EndIf;	
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	ShowAccountingInvoices();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FinancialAccountingGroupFilterOnChange(Item)
	
	ShowAccountingInvoices();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure FinancialAccountingGroupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.FinancialAccountingGroupsDescription Then
		CurrentData = FinancialAccountingGroups.FindByID(RowSelected);
		
		FormParameters = New Structure("Key", CurrentData.Ref);
		CatalogName = FinancialAccountingClientServer.NameOfFinancialAccountingGroupsCatalog(AccountSpecificationSourceType);
		OpenForm("Catalog." + CatalogName + ".ObjectForm", FormParameters, ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateFinancialAccountingGroup(Command)
	
	CallbackDescription = New CallbackDescription("HandlerShowIssueWhenCreatingFinancialAccountingGroup", ThisObject);
	QueryText = NStr("vi = 'Các cài đặt sàng lọc tài khoản hiện tại sẽ được ghi lại. Tiếp tục?';
					|ru = 'Текущие настройки уточнения счета будут записаны. Продолжить?';
					|en = 'The current settings of account specification will be saved. Continue?'; fa = 'The current settings of account specification will be saved. Continue?';
					|it = 'Le impostazioni correnti di correzione del conto verranno registrate. Continuare?';
					|pl = 'Ustawienia bieżące uściślenia rachunku zostaną zapisane. Kontynuować?';
					|tr = 'Cari hesap iyileştirme ayarları kaydedilecektir. Devam edilsin mi?'");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	ArrayOfSelectedRows = Items.FinancialAccountingGroups.SelectedRows;
	If ArrayOfSelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("ChartOfAccounts", ChartOfAccounts));
	OpenForm("ChartOfAccounts.International.ChoiceForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	RecordAccountingAccounts();
	Close();
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	RecordAccountingAccounts();
	Modified = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FinancialAccountingGroupsGLAccount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FinancialAccountingGroups.GLAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tài khoản mặc định>';
													|ru = '<Счет по умолчанию>';
													|en = '<Default account>'; fa = '<حساب پیش‌فرض>';
													|it = '<Conto di default>';
													|pl = '<Domyślne konto>';
													|tr = '<Varsayılan hesap>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FinancialAccountingGroupsDescription.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FinancialAccountingGroups.GLAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

&AtServer
Procedure ShowAccountingInvoices()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	RulesForClarifyingInvoices.FinancialAccountingGroup,
	|	RulesForClarifyingInvoices.PostingTemplate,
	|	RulesForClarifyingInvoices.RecordType,
	|	RulesForClarifyingInvoices.GLAccount
	|INTO RulesForClarifyingInvoices
	|FROM
	|	InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting AS RulesForClarifyingInvoices
	|WHERE
	|	RulesForClarifyingInvoices.PostingTemplate = &PostingTemplate
	|	AND RulesForClarifyingInvoices.RecordType = &RecordType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialAccountingGroups.Ref AS Ref,
	|	FinancialAccountingGroups.Description AS Description,
	|	RulesForClarifyingInvoices.GLAccount AS GLAccount
	|FROM
	|	&CatalogFinancialAccountingGroups AS FinancialAccountingGroups
	|		LEFT JOIN RulesForClarifyingInvoices AS RulesForClarifyingInvoices
	|		ON (RulesForClarifyingInvoices.FinancialAccountingGroup = FinancialAccountingGroups.Ref)
	|WHERE
	|	FinancialAccountingGroups.DeletionMark = FALSE
	|	AND FinancialAccountingGroups.IsFolder = FALSE
	|	AND (RulesForClarifyingInvoices.GLAccount IS NOT NULL OR &ShowAllFinancialAccountingGroups)
	|
	|ORDER BY
	|	FinancialAccountingGroups.Description
	|";
	
	Query.Text = StrReplace(Query.Text, "&CatalogFinancialAccountingGroups", 
	   "Catalog." + FinancialAccountingClientServer.NameOfFinancialAccountingGroupsCatalog(AccountSpecificationSourceType));
	
	Query.SetParameter("PostingTemplate", PostingTemplate);
	Query.SetParameter("RecordType", RecordType);
	Query.SetParameter("ShowAllFinancialAccountingGroups", FinancialAccountingGroupFilter = "All");
	
	FinancialAccountingGroups.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure SetCurRowOfInvoiceTable(FinancialAccountingGroup)

	FilterParameters = New Structure("Ref", FinancialAccountingGroup);
	RowsArray = FinancialAccountingGroups.FindRows(FilterParameters);
	If RowsArray.Count() > 0 Then
		Items.FinancialAccountingGroups.CurrentRow = RowsArray[0].GetID();	
		Items.FinancialAccountingGroups.CurrentItem = Items.FinancialAccountingGroupsGLAccount;
	EndIf;

EndProcedure

&AtServer
Procedure RecordAccountingAccounts()

	RecordSet = InformationRegisters.RulesOfSpecifyingAccountsFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.PostingTemplate.Set(PostingTemplate);
	RecordSet.Filter.RecordType.Set(RecordType);
	For Each  String In FinancialAccountingGroups Do
		If ValueIsFilled(String.GLAccount) Then
 			NewRecord	= RecordSet.Add();
			NewRecord.PostingTemplate = PostingTemplate;
			NewRecord.FinancialAccountingGroup = String.Ref;
			NewRecord.RecordType = RecordType;
			NewRecord.GLAccount = String.GLAccount;
		EndIf;
	EndDo;
	RecordSet.Write();

EndProcedure

&AtClient
Procedure FillInAccountingInvoices(ArrayOfSelectedRows, GLAccount)

	For Each RowID In ArrayOfSelectedRows Do
		FoundRow = FinancialAccountingGroups.FindByID(RowID);
		FoundRow.GLAccount = GLAccount;
	EndDo;

EndProcedure

&AtServer
Procedure SetAvailabilityVisibilityOfItemsOnServer()

	ChangingMFPSettingsIsAvailable = FinancialAccountingOfGeneralPurpose.InternationalAccountingSettingsCanBeChanged();
	
	ItemArray = New Array;
	ItemArray.Add("FormWriteAndClose");
	ItemArray.Add("FinancialAccountingGroups");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not ChangingMFPSettingsIsAvailable);
	
	ItemArray = New Array;
	ItemArray.Add("CreateFinancialAccountingGroup");
	ItemArray.Add("ChangeSelectedItems");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", ChangingMFPSettingsIsAvailable);

EndProcedure

&AtClient
Procedure HandlerShowIssueWhenCreatingFinancialAccountingGroup(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		RecordAccountingAccounts();
		OpenForm("Catalog."
					+ FinancialAccountingClientServer.NameOfFinancialAccountingGroupsCatalog(AccountSpecificationSourceType)
					+ ".ObjectForm",, ThisForm);
	EndIf;

EndProcedure

#EndRegion
