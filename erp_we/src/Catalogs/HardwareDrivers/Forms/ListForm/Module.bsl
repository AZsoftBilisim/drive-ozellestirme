
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DisplayAdditionalElements = Not CommonCEL.ThisIsMobilePlatform();
	
	// APK: 484-off not used BSP
	List.QueryText = StrTemplate(List.QueryText, 
		NStr("vi = 'Thiết bị được cung cấp trong cấu hình';
			|ru = 'Поставляемый в составе конфигурации';
			|en = 'Supplied with configuration'; fa = 'Supplied with configuration';
			|it = 'Come parte della configurazione';
			|pl = 'Dostarczany w składzie konfiguracji';
			|tr = 'Uygulama ile birlikte sağlanır'"),
		NStr("vi = 'Thiết bị được kết nối theo chuẩn """"1C:Compatible""""';
			|ru = 'Подключаемый по стандарту """"1С:Совместимо""""';
			|en = 'Connected according to the 1C:Compatible standard'; fa = 'Connected according to the 1C:Compatible standard';
			|it = 'Plug-in secondo standard """"1C:Compatibile""""';
			|pl = 'Podłączany zgodnie ze standardem """"1C:Zgodne""""';
			|tr = '1C:Compatible standardına uygun olarak bağlandı'"));
	// APK: 484-on
	
	AddingNewDrivers = EquipmentManager.AvailableAddingNewDrivers();
	AccessRightInsert = AccessRight("Insert", Metadata.Catalogs.HardwareDrivers);
	ThisForm.CommandBar.Visible = AddingNewDrivers And AccessRightInsert;
	
	Items.HardwareDrivers.ChangeRowSet = AddingNewDrivers;
	GroupItem2 = List.Group.Items.Add(Type("DataCompositionGroupField"));
	GroupItem2.Field = New DataCompositionField("DeliveryOption");
	GroupItem2.Use = True;
	
	Items.HardwareDrivers.ChangeRowSet = AddingNewDrivers;
	GroupItem2 = List.Group.Items.Add(Type("DataCompositionGroupField"));
	GroupItem2.Field = New DataCompositionField("EquipmentType");
	GroupItem2.Use = True;
	
	Items.HardwareDrivers.Header = DisplayAdditionalElements;     
	Items.ConnectNewOne.Visible = DisplayAdditionalElements;    
	Items.ConnectionMethod.Visible = DisplayAdditionalElements;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InstalledOnLocalComputer(Command)
	
	Items.HardwareDrivers.AddRow();
	
EndProcedure

&AtClient
Procedure DownloadNewDriverFromFile(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	ConnectionComponentTypeSearchParameters = AddInsCELClient.AdditionalInformationSearchParameters();
	ConnectionComponentTypeSearchParameters.XMLFileName = "INFO.XML";
	ConnectionComponentTypeSearchParameters.XPathExpression = "//drivers/component/@type";
	
	ImportParameters = AddInsCELClient.ImportParameters();
	ImportParameters.AdditionalInformationSearchParameters.Insert("ConnectionComponentType", ConnectionComponentTypeSearchParameters);
	
	Notification = New CallbackDescription("DownloadNewDriverFromFile_Completion", ThisObject, AdditionalParameters);
	
	AddInsCELClient.ImportAddInFromFile(Notification, ImportParameters);
	
EndProcedure

#EndRegion

#Region Private      

&AtClient
Procedure InstallHardwareDriver(Command)
	
	ClearMessages();
	
	CurrentData = Items.HardwareDrivers.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Property("Ref") Then
		EquipmentManagerClient.InstallHardwareDriver(Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtServerNoContext
// Performs the creation of hardware drivers
// 
// Parameters:
//   Loading Result - Structure:
//     * Id - String
//     * Name - String
//     * Version - String
//   An array of Equipment types is an array from the Link enumeration.Type of switchable equipment
// 
// Returns:
//   Array of Structure
Function CreateHardwareDriversOnServer(ImportResult1, ArrayOfEquipmentTypes)
	
	ArrayOfDrivers = New Array();
	For Each EquipmentType In ArrayOfEquipmentTypes Do 
		CreationParameters = EquipmentManagerClientServer.ParametersForCreatingNewDriver();
		CreationParameters.Insert("Imported1", True);
		CreationParameters.EquipmentType = EquipmentType;
		Result = ImportResult1; // Structure
		CreationParameters.ObjectID = Result.Id;
		CreationParameters.Description         = Result.Description;
		CreationParameters.ConnectionMethod    = Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase;
		NewItem = EquipmentManager.CreateHardwareDriver(CreationParameters);
		ArrayOfDrivers.Add(NewItem);
	EndDo;
	Return ArrayOfDrivers;
	
EndFunction

&AtClient
Procedure DownloadNewDriverFromFile_Completion(Result, AdditionalParameters) Export
	
	If Result.Imported1 Then  
		
		EquipmentType = Result.AdditionalInformation.Get("ConnectionComponentType");
		If IsBlankString(EquipmentType) Then
			ShowMessageBox(, NStr("vi = 'Chưa chỉ định kiểu thiết bị của driver được kết nhập.';
									|ru = 'Не указан тип оборудования загружаемого драйвера.';
									|en = 'Peripherals type of the driver to import is not specified.'; fa = 'Peripherals type of the driver to import is not specified.';
									|it = 'Non è indicato il tipo di apparecchiatura del driver scaricabile.';
									|pl = 'Nie podano typu sprzętu pobieranego sterownika.';
									|tr = 'Yüklenecek sürücünün donanım türü belirtilmemiş.'") );
			Return;
		EndIf;
		
		ArrayOfEquipmentTypes = StrSplit(StrReplace(EquipmentType, ";", ","), ",");
		ArrayOfDrivers = CreateHardwareDriversOnServer(Result, ArrayOfEquipmentTypes);
		If ArrayOfDrivers.Count()>0 Then
			Items.HardwareDrivers.Refresh();
			Items.HardwareDrivers.CurrentRow = ArrayOfDrivers[ArrayOfDrivers.UBound()];
		EndIf;
		
		InstallHardwareDriver(Undefined);
	Else 
		ShowMessageBox(, NStr("vi = 'Lỗi kết nhập driver mới.';
								|ru = 'Ошибка загрузки нового драйвера.';
								|en = 'An error occurred while importing the new driver.'; fa = 'An error occurred while importing the new driver.';
								|it = 'Errore di download del nuovo driver.';
								|pl = 'Błąd pobierania nowego sterownika.';
								|tr = 'Yeni sürücü yüklenirken hata oluştu.'") );
	EndIf;
	
EndProcedure

#EndRegion