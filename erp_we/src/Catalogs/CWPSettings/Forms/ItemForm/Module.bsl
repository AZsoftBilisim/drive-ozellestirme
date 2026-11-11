#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UseRetailSales           = GetFunctionalOption("UseRetailSales");
	UseSeveralCashRegisters           = GetFunctionalOption("UseSeveralCashRegisters");
	UseMultipleCashAccounts              = GetFunctionalOption("UseMultipleCashAccounts");
	UsePeripherals   = GetFunctionalOption("UsePeripherals");
	UsePaymentByCards    = GetFunctionalOption("UsePaymentByCards");
	
	FillChoiceLists();
	
	Items.GroupCashRegisters.Visible     = UseSeveralCashRegisters And UseRetailSales;
	Items.GroupOneCashRegisterKKM.Visible = Not UseSeveralCashRegisters And UseRetailSales;
	
	Items.GroupCash.Visible     = UseMultipleCashAccounts;
	Items.GroupOneCheckout.Visible = Not UseMultipleCashAccounts;
	
	Items.AutomaticCashCollection.Visible                = Not UseSeveralCashRegisters;
	Items.UseWithoutConnectingPeripherals.Visible  = Not UseSeveralCashRegisters And UsePeripherals;
	Items.Peripherals.Visible                = Not UseSeveralCashRegisters And UsePeripherals;
	Items.ConnectedEquipmentCashRegister.Visible           = Not UseMultipleCashAccounts    And UsePeripherals;
	Items.AcquiringTerminalsGroup.Visible            = UsePaymentByCards;
	
	Items.GroupAuthorization.Visible                = UseRetailSales;
	Items.UseAuthorizationExplanation.Visible = UseRetailSales;
	Items.KeyboardShortcutsExplanation.Visible          = UseRetailSales;

	Items.PaymentSystemsContractForConnectionToPaymentSystem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
	
	If UseRetailSales
		And Not ValueIsFilled(Object.Ref)
		And Not UseSeveralCashRegisters Then
		CashRegister = Catalogs.CashRegisters.CashRegisterFiscalRegistrarByDefault();
		If Not ValueIsFilled(CashRegister) Then
			Raise NStr("vi = 'Trong cơ sở thông tin chưa tạo quầy thu ngân có dạng: Máy ghi nhận tiền mặt.
			|Để làm việc với tùy chỉnh quầy thu ngân, trong hệ thống cần ghi nhận ít nhất một máy ghi nhận tiền mặt.';
			|ru = 'В информационной базе не создано кассы ККМ с типом: Фискальный регистратор.
			|Для работы с настройкой РМК в системе должен быть зарегистрирован как минимум один фискальный регистратор.';
			|en = 'Cash register with type ""Fiscal cash register"" is not created in the infobase.
			|At least one fiscal cash register should be registered in the application to operate with the point of sale workplace setting.'; fa = 'Cash register with type ""Fiscal cash register"" is not created in the infobase.
			|At least one fiscal cash register should be registered in the application to operate with the point of sale workplace setting.';
			|it = 'Nel database informatico non è stata creata alcuna cassa Macchinari di Registrazione e Controllo con il tipo: registratore Fiscale.
			|Per lavorare con la configurazione Postazione di Lavoro del Cassiere minimo un registratore fiscale deve essere registrato nel sistema.';
			|pl = 'W bazie informacyjnej nie utworzono kasy z typem: Rejestrator fiskalny.
			|Do pracy z ustawieniami MPK w systemie musi być zarejestrowany co najmniej jeden rejestrator fiskalny.';
			|tr = 'Infobase''da şu türde bir yazar kasa oluşturulmamıştır: Mali yazar kasa.
			|Satış noktası işyeri ortamında kullanılabilmesi için uygulamada en az bir mali yazar kasa kayıtlı olmalıdır.'");
		EndIf;
		
		UseWithoutConnectingPeripherals = True;
		Items.Peripherals.Enabled = Not UseWithoutConnectingPeripherals;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref)
		And Not UseMultipleCashAccounts Then
		CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Undefined);
		If Not ValueIsFilled(CashAccount) Then
			Raise NStr("vi = 'Trong cơ sở thông tin chưa tạo quỹ tiền mặt nào.
			                             |Để làm việc với tùy chỉnh quầy thu ngân, trong hệ thống cần ghi nhận ít nhất một quỹ tiền mặt của doanh nghiệp.';
			                             |ru = 'В информационной базе не создано ни одной кассы.
			                             |Для работы с настройкой РМК в системе должна быть зарегистрирована как минимум одна касса предприятия.';
			                             |en = 'No cash account is created in the infobase.
			                             |At least one cash account should be registered in the application to operate with the point of sale workplace setting.'; fa = 'No cash account is created in the infobase.
			                             |At least one cash account should be registered in the application to operate with the point of sale workplace setting.';
			                             |it = 'Nel database informatico non è stata creata alcuna cassa.
			                             |Per lavorare con la configurazione Postazione di Lavoro del Cassiere minimo una cassa della società deve essere registrata nel sistema.';
			                             |pl = 'W bazie informacyjnej nie utworzono ani jednej kasy.
			                             |Do pracy z ustawieniami MPK w systemie musi być zarejestrowana co najmniej jedna kasa przedsiębiorstwa.';
			                             |tr = 'Veri tabanında herhangi bir yazar kasa oluşturulmamıştır.
			                             | RMC kurulumu ile çalışabilmek için en az bir şirket yazar kasasının sistemde kayıtlı olması gerekmektedir.'");
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.PaymentSystemsCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	Items.Workplace.ChoiceList.Add("", "<" + NStr("vi = 'Chỗ làm việc hiện tại';
													|ru = 'Текущее рабочее место';
													|en = 'Current workplace'; fa = 'میز کار فعلی';
													|it = 'Desktop corrente';
													|pl = 'Aktualne miejsce pracy';
													|tr = 'Mevcut çalışma alanı'") + ">");

	Items.LocalizationPaymentSystemsGroup.Visible = False;
	
	If ValueIsFilled(Object.Ref) Then
		ToVerifyCorrectnessOfEquipmentIndicationInCWPSetup();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Object.Workplace) Then
		EquipmentManagerClient.UpdateClientWorkplace();
		Object.Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	AdditionalParameters = New Structure("ServerCallRequired__", False);
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source, AdditionalParameters);
	If AdditionalParameters.ServerCallRequired__ Then
		ProcessingNotificationOnServer(EventName, Parameter);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If UseRetailSales
		And Not UseSeveralCashRegisters Then
		
		CurrentObject.CashRegisters.Clear();
		NewRow = CurrentObject.CashRegisters.Add();
		NewRow.CashRegister                               = CashRegister;
		NewRow.UseWithoutConnectingPeripherals = UseWithoutConnectingPeripherals;
		NewRow.AutomaticCashCollection               = AutomaticCashCollection;
		NewRow.Peripherals               = Peripherals;
		
	EndIf;
	
	If Not UseMultipleCashAccounts Then
		
		CurrentObject.CashAccounts.Clear();
		NewRow = CurrentObject.CashAccounts.Add();
		NewRow.CashAccount                    = CashAccount;
		NewRow.Peripherals = ConnectedEquipmentCashRegister;
		
	EndIf;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInOrganizationInRowsOfFormTable(Items.POSTerminals);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If UseRetailSales
		And Not ValueIsFilled(Peripherals)
		And Not UseWithoutConnectingPeripherals
		And Not UseSeveralCashRegisters Then
		
		Common.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Thiết bị kết nối""';
				|ru = 'Не заполнено поле ""Подключаемое оборудование""';
				|en = '""Peripherals"" is required'; fa = '""Peripherals"" is required';
				|it = 'Il campo ""Attrezzatura collegata"" non è compilato';
				|pl = 'Nie wypełniono pola ""Urządzenia peryferyjne""';
				|tr = '""Bağlanabilir donanım"" alanı doldurulmamış'"),,"Peripherals",,Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(ConnectedEquipmentCashRegister)
		And Not UseMultipleCashAccounts Then
		
		Common.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Thiết bị kết nối""';
				|ru = 'Не заполнено поле ""Подключаемое оборудование""';
				|en = '""Peripherals"" is required'; fa = '""Peripherals"" is required';
				|it = 'Il campo ""Attrezzatura collegata"" non è compilato';
				|pl = 'Nie wypełniono pola ""Urządzenia peryferyjne""';
				|tr = '""Bağlanabilir donanım"" alanı doldurulmamış'"),,"ConnectedEquipmentCashRegister",,Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentSystems

&AtClient
Procedure PaymentSystemsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	curData = Item.CurrentData;
	If curData = Undefined Then
		Return;
	EndIf;
	
	CurTreaty = curData.ContractForConnectionToPaymentSystem;
	CurRowNumber = curData.LineNumber;
	
	If Not ValueIsFilled(CurTreaty) Then
		
		Object.PaymentSystems.Delete(CurRowNumber-1);
		
		Return;
		
	EndIf;
	
	For Each Itm In Object.PaymentSystems Do
		If Itm.ContractForConnectionToPaymentSystem = CurTreaty
			And Itm.LineNumber <> CurRowNumber Then
			
			MessageTemplate = NStr("vi = 'Đã thêm hợp đồng ""%1"" vào tùy chỉnh quầy thu ngân (dòng %2)';
									|ru = 'Договор ""%1"" добавлен в настройку РМК (строка %2)';
									|en = 'The ""%1"" contract is added to the setting of the point of sale workplace (line %2)'; fa = 'The ""%1"" contract is added to the setting of the point of sale workplace (line %2)';
									|it = 'Договор ""%1"" добавлен в настройку РМК (строка %2)';
									|pl = 'The ""%1"" contract is added to the setting of the point of sale workplace (line %2)';
									|tr = 'KİY ayarına ""%1"" sözleşmesi eklendi (%2 satırı)'");
			CommonClient.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
						MessageTemplate,
						CurTreaty,
						Itm.LineNumber));
			CancelEdit = True;
			Cancel = True;
			
			Return;
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenTheUserIdentificationDataList(Command)
	
	OpenForm("InformationRegister.UserIdentityDetails.ListForm");
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseAuthorizationOnChange(Item)
	
	Items.UserIdentityDetails.Enabled = Object.UseAuthorization;
	
EndProcedure

&AtClient
Procedure WorkplaceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If Not ValueIsFilled(ValueSelected) Then
		StandardProcessing = False;
		EquipmentManagerClient.UpdateClientWorkplace();
		Object.Workplace = EquipmentManagerServerCall.GetClientSWorkplace();
	EndIf;
	
EndProcedure

&AtClient
Procedure CashierCanBeASellerOnChange(Item)
	
	If Not Object.SellingAreaManagerMayActAsASeller And Not Object.CashierCanBeASeller Then
		Object.SellingAreaManagerMayActAsASeller = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SellingAreaManagerMayActAsASellerOnChange(Item)
	
	If Not Object.SellingAreaManagerMayActAsASeller And Not Object.CashierCanBeASeller Then
		Object.CashierCanBeASeller = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseWithoutConnectingPeripheralsOnChange(Item)
	
	Items.Peripherals.Enabled = Not UseWithoutConnectingPeripherals;
	
EndProcedure

&AtClient
Procedure PeripheralsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	CRType = CRType(CashRegister);
	SetRestrictionOnTypeOfItemSelectionByTypeOfCashREGISTER(CRType, Items.Peripherals);
	
	
EndProcedure

&AtClient
Procedure FPSLinkKindOnChange(Item)

	
EndProcedure

&AtClient
Procedure PaymentSystemsCashLinkOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure

&AtClient
Procedure PaymentSystemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure PaymentSystemsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	
EndProcedure

&AtClient
Procedure PaymentSystemsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashRegisters

&AtClient
Procedure CashRegistersCashRegisterOnChange(Item)
	
	CurrentData = Items.CashRegisters.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CashRegisterCashRegisterCashRegisterWhenChangedOnServer(CurrentData.GetID());
	
EndProcedure

&AtServer
Procedure CashRegisterCashRegisterCashRegisterWhenChangedOnServer(RowID)
	
	LineOfATabularSection = Object.CashRegisters.FindByID(RowID);
	OldOrganizationValue = LineOfATabularSection.Organization;
	FillInOrganizationInRowsOfFormTable(Items.CashRegisters, RowID);
	AttributesArray = New Array;
	AttributesArray.Add("Peripherals");
	CheckClearCompanyRelatedAttributesInLine(LineOfATabularSection, OldOrganizationValue, AttributesArray);
	
	AdditionalParameters = New Structure("RowID", RowID);
	FormEvents.WhenChangingElement(ThisObject, "CashRegister", AdditionalParameters);
	
	
EndProcedure

&AtClient
Procedure CashRegistersSelection(Item, RowSelected, Field, StandardProcessing)
	
	FormEventsClient.WhenSelectingItem(ThisObject, Item, RowSelected, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CashRegistersUseWithoutConnectingPeripheralsOnChange(Item)
	
	CurrentData = Items.CashRegisters.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.UseWithoutConnectingPeripherals Then
		CurrentData.Peripherals = PredefinedValue("Catalog.Peripherals.EmptyRef");
	EndIf;
	
	CashRegisterCanBeUsedWithoutHardwareConnectionWhenChangesAreMadeOnServer(CurrentData.GetID());
	
EndProcedure

&AtServer
Procedure CashRegisterCanBeUsedWithoutHardwareConnectionWhenChangesAreMadeOnServer(RowID)
	
	AdditionalParameters = New Structure("RowID", RowID);
	FormEvents.WhenChangingElement(ThisObject, "UseWithoutConnectingPeripherals", AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CashRegistersPeripheralsStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Items.CashRegisters.CurrentData;
	
	If Not ValueIsFilled(CurrentRow.CashRegister) Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	CRType = CRType(CurrentRow.CashRegister);
	SetRestrictionOnTypeOfItemSelectionByTypeOfCashREGISTER(CRType, Items.CashRegistersPeripherals);

EndProcedure

&AtClient
Procedure CashRegistersBeforeDeleteRow(Item, Cancel)
	
	ClearMessages();
	CheckPossibilityOfRemovingConnectedEquipmentAccordingToAcquiringTerminalsTable(Item, Cancel);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashAccounts

&AtClient
Procedure CashAccountsCashAccountOnChange(Item)
	
	CurrentData = Items.CashAccounts.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CashiersCashierWhenChangesAreMadeOnServer(CurrentData.GetID());
	
EndProcedure

&AtServer
Procedure CashiersCashierWhenChangesAreMadeOnServer(RowID)
	
	LineOfATabularSection = Object.CashAccounts.FindByID(RowID);
	OldOrganizationValue = LineOfATabularSection.Organization;
	FillInOrganizationInRowsOfFormTable(Items.CashAccounts, RowID);
	AttributesArray = New Array;
	AttributesArray.Add("Peripherals");
	CheckClearCompanyRelatedAttributesInLine(LineOfATabularSection, OldOrganizationValue, AttributesArray);
	
EndProcedure

&AtClient
Procedure CashAccountsBeforeDeleteRow(Item, Cancel)
	
	ClearMessages();
	CheckPossibilityOfRemovingConnectedEquipmentAccordingToAcquiringTerminalsTable(Item, Cancel);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPOSTerminals

&AtClient
Procedure POSTerminalsPOSTerminalOnChange(Item)
	
	CurrentData = Items.POSTerminals.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	AcquiringTerminalsAcquiringTerminalWhenChangingOnServer(CurrentData.GetID());
	
EndProcedure

&AtServer
Procedure AcquiringTerminalsAcquiringTerminalWhenChangingOnServer(RowID)
	
	LineOfATabularSection = Object.POSTerminals.FindByID(RowID);
	OldOrganizationValue = LineOfATabularSection.Organization;
	FillInOrganizationInRowsOfFormTable(Items.POSTerminals, RowID);
	AttributesArray = New Array;
	AttributesArray.Add("Peripherals");
	AttributesArray.Add("CREPeripherals");
	CheckClearCompanyRelatedAttributesInLine(LineOfATabularSection, OldOrganizationValue, AttributesArray);
	
EndProcedure

&AtClient
Procedure POSTerminalsUseWithoutConnectingPeripheralsOnChange(Item)
	
	CurrentData = Items.POSTerminals.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CurrentData.UseWithoutConnectingPeripherals Then
		CurrentData.DoNotAskForCardNumber = False;
	Else
		CurrentData.Peripherals = PredefinedValue("Catalog.Peripherals.EmptyRef");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessingNotificationOnServer(EventName, Parameter)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("EventName", EventName);
	FormEvents.WhenChangingElement(ThisObject, "Notification", AdditionalParameters);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashRegistersPeripherals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashRegisters.UseWithoutConnectingPeripherals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Được sử dụng không có kết nối';
													|ru = 'Используется без подключения';
													|en = 'Used without connection'; fa = 'Used without connection';
													|it = 'Viene utilizzato senza connessione';
													|pl = 'Używa się bez podłączenia';
													|tr = 'Bağlantı yapılmadan kullanılır'"));
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.POSTerminalsPeripherals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.POSTerminals.UseWithoutConnectingPeripherals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Được sử dụng không có kết nối';
													|ru = 'Используется без подключения';
													|en = 'Used without connection'; fa = 'Used without connection';
													|it = 'Viene utilizzato senza connessione';
													|pl = 'Używa się bez podłączenia';
													|tr = 'Bağlantı yapılmadan kullanılır'"));
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.POSTerminalsDoNotAskForCardNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.POSTerminals.UseWithoutConnectingPeripherals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.POSTerminalsCREPeripherals.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.POSTerminals.UseWithoutConnectingPeripherals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Enabled", True);

EndProcedure

&AtServer
Procedure FillInDetailsOfCashRegisterAndCashRegister()
	
	If GetFunctionalOption("UseRetailSales")
		And Not GetFunctionalOption("UseSeveralCashRegisters")
		And ValueIsFilled(Object.Ref) Then
		
		If Object.CashRegisters.Count() > 0 Then
			
			If Not ValueIsFilled(Object.CashRegisters[0].CashRegister) Then
				Object.CashRegisters[0].CashRegister = Catalogs.CashRegisters.CashRegisterFiscalRegistrarByDefault();
				Modified = True;
			EndIf;
			
			CashRegister                               = Object.CashRegisters[0].CashRegister;
			Peripherals               = Object.CashRegisters[0].Peripherals;
			UseWithoutConnectingPeripherals = Object.CashRegisters[0].UseWithoutConnectingPeripherals;
			AutomaticCashCollection               = Object.CashRegisters[0].AutomaticCashCollection;
			
		Else
			
			CashRegister = Catalogs.CashRegisters.CashRegisterFiscalRegistrarByDefault();
			
		EndIf;
		
		Items.Peripherals.Enabled = Not UseWithoutConnectingPeripherals;
		
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCashAccounts")
		And ValueIsFilled(Object.Ref) Then
		
		If Object.CashAccounts.Count() > 0 Then
			
			If Not ValueIsFilled(Object.CashAccounts[0].CashAccount) Then
				Object.CashAccounts[0].CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Undefined);
				Modified = True;
			EndIf;
			
			CashAccount                         = Object.CashAccounts[0].CashAccount;
			ConnectedEquipmentCashRegister = Object.CashAccounts[0].Peripherals;
			
		Else
			
			CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Undefined);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInDetailsOfCashRegisterAndCashRegister();
	
	FillInOrganizationInRowsOfFormTable(Items.CashRegisters);
	FillInOrganizationInRowsOfFormTable(Items.CashAccounts);
	FillInOrganizationInRowsOfFormTable(Items.POSTerminals);
	
	If GetFunctionalOption("UseRetailSales") Then
		
		Items.UserIdentityDetails.Enabled = Object.UseAuthorization;
		
	EndIf;
	
EndProcedure

// Returns the type of Cash Register KKM
// 
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - KKM ticket office
// 
// Returns:
//  EnumRef.CashRegisterTypes
//
&AtServer
Function CRType(CashRegister)
	
	Return Common.ObjectAttributeValue(CashRegister, "CashRegisterType");
	
EndFunction

&AtClient
Procedure SetRestrictionOnTypeOfItemSelectionByTypeOfCashREGISTER(CRType, FormItem)
	
	If CRType = PredefinedValue("Enum.CashRegisterTypes.FiscalCashRegisters") Then
		FormItem.TypeRestriction = New TypeDescription("CatalogRef.Peripherals");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInOrganizationInRowsOfFormTable(FormItem, RowID = Undefined)
	
	If TypeOf(FormItem) <> Type("FormTable") Or Not ValueIsFilled(FormItem.DataPath) Then
		Return;
	EndIf;
	
	TabularSection = FormAttributeToValue(FormItem.DataPath);
	If TabularSection.Count() = 0 Then
		Return;
	EndIf;
	
	LineOfATabularSection = Undefined;
	If TypeOf(RowID) = Type("Number") Then
		LineOfATabularSection = TabularSection.FindByID(RowID);	
	EndIf;	
	
	AttributeName = "CashRegister";
	CompanyAttributeName = "Owner";
	If FormItem.Name = Items.CashRegisters.Name Then
		AttributeName = "CashRegister";
		CompanyAttributeName = "Owner";
	ElsIf FormItem.Name = Items.CashAccounts.Name Then
		AttributeName = "CashAccount";
		CompanyAttributeName = "Owner";
	ElsIf FormItem.Name = Items.POSTerminals.Name Then
		AttributeName = "POSTerminal";
		CompanyAttributeName = "Owner.Organization";
	Else
		Return;
	EndIf;
	
	ReferencesArrray = New Array;
	If LineOfATabularSection <> Undefined Then
		ReferencesArrray.Add(LineOfATabularSection[AttributeName]);
	Else
		ReferencesArrray = TabularSection.Unload().UnloadColumn(AttributeName);
	EndIf;
	
	Companies = New Map;
	If FormItem.Name = Items.POSTerminals.Name Then
		Query = New Query;
		Query.Text = "SELECT DISTINCT
		               |	POSTerminals.Ref AS Key,
		               |	POSTerminals.Owner.Organization AS Value
		               |FROM
		               |	Catalog.POSTerminals AS POSTerminals
		               |WHERE
		               |	POSTerminals.Ref IN(&ReferencesArrray)";
		Query.SetParameter("ReferencesArrray", ReferencesArrray);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Companies.Insert(Selection.Key, Selection.Value);
		EndDo;
	Else
		Companies = Common.ObjectsAttributeValue(ReferencesArrray, CompanyAttributeName);
	EndIf;
	
	If Companies.Count() Then
		If LineOfATabularSection = Undefined Then
			For Each KeyValue In Companies Do
				For Each String In TabularSection.FindRows(New Structure(AttributeName, KeyValue.Key)) Do
					String.Organization = KeyValue.Value;
				EndDo;
			EndDo;
		Else
			LineOfATabularSection.Organization = Companies[LineOfATabularSection[AttributeName]];
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckClearCompanyRelatedAttributesInLine(TableRow, PreviousValue2, AttributesArray)
	
	If TableRow.Organization <> PreviousValue2 Then
		For Each AttributeName In AttributesArray Do
			TableRow[AttributeName] = Undefined;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure ToVerifyCorrectnessOfEquipmentIndicationInCWPSetup()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CWPSettingsPOSTerminals.LineNumber AS LineNumber,
	|	CWPSettingsPOSTerminals.POSTerminal AS POSTerminal,
	|	CWPSettingsPOSTerminals.Peripherals AS Peripherals
	|FROM
	|	Catalog.CWPSettings.POSTerminals AS CWPSettingsPOSTerminals
	|		INNER JOIN Catalog.Peripherals AS CatalogPeripherals
	|		ON CWPSettingsPOSTerminals.Peripherals = CatalogPeripherals.Ref
	|WHERE
	|	CWPSettingsPOSTerminals.Ref = &Ref
	|	AND NOT CatalogPeripherals.DeviceIsInUse";
	Query.SetParameter("Ref", Object.Ref);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageTemplate = NStr("vi = 'Trong tùy chỉnh Quầy thu ngân đã tùy chỉnh sai thiết bị thanh toán thẻ:
		|Trong dòng ""%1"", thiết bị ""%2"" - đã chỉ định thiết bị kết nối ""%3"" có bỏ dấu hộp kiểm ""Đang sử dụng thiết bị""';
		|ru = 'В настройках РМК некорректно настроен эквайринговый терминал:
		|В строке ""%1"", терминал ""%2"" - указано подключаемое оборудование ""%3"" со снятым флагом ""Устройстройство используется""';
		|en = 'The POS terminal is incorrectly configured in the point of sale workplace settings:
		|In line ""%1"", for the ""%2"" terminal, the ""%3"" peripheral with the cleared ""Device is in use"" checkbox is specified'; fa = 'The POS terminal is incorrectly configured in the point of sale workplace settings:
		|In line ""%1"", for the ""%2"" terminal, the ""%3"" peripheral with the cleared ""Device is in use"" checkbox is specified';
		|it = 'The POS terminal is incorrectly configured in the point of sale workplace settings:
		|In line ""%1"", for the ""%2"" terminal, the ""%3"" peripheral with the cleared ""Device is in use"" checkbox is specified';
		|pl = 'The POS terminal is incorrectly configured in the point of sale workplace settings:
		|In line ""%1"", for the ""%2"" terminal, the ""%3"" peripheral with the cleared ""Device is in use"" checkbox is specified';
		|tr = 'Satış noktası çalışma alanı ayarlarında, satın alma terminali yanlış ayarlanmıştır:
		| ""%1"" satırında, ""%2"" terminali - ""%3"" bağlantı ekipmanı, “Cihaz kullanılıyor” bayrağı kaldırılmış olarak belirtilmiştir.'");
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				Selection.LineNumber,
				Selection.POSTerminal,
				Selection.Peripherals));
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckPossibilityOfRemovingConnectedEquipmentAccordingToAcquiringTerminalsTable(Item, Cancel)
	
	If Not (Item = Items.CashRegisters Or Item = Items.CashAccounts)
		Or Item.CurrentData = Undefined
		Or Not ValueIsFilled(Item.CurrentData.Peripherals) Then
		Return;
	EndIf;
	
	Peripherals = Item.CurrentData.Peripherals;
	AcquiringTerminalsFound = Object.POSTerminals.FindRows(New Structure("CREPeripherals", Peripherals));
	If AcquiringTerminalsFound.Count() > 0 Then
		
		If Item = Items.CashRegisters Then
			FormTableBeingChecked = Object.CashRegisters;
			RelatedFormTable = Object.CashAccounts;
		Else
			FormTableBeingChecked = Object.CashAccounts;
			RelatedFormTable = Object.CashRegisters;
		EndIf;
		
		RowsOfTableBeingChecked = FormTableBeingChecked.FindRows(New Structure("Peripherals", Peripherals));
		RowsOfLinkedTable = RelatedFormTable.FindRows(New Structure("Peripherals", Peripherals));

		If RowsOfLinkedTable.Count() = 0 And 
			RowsOfTableBeingChecked.Count() = 1 Then
			Cancel = True;
			
			MessageStrings = New Array;
			MessageTemplate = NStr("ru = 'Есть настройка для эквайрингового терминала ""%1"", связанная с оборудованием ""%2"".';
									|vi = 'There is a setting for the ""%1"" POS terminal related to the ""%2"" peripherals.';
									|en = 'There is a setting for the ""%1"" POS terminal related to the ""%2"" peripherals.'; fa = 'There is a setting for the ""%1"" POS terminal related to the ""%2"" peripherals.';
									|it = 'There is a setting for the ""%1"" POS terminal related to the ""%2"" peripherals.';
									|pl = 'There is a setting for the ""%1"" POS terminal related to the ""%2"" peripherals.';
									|tr = '""%2"" donanımıyla ilişkili, ""%1"" POS terminali için ayar mevcut.'");
			MessageStrings.Add(StrTemplate(MessageTemplate, AcquiringTerminalsFound[0].POSTerminal,
											Peripherals));
			MessageStrings.Add(NStr("ru = 'Сначала на закладке ""Эквайринговые терминалы"" нужно удалить эту настройку.';
									|vi = 'First delete this setting on the ""POS terminals"" tab.';
									|en = 'First delete this setting on the ""POS terminals"" tab.'; fa = 'First delete this setting on the ""POS terminals"" tab.';
									|it = 'First delete this setting on the ""POS terminals"" tab.';
									|pl = 'First delete this setting on the ""POS terminals"" tab.';
									|tr = 'Önce ""POS terminalleri"" sekmesinden bu ayarı silmeniz gerekir.'"));
			CommonClient.MessageToUser(StrConcat(MessageStrings, Char(32)));
		EndIf;
	
	EndIf;
	
EndProcedure


&AtClient
// Parameters:
//	Print Parameters - Structure:
//	 *Form - Client Application form
// 
// Returns:
//	Undefined -
Function PrintingCashLinkUsingTemplate(PrintParameters) Export
	

	Return Undefined;
	
EndFunction


&AtServer
Procedure FillChoiceLists()
	
	
EndProcedure


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


#EndRegion
