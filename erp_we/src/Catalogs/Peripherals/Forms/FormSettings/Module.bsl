
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Parameters.Property("Id", Id);
	LanguageCode = ?(Parameters.Property("LanguageCode"), Parameters.LanguageCode, ""); 
	DeviceDataStructure = EquipmentManager.DeviceData(Id, LanguageCode); // Structure
	If DeviceDataStructure = Undefined Then
		Cancel = True;
		CommonCEL.MessageToUser(NStr("vi = 'Không thể nhận dữ liệu thiết bị.';
									|ru = 'Не удалось получить данные устройства.';
									|en = 'Cannot get the device data.'; fa = 'Cannot get the device data.';
									|it = 'Не удалось получить данные устройства.';
									|pl = 'Cannot get the device data.';
									|tr = 'Cihaz verileri alınamadı.'"));
		Return;
	EndIf;
	HardwareDriver = DeviceDataStructure.HardwareDriver;
	ParameterValues_2  = DeviceDataStructure.Parameters;
	DeviceData    = DeviceDataStructure;
	If Not ValueIsFilled(ParameterValues_2) Then
		ParameterValues_2 = New Structure();
	EndIf;
	
	Title = NStr("vi = 'Thiết bị:';
				|ru = 'Оборудование:';
				|en = 'Peripherals:'; fa = 'Peripherals:';
				|it = 'Apparecchiature:';
				|pl = 'Sprzęt:';
				|tr = 'Ekipman:'") + Chars.NBSp  + String(Id);
	
	HardwareDriverHardwareType = CommonCEL.ObjectAttributeValue(HardwareDriver, "EquipmentType");
	
	MagneticStripeCardReaders = HardwareDriverHardwareType = Enums.PeripheralTypes.MagneticStripeCardReaders;
	If MagneticStripeCardReaders Then
		TimeTrackParameters = Undefined;
		If Not ParameterValues_2.Property("TrackParameters", TimeTrackParameters) Then
			TimeTrackParameters = New Array();
			For IndexOf = 1 To 3 Do
				NewRow = New Structure();
				NewRow.Insert("TrackNumber", IndexOf);
				NewRow.Insert("Prefix"     , 0);
				NewRow.Insert("Suffix"     , ?(IndexOf = 2, 13, 0));
				NewRow.Insert("Use", ?(IndexOf = 2, True, False));
				TimeTrackParameters.Add(NewRow);
			EndDo;
		EndIf;
		For Each TrackString In TimeTrackParameters Do
			NewRow = TrackParameters.Add();
			NewRow.TrackNumber = TrackString.TrackNumber;
			NewRow.Prefix      = TrackString.Prefix;
			NewRow.Suffix      = TrackString.Suffix;
			NewRow.Use = TrackString.Use;
		EndDo;
	EndIf;
	
	WorkplaceId = CommonCEL.ObjectAttributeValue(Id, "Workplace");
	CustomerWorkplace = EquipmentManagerServerCall.CustomerWorkplace();
	CurrentWorkplace = (CustomerWorkplace = WorkplaceId);
	
	Items.DeviceTest.Visible          = CurrentWorkplace;
	Items.StatusOfComponent.Visible        = CurrentWorkplace;
	Items.AdditionalActions.Visible  = CurrentWorkplace Or IsBlankString(WorkplaceId);
	
	If CommonCEL.ThisIsMobilePlatform() Then
		CommonCEL.PrepareControl(Items.Version);
		CommonCEL.PrepareControl(Items.Status);
		CommonCEL.PrepareControl(Items.DriverName);
		CommonCEL.PrepareControl(Items.DriverDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateHardwareDriverInformation(True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	TimeSettings = GetSettings();
	
	If MagneticStripeCardReaders Then
		
		ConfiguredTracks = 0;
		TrackWithEmptySuffix = False;
		TimeTrackParameters = New Array();
		DriverPrefix = -1;
		DriverSuffix = -1;

		For IndexOf = 1 To 3 Do
			If TrackParameters[3 - IndexOf].Use Then
				TrackWithEmptySuffix =
				    TrackWithEmptySuffix Or (TrackParameters[3 - IndexOf].Suffix = 0);
				ConfiguredTracks = ConfiguredTracks + 1;
			EndIf;
		EndDo;
		
		If Not TrackWithEmptySuffix Then
			
			For IndexOf = 1 To 3 Do
				NewRow = New Structure();
				NewRow.Insert("TrackNumber", TrackParameters[IndexOf - 1].TrackNumber);
				NewRow.Insert("Use", TrackParameters[IndexOf - 1].Use);
				NewRow.Insert("Prefix"     , TrackParameters[IndexOf - 1].Prefix);
				NewRow.Insert("Suffix"     , TrackParameters[IndexOf - 1].Suffix);
				TimeTrackParameters.Add(NewRow);
			EndDo;
			
			For IndexOf = 1 To 3 Do
				If TimeTrackParameters[IndexOf - 1].Use Then
					DriverPrefix = TimeTrackParameters[IndexOf - 1].Prefix;
					DriverPrefix = ?(DriverPrefix = 0, -1, DriverPrefix);
					TimeSettings.EquipmentParameters.Insert("P_Prefix", DriverPrefix);
					Break;
				EndIf;
			EndDo;
			
			For IndexOf = 1 To 3 Do
				If TimeTrackParameters[3 - IndexOf].Use Then
					DriverSuffix = TimeTrackParameters[3 - IndexOf].Suffix;
					DriverSuffix = ?(DriverSuffix = 0, -1, DriverSuffix);
					TimeSettings.EquipmentParameters.Insert("P_Suffix", DriverSuffix);
					Break;
				EndIf;
			EndDo;
			
			TimeSettings.EquipmentParameters.Insert("TrackParameters", TimeTrackParameters);
			
		EndIf;
		
		If DriverPrefix > 0 And DriverSuffix > 0 And DriverPrefix = DriverSuffix Then
			MessageText = NStr("vi = 'Tiền tố của đường dẫn được sử dụng đầu tiên trùng với hậu tố đường dẫn được sử dụng cuối cùng';
								|ru = 'Префикс первой используемой дорожки совпадает с суффикс последней используемой дорожки';
								|en = 'Prefix of the first used track matches the suffix of the last used track'; fa = 'Prefix of the first used track matches the suffix of the last used track';
								|it = 'Il prefisso della prima traccia utilizzata coincide con il suffisso dell''ultima traccia utilizzata';
								|pl = 'Prefiks pierwszej wykorzystywanej ścieżki jest taki sam, jak sufiks ostatniej wykorzystywanej ścieżki';
								|tr = 'İlk kullanılan parçanın ön eki, son kullanılan parçanın son ekiyle aynıdır'");
			CommonCELClient.MessageToUser(MessageText);
		ElsIf ConfiguredTracks > 0 And Not TrackWithEmptySuffix Then
			Close(TimeSettings);  
		ElsIf ConfiguredTracks = 0 Then
			MessageText = NStr("vi = 'Cần chỉ ra việc sử dụng ít nhất một đường dẫn đối với đầu đọc';
								|ru = 'Необходимо указать использование хотя бы одной дорожки для считывателя';
								|en = 'Specify at least one track for the reader'; fa = 'Specify at least one track for the reader';
								|it = 'È necessario indicare l''utilizzo di almeno una traccia per il lettore';
								|pl = 'Należy określić wykorzystanie chociażby jednej ścieżki dla czytnika';
								|tr = 'Okuyucu için en az bir parçanın kullanımı belirtilmeli'");
			CommonCELClient.MessageToUser(MessageText);
		ElsIf TrackWithEmptySuffix Then
			MessageText = NStr("vi = 'Đối với mỗi đường dẫn được sử dụng cần chỉ ra hậu tố';
								|ru = 'Для каждой используемой дорожки должен быть указан суффикс';
								|en = 'Specify a suffix for each used track'; fa = 'Specify a suffix for each used track';
								|it = 'Per ogni traccia utilizzata deve essere indicato un suffisso';
								|pl = 'Dla każdej wykorzystywanej ścieżki musi być wskazany sufiks';
								|tr = 'Kullanılan her parçanın son eki olmalıdır'");
			CommonCELClient.MessageToUser(MessageText);
		EndIf;
		
	Else
		Close(TimeSettings);  
	EndIf;
	
	
EndProcedure

&AtClient
Procedure BeginRunningApplicationCompletion(Result, Var_Parameters) Export
	
	CommonCELClient.MessageToUser(NStr("vi = 'Bắt đầu cài đặt bộ cài đặt chính driver.';
										|ru = 'Начата установка основной поставки драйвера.';
										|en = 'Main driver supply setup started.'; fa = 'Main driver supply setup started.';
										|it = 'Installazione alimentazione driver principale avviata.';
										|pl = 'Rozpoczęto instalację głównej dostawy sterownika.';
										|tr = 'Ana sürücü dağıtımının kurulumu başladı.'")); 
	
EndProcedure

&AtClient
Procedure DriverInstallationBasicDeliveryEnd(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Notifications = New CallbackDescription("BeginRunningApplicationCompletion", ThisObject);
		// APK:534-off the driver's URL is provided by the driver manufacturer
		BeginRunningApplication(Notifications, DriverDownloadURL, , False);
		// APK:534-on
	EndIf;   
	
EndProcedure

&AtClient
Procedure InstallDriverCompletion(OperationResult, Var_Parameters) Export 
	
	If OperationResult.Result Then
		CommonCELClient.MessageToUser(NStr("vi = 'Đã hoàn tất cài đặt driver.';
											|ru = 'Установка драйвера завершена.';
											|en = 'Driver is installed.'; fa = 'Driver is installed.';
											|it = 'Installazione del driver completata.';
											|pl = 'Instalacja sterownika została zakończona.';
											|tr = 'Sürücü yüklemesi tamamlandı.'")); 
		UpdateHardwareDriverInformation(True);
	Else
		CommonCELClient.MessageToUser(OperationResult.ErrorDescription); 
	EndIf;

EndProcedure 

&AtClient
Procedure InstallDriver(Command)
	
	If IntegrationComponent Then
		Text = NStr("vi = 'Để chuyển đến Website của nhà sản xuất, cần kết nối Internet.
			|Tiếp tục thực hiện thao tác?';
			|ru = 'Для перехода на сайт производителя необходимо подключение к Интернету.
			|Продолжить выполнение операции?';
			|en = 'To go to the manufacturer website, connect to the Internet.
			|Continue?'; fa = 'To go to the manufacturer website, connect to the Internet.
			|Continue?';
			|it = 'Per il passaggio al sito del produttore è necessaria una connessione a Internet.
			|Continuare con l''operazione?';
			|pl = 'Aby przejść na stronę producenta jest podłączenie do internetu. 
			| Kontynuować wykonanie operacji?';
			|tr = 'Üreticinin web sitesine gitmek için İnternet bağlantısı gereklidir.
			|İşleme devam edilsin mi?'");
		Notification = New CallbackDescription("DriverInstallationBasicDeliveryEnd",  ThisObject);
		ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo);
	Else
		AlertsInstallDriverEnd = New CallbackDescription("InstallDriverCompletion", ThisObject);
		EquipmentManagerClient.InstallHardwareDriver(AlertsInstallDriverEnd, HardwareDriver);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeviceTestCompletion(ExecutionResult, Var_Parameters) Export
	
	ReadOnly = False;
	CommandBar.Enabled = True;
	
	If  ExecutionResult.Result Then
		AdditionalDetails = ExecutionResult.ExecutionResult;
		DemoMode =  ExecutionResult.DemoModeActivated;
		Items.GroupDemoMode.Visible = Not IsBlankString(DemoMode);
		MessageText = NStr("vi = 'Thử nghiệm thành công.';
							|ru = 'Тест успешно выполнен.';
							|en = 'Test completed successfully.'; fa = 'Test completed successfully.';
							|it = 'Test completato con successo.';
							|pl = 'Test został wykonany pomyślnie.';
							|tr = 'Test başarıyla yapıldı.'");   
		If Not IsBlankString(AdditionalDetails) Then
			MessageText = MessageText + Chars.NBSp + AdditionalDetails;    
		EndIf
	Else
		MessageText = StrTemplate(NStr("vi = 'Đã thử nghiệm thành công. %1';
										|ru = 'Тест не пройден. %1';
										|en = 'Test failed. %1'; fa = 'Test failed. %1';
										|it = 'Тест не пройден. %1';
										|pl = 'Test failed. %1';
										|tr = 'Test başarısız. %1'"), ExecutionResult.ErrorDescription);
	EndIf;
	CommonCELClient.MessageToUser(MessageText);
	
EndProcedure

&AtClient
Procedure ConnectionTest(Command)
	
	ClearMessages();
	ReadOnly = True;
	CommandBar.Enabled = False;
	
	DemoMode = "";
	
	DeviceParameters = GetSettings().EquipmentParameters;
	Notification = New CallbackDescription("DeviceTestCompletion", ThisObject);
	EquipmentManagerClient.StartDeviceTest(Notification, Id, DeviceParameters);
	
EndProcedure   

&AtServer
Procedure ClearParametersOnServer()
	
	DriverParametersAttributes = GetAttributes();
	For Each Parameter In DriverParametersAttributes Do
		If Left(Parameter.Name, 2) = "P_" Then
			ThisObject[Parameter.Name] = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AutoTuneSetParameters(ConnectionParameters)  
	
	ClearParametersOnServer();
	FillPropertyValues(ThisObject, ConnectionParameters);  
	
EndProcedure

&AtClient
Procedure AutoTuningDeviceCompletion(ExecutionResult, Var_Parameters) Export
	
	ReadOnly = False;
	CommandBar.Enabled = True;
	MessageText = ?(ExecutionResult.Result, NStr("vi = 'Đã thực hiện thành công thao tác.';
												|ru = 'Операция выполнена успешно.';
												|en = 'Operation has been successfully installed.'; fa = 'Operation has been successfully installed.';
												|it = 'Операция выполнена успешно.';
												|pl = 'Operacja została wykonana pomyślnie.';
												|tr = 'İşlem başarıyla tamamlandı.'"), NStr("vi = 'Chưa thực hiện giao dịch.';
																											|ru = 'Операция не выполнена.';
																											|en = 'Operation failed.'; fa = 'Operation failed.';
																											|it = 'Операция не выполнена.';
																											|pl = 'Operacja nie powiodła się.';
																											|tr = 'İşlem tamamlanmadı.'"));
	
	If ExecutionResult.Result Then        
		If ExecutionResult.ConnectionParameters.Count() > 0 Then
			AutoTuneSetParameters(ExecutionResult.ConnectionParameters);
		Else   
			MessageText = NStr("vi = 'Chưa xác định tham số tùy chỉnh driver.';
								|ru = 'Параметры настройки драйвера не определены.';
								|en = 'The driver settings are not defined.'; fa = 'The driver settings are not defined.';
								|it = 'Параметры настройки драйвера не определены.';
								|pl = 'The driver settings are not defined.';
								|tr = 'Sürücü ayar parametreleri tanımlanmamış.'");
		EndIf;
	EndIf;
	
	CommonCELClient.MessageToUser(MessageText);
	
EndProcedure

&AtClient
Procedure AutoTuningDevice(Command)
	
	ClearMessages();
	ReadOnly = True;
	CommandBar.Enabled = False;
	
	DemoMode = "";
	
	DeviceParameters = GetSettings().EquipmentParameters;
	Notification = New CallbackDescription("AutoTuningDeviceCompletion", ThisObject);
	EquipmentManagerClient.StartAutoTuningDevice(Notification, Id, DeviceParameters);
	
EndProcedure

&AtClient
Procedure AdditionalActionCompletion(ExecutionResult, Var_Parameters) Export
	
	MessageText = ?(ExecutionResult.Result,  
						NStr("vi = 'Đã thực hiện thành công thao tác.';
							|ru = 'Операция выполнена успешно.';
							|en = 'Operation has been successfully installed.'; fa = 'Operation has been successfully installed.';
							|it = 'Operazione completata con successo.';
							|pl = 'Operacja została wykonana pomyślnie.';
							|tr = 'İşlem başarıyla tamamlandı.'"),
						NStr("vi = 'Lỗi thực hiện giao dịch:';
							|ru = 'Ошибка выполнения операции:';
							|en = 'Operation error:'; fa = 'Operation error:';
							|it = 'Errore di esecuzione operazione:';
							|pl = 'Błąd wykonania operacji:';
							|tr = 'İşlem yürütme hatası:'") + ExecutionResult.ErrorDescription);
	CommonCELClient.MessageToUser(MessageText);
	
	ClearCustomizableInterface();
	
	UpdateHardwareDriverInformation(False);
	
EndProcedure

&AtClient
Procedure AdditionalAction(Command)
	
	ActionName = Mid(Command.Name, 3);
	ExecutionParameters = New Structure("ActionName", ActionName);
	
	DeviceParameters = GetSettings().EquipmentParameters;
	Notification = New CallbackDescription("AdditionalActionCompletion", ThisObject);
	EquipmentManagerClient.Start_ExecutingAdditionalCommand(Notification, Id, DeviceParameters, ExecutionParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetSettings()
	            
	DriverParametersAttributes = GetAttributes();
	
	NewParameterValues = New Structure;
	For Each Parameter In DriverParametersAttributes Do
		If Left(Parameter.Name, 2) = "P_" Then
			NewParameterValues.Insert(Parameter.Name, ThisObject[Parameter.Name]);
		EndIf;
	EndDo;
	
	Result = New Structure;
	Result.Insert("Id", Id);
	Result.Insert("EquipmentParameters", NewParameterValues);
	
	Return Result;
	
EndFunction

&AtServer
Procedure ClearCustomizableInterface()
	
	While Items.Pages.ChildItems.Count() > 0 Do
		Items.Delete(Items.Pages.ChildItems.Get(0));
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateCustomizableInterface(InterfaceDescription, AdditionalActions, FirstRun)
	
	Suffix = False;
	Prefix = False;
	BaseGroup = Undefined;
	Item = Undefined;
	GroupIndex = 0;
	PageCount = 0;
	CurrentPage = Items.Add("BasicPage", Type("FormGroup"), Items.Pages);
	
	XMLReader = New XMLReader; 
	XMLReader.SetString(InterfaceDescription);
	XMLReader.MoveToContent();
	
	If XMLReader.Name = "Settings" And XMLReader.NodeType = XMLNodeType.StartElement Then  
		While XMLReader.Read() Do  
			
			If XMLReader.Name = "Parameter" And XMLReader.NodeType = XMLNodeType.StartElement Then  
				
				Var_ReadOnly = ?(Upper(XMLReader.AttributeValue("ReadOnly")) = "TRUE", True, False) 
										Or ?(Upper(XMLReader.AttributeValue("ReadOnly")) = "TRUE", True, False);
				OriginalName_   =  XMLReader.AttributeValue("Name");
				NameParameter       = ?(Var_ReadOnly, "R_", "P_") + OriginalName_;
				HeaderParameter_ = XMLReader.AttributeValue("Caption");
				ParameterType       = Upper(XMLReader.AttributeValue("TypeValue"));
				ParameterType       = ?(Not IsBlankString(ParameterType), ParameterType, "STRING");
				ParameterValue1  = XMLReader.AttributeValue("DefaultValue");
				ParameterDescription  = XMLReader.AttributeValue("Description");
				FormattingString = XMLReader.AttributeValue("FieldFormat");
				
				If MagneticStripeCardReaders Then
					Suffix = Upper(OriginalName_) = "SUFFIX" Or ?(Upper(XMLReader.AttributeValue("Suffix")) = "TRUE", True, False);
					Prefix = Upper(OriginalName_) = "PREFIX" Or ?(Upper(XMLReader.AttributeValue("Prefix")) = "TRUE", True, False);
				EndIf;
				
				ParameterExists = False;
				DriverParametersAttributes = GetAttributes();
				For Each DriverParameterAttributes In DriverParametersAttributes Do
					If DriverParameterAttributes.Name = NameParameter Then
						ParameterExists = True;
						Break;
					EndIf;
				EndDo;
				
				If Not ParameterExists Then
					
					If ParameterType = "NUMBER" Then 
						Attribute = New FormAttribute(NameParameter, New TypeDescription("Number"), , HeaderParameter_, True);
					ElsIf ParameterType = "BOOLEAN" Then 
						Attribute = New FormAttribute(NameParameter, New TypeDescription("Boolean"), , HeaderParameter_, True);
					Else
						Attribute = New FormAttribute(NameParameter, New TypeDescription("String"), , HeaderParameter_, True);
					EndIf;
				
					// Adding new props to the form.
					AttributesToBeAdded = New Array;
					AttributesToBeAdded.Add(Attribute);
					ChangeAttributes(AttributesToBeAdded);
				
				EndIf;
				
				If Suffix Then 
					Item = Items.TrackParametersSuffix
				ElsIf Prefix Then
					Item = Items.TrackParametersPrefix;
				ElsIf Items.Find(NameParameter) = Undefined Then
					// If more than one group has not been created.
					If BaseGroup = Undefined Then
						BaseGroup = Items.Add("BaseGroup" + PageCount, Type("FormGroup"), CurrentPage);
						BaseGroup.Type = FormGroupType.UsualGroup;
						BaseGroup.Representation = Items.HardwareDriver.Representation;
						BaseGroup.HorizontalStretch = True;
						BaseGroup.Title = NStr("vi = 'Tham số';
												|ru = 'Параметры';
												|en = 'Parameters'; fa = 'پارامترها';
												|it = 'Parametri';
												|pl = 'Parametry';
												|tr = 'Parametreler'");
						BaseGroup.Group = Items.HardwareDriver.Group;
					EndIf;
					// Adding a new input field to the form.
					Item = Items.Add(NameParameter, Type("FormField"), BaseGroup);
					If ParameterType = "BOOLEAN" Then 
						Item.Type = FormFieldType.CheckBoxField
					Else
						Item.Type = FormFieldType.InputField;
						Item.AutoMaxWidth = False;
						Item.HorizontalStretch = True;
						Item.Format = FormattingString;
						Item.EditFormat = FormattingString;       
						If CommonCEL.ThisIsMobilePlatform() Then
							CommonCEL.PrepareControl(Item);
						EndIf;
					EndIf;
					Item.DataPath = NameParameter;
					Item.ToolTip = ParameterDescription;
					Item.ReadOnly = Var_ReadOnly; 
				EndIf;
				
				StoredValue = Undefined;
				If ParameterValues_2.Property(NameParameter, StoredValue) Then
					ParameterValue1 = StoredValue
				Else
					If Not IsBlankString(ParameterValue1) Then
						If ParameterType = "BOOLEAN" Then
							ParameterValue1 = ?(Upper(ParameterValue1) = "TRUE", True, False) Or  ?(Upper(ParameterValue1) = "TRUE", True, False);
						ElsIf ParameterType = "STRING" Then
							ParameterValue1 = String(ParameterValue1);
						EndIf;
					EndIf;
				EndIf;
				
				ThisObject[NameParameter] = ParameterValue1;
				
			EndIf;
			
			If XMLReader.Name = "ChoiceList" And XMLReader.NodeType = XMLNodeType.StartElement Then 
				
				If Not (Item = Undefined) And Not (Item.Type = FormFieldType.CheckBoxField) Then   
					Item.ListChoiceMode  = True; 
					Item.ChoiceListHeight   = 10;
					Item.TextEdit = False; 
					If Suffix Or Prefix Then
						Item.ChoiceList.Add(0, "<NONE>");
					EndIf;
				EndIf;
				
				While XMLReader.Read() And Not (XMLReader.Name = "ChoiceList") Do   
					
					If XMLReader.Name = "Item" And XMLReader.NodeType = XMLNodeType.StartElement Then  
						AttributeValue = XMLReader.AttributeValue("Value"); 
						If XMLReader.Read() Then
							AttributePresentation_1 = XMLReader.Value;
						EndIf;
						If IsBlankString(AttributeValue) Then
							AttributeValue = AttributePresentation_1;
						EndIf;
						
						If Suffix Or Prefix Then
							If Number(AttributeValue) > 0 Then
								Item.ChoiceList.Add(Number(AttributeValue), AttributePresentation_1);
							EndIf;
						ElsIf ParameterType = "NUMBER" Then 
								Item.ChoiceList.Add(Number(AttributeValue), AttributePresentation_1);
						Else
							Item.ChoiceList.Add(AttributeValue, AttributePresentation_1)
						EndIf;         
						If CommonCEL.ThisIsMobilePlatform() Then
							CommonCEL.PrepareControl(Item);   
						EndIf; 
					EndIf;
				EndDo; 
				
			EndIf;
			
			If XMLReader.Name = "Page" And XMLReader.NodeType = XMLNodeType.StartElement Then
				
				PageHeader = XMLReader.AttributeValue("Caption");
				PageHeader = ?(IsBlankString(PageHeader), NStr("vi = 'Tham số';
																|ru = 'Параметры';
																|en = 'Parameters'; fa = 'پارامترها';
																|it = 'Parametri';
																|pl = 'Parametry';
																|tr = 'Parametreler'"), PageHeader);
				
				PageCount = PageCount + 1;
				If PageCount > 1 Then
					Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
					CurrentPage = Items.Add("Page" + PageCount, Type("FormGroup"), Items.Pages);
					BaseGroup = Undefined;
				EndIf;
				CurrentPage.Title = PageHeader;
				
			EndIf;
				
			If XMLReader.Name = "Group" And XMLReader.NodeType = XMLNodeType.StartElement Then  
				
				GroupTitle = XMLReader.AttributeValue("Caption");
				GroupTitle = ?(IsBlankString(GroupTitle), NStr("vi = 'Tham số';
																|ru = 'Параметры';
																|en = 'Parameters'; fa = 'پارامترها';
																|it = 'Parametri';
																|pl = 'Parametry';
																|tr = 'Parametreler'"), GroupTitle);
				
				BaseGroup = Items.Add("Group" + GroupIndex, Type("FormGroup"), CurrentPage);
				BaseGroup.Type = FormGroupType.UsualGroup;
				BaseGroup.Representation = Items.HardwareDriver.Representation;
				BaseGroup.HorizontalStretch = True;
				BaseGroup.Group = Items.HardwareDriver.Group;
				BaseGroup.Title = GroupTitle;
				GroupIndex = GroupIndex + 1;
				
			EndIf;
			
		EndDo;  
		
	EndIf;
	
	XMLReader.Close(); 
	
	If FirstRun And Not IsBlankString(AdditionalActions) Then
		
		XMLReader = New XMLReader; 
		XMLReader.SetString(AdditionalActions);
		XMLReader.MoveToContent();
		
		If XMLReader.Name = "Actions" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			
			While XMLReader.Read() Do  
				If XMLReader.Name = "Action" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					
					Action_Name       = "M_"  + XMLReader.AttributeValue("Name");
					ActionHeader = XMLReader.AttributeValue("Caption");
					
					Command = Commands.Add("A_" + XMLReader.AttributeValue("Name"));
					Command.Title = ActionHeader;
					Command.Action = "AdditionalAction";
					
					MenuItem_ = Items.Add(Action_Name, Type("FormButton"), Items.AdditionalActions);
					MenuItem_.Type = FormButtonType.CommandBarButton;
					MenuItem_.Title = ActionHeader;
					MenuItem_.CommandName = "A_" + XMLReader.AttributeValue("Name");
					 
				EndIf;
			EndDo;  
			
		EndIf;
		
		XMLReader.Close(); 
		
	EndIf;
	
	Items.TrackPrefixesAndSuffixes.Visible = MagneticStripeCardReaders;
	
EndProcedure                                   

&AtClient
Procedure UpdateFormInterface(FirstRun, OperationParametersList)
	
	If OperationParametersList.Result Then
		
		Items.StatusOfComponent.CurrentPage = Items.AddInInstalled;
		DriverIsReadyToWork = False;
		Items.DriverIsMainSupply.Visible = False;
		
		FillPropertyValues(ThisForm, OperationParametersList.DriverDescription);
		
		Items.DecorationInformationAboutEnvironment.Visible = Not IsBlankString(InformationAboutEnvironment);
		
		If NumberOfConnectedDevices > 0 Then 
			
			Items.StatusOfComponent.CurrentPage = Items.DeviceIsConnected;
			
		ElsIf IntegrationComponent Then
			
			If Not MainDriverIsInstalled Then   
				ThisObject.Height = 14;
				Items.StatusOfComponent.CurrentPage = Items.DriverIntegrationComponent;
				DriverIs_Specified = NStr("vi = 'Đã cài đặt cấu phần tích hợp';
											|ru = 'Установлен интеграционный компонент';
											|en = 'Integration component is installed'; fa = 'مؤلفه یکپارچگی نصب شده است';
											|it = 'Installato componente di integrazione';
											|pl = 'Zainstalowano komponent integracyjny';
											|tr = 'Entegre add-in ayarlandı'");
				DriverVersion = NStr("vi = 'Không xác định';
									|ru = 'Не определена';
									|en = 'Not defined'; fa = 'Not defined';
									|it = 'Non definita';
									|pl = 'Nie określono';
									|tr = 'Belirlenmedi'");
				Items.DriverWarning.Visible = Not IsBlankString(DriverName); 
				Items.DriverWarning.Title = StrTemplate(Items.DriverWarning.Title, DriverName);
				Items.GoToTheManufacturerSWebsite.Visible = Not IsBlankString(DriverDownloadURL);
			Else
				DriverIsReadyToWork = True;
				DriverIs_Specified = NStr("vi = 'Đã cài đặt';
											|ru = 'Установлен';
											|en = 'Installed'; fa = 'نصب‌شده';
											|it = 'Impostato';
											|pl = 'Ustawiono';
											|tr = 'Ayarlandı'");
				Items.DriverIsMainSupply.Visible = True;
				Items.MainSupplyIsInstalled.Title = StrTemplate(
				NStr("vi = 'Đã cài đặt bộ cài driver chính. Phiên bản %1.';
					|ru = 'Установлена основная поставка драйвера. Версия %1.';
					|en = 'Main driver distribution package is installed. Version %1.'; fa = 'Main driver distribution package is installed. Version %1.';
					|it = 'Установлена основная поставка драйвера. Версия %1.';
					|pl = 'Main driver distribution package is installed. Version %1.';
					|tr = 'Ana sürücü kaynağı yüklendi. Sürüm %1.'"),
				OperationParametersList.DriverDescription.DriverVersion);
				DriverVersion = OperationParametersList.DriverDescription.VersionOfIntegrationComponent;
			EndIf
		Else
			DriverIs_Specified = NStr("vi = 'Đã cài đặt';
										|ru = 'Установлен';
										|en = 'Installed'; fa = 'نصب‌شده';
										|it = 'Impostato';
										|pl = 'Ustawiono';
										|tr = 'Ayarlandı'");
			DriverIsReadyToWork = True;
		EndIf;
		
		If DriverIsReadyToWork And Not IsBlankString(DriverParameters) Then
			UpdateCustomizableInterface(DriverParameters, AdditionalActions, FirstRun);
		EndIf;
		
	Else               
		ThisObject.Height = 14;
		Items.StatusOfComponent.CurrentPage = Items.ComponentIsNotInstalled;
		DriverIsReadyToWork = False;
		DriverIs_Specified = NStr("vi = 'Chưa cài đặt';
									|ru = 'Не установлен';
									|en = 'Not set'; fa = 'تنظیم نشده';
									|it = 'Non impostato';
									|pl = 'Nie ustawiono';
									|tr = 'Gönderilmedi'");
		DriverVersion    = NStr("vi = 'Không xác định';
								|ru = 'Не определена';
								|en = 'Not defined'; fa = 'Not defined';
								|it = 'Non definita';
								|pl = 'Nie określono';
								|tr = 'Belirlenmedi'");          
		If Not IsBlankString(OperationParametersList.ErrorDescription) Then 
			CommonCELClient.MessageToUser(OperationParametersList.ErrorDescription);
		EndIf;
	EndIf;
	
	Items.DeviceTest.Visible = DriverIsReadyToWork;  
	Items.AutoTuningDevice.Visible = DriverIsReadyToWork And AutoHardwareConfiguration; 
	Items.WriteAndClose.Visible = DriverIsReadyToWork;
	Items.HardwareDriver.Visible   = DriverIsReadyToWork;
	Items.Functions.Visible = DriverIsReadyToWork;
	Items.DriverDescription.Visible = DriverIsReadyToWork And Not IsBlankString(DriverDescription);
	
EndProcedure

&AtClient
Procedure UpdateHardwareDriverInformation_Completion(ExecutionResult, Var_Parameters) Export
		
	If Not TypeOf(ExecutionResult) = Type("Structure") Then
		Return;
	EndIf;
	
	FirstRun = ?(Var_Parameters.Property("FirstRun"), Var_Parameters.FirstRun, True);
	UpdateFormInterface(FirstRun, ExecutionResult);
	
EndProcedure

&AtClient
Procedure UpdateHardwareDriverInformation(FirstRun)

	CommandParameters = New Structure("FirstRun", FirstRun);
	Notification = New CallbackDescription("UpdateHardwareDriverInformation_Completion", ThisObject, CommandParameters);
	EquipmentManagerClient.StartGettingDescriptionOfEquipment(Notification, , DeviceData);
	  
EndProcedure

&AtClient
Procedure DecorationInformationAboutEnvironmentClick(Item)
	
	DoMessageBoxAsync(InformationAboutEnvironment, , NStr("vi = 'Thông tin về môi trường';
															|ru = 'Информация об окружении';
															|en = 'Environment information'; fa = 'اطلاعات محیط';
															|it = 'Информация об окружении';
															|pl = 'Environment information';
															|tr = 'Çevre hakkında bilgi'"));
	
EndProcedure

&AtClient
Procedure ClearParameters(Command)     
	
	ClearParametersOnServer();
	
EndProcedure

#EndRegion