
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		If Parameters.Property("FillingValues") And Parameters.FillingValues.Property("AssetLiability") Then
			Object.AssetLiability = Parameters.FillingValues.AssetLiability;
		Else
			Object.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
		EndIf;
		OnReadCreateAtServer();
	ElsIf ChartsOfCharacteristicTypes.AssetLiabilityItems.ThisIsItemOfManagementBalanceSheet(Object) Then
		AutoTitle = False;
		Title = Object.Description + " (" + NStr("vi = 'Dạng bảng cân đối kế toán quản trị';
												|ru = 'Статья управленческого баланса';
												|en = 'Balance sheet statement item'; fa = 'Balance sheet statement item';
												|it = 'Статья управленческого баланса';
												|pl = 'Balance sheet statement item';
												|tr = 'Yönetim bakiyesi kalemleri'") + ")";
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	TypesArray = New Array();
	For Each ListItem In Dimension Do
		CommonClientServer.SupplementArray(TypesArray, ListItem.Value.Types(), True);
	EndDo;
	If TypesArray.Count() > 0 Then
		CurrentObject.ValueType = New TypeDescription(TypesArray);
	EndIf;
	
	If AssetLiability = "AssetBalanceSheetName" Then
		CurrentObject.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
	ElsIf AssetLiability = "AssetLiability" Then
		CurrentObject.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.AssetLiability;
	Else
		CurrentObject.AssetLiability = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
	EndIf;
	
	If ThisIsCustomArticle Then
		If AssetLiability = "AssetBalanceSheetName" Then
			CurrentObject.Kind = Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName;
		ElsIf AssetLiability = "AssetLiability" Then
			CurrentObject.Kind = Enums.AssetAndLiabilityItemKinds.AssetLiability;
		Else
			CurrentObject.Kind = Enums.AssetAndLiabilityItemKinds.Liabilities;
		EndIf;
		
		If IsBlankString(CurrentObject.DataSource) Then
			CurrentObject.DataSource = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
		EndIf;
	EndIf;
	
	CurrentObject.LedgerAccountsInEntrySettings = Boolean(LedgerAccountsInEntrySettings);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Dimension.Count() > 1 Then
		If ThisIsCustomArticle Then
			MessageText = NStr("vi = 'Cần chỉ ra chỉ một kiểu đối tượng phân tích';
								|ru = 'Необходимо указать только один тип аналитики';
								|en = 'Specify one dimension type only'; fa = 'Specify one dimension type only';
								|it = 'Необходимо указать только один тип аналитики';
								|pl = 'Specify one dimension type only';
								|tr = 'Sadece bir boyut türü belirtmeniz gerekmektedir'");
			Common.MessageToUser(MessageText,, "Dimension",, Cancel); 
		Else
			TypeWithoutAnalytics = Type("EnumRef.AssetAndLiabilityItemsWithoutDimension");
			TypeNameWithoutAnalytics = "";
			
			For Each ListItem In Dimension Do
				If ListItem.Value.ContainsType(TypeWithoutAnalytics) Then
					TypeNameWithoutAnalytics = Metadata.FindByType(TypeWithoutAnalytics).Synonym;
					Break;
				EndIf;
			EndDo;
			
			If Not IsBlankString(TypeNameWithoutAnalytics) Then
				MessageText = StrTemplate(
					NStr("vi = 'Không thể sử dụng đối tượng phân tích ""%1"" cùng với kiểu đối tượng phân tích khác';
						|ru = 'Аналитика ""%1"" не может использоваться совместно с другими типами аналитики';
						|en = 'You cannot use the ""%1"" dimension together with other dimension types'; fa = 'You cannot use the ""%1"" dimension together with other dimension types';
						|it = 'Аналитика ""%1"" не может использоваться совместно с другими типами аналитики';
						|pl = 'You cannot use the ""%1"" dimension together with other dimension types';
						|tr = '""%1"" boyutu, başka boyut türleri ile birlikte kullanılamaz.'"),
					TypeNameWithoutAnalytics);
				Common.MessageToUser(MessageText,, "Dimension",, Cancel); 
			EndIf;
		EndIf;
	ElsIf Dimension.Count() = 0 Then
		If ThisIsCustomArticle Then
			CheckedAttributes.Add("Dimension");
		EndIf;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AssetLiabilityOnChange(Item)
	ManagingVisibilityOfFormElements(ThisObject);
EndProcedure

&AtClient
Procedure DimensionOnChange(Item)
	
	If ThisIsCustomArticle Then
		While Dimension.Count() > 1 Do
			Dimension.Delete(0);
		EndDo;
	EndIf;
	
	ManagingVisibilityOfFormElements(ThisForm);
	
EndProcedure

&AtClient
Procedure ShowTurnoverWhenChanging(Item)

	ManagingVisibilityOfFormElements(ThisForm);

EndProcedure

&AtClient
Procedure SpecifyingAccountingAccountsInSettingsWhenChanging(Item)
	SpecifyingAccountingAccountsInSettingsWhenChangingOnServer();
EndProcedure

&AtServer
Procedure SpecifyingAccountingAccountsInSettingsWhenChangingOnServer()
	
	DetermineAvailabilityOfAccountingAccountSettings();
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ValuesOfOtherAssetsLiabilities(Command)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến giá trị tài sản và nợ phải trả khác sau khi ghi lại dữ liệu.
		|Dữ liệu sẽ được ghi lại.';
		|ru = 'Данные еще не записаны.
		|Переход к значениям прочих активов и пассивов возможен только после записи данных.
		|Данные будут записаны.';
		|en = 'Data is not saved yet.
		|You can view values of other assets and liabilities only after data is saved.
		|Data will be saved.'; fa = 'Data is not saved yet.
		|You can view values of other assets and liabilities only after data is saved.
		|Data will be saved.';
		|it = 'Данные еще не записаны.
		|Переход к значениям прочих активов и пассивов возможен только после записи данных.
		|Данные будут записаны.';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do wartości innych aktywów i pasywów jest możliwe tylko po zapisaniu danych.
		|Dane zostaną zapisane.';
		|tr = 'Veriler henüz kaydedilmedi.
		|Diğer varlıklar ve yükümlülüklerin değerlerine geçiş ancak verilerin kaydedilmesinin sonra mümkündür.
		|Veriler kaydedilecektir.'");
		
		ShowQueryBox(New CallbackDescription("ValuesOfOtherAssetsLiabilitiesCompletion", ThisObject), QueryText, QuestionDialogMode.OKCancel);
		Return;
		
	EndIf;
	
	ValuesOfOtherAssetsLiabilitiesFragment();
EndProcedure

&AtClient
Procedure ValuesOfOtherAssetsLiabilitiesCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;

	If Not Write() Then
		Return;
	EndIf;

	ValuesOfOtherAssetsLiabilitiesFragment();

EndProcedure

&AtClient
Procedure ValuesOfOtherAssetsLiabilitiesFragment()

	FilterStructure1 = New Structure("Owner", Object.Ref);
	FormParameters = New Structure("Filter", FilterStructure1);
	OpenForm("Catalog.OtherAssetsLiabilities.ListForm", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure SetUpAccountingAccounts(Command)
	ConfigurationData = GLAccountSettingsClientServer.CompositionOfAccountingAccountSettings();
	
	
	For Each TSRow In Object.FinancialAccountingSettings Do
		InternationalConfigurationData = GLAccountSettingsClientServer.CompositionOfInternationalAccountingAccounts();
		FillPropertyValues(InternationalConfigurationData, TSRow);
		ConfigurationData.FinancialAccountingSettings.Add(InternationalConfigurationData);
	EndDo;
	ConfigurationFormParameters = GLAccountSettingsClient.ParametersOfInvoiceConfigurationForm();
	ConfigurationFormParameters.ConfigurationData = ConfigurationData;
	ConfigurationFormParameters.GLAccountSettings = Object.Ref;
	ConfigurationFormParameters.ReadOnly = ThisObject.ReadOnly;
	ConfigurationFormParameters.LedgerAccountsInEntrySettings = Boolean(LedgerAccountsInEntrySettings);
	
	CallbackDescription = New CallbackDescription("SettingUpCompletionOperationReflection", ThisObject);
	
	OpenForm("CommonForm.TransactionGLAccountsSettings", ConfigurationFormParameters, ThisObject, , , , CallbackDescription);
	Return; // not an empty handler
	
EndProcedure

&AtClient
Procedure SettingUpCompletionOperationReflection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		Object.FinancialAccountingSettings.Clear();
		For Each InternationalConfigurationData In Result.ConfigurationData.FinancialAccountingSettings Do
			NewRow = Object.FinancialAccountingSettings.Add();
			FillPropertyValues(NewRow, InternationalConfigurationData);
		EndDo;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	SetValuesOfFormAttributes();
	FillInListOfSelectedTypesOfAnalyticsValues();
	DetermineAvailabilityOfAccountingAccountSettings();
	ManagingVisibilityOfFormElements(ThisForm);
	
EndProcedure

#Region FormItemsManagement

&AtClientAtServerNoContext
Procedure ManagingVisibilityOfFormElements(Form)
	
	Form.Items.ValuesOfOtherAssetsLiabilities.Visible = 
		Form.Dimension.Count() = 1
		And Form.Dimension[0].Value.ContainsType(Type("CatalogRef.OtherAssetsLiabilities"));
	
	Form.Items.LedgerAccountsInEntrySettings.Visible = Form.ThisIsCustomArticle;
	
	// Set input prompts
	If Form.AssetLiability = "Liabilities" Then
		Form.Items.ItemDebitPresentation.InputHint = NStr("vi = 'Giảm';
															|ru = 'Уменьшение';
															|en = 'Decrease'; fa = 'کاهش';
															|it = 'Уменьшение';
															|pl = 'Zmniejszenie';
															|tr = 'Azalış'");
		Form.Items.PresentationOfCrBalanceOfAssetAndLiabilityItems.InputHint = NStr("vi = 'Tăng';
																					|ru = 'Увеличение';
																					|en = 'Increase'; fa = 'افزایش';
																					|it = 'Увеличение';
																					|pl = 'Zwiększenie';
																					|tr = 'Artış'");
	Else
		Form.Items.ItemDebitPresentation.InputHint = NStr("vi = 'Tăng';
															|ru = 'Увеличение';
															|en = 'Increase'; fa = 'افزایش';
															|it = 'Увеличение';
															|pl = 'Zwiększenie';
															|tr = 'Artış'");
		Form.Items.PresentationOfCrBalanceOfAssetAndLiabilityItems.InputHint = NStr("vi = 'Giảm';
																					|ru = 'Уменьшение';
																					|en = 'Decrease'; fa = 'کاهش';
																					|it = 'Уменьшение';
																					|pl = 'Zmniejszenie';
																					|tr = 'Azalış'");
	EndIf;
	
EndProcedure

&AtServer
Procedure DetermineAvailabilityOfAccountingAccountSettings()
	
	VisibilityOfAccountSettings = False;
	LocalAccountingAccountsCanBeConfigured = False;
	SettingUpInternationalAccountingAccountsIsAvailable = False;
	LocalAccountingAccountsCanBeConfigured = GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured();
	SettingUpInternationalAccountingAccountsIsAvailable = GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable();
	
	VisibilityOfAccountSettings = LocalAccountingAccountsCanBeConfigured Or SettingUpInternationalAccountingAccountsIsAvailable;
	If SettingUpInternationalAccountingAccountsIsAvailable Then
		SettingUpInternationalAccountingAccountsIsAvailable = LedgerAccountsInEntrySettings = 0;
	EndIf;
	If Not VisibilityOfAccountSettings Then
		Items.SetUpAccountingAccounts.Visible = False;
	ElsIf Not (LocalAccountingAccountsCanBeConfigured Or SettingUpInternationalAccountingAccountsIsAvailable) Then
		Items.SetUpAccountingAccounts.Visible = True;
		Items.SetUpAccountingAccounts.Enabled = False;
		Items.SetUpAccountingAccounts.Title = NStr("vi = 'Không cần thiết lập tài khoản kế toán dạng trong các chứng từ';
													|ru = 'Настройка счетов учета статьи в документах не требуется';
													|en = 'Item ledger account setup in documents is not required'; fa = 'Item ledger account setup in documents is not required';
													|it = 'Настройка счетов учета статьи в документах не требуется';
													|pl = 'Item ledger account setup in documents is not required';
													|tr = 'Belgelerdeki kalemin defterikebir hesabı ayarı gerekmiyor'");
	ElsIf LocalAccountingAccountsCanBeConfigured And Not SettingUpInternationalAccountingAccountsIsAvailable Then
		Items.SetUpAccountingAccounts.Visible = True;
		Items.SetUpAccountingAccounts.Enabled = True;
		Items.SetUpAccountingAccounts.Title = NStr("vi = 'Thiết lập tài khoản kế toán tài chính dạng trong các chứng từ theo mặc định';
													|ru = 'Настройка счета регл. учета статьи в документах по умолчанию';
													|en = 'Set up default local ledger account of item in documents'; fa = 'Set up default local ledger account of item in documents';
													|it = 'Настройка счета регл. учета статьи в документах по умолчанию';
													|pl = 'Set up default local ledger account of item in documents';
													|tr = 'Varsayılan olarak belgelerdeki kalemin yerel defterikebir hesabı ayarı'");
	Else
		Items.SetUpAccountingAccounts.Visible = True;
		Items.SetUpAccountingAccounts.Enabled = True;
		Items.SetUpAccountingAccounts.Title = NStr("vi = 'Thiết lập tài khoản dạng trong chứng từ theo mặc định';
													|ru = 'Настройка счетов учета статьи в документах по умолчанию';
													|en = 'Item ledger accounts settings in default documents'; fa = 'تنظیمات حساب‌های دفتر کل قلم در اسناد پیش‌فرض';
													|it = 'Настройка счетов учета статьи в документах по умолчанию';
													|pl = 'Ustawienie kont ewidencji pozycji w dokumentach domyślnych';
													|tr = 'Varsayılan olarak belgelerde kalem defterikebir hesabı ayarı'");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInListOfSelectedTypesOfAnalyticsValues()
	
	Dimension.Clear();
	
	ChoiceList = Items.Dimension.ChoiceList;
	ChoiceList.Clear();
	
	For Each Type In Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type.Types() Do
		MetadataObject = Metadata.FindByType(Type);
		If Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
			ListItem = ChoiceList.Add(
				New TypeDescription(CommonClientServer.ValueInArray(Type)),
				MetadataObject.Presentation());
			If Object.ValueType.ContainsType(Type) Then
				ListItem.Check = True;
			EndIf;
		EndIf;
	EndDo;
	
	ChoiceList.SortByPresentation();
	
	TypesAtEnd = New Array;
	TypesAtEnd.Add(Type("CatalogRef.OtherAssetsLiabilities"));
	TypesAtEnd.Add(Type("EnumRef.AssetAndLiabilityItemsWithoutDimension"));
	
	For Each Type In TypesAtEnd Do
		ListItem = ChoiceList.FindByValue(New TypeDescription(CommonClientServer.ValueInArray(Type)));
		IndesOfElement = ChoiceList.IndexOf(ListItem);
		ChoiceList.Move(ListItem, ChoiceList.Count() - IndesOfElement - 1);
	EndDo;
	
	If Not ValueIsFilled(Object.Ref) Then
		ChoiceList.FillChecks(False);
		LastItem = ChoiceList[ChoiceList.Count() - 1];
		LastItem.Check = True;
	EndIf;
	
	For Each ListItem In ChoiceList Do
		If ListItem.Check Then
			FillPropertyValues(Dimension.Add(), ListItem);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetValuesOfFormAttributes()
	
	If Object.AssetLiability = PredefinedValue("Enum.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName") Then
		AssetLiability = "AssetBalanceSheetName";
	ElsIf Object.AssetLiability = PredefinedValue("Enum.KindsOfBalanceSheetStatementItems.AssetLiability") Then
		AssetLiability = "AssetLiability";
	Else
		AssetLiability = "Liabilities";
	EndIf;
	
	LedgerAccountsInEntrySettings = Number(Object.LedgerAccountsInEntrySettings);
	
	ThisIsCustomArticle = ChartsOfCharacteristicTypes.AssetLiabilityItems.ThisIsCustomArticle(Object);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		FullFormName = "ChartOfCharacteristicTypes.AssetLiabilityItems.Form.AttributeUnlocking";
		FormParameters = New Structure;
		FormParameters.Insert("ThisIsCustomArticle", ThisIsCustomArticle);
		CallbackDescription = New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject);
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
		OpenForm(FullFormName, FormParameters,,,,, CallbackDescription, WindowOpeningMode);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
	EndIf;

EndProcedure

// StandardSubsystems.Properties 

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion
