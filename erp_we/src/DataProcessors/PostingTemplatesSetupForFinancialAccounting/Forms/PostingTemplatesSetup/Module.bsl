
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	Organization = Parameters.Organization;
	PostingGenerationSetting = Parameters.PostingGenerationSetting;
	ChartOfAccounts = Parameters.ChartOfAccounts;
	
	If ValueIsFilled(PostingGenerationSetting) And Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Common.ObjectAttributeValue(PostingGenerationSetting, "Owner");
	EndIf;
	
	If Not ValueIsFilled(Organization) Then
		Organization = Catalogs.Companies.GetDefaultOrganization();
	EndIf;
	
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	
	ConfigureDynamicListsAccordingToChartOfAccounts();
			
	If Not ValueIsFilled(PostingGenerationSetting) Then
		PostingGenerationSetting = 
			Catalogs.FinancialAccountingPostingGenerationSetting.ConfiguringDefaultPostingGeneration(ChartOfAccounts);
	EndIf;
	
	PostingGenerationSettingOnChangeServer();
	
	FilterChartOfAccounts = "All";
	CurrentMonth = BegOfMonth(CurrentSessionDate());
	
	If Parameters.Property("BusinessOperation") Then
		BusinessOperation = Parameters.BusinessOperation;
		If TypeOf(BusinessOperation) = Type("EnumRef.BusinessTransactions") Then
			BusinessOperation = FinancialAccountingOfGeneralPurpose.BusinessTransferOperation(BusinessOperation);
		EndIf;
		Items.BusinessTransactions.CurrentRow = BusinessOperation;
	EndIf;
	
	SetAvailabilityVisibilityOfItemsOnServer();
	SetSelectionOfTransactionTemplates(Catalogs.BusinessTransactionsSettings.EmptyRef());
	
	// StandardSubsystems.AttachableCommands
	TypesList = PostingTemplates.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.PostingTemplatesCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	AdditionalParameters = New Structure;
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ConfigureDynamicListsAccordingToChartOfAccounts();
	PostingGenerationSettingOnChangeServer();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	DoNotImportSettings = False;
	If ValueIsFilled(ChartOfAccounts) 
			Or ValueIsFilled(PostingGenerationSetting) 
			Or ValueIsFilled(Organization) Then
		DoNotImportSettings = True;
	EndIf;
	
	If DoNotImportSettings And Settings["Organization"] <> Undefined Then
		Settings.Delete("Organization");
	EndIf;
	
	If DoNotImportSettings And Settings["ChartOfAccounts"] <> Undefined Then
		Settings.Delete("ChartOfAccounts");
	EndIf;
	
	If DoNotImportSettings And Settings["PostingGenerationSetting"] <> Undefined Then
		Settings.Delete("PostingGenerationSetting");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	Notify("CompletedConfigurationOfInternationalAccountingTransactionTemplates");

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "RecordedTransactionTemplate" 
		And Items.BusinessTransactions.CurrentRow <> Undefined Then
		NotifyChanged(Items.BusinessTransactions.CurrentRow);
	EndIf;
	
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterChartOfAccountsOnChange(Item)
	
	ChangeDisplayOfChartOfAccountsTable();
	
EndProcedure

&AtClient
Procedure PostingGenerationSettingOnChange(Item)
	
	PostingGenerationSettingOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	ChartOfAccountsOnChangeServer();
	
EndProcedure

&AtClient
Procedure ConfigurationStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	Filter = New Structure;
	Filter.Insert("Organization", Organization);
	Filter.Insert("ChartOfAccounts",   ChartOfAccounts);
	
	If FormattedStringURL = "CreateBusinessAccountPlansEntry" Then
		
		NotificationProcessing = New CallbackDescription("SelectingRecordingPeriodBusinessAccountPlans", ThisObject);
		ShowInputDate(NotificationProcessing, CurrentMonth, NStr("vi = 'Bật thiết lập từ';
																|ru = 'Включить настройку с';
																|en = 'Enable setting since'; fa = 'Enable setting since';
																|it = 'Includere impostazione con';
																|pl = 'Włącz ustawienie od';
																|tr = 'Bununla ayarları etkinleştir'"), DateFractions.Date);
		
		StandardProcessing = False;
	
	ElsIf FormattedStringURL = "OpenHistoryBusinessAccountPlans" Then
			
		FormParameters = New Structure;
		FormParameters.Insert("Filter", Filter);
		OpenForm("InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.Form.ListForm", 
			FormParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBusinessTransactions

&AtClient
Procedure BusinessTransactionsOnActivateRow(Item)
	
	AttachIdleHandler("HandlerBusinessTransactionsOnActivateRow",0.2,True);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInternationalChartOfAccounts

&AtClient
Procedure InternationalChartOfAccountsOnActivateRow(Item)
	
	AttachIdleHandler("ChartOfAccountsHandlerWhenRowIsActivated", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPostingTemplatesByAccount

&AtClient
Procedure PostingTemplatesByAccountSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	If Field = Items.PostingTemplatesByAccountFinancialAccountingGroupPresentation
		And ValueIsFilled(CurrentData.FinancialAccountingGroup) Then
		ShowValue(, CurrentData.FinancialAccountingGroup);
	Else
		ShowValue(, CurrentData.PostingTemplate);
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPostingTemplates

&AtServerNoContext
Procedure PostingTemplatesOnGetDataAtServer(TagName, Settings, Rows)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PostingTemplatesForFinancialAccounting.Ref AS Ref,
		|	PostingTemplatesForFinancialAccounting.AdditionalSelection AS AdditionalSelection
		|FROM
		|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplatesForFinancialAccounting
		|WHERE
		|	PostingTemplatesForFinancialAccounting.Ref IN(&PostingTemplates)";
	
	Query.SetParameter("PostingTemplates", Rows.GetKeys());
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	CustomizingByTemplate = New Map();
	While SelectionDetailRecords.Next() Do
		AdditionalSelection = SelectionDetailRecords.AdditionalSelection; //ValueStorage
		CustomizingByTemplate.Insert(SelectionDetailRecords.Ref, AdditionalSelection.Get());
	EndDo;
	
	SchemeForEconomicOperations = Undefined;
	For Each String In Rows Do
		If SchemeForEconomicOperations = Undefined Then
			SchemeForEconomicOperations = DataSourcesCached.DataAcquisitionScheme(String.Key.Operation);
			If SchemeForEconomicOperations = Undefined Then
				Break;
			EndIf;
			SettingsComposer = New DataCompositionSettingsComposer();
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemeForEconomicOperations));
		EndIf;
		AdditionalSelection = CustomizingByTemplate.Get(String.Key);
		If SchemeForEconomicOperations <> Undefined
			And AdditionalSelection <> Undefined Then 
				SettingsComposer.LoadSettings(AdditionalSelection);
				String.Value.Data.FilterPresentation = String(SettingsComposer.Settings.Filter);
		EndIf; 
	EndDo;
	
EndProcedure

&AtClient
Procedure PostingTemplatesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	CreateGroupOrTransactionTemplate(False);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableBusinessTransactionInTheTransactionGenerationSetting(Command)
	
	ChangeReflectionOfBusinessOperationsInSettings(True);
	
EndProcedure

&AtClient
Procedure ExcludeBusinessTransactionFromTheTransactionGenerationSetting(Command)
	
	ChangeReflectionOfBusinessOperationsInSettings(False);
	
EndProcedure

&AtClient
Procedure IncludeInPostingGenerationSetting(Command)
	
	TemplatesArray1 = Items.PostingTemplates.SelectedRows;
	If TemplatesArray1.Count() = 0 Then
		Return;
	EndIf;
	
	GoToSettingsForGeneratingTransactions(TemplatesArray1, True);
	
EndProcedure

&AtClient
Procedure ExcludeFromPostingGenerationSetting(Command)
	
	TemplatesArray1 = Items.PostingTemplates.SelectedRows;
	If TemplatesArray1.Count() = 0 Then
		Return;
	EndIf;
	
	GoToSettingsForGeneratingTransactions(TemplatesArray1, False);
	
EndProcedure

&AtClient
Procedure EnableAccountTransactionTemplatesInTheTransactionGenerationSetup(Command)
	
	ArrayOfSelectedStrings = Items.PostingTemplatesByAccount.SelectedRows;
	If ArrayOfSelectedStrings.Count() = 0 Then
		Return;
	EndIf;
	
	TemplatesArray1 = ArrayOfSelectedAccountTransactionTemplates(ArrayOfSelectedStrings);
	GoToSettingsForGeneratingTransactions(TemplatesArray1, True);
	AttachIdleHandler("ChartOfAccountsHandlerWhenRowIsActivated", 0.2, True);
	
EndProcedure

&AtClient
Procedure ExcludeAccountTransactionTemplatesFromTheTransactionGenerationSetup(Command)
	
	ArrayOfSelectedStrings = Items.PostingTemplatesByAccount.SelectedRows;
	If ArrayOfSelectedStrings.Count() = 0 Then
		Return;
	EndIf;
	
	TemplatesArray1 = ArrayOfSelectedAccountTransactionTemplates(ArrayOfSelectedStrings);
	GoToSettingsForGeneratingTransactions(TemplatesArray1, False);
	AttachIdleHandler("ChartOfAccountsHandlerWhenRowIsActivated", 0.2, True);
	
EndProcedure

&AtClient
Procedure UpdateFormData(Command)
	
	UpdateFormDataServer();
	
EndProcedure

&AtClient
Procedure CreateFolder(Command)
	
	CreateGroupOrTransactionTemplate(True);
	
EndProcedure

&AtClient
Procedure CreatePostingTemplate(Command)
	
	CreateGroupOrTransactionTemplate(False);
	
EndProcedure

&AtClient
Procedure PostingGenerationSetting(Command)
	If CheckFilling() Then
		FormParameters = New Structure();
		FormParameters.Insert("Key", PostingGenerationSetting);
		OpenForm("Catalog.FinancialAccountingPostingGenerationSetting.ObjectForm", 
			FormParameters, ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
 
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
 
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.PostingTemplates);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.PostingTemplates, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.PostingTemplates);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region Overall

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

#Region BusinessTransactions

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BusinessTransactions.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessTransactions.NotReflectedInTheTransactionGenerationSetup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

#EndRegion

#Region PostingTemplates

#Region ElementDesign

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplates.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.ThisIsTemplateGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.ValidTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.Ignore");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	// Disabling column visibility
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesJointApplicationOption.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.ThisIsTemplateGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
#EndRegion

#Region GroupDesign

	// Disabling column visibility
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesDrAccountDefault.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesDrAccountDefaultDescription.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesCrAccountDefault.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesCrAccountDefaultDescription.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.ThisIsTemplateGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	// Reference label for the group with the option "Displacement"
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesJointApplicationOption.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.ThisIsTemplateGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.JointApplicationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsOfJointApplicationOfPostingTemplates.Exclusion;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mẫu đăng đầu tiên đảm bảo các điều kiện lựa chọn bổ sung';
													|ru = 'Первый в порядке следования шаблон проводки, удовлетворяющий условиям дополнительного отбора';
													|en = 'First posting template which satisfies the additional filter conditions'; fa = 'اولین الگوی ثبتی که شرایط فیلتر تکمیلی را برآورده می‌کند';
													|it = 'Primo modello di registrazione in ordine di procedimento, che soddisfa le condizioni di selezione aggiuntiva';
													|pl = 'Pierwszy w kolejności szablon dekretowania, spełniający warunki filtru dodatkowego';
													|tr = 'Takip sırasına göre, ek seçim koşullarını karşılayan ilk kayıt şablonu'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InformationLabelText);

	// Reference label for the group with the option "All"
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesJointApplicationOption.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.ThisIsTemplateGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.JointApplicationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OptionsOfJointApplicationOfPostingTemplates.All;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả các mẫu đăng trong một nhóm';
													|ru = 'Все шаблоны проводок, входящие в группу';
													|en = 'All posting templates included in the group'; fa = 'همه الگوهای ثبت موجود در گروه';
													|it = 'Tutti i modeli di registrazione che rientrano nel gruppo';
													|pl = 'Wszystkie szablony dekretowania, należace do grupy';
													|tr = 'Gruba ait olan tüm kayıt şablonları'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InformationLabelText);
	
#EndRegion

#EndRegion

#Region PostingTemplatesByAccount

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesByAccountRecordType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplatesByAccount.RecordType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AccountingMovementKinds.Debit;

	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Nợ';
													|ru = 'Дт';
													|en = 'Dr'; fa = 'بد';
													|it = 'Debito';
													|pl = 'Wn';
													|tr = 'Borç'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.DebitTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesByAccountRecordType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplatesByAccount.RecordType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AccountingMovementKinds.Credit;

	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Right);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có';
													|ru = 'Кт';
													|en = 'Cr'; fa = 'بس';
													|it = 'Credito';
													|pl = 'Ma';
													|tr = 'Alacak'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.CreditTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesByAccount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplatesByAccount.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplatesByAccount.Valid");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplatesByAccount.Ignore");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	// Text for default invoices
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesByAccountFinancialAccountingGroupPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplatesByAccount.FinancialAccountingGroup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tài khoản mặc định>';
													|ru = '<Счет по умолчанию>';
													|en = '<Default account>'; fa = '<حساب پیش‌فرض>';
													|it = '<Conto di default>';
													|pl = '<Domyślne konto>';
													|tr = '<Varsayılan hesap>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

#EndRegion

EndProcedure

&AtServer
Procedure SetAvailabilityVisibilityOfItemsOnServer()

	ChangingMFPSettingsIsAvailable = FinancialAccountingOfGeneralPurpose.InternationalAccountingSettingsCanBeChanged();
	
	ItemArray = New Array;
	ItemArray.Add("BusinessTransactionsGroupChangeReflectionInSettingsForGeneratingTransactions");
	ItemArray.Add("PostingTemplatesCreatePostingTemplate");
	ItemArray.Add("PostingTemplatesCreateFolder");
	ItemArray.Add("TransactionTemplatesYouCanChangeReflectionInTransactionGenerationSetting");
	ItemArray.Add("AccountTransactionTemplatesCreateGroup");
	ItemArray.Add("TransactionTemplatesByAccountGroupChangeReflectionInTransactionGenerationSettings");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", ChangingMFPSettingsIsAvailable);

EndProcedure

&AtClient
Function TransactionGenerationSettingsFilledIn()

	TransactionGenerationSettingsFilledIn = ValueIsFilled(PostingGenerationSetting);
	
	If Not TransactionGenerationSettingsFilledIn Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền ""Cài đặt tạo bút toán""';
										|ru = 'Не заполнена ""Настройка формирования проводок""';
										|en = 'The ""Posting schema"" cannot be blank'; fa = 'The ""Posting schema"" cannot be blank';
										|it = 'Non compilata ""Impostazione di formazione delle transazioni""';
										|pl = 'Nie jest wypełnione ""Ustawienie formowania księgowań""';
										|tr = '""Giriş oluşturulması ayarları"" doldurulmadı'"), ,"PostingGenerationSetting");
	EndIf;

	Return TransactionGenerationSettingsFilledIn;
	
EndFunction

&AtServer
Procedure UpdateFormDataServer()
	
	ConfigureDynamicListsByConfiguringTransactionGeneration();
	
EndProcedure

&AtServer
Procedure ConfigureDynamicListsAccordingToChartOfAccounts()
	
	CommonClientServer.SetDynamicListFilterItem(
		InternationalChartOfAccounts, 
		"ChartOfAccounts",
		ChartOfAccounts,
		,
		,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
	CommonClientServer.SetDynamicListFilterItem(
		PostingTemplates,
		"ChartOfAccounts",
		ChartOfAccounts,
		,
		,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
	CommonClientServer.SetDynamicListParameter(
		BusinessTransactions,
		"ChartOfAccounts",
		ChartOfAccounts,
		True);
		
EndProcedure

&AtServer
Procedure ConfigureDynamicListsByConfiguringTransactionGeneration()
	
	CommonClientServer.SetDynamicListParameter(
		BusinessTransactions,
		"PostingGenerationSetting",
		PostingGenerationSetting,
		True);
		
	CommonClientServer.SetDynamicListParameter(
		PostingTemplates,
		"PostingGenerationSetting",
		PostingGenerationSetting, True);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	GetSetupStatus();
	
EndProcedure

&AtServer
Procedure ChartOfAccountsOnChangeServer()
	
	ConfigureDynamicListsAccordingToChartOfAccounts();
	
	PostingGenerationSetting = 
		Catalogs.FinancialAccountingPostingGenerationSetting.ConfiguringDefaultPostingGeneration(ChartOfAccounts);
	PostingGenerationSettingOnChangeServer();
	
EndProcedure

&AtServer
Procedure PostingGenerationSettingOnChangeServer()
	
	GetSetupStatus();
	UpdateFormDataServer();
	
EndProcedure

&AtServer
Procedure GetSetupStatus()
	
	If Not ValueIsFilled(ChartOfAccounts) 
			Or Not ValueIsFilled(Organization)
			Or Not ValueIsFilled(PostingGenerationSetting) Then
		ConfigurationStatus = Undefined;
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(FinancialAccountingChartsOfAccounts.Period) AS Period
	|INTO TTIsAppliedWith
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccounts
	|WHERE
	|	FinancialAccountingChartsOfAccounts.Organization = &Organization
	|	AND FinancialAccountingChartsOfAccounts.ChartOfAccounts = &ChartOfAccounts
	|	AND FinancialAccountingChartsOfAccounts.PostingGenerationSetting = &PostingGenerationSetting
	|;
	|
	|/////////////////////////////////////////////////////////////
	|SELECT
	|	AppliedFrom.Period AS PeriodFrom,
	|	MIN(ISNULL(FinancialAccountingChartsOfAccounts.Period, &DateEmpty)) AS PeriodFor
	|FROM
	|	TTIsAppliedWith AS AppliedFrom
	|	LEFT JOIN 
	|		InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccounts
	|	ON
	|		FinancialAccountingChartsOfAccounts.Organization = &Organization
	|		AND FinancialAccountingChartsOfAccounts.ChartOfAccounts = &ChartOfAccounts
	|		AND FinancialAccountingChartsOfAccounts.PostingGenerationSetting <> &PostingGenerationSetting
	|		AND FinancialAccountingChartsOfAccounts.Period >AppliedFrom.Period
	|WHERE
	|	AppliedFrom.Period <> &DateEmpty
	|
	|GROUP BY
	|	AppliedFrom.Period";
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	Query.SetParameter("DateEmpty", Date(1,1,1));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		If ValueIsFilled(Selection.PeriodFor) Then
			Presentation = StrTemplate(NStr("vi = 'Áp dụng từ %1 đến %2';
											|ru = 'Применялась с %1 по %2';
											|en = 'Has been applied since %1 till %2'; fa = 'Has been applied since %1 till %2';
											|it = 'Applicata da %1 per %2';
											|pl = 'Było stosowane od %1 do %2';
											|tr = '%1 ile %2 arasında uygulandı'"), 
													Format(Selection.PeriodFrom, "DLF=D"), Format(Selection.PeriodFor, "DLF=D"));
			ConfigurationStatus = New FormattedString(
													Presentation, , , , "OpenHistoryBusinessAccountPlans");
		Else
			Presentation = StrTemplate(NStr("vi = 'Áp dụng từ %1';
											|ru = 'Применяется с %1';
											|en = 'Applied since %1'; fa = 'Applied since %1';
											|it = 'Si applica dal %1';
											|pl = 'Jest stosowana od %1';
											|tr = '%1 itibarıyla uygulanıyor'"), Format(Selection.PeriodFrom, "DLF=D"));
			ConfigurationStatus = New FormattedString(
													Presentation, , , , "OpenHistoryBusinessAccountPlans");
		EndIf;
		
	ElsIf AccessRight("Update", Metadata.InformationRegisters.FinancialAccountingChartsOfAccountsForCompanies) Then 
		Presentation = StrTemplate(NStr("vi = 'Bật cho doanh nghiệp từ %1';
										|ru = 'Включить для организации с %1';
										|en = 'Enable for company since %1'; fa = 'Enable for company since %1';
										|it = 'Attivare per organizzazione da %1';
										|pl = 'Włącz dla firm od %1';
										|tr = '%1''den itibaren iş yeri için etkinleştir'"), Format(CurrentMonth, "DLF=D"));
		ConfigurationStatus = New FormattedString(Presentation, , StyleColors.ErrorNoteText, , "CreateBusinessAccountPlansEntry");
	Else
		Presentation = StrTemplate(NStr("vi = 'Không áp dụng cho doanh nghiệp';
										|ru = 'Не применяется для организации';
										|en = 'Not applied for the company'; fa = 'Not applied for the company';
										|it = 'Non si applica per azienda';
										|pl = 'Nie jest stosowane dla firmy';
										|tr = 'İş yerleri için uygulanmıyor'"));
		ConfigurationStatus = New FormattedString(Presentation, , StyleColors.ErrorNoteText);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingRecordingPeriodBusinessAccountPlans(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	CreateBusinessAccountPlansEntry(Result);
	
EndProcedure

&AtServer
Procedure CreateBusinessAccountPlansEntry(Period)
	
	RecordManager = InformationRegisters.FinancialAccountingChartsOfAccountsForCompanies.CreateRecordManager();
	RecordManager.Period = Period;
	RecordManager.ChartOfAccounts = ChartOfAccounts;
	RecordManager.Organization = Organization;
	RecordManager.PostingGenerationSetting = PostingGenerationSetting;
	RecordManager.Write();
	
	GetSetupStatus();
	
EndProcedure

#EndRegion

#Region SettingUpBusinessOperations

&AtClient
Procedure HandlerBusinessTransactionsOnActivateRow()

	CurrentData = Items.BusinessTransactions.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SetSelectionOfTransactionTemplates(CurrentData.Ref);
	
EndProcedure

&AtServer
Procedure SetSelectionOfTransactionTemplates(Val BusinessOperation)
	
	CommonClientServer.SetDynamicListFilterItem(
		PostingTemplates, "Operation", BusinessOperation);
	
EndProcedure

&AtClient
Procedure ChangeReflectionOfBusinessOperationsInSettings(ReflectInInternationalAccounting)

	RowsArray = Items.BusinessTransactions.SelectedRows;
	If RowsArray.Count() = 0 Then
		Return;
	EndIf;
	
	If Not TransactionGenerationSettingsFilledIn() Then
		Return;
	EndIf;
	
	ChangeReflectionOfBusinessOperationsInSettingsForGeneratingTransactionsServer(RowsArray, ChartOfAccounts, PostingGenerationSetting, ReflectInInternationalAccounting);
	
	NotifyChanged(Items.BusinessTransactions.CurrentRow);
	
	Items.PostingTemplates.Refresh();

EndProcedure

// LongDesc
// 
// Parameters:
// 	RowsArray - Array of CatalogRef.BusinessTransactionsSettings - 
// 	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - 
// 	PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - 
// 	ReflectInInternationalAccounting - Boolean - 
&AtServerNoContext
Procedure ChangeReflectionOfBusinessOperationsInSettingsForGeneratingTransactionsServer(RowsArray, ChartOfAccounts, PostingGenerationSetting, ReflectInInternationalAccounting)
	
	RecordSet = InformationRegisters.BusinessTransactionsNotPostedInFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.PostingGenerationSetting.Set(PostingGenerationSetting);
	TableOfRecordsToAdd = RecordSet.Unload();
	TableOfRecordsToDelete = RecordSet.Unload();
	
	RecordSet.Read();
	RecordsTable = RecordSet.Unload();
	
	For Each String In RowsArray Do
		Record = RecordsTable.Find(String.Ref, "Operation");
		If Record = Undefined Then
			If Not ReflectInInternationalAccounting Then
				NewRow = TableOfRecordsToAdd.Add();
				NewRow.PostingGenerationSetting = PostingGenerationSetting;
				NewRow.Operation = String;
			EndIf;
		Else
			If ReflectInInternationalAccounting Then
				NewRow = TableOfRecordsToDelete.Add();
				FillPropertyValues(NewRow, Record);
			EndIf;
		EndIf;
	EndDo;
	
	If TableOfRecordsToAdd.Count() > 0 Then
		RecordSet.Load(TableOfRecordsToAdd);
		RecordSet.Write(False);		
	EndIf;
	
	RecordSet.Clear();
	If TableOfRecordsToDelete.Count() > 0 Then
		
		For Each String In TableOfRecordsToDelete Do
			RecordSet.Filter.Operation.Set(String.Operation);
			RecordSet.Write();
		EndDo;
		
		ReflectSubordinateTransactionTemplatesInTransactionGenerationSetting(TableOfRecordsToDelete, ChartOfAccounts, PostingGenerationSetting);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToSettingsForGeneratingTransactions(TemplatesArray1, IncludeInPostingGenerationSetting)

	If Not TransactionGenerationSettingsFilledIn() Then
		Return;
	EndIf;

	GoToSettingsForGeneratingTransactionsOnServer(TemplatesArray1, IncludeInPostingGenerationSetting);
	
	NotifyChanged(Items.BusinessTransactions.CurrentRow);
	
EndProcedure

&AtServerNoContext
Procedure ReflectSubordinateTransactionTemplatesInTransactionGenerationSetting(ReflectedTransactions, ChartOfAccounts, PostingGenerationSetting)
	
	OperationKinds = ReflectedTransactions.UnloadColumn("Operation");
	
	Query = New Query("SELECT ALLOWED
		|	PostingTemplatesForFinancialAccounting.Ref AS PostingTemplate
		|FROM
		|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplatesForFinancialAccounting
		|WHERE
		|	PostingTemplatesForFinancialAccounting.Operation IN(&OperationArray)
		|	AND PostingTemplatesForFinancialAccounting.ChartOfAccounts = &ChartOfAccounts");
		
	Query.SetParameter("OperationArray", OperationKinds);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	
	QueryResult = Query.Execute().Unload();
	
	If QueryResult.Count() > 0 Then
		TransactionTemplatesForReflection = QueryResult.UnloadColumn("PostingTemplate");
		ChangeReflectionOfTransactionTemplatesInTransactionGenerationSettings(TransactionTemplatesForReflection, PostingGenerationSetting, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure GoToSettingsForGeneratingTransactionsOnServer(TemplatesArray1, IncludeInPostingGenerationSetting)
	
	ChangeReflectionOfTransactionTemplatesInTransactionGenerationSettings(TemplatesArray1, PostingGenerationSetting, IncludeInPostingGenerationSetting);
	Items.PostingTemplates.Refresh();
	
EndProcedure

&AtServerNoContext
Procedure ChangeReflectionOfTransactionTemplatesInTransactionGenerationSettings(TemplatesArray1, PostingGenerationSetting, IncludeInPostingGenerationSetting)
	
	RecordSet = InformationRegisters.RulesOfPostingsInFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.PostingGenerationSetting.Set(PostingGenerationSetting);
	TableOfRecordsToAdd = RecordSet.Unload();
	TableOfRecordsToDelete = RecordSet.Unload();
	
	RecordSet.Read();
	RecordsTable = RecordSet.Unload();
	
	For Each Template In TemplatesArray1 Do
		Record = RecordsTable.Find(Template, "PostingTemplate");
		If Record = Undefined Then
			If IncludeInPostingGenerationSetting Then
				NewRow = TableOfRecordsToAdd.Add();
				NewRow.PostingGenerationSetting = PostingGenerationSetting;
				NewRow.PostingTemplate = Template;
			EndIf;
		Else
			If Not IncludeInPostingGenerationSetting Then
				NewRow = TableOfRecordsToDelete.Add();
				FillPropertyValues(NewRow, Record);
			EndIf;
		EndIf;
	EndDo;
	
	If TableOfRecordsToAdd.Count() > 0 Then
		RecordSet.Load(TableOfRecordsToAdd);
		RecordSet.Write(False);
	EndIf;
	
	RecordSet.Clear();
	For Each String In TableOfRecordsToDelete Do
		RecordSet.Filter.PostingTemplate.Set(String.PostingTemplate);
		RecordSet.Write();
	EndDo;
	
EndProcedure

&AtClient
Function CheckAbilityToCreateTransactionTemplates()

	CurrentData = Items.BusinessTransactions.CurrentData;
	Return ?(CurrentData = Undefined Or CurrentData.IsFolder, False, True);

EndFunction

&AtClient
Procedure CreateGroupOrTransactionTemplate(CreateFolder)

	If Not CheckAbilityToCreateTransactionTemplates() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PostingGenerationSetting", PostingGenerationSetting);
	AdditionalParameters.Insert("ThisIsTemplateGroup", CreateFolder);
	FormParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	FillingValues = New Structure;
	FillingValues.Insert("ChartOfAccounts", ChartOfAccounts);
	FillingValues.Insert("Operation", Items.BusinessTransactions.CurrentRow);
	FormParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("Catalog.PostingTemplatesForFinancialAccounting.ObjectForm", FormParameters, ThisForm);

EndProcedure

#EndRegion

#Region SettingUpChartOfAccounts

&AtClient
Procedure ChartOfAccountsHandlerWhenRowIsActivated()
	
	CurrentData = Items.InternationalChartOfAccounts.CurrentData;
	If CurrentData = Undefined Then
		Account = Undefined;
	Else
		Account = CurrentData.Ref;
	EndIf;
	FillInTableOfTransactionTemplatesForAccount(Account);
	
EndProcedure

&AtServer
Procedure FillInTableOfTransactionTemplatesForAccount(Account)
	
	PostingTemplatesByAccount.Clear();
	
	If Not ValueIsFilled(Account) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PostingTemplates.PostingTemplate AS PostingTemplate,
	|	PRESENTATION(PostingTemplates.PostingTemplate) AS PostingTemplatePresentation,
	|	PostingTemplates.Operation AS Operation,
	|	PostingTemplates.RecordType AS RecordType,
	|	PostingTemplates.AdditionalFilterIsSet AS AdditionalFilterIsSet,
	|	PostingTemplates.Ignore AS Ignore,
	|	PostingTemplates.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	PRESENTATION(PostingTemplates.FinancialAccountingGroup) AS FinancialAccountingGroupPresentation,
	|	CASE
	|		WHEN NOT ReflectionRules.PostingTemplate IS NULL 
	|			THEN TRUE
	|	END AS Valid
	|FROM
	|	(SELECT
	|		PostingTemplates.Ref AS PostingTemplate,
	|		PostingTemplates.Operation AS Operation,
	|		VALUE(Enum.AccountingMovementKinds.Debit) AS RecordType,
	|		PostingTemplates.AdditionalFilterIsSet AS AdditionalFilterIsSet,
	|		PostingTemplates.Ignore AS Ignore,
	|		UNDEFINED AS FinancialAccountingGroup
	|	FROM
	|		Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|	WHERE
	|		PostingTemplates.DrAccountDefault = &Account
	|
	|	UNION ALL
	|
	|	SELECT
	|		PostingTemplates.Ref,
	|		PostingTemplates.Operation,
	|		VALUE(Enum.AccountingMovementKinds.Credit),
	|		PostingTemplates.AdditionalFilterIsSet,
	|		PostingTemplates.Ignore,
	|		UNDEFINED
	|	FROM
	|		Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|	WHERE
	|		PostingTemplates.CrAccountDefault = &Account
	|
	|	UNION ALL
	|
	|	SELECT
	|		PostingTemplates.Ref,
	|		PostingTemplates.Operation,
	|		RulesForClarifyingInvoices.RecordType,
	|		PostingTemplates.AdditionalFilterIsSet,
	|		PostingTemplates.Ignore,
	|		RulesForClarifyingInvoices.FinancialAccountingGroup
	|	FROM
	|		Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|		INNER JOIN
	|			InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting AS RulesForClarifyingInvoices
	|		 ON (RulesForClarifyingInvoices.GLAccount = &Account)
	|			AND PostingTemplates.Ref = RulesForClarifyingInvoices.PostingTemplate
	|	) AS PostingTemplates
	|	
	|	LEFT JOIN
	|		InformationRegister.RulesOfPostingsInFinancialAccounting AS ReflectionRules
	|	ON 
	|		(ReflectionRules.PostingGenerationSetting = &PostingGenerationSetting)
	|		AND PostingTemplates.PostingTemplate = ReflectionRules.PostingTemplate
	|";

	Query.SetParameter("Account", Account);
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	ResultTable2 = Query.Execute().Unload();
	ResultTable2.Sort("RecordType, FinancialAccountingGroupPresentation, PostingTemplatePresentation");
	PostingTemplatesByAccount.Load(ResultTable2);
	
EndProcedure

&AtServer
Procedure ChangeDisplayOfChartOfAccountsTable()
	
	If FilterChartOfAccounts = "All" Then
		Items.InternationalChartOfAccounts.Representation = TableRepresentation.Tree;
	Else
		Items.InternationalChartOfAccounts.Representation = TableRepresentation.List;
	EndIf;
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		InternationalChartOfAccounts, 
		"UsedInTemplates_", 
		True, 
		FilterChartOfAccounts = "UsedInTemplates");
	
EndProcedure

&AtClient
Function ArrayOfSelectedAccountTransactionTemplates(ArrayOfSelectedStrings)

	TemplatesArray1 = New Array;
	For Each String In ArrayOfSelectedStrings Do
		Template = PostingTemplatesByAccount.FindByID(String).PostingTemplate;
		If ValueIsFilled(Template) Then
			TemplatesArray1.Add(Template);
		EndIf;
	EndDo;
	
	Return TemplatesArray1;
	
EndFunction

#EndRegion

#EndRegion
