
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ObjectAttributesLock.LockAttributes(ThisObject);
		
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	GLAccountSettingsClient.FinishedSettingUpAccountingAccounts(ThisObject, EventName, Parameter);
	Return; // The UT handler is empty
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	GLAccountSettingsServer.WhenWritingAccountSettingsObject(ThisObject, Cancel, CurrentObject, WriteParameters);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Cancel Then
		Return;
	EndIf;
	GLAccountSettingsServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PropertyAccountingOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Not Object.PropertyAccounting Then
		Object.MethodOfRepaymentOfCostOfAC = PredefinedValue("Enum.WaysToRepayCostOfInventory.OnCommissioning");
		Object.MethodOfRepaymentOfCostTA = PredefinedValue("Enum.WaysToRepayCostOfInventory.OnCommissioning");
		ChangedBankingDetails = ChangedBankingDetails + ",MethodOfRepaymentOfCostOfAC,MethodOfRepaymentOfCostTA";
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

	Return; // For UT, the handler is empty
	
EndProcedure

&AtClient
Procedure StocktakingRecordOnChange(Item)
	If Not Object.StocktakingRecord
		And Object.ConsiderRunningTime Then
			
		Object.MethodOfRepaymentOfCostOfAC = PredefinedValue("Enum.WaysToRepayCostOfInventory.ByDate");
		Object.ConsiderRunningTime = False;
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
EndProcedure

&AtClient
Procedure TakeIntoAccountAsGroupUnitFAWhenChanging(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);

EndProcedure

&AtClient
Procedure MethodOfRepaymentOfCostOfACOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.MethodOfRepaymentOfCostOfAC = PredefinedValue("Enum.WaysToRepayCostOfInventory.ByAssetActivity")
		And Not Object.ConsiderRunningTime Then
		
		Object.ConsiderRunningTime = True;
		ChangedBankingDetails = ChangedBankingDetails + ",ConsiderRunningTime";
		
	ElsIf Object.MethodOfRepaymentOfCostOfAC <> PredefinedValue("Enum.WaysToRepayCostOfInventory.ByAssetActivity")
		And Object.ConsiderRunningTime Then
			
		Object.ConsiderRunningTime = False;
		ChangedBankingDetails = ChangedBankingDetails + ",ConsiderRunningTime";
	EndIf;
	
	If Object.MethodOfRepaymentOfCostTA <> PredefinedValue("Enum.WaysToRepayCostOfInventory.OnCommissioning") Then
		Object.PropertyAccounting = True;
		Object.MethodOfRepaymentOfCostTA = Object.MethodOfRepaymentOfCostOfAC;
		ChangedBankingDetails = ChangedBankingDetails + ",PropertyAccounting,MethodOfRepaymentOfCostTA";
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
	Return; // For UT, the handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#Region SettingUpAccountingAccounts_EventHandlersForFormHeaderElements

&AtClient
Procedure Attachable_OnChange_SettingUpAccountingAccounts(Item)
	GLAccountSettingsClient.OnChange(Item, ThisObject);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_StartOfSelection_SettingUpAccountingAccounts(Item, ChoiceData, StandardProcessing)
	GLAccountSettingsClient.StartChoice(ThisObject, Item, ChoiceData, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Regulation_SettingUpAccountingAccounts(Item, Direction, StandardProcessing)
	GLAccountSettingsClient.Tuning(ThisObject, Item, Direction, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Cleaning_SettingUpAccountingAccounts(Item, StandardProcessing)
	GLAccountSettingsClient.Clearing(ThisObject, Item, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ContinuationHandler = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
    ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject, ContinuationHandler);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	ThisIsTradeManagement = GetFunctionalOption("TradeManagement");
	UseVNA24 = GetFunctionalOption("UseNonCurrentAssets2_4");
	
	AccountForInventoryInERP2AndCAOperation = GetFunctionalOption("AccountForInventoryInERP2AndCAOperation");
	
	Items.ServiceLifeTrade.Visible = ThisIsTradeManagement;
	Items.DecorationServiceLifeTrade.Visible = ThisIsTradeManagement;
	Items.ServiceLife.Visible = Not ThisIsTradeManagement;
	Items.DecorationServiceLife.Visible = Not ThisIsTradeManagement;
	Items.GroupPropertyAccountingIndent.Visible = Not ThisIsTradeManagement;
	Items.UnusedBankingDetailsPicture.Visible = AccountForInventoryInERP2AndCAOperation;
	Items.UnusedBankingDetailsInformation.Visible = AccountForInventoryInERP2AndCAOperation;
	Items.UnusedAttributesGroup.Visible = Not ThisIsTradeManagement;

	If Not UseVNA24 Then
		Items.GroupIsTakenIntoAccountInFormOfGroupFAIndent.Visible = False;
		Items.AccountAsGroupFA.Visible = False;
		Items.OSGroup.Visible = False;
		Items.FACostCapitalizationArticle.Visible = False;
	EndIf;
	
	Items.UnusedAttributesGroup.Visible = AccountForInventoryInERP2AndCAOperation;
	
	GLAccountSettingsServer.WhenReadingCreatingAccountSettingsObject(ThisObject);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")

	Items = Form.Items;
	Object = Form.Object;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = InventoryInOperationClientServer.ValuesOfPropertiesOfDependentDetails_CategoriesOfOperation(
									Object, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);

	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters);
	EndIf;
	
	
	If StructureOfChangedProps.Property("AccountAsGroupFA")
		Or UpdateAll Then
		
		If Object.AccountAsGroupFA Then
			ElementHint = NStr("vi = 'Xác định dạng nào sẽ được sử dụng mặc định khi điền tiếp nhận TSCĐ theo nhóm vào kế toán';
								|ru = 'Определяет, какая статья будет использоваться по умолчанию при заполнении принятия к учету группового ОС.';
								|en = 'Determines what item will be default upon filling in the group fixed asset recognition.'; fa = 'Determines what item will be default upon filling in the group fixed asset recognition.';
								|it = 'Definisce quale voce sarà utilizzata da impostazione predefinita durante la compilazione della ricezione in contabilità delle immobilizzazioni di gruppo.';
								|pl = 'Określa, jaka pozycja będzie używana domyślnie przy wypełnieniu przyjęcie do ewidencji grupowego środka trwałego.';
								|tr = 'Bir grup SV''nin kabulü tamamlanırken varsayılan olarak hangi kalemin kullanılacağını belirler.'");
		Else
			ElementHint = NStr("vi = 'Xác định dạng nào sẽ được sử dụng mặc định khi điền chuyển giao vật tư vào sử dụng.';
								|ru = 'Определяет, какая статья будет использоваться по умолчанию при заполнении передачи в ТМЦ в эксплуатацию.';
								|en = 'Determines which item will be used by default when filling in the inventory commissioning.'; fa = 'تعیین می‌کند کدام قلم به طور پیش‌فرض هنگام پرکردن راه‌اندازی موجودی استفاده شود.';
								|it = 'Definisce quale voce sarà utilizzata da impostazione predefinita alla compilazione del trasferimento del bene materiale in lavorazione.';
								|pl = 'Określa, jaka pozycja będzie używana domyślnie przy wypełnieniu przekazania zapasów do eksploatacji.';
								|tr = 'Kullanılan stoka aktarım tamamlanırken varsayılan olarak hangi kalemin kullanılacağını belirler.'");
		EndIf;
		
		Items.ExpenseItem.ToolTip = ElementHint;
		 
	EndIf;
	
EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
EndProcedure

#EndRegion