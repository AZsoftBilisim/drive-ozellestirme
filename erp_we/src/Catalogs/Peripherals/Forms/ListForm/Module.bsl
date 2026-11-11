
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DisplayAdditionalElements = Not CommonCEL.ThisIsMobilePlatform();      
	
	TypeOfEquipmentConnection = Enums.PeripheralsTypes.LocalConnection;
	
	UpdateListOfEquipmentTypes();
	SetConditionalAppearance();
	
	Items.ListOfDevicesMessageToTechnicalSupport.Visible = CommonCEL.UsedMessagesToTechnicalSupportService()
			And CommonCELInternalServerCall.AuthenticationDataOfOnlineSupportUserFilled();
	
	// Calling BSP
	// Standard subsystems.Pluggable Commands
	If CommonCEL.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = CommonCEL.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// The end of the standard subsystem.Pluggable Commands
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonCELClient.UsedMessagesToTechnicalSupportService() Then
		MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
		Items.ListOfDevicesMessageToTechnicalSupport.Visible
			= MessageModuleToBPOTechnicalSupportServiceClient.SendMessagesToTechnicalSupport();
	EndIf;
		
	EquipmentManagerClient.SetConnectionModeOfComputerInformationExtension(True);
	EquipmentManagerClient.UpdateClientWorkplace();
	If Not ValueIsFilled(CurrentWorkplace) Then
		CurrentWorkplace = EquipmentManagerClient.CustomerWorkplace();
		UpdateUserInterface();
	EndIf;
	UpdateDisplay();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfDevices

&AtClient
Async Procedure ListOfDevicesOnChange(Item)
	
	SelectedEquipment = Items.ListOfDevices.CurrentRow;
	If SelectedEquipment = Undefined Or Not TypeOf(SelectedEquipment) = Type("CatalogRef.Peripherals") Then
		Return;
	EndIf;
	
	ShouldOutputWarning = True;
	WarningText = NStr("vi = 'Thiết bị %1 đang được dùng trong ứng dụng.
							   |Khi đặt dấu xóa có thể dẫn đến làm việc không chính xác với thiết bị này.
							   |Tiếp tục thao tác?';
							   |ru = 'Оборудование %1 используется в приложении.
							   |Пометка на удаление может привести к некорректной работе с этим оборудованием.
							   |Продолжить выполнение операции?';
							   |en = 'The %1 peripheral is used in the application.
							   |Marking for deletion may lead to incorrect operation of this peripheral.
							   |Continue?'; fa = 'The %1 peripheral is used in the application.
							   |Marking for deletion may lead to incorrect operation of this peripheral.
							   |Continue?';
							   |it = 'Оборудование %1 используется в приложении.
							   |Пометка на удаление может привести к некорректной работе с этим оборудованием.
							   |Продолжить выполнение операции?';
							   |pl = 'The %1 peripheral is used in the application.
							   |Marking for deletion may lead to incorrect operation of this peripheral.
							   |Continue?';
							   |tr = 'Bu ekipman %1 bir uygulamada kullanımdadır. 
							   |Silinmek için işaretlenmesi bu ekipmanın yanlış çalışmasına sebep olabilir. 
							   |İşleme devam edilsin mi?'");
	WarningText = StrTemplate(WarningText, SelectedEquipment);
							   
	DeterminePossibilityOfMarkingForRemovalOfEquipment(SelectedEquipment, ShouldOutputWarning, WarningText);
	If ShouldOutputWarning Then
		If Await DoQueryBoxAsync(WarningText, QuestionDialogMode.YesNo) = DialogReturnCode.No Then
			UncheckItemSDeletionMark(SelectedEquipment);
			NotifyChanged(SelectedEquipment);
			RefreshDataRepresentation(Items.ListOfDevices);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfDevicesOnActivateRow(Item)
	
	Items.ListOfDevicesMessageToTechnicalSupport.Enabled = 
		TypeOf(Items.ListOfDevices.CurrentRow) = Type("CatalogRef.Peripherals");
		
	// Calling BSP
	// Standard subsystems.Pluggable Commands
	If CommonCELClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonCELClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// The end of the standard subsystem.Pluggable Commands
	// The end of the BSP Challenge
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TypeOfEquipmentConnectionOnChange(Item)
	
	UpdateDisplay();
	
EndProcedure

&AtClient
Procedure WorkplaceOnChange(Item)
	
	UpdateDisplay();
	
EndProcedure

&AtClient
Procedure EquipmentTypeOnChange(Item)
	
	UpdateDisplay();
	
EndProcedure

&AtClient
Procedure SelectAWorkplaceCompletion(Result, ChoiceParameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.Property("Workplace") Then 
		EquipmentManagerClient.EstablishWorkplace(Result.Workplace);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAWorkplace(Command)
	
	Notification = New CallbackDescription("SelectAWorkplaceCompletion", ThisObject);
	EquipmentManagerClient.SuggestChoiceOfWorkplace(Notification);
	
EndProcedure

&AtClient
Procedure ListOfWorkplaces(Command)
	
	Mode = FormWindowOpeningMode.LockWholeInterface;
	OpenForm("Catalog.Workplaces.ListForm",,,,,,, Mode);
	
EndProcedure

&AtClient
Procedure HardwareDrivers(Command)
	
	OpenForm("Catalog.HardwareDrivers.ListForm");
	
EndProcedure

&AtClient
Procedure MessageToTechnicalSupport(Command)
	
	If TypeOf(Items.ListOfDevices.CurrentRow) = Type("CatalogRef.Peripherals") Then
		
		HardwareId = Items.ListOfDevices.CurrentRow;
		If EquipmentManagerServerCall.DriverIsSuppliedInConfiguration(HardwareId) Then
			MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
			ParametersForMessage = MessageModuleToBPOTechnicalSupportServiceClient.ParametersForSendingErrorMessage();
			ParametersForMessage.HardwareId = HardwareId;
			ParametersForMessage.ErrorText = NStr("vi = 'Thông tin để hỗ trợ kỹ thuật';
													|ru = 'Информация для тех.поддержки';
													|en = 'Information for support'; fa = 'اطلاعات برای پشتیبانی';
													|it = 'Информация для тех.поддержки';
													|pl = 'Information for support';
													|tr = 'Teknik destek için bilgi'");
			CallbackDescription = New CallbackDescription("MessageToTechnicalSupportCompletion", ThisObject);
			MessageModuleToBPOTechnicalSupportServiceClient.StartSendingErrorMessage(CallbackDescription, ParametersForMessage);
		Else                      
			CommonCELClient.ShowDriverNotCertifiedWarning();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MessageToTechnicalSupportCompletion(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorCode) Then
		CommonCELClient.MessageToUser(Result.ErrorMessage);
	EndIf;
	
EndProcedure 

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ListOfDevices.ConditionalAppearance.Items.Clear();
	
	ConditionalAppearanceItem = ListOfDevices.ConditionalAppearance.Items.Add();
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("DeviceIsInUse");       
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.BorderColor);
	
EndProcedure

&AtServer
Procedure UpdateUserInterface()
	
	UpdateListOfJobs();
	
	CustomerWorkplace = EquipmentManagerServerCall.CustomerWorkplace();
	If CurrentWorkplace = Catalogs.Workplaces.EmptyRef()
		Or CurrentWorkplace <> CustomerWorkplace Then
		CurrentWorkplace = CustomerWorkplace;
	EndIf;
	CodeOfCurrentWorkplace = CommonCEL.ObjectAttributeValue(CurrentWorkplace, "Code");
	Workplace = CodeOfCurrentWorkplace;
	
	ListOfDevices.Filter.Items.Clear();
	
	// Elementobora - 0 - Work Place
	FilterElement = ListOfDevices.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("WorkplaceCode");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = String(Workplace);
	FilterElement.Use = False;
	
	If DisplayAdditionalElements Then
		// Elementobora - 1 - Connection type
		FilterElement = ListOfDevices.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("AttachmentType");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = Enums.PeripheralsTypes.LocalConnection;
		FilterElement.Use = True;
		// ElementOtbora - 2 - Type of equipment
		FilterElement = ListOfDevices.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("EquipmentType");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = Undefined;
		FilterElement.Use = False;
	EndIf;
	
	// Grouping - 0 - Type of equipment
	ListOfDevices.Group.Items.Clear();
	GroupItem2 = ListOfDevices.Group.Items.Add(Type("DataCompositionGroupField"));
	GroupItem2.Field = New DataCompositionField("EquipmentType");
	GroupItem2.Use = True;
	
	Items.ListOfDevices.Header = DisplayAdditionalElements;
	Items.Management_.Visible = DisplayAdditionalElements;    
	Items.ListOfDevicesHardwareDriver.Visible = DisplayAdditionalElements;  
	
	NetworkEquipment = EquipmentManager.AvailableNetworkEquipment();
	Items.TypeOfEquipmentConnection.Visible = NetworkEquipment;
	
EndProcedure

&AtServer
Procedure UpdateWorkplaceSettings()
	
	If CurrentWorkplace = Catalogs.Workplaces.EmptyRef()  
		Or CurrentWorkplace <> EquipmentManagerServerCall.CustomerWorkplace() Then
			CurrentWorkplace = EquipmentManagerServerCall.CustomerWorkplace();
			Workplace = CommonCEL.ObjectAttributeValue(CurrentWorkplace, "Code");
	EndIf;       
	
EndProcedure

&AtClient
Procedure UpdateDisplay()
	
	LocalConnection = TypeOfEquipmentConnection = PredefinedValue("Enum.PeripheralsTypes.LocalConnection");
	Items.ListOfDevicesWorkplace.Visible = False; 
	
#If MobileAppClient Then
	ListOfDevices.Filter.Items[0].Use = False;
#Else 
	If LocalConnection Then
		// Elementobora - 0 - Work Place
		If Workplace = "0" Then // All
			ListOfDevices.Filter.Items[0].Use = False;
			Items.ListOfDevicesWorkplace.Visible  = DisplayAdditionalElements;
		Else 
			ListOfDevices.Filter.Items[0].RightValue = String(Workplace);
			ListOfDevices.Filter.Items[0].Use  = True;
		EndIf;
	Else
		ListOfDevices.Filter.Items[0].Use = False;
	EndIf;
#EndIf

	If DisplayAdditionalElements Then
		// Elementobora - 1 - Connection type
		ListOfDevices.Filter.Items[1].RightValue = TypeOfEquipmentConnection;
		Items.Workplace.Visible = LocalConnection;
		Items.EquipmentType.Visible = LocalConnection;
		// ElementOtbora - 2 - Type of equipment
		If IsBlankString(EquipmentType) Or Not LocalConnection Then
			ListOfDevices.Filter.Items[2].Use = False;   // EquipmentType
		Else                                     
			ListOfDevices.Filter.Items[2].RightValue = EquipmentType;
			ListOfDevices.Filter.Items[2].Use = True;  // EquipmentType
		EndIf;
		// Grouping - 0 - Type of equipment
		ListOfDevices.Group.Items[0].Use = Not ListOfDevices.Filter.Items[2].Use;
	EndIf;      
	
EndProcedure

&AtServer
Procedure UpdateListOfEquipmentTypes();
	
	EquipmentList = EquipmentManager.AvailableTypesOfEquipment();
	
	For Each SoftwareType In EquipmentList Do
		Items.EquipmentType.ChoiceList.Add(SoftwareType);
	EndDo;
	EquipmentType = Enums.PeripheralTypes.EmptyRef();
	
EndProcedure

&AtServer
Procedure UpdateListOfJobs();
	
	Items.Workplace.ChoiceList.Clear();
	Items.Workplace.ChoiceList.Add("0",  NStr("vi = '<TẤT CẢ>';
												|ru = '<ВСЕ>';
												|en = '<ALL>'; fa = '<همه>';
												|it = '<TUTTI>';
												|pl = '<ALL>';
												|tr = '<TÜMÜ>'"));
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	Workplaces.Ref AS Ref,
		|	Workplaces.Code AS Code,
		|	Workplaces.Description AS Description
		|FROM
		|	Catalog.Workplaces AS Workplaces
		|
		|ORDER BY
		|	Description DESC";
	      
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		Items.Workplace.ChoiceList.Add(SelectionDetailRecords.Code, SelectionDetailRecords.Description);
	EndDo;
	
EndProcedure

&AtClient
Procedure ConfigureHardware_(Command)
	
	ClearMessages();
	
	If Items.ListOfDevices.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Items.ListOfDevices.CurrentData.Property("Ref") Then
		
		CashRegisterType = EquipmentType(Items.ListOfDevices.CurrentData.Ref);
		If CashRegisterType = PredefinedValue("Enum.PeripheralTypes.CloudCashRegister") Then
			CloudCashAccountsModule = CommonCELClient.CommonModule("CloudCashAccountsClient");
			CloudCashAccountsModule.ConnectionSetup(Items.ListOfDevices.CurrentData.Ref);
		Else
			EquipmentManagerClient.ConfigureHardware(Items.ListOfDevices.CurrentData.Ref);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangedCurSessionWorkplace" Then
		UpdateWorkplaceSettings();     
		UpdateUserInterface();
		UpdateDisplay();
	ElsIf EventName = "ChangedAvailableTypesOfConnectedEquipment" Then
		UpdateUserInterface();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeterminePossibilityOfMarkingForRemovalOfEquipment(Peripherals, ShouldOutputWarning, WarningText)

	MarkingObjectDeletion = CommonCEL.ObjectAttributeValue(Peripherals, "DeletionMark");
	MarkingObjectDeletion = (MarkingObjectDeletion = True); // May be Undefined
	If MarkingObjectDeletion Then
		StandardProcessing = True;
		EquipmentManagerServerCallOverridable.DeterminePossibilityOfEquipmentShutdown(
			Peripherals, ShouldOutputWarning, WarningText, StandardProcessing);
		If StandardProcessing Then
			ShouldOutputWarning = True;
		EndIf;
	Else
		ShouldOutputWarning = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure UncheckItemSDeletionMark(SelectedEquipment);
	
	SelectedEquipmentObject = SelectedEquipment.GetObject();
	SelectedEquipmentObject.DeletionMark = False;
	SelectedEquipmentObject.Write();
	
EndProcedure

&AtServerNoContext
Function EquipmentType(HardwareReference)
	
	Return CommonCEL.ObjectAttributeValue(HardwareReference, "EquipmentType");
	
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	// Calling BSP
	If CommonCELClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonCELClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ListOfDevices);
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters)
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	// Calling BSP
	If CommonCEL.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = CommonCEL.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.ListOfDevices);
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	// Calling BSP
	If CommonCELClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonCELClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListOfDevices);
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion