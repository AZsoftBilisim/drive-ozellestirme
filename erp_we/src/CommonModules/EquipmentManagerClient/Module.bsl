#Region Public

#Region System

// Returns the version number of the library of the connected hardware.
//
// Returns:
//  String
//
Function LibraryVersion() Export
	
	Return Peripherals().LibraryVersion;
	
EndFunction

// Receives an event from the device.
// 
// Parameters:
//  EventDescription1 - Structure:
//   * Source - String - Source of the external event.
//   * Event - String - name of the event.
//   * Data - String - the data for the event.
//  ErrorDescription - String - error description
//
// Returns:
//  Structure
//  Undefined.
//
Function GetEventFromDevice(EventDescription1, ErrorDescription = "") Export
	
	Result = Undefined;
	
	// Event Handler Search
	Peripherals = Peripherals();
	For Each Connection In Peripherals.SoftwareConnectionParameters Do
		If Connection.DeviceID_ = EventDescription1.Source
		 Or (IsBlankString(Connection.DeviceID_) And Connection.EventNames.Count() > 0) Then
			// We are looking for a device with the received event among the connected equipment.
			Event = Connection.EventNames.Find(EventDescription1.Event);
			If Event <> Undefined Then
				DriverObject = Connection.DriverObject;
				// Processing the message
				ProcessingResult = Connection.DriverHandler.ProcessEvent(DriverObject, Connection, EventDescription1.Event, EventDescription1.Data);
				// Notify 
				If ProcessingResult.Result Then 
					Result = New Structure();
					Result.Insert("EventName", ProcessingResult.Event);
					Result.Insert("Parameter",   ProcessingResult.Data);
					Result.Insert("Source",   "Peripherals");
					Return Result;
				Else
					ErrorDescription = EventDescription1.Event;
					Return Undefined;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Processes event data received from the client.
// 
// Parameters:
//  EventDescription1 - Structure:
//   * Source - String - Source of the external event.
//   * Event - String - name of the event.
//   * Data - String - the data for the event.
//  ErrorDescription - String - error description
//
// Returns:
//  Boolean
//
Function ProcessEventFromDevice(EventDescription1, ErrorDescription = "") Export
	
	Result = True;
	// Event Handler Search
	Peripherals = Peripherals();
	For Each Connection In Peripherals.SoftwareConnectionParameters Do
		If Connection.DeviceID_ = EventDescription1.Source
		 Or (IsBlankString(Connection.DeviceID_) And Connection.EventNames.Count() > 0) Then
			If Not Connection.NonCertified Then
				// We are looking for a device with the received event among the connected equipment.
				Event = Connection.EventNames.Find(EventDescription1.Event);
				If Event <> Undefined Then
					DriverObject = Connection.DriverObject;
					// Processing the message
					ProcessingResult = Connection.DriverHandler.ProcessEvent(DriverObject, Connection, EventDescription1.Event, EventDescription1.Data);
					// Notify 
					If ProcessingResult.Result Then 
						Notify(ProcessingResult.Event, ProcessingResult.Data, "Peripherals");
					Else
						Result = False;
						ErrorDescription = EventDescription1.Event;
					EndIf;
				EndIf;
			Else
				ProcessEventFromNonCertifiedDriver(Connection, EventDescription1, ErrorDescription);
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Driver connection parameters.
// 
// Parameters:
//  DriverData - Structure - Driver data.
// 
// Returns:
//  Structure - Connection setting:
//   *Description - String
//   *EquipmentType - EnumRef.PeripheralTypes
//   *ConnectingFromTemplate - Boolean
//   *ConnectingLocallyById - Boolean 
//   *ObjectID - CatalogRef.Peripherals
//   *DriverVersion - String
//   *DriverTemplateName - String
//   *InterfaceRevision - String
//   *LineWidth_ - String
//   *PrintSlipOnTerminal - Boolean 
//   *ShortSlipChecks - Boolean
//   *CashWithdrawals - Boolean 
//   *PaymentByElectronicCertificates - Boolean
//   *ColumnsOnDisplay - Number
//   *LinesOnDisplay - Number 
//   *DisplayDisplaysText - Boolean
//   *DisplayDisplaysGraphics - Boolean
//   *DisplayDisplaysQRCode - Boolean  
//   *DisplayDisplaysHTML - Boolean
//   *DISPLAYShowsStatus - Boolean
//   *DeviceID - UUID
//   *DriverObject - Undefined -
//   *Parameters - Undefined -
//   *DriverHandler - Undefined -
//
Function DriverConnectionParameters(DriverData) Export
	
	Connection = EquipmentManagerClientServer.ConnectionParameters(DriverData);
	Connection.Insert("DriverObject"    , Undefined);
	Connection.Insert("Parameters"         , Undefined);   
	Connection.Insert("DriverHandler", GenericDriverClient);
	Return Connection;
	
EndFunction

// Device connection parameters.
// 
// Parameters:
//  DeviceData - Undefined, Arbitrary, Structure - Device data
// 
// Returns:
//  Structure - Connection setting:
//   * Description - String
//   * EquipmentType - EnumRef.PeripheralTypes
//   * ConnectingFromTemplate - Boolean
//   * ConnectingLocallyById - Boolean 
//   * ObjectID - CatalogRef.Peripherals
//   * DriverVersion - String
//   * DriverTemplateName - String
//   * InterfaceRevision - String
//   * LineWidth_ - String
//   * PrintSlipOnTerminal - Boolean 
//   * ShortSlipChecks - Boolean
//   * CashWithdrawals - Boolean
//   * PaymentByElectronicCertificates - Boolean 
//   * PartialCancellation - Boolean 
//   * ListOfCardTransactions - Boolean
//   * ConsumerPresentedQR - Boolean   
//   * PurchaseWithCreditCard - Boolean  
//   * ColumnsOnDisplay - Number
//   * LinesOnDisplay - Number 
//   * DisplayDisplaysText - Boolean
//   * DisplayDisplaysGraphics - Boolean
//   * DisplayDisplaysQRCode - Boolean
//   * DeviceID - UUID
//   * DriverObject - Undefined -
//   * Parameters - Undefined -
//   * DriverHandler - Undefined -
//   * Customers - Array of CatalogRef.Workplaces -
//   * Ref - CatalogRef.Peripherals
//   * NetworkEquipment - Boolean 
//   * NumberOfConnectedDevices - Number -
//   * EventNames - Array of String -
//   * DeviceID_ - String
//
Function DeviceConnectionParameters(DeviceData) Export
	
	Connection = DriverConnectionParameters(DeviceData);
	Connection.Insert("Customers", New Array());
	Connection.Insert("Ref"                  , DeviceData.Ref);
	Connection.Insert("Parameters"               , DeviceData.Parameters);
	Connection.Insert("XMLParameters"            , DeviceData.XMLParameters);    
	Connection.Insert("XMLApplicationParameters"  , DeviceData.XMLApplicationParameters);    
	Connection.Insert("NetworkEquipment"     , DeviceData.NetworkEquipment);
	Connection.Insert("NumberOfConnectedDevices"  , 0);
	Connection.Insert("EventNames"            , New Array());
	Connection.Insert("DeviceID_"            , "");
	Return Connection;
	
EndFunction

// Input device event new format.
// 
// Returns:
//  Boolean - Input device event new format
//
Function InputDevicesEventNewFormat() Export
	
	StandardProcessing = True;
	NewFormat = False;
	EquipmentManagerClientOverridable.InputDevicesEventNewFormat(NewFormat, StandardProcessing);
	Result = ?(Not StandardProcessing, NewFormat, False); 
	
	Return Result;
	
EndFunction

// Returns the need to print the slip receipt of the acquiring operation. 
// 
// Returns:
//  Boolean
//
Function PrintingSlipReceiptOfAcquiringOperation() Export
	
	PrintingSlipReceipt = True;      
	FullSlipReceipt  = True; 
	StandardProcessing = True;
	EquipmentManagerClientOverridable.PrintingSlipReceiptOfAcquiringOperation(PrintingSlipReceipt, FullSlipReceipt, StandardProcessing);
	
	Result = New Structure();
	Result.Insert("PrintingSlipReceipt", ?(StandardProcessing, True, PrintingSlipReceipt)); 
	Result.Insert("FullSlipReceipt" , ?(StandardProcessing, True, FullSlipReceipt));
	
	Return Result; 
	
EndFunction 

// Returns the need to display the QR code of the receipt on the buyer's display after fiscalization. 
// 
// Returns:
//  Boolean
//
Function DisplayingQRCodeOfReceiptOnBuyerSDisplayAfterFiscalization() Export
	
	Result = True;
	OutputOfReceiptQRCode = Result; 
	StandardProcessing = True;
	EquipmentManagerClientOverridable.DisplayingQRCodeOfReceiptOnBuyerSDisplayAfterFiscalization(OutputOfReceiptQRCode, StandardProcessing);
	Result = ?(StandardProcessing, Result, OutputOfReceiptQRCode);
	Return Result; 
	
EndFunction

// Returns global variables of the connected hardware
//
// Returns:
//  Structure:
//   * SoftwareConnectionParameters - Array of Structure
//   * HardwareDrivers - Map of KeyAndValue
//   * LastSlipCheck - String
//   * ShouldExitApp - Boolean
//   * QueueData - Undefined
//   * FiscalDevices - Array of Structure
//   * MarkingCodeChecks - Array of Structure
//   * Workplace - CatalogRef.Workplaces
//   * IsPeripherals - Boolean
//   * MACAddress - String
//   * TimeConsumingOperations - Map of KeyAndValue
//   * InterimResult - Map of KeyAndValue
//   * LoggingSystem - Structure
//   * SessionTimeOffset - Number
//
Function Peripherals() Export
	
	If ApplicationParameters = Undefined Then
		ApplicationParameters = New Map();
	EndIf;
	
	Peripherals = ApplicationParameters.Get("BPO.Peripherals");
	
	If Peripherals = Undefined Then
		Peripherals = New Structure();
		Peripherals.Insert("LibraryVersion", "");
		Peripherals.Insert("SoftwareConnectionParameters", New Array());
		Peripherals.Insert("HardwareDrivers", New Map());
		Peripherals.Insert("LastSlipCheck", "");
		Peripherals.Insert("ShouldExitApp", False);
		Peripherals.Insert("QueueData", Undefined);
		Peripherals.Insert("FiscalDevices", New Array()); 
		Peripherals.Insert("MarkingCodeChecks", New Array());
		Peripherals.Insert("WorkplaceParameters", EquipmentManagerClientServer.NewWorkplaceSettings());
		Peripherals.Insert("IsPeripherals", False);
		Peripherals.Insert("MACAddresses", New Array);
		Peripherals.Insert("TimeConsumingOperations", New Map());
		Peripherals.Insert("InterimResult", New Map());
		Peripherals.Insert("LoggingSystem", Undefined);
		Peripherals.Insert("SessionTimeOffset" , 0);      
		Peripherals.Insert("ConnectedComponents", New Map());
		Peripherals.Insert("LocalErrorHandling", New Array());                
		Peripherals.Insert("LibraryClassifiers", New Structure);
		Peripherals.Insert("StatusesOfCashShifts", New Map);
		Peripherals.Insert("ClientNotificationsAreAvailable", False);
		Peripherals.Insert("CheckingMaxSAgeAtServer", False);
		FillInErrorHandlingField(Peripherals.LocalErrorHandling);
		ApplicationParameters.Insert("BPO.Peripherals", Peripherals);
	EndIf;
	
	Return Peripherals;
	
EndFunction

// Get a description of the driver.
//
// Parameters:
//  XMLLine - String
//
// Returns:
//  See EquipmentManagerClientServer.DescriptionParametersDriver
//
Function GetDriverDescription(XMLLine) Export
	
	XMLParameters = CommonCELClient.ReadRootXMLElement(XMLLine);      
	
	Parameters = EquipmentManagerClientServer.DescriptionParametersDriver();
	Parameters.DriverName = ?(XMLParameters.Property("Name"), XMLParameters.Name, "");
	Parameters.DriverDescription     = ?(XMLParameters.Property("Description"), XMLParameters.Description, "");
	Parameters.EquipmentType      = ?(XMLParameters.Property("EquipmentType"), XMLParameters.EquipmentType, "");
	Parameters.DriverVersion       = ?(XMLParameters.Property("DriverVersion"), XMLParameters.DriverVersion, ""); 
	Parameters.VersionOfIntegrationComponent = ?(XMLParameters.Property("IntegrationComponentVersion"), XMLParameters.IntegrationComponentVersion, "");    
	Parameters.DriverDownloadURL   = ?(XMLParameters.Property("DownloadURL"), XMLParameters.DownloadURL, "");
	Parameters.DriverLogFilePath = ?(XMLParameters.Property("LogPath"), XMLParameters.LogPath, "");
	Parameters.IntegrationComponent   = XMLParameters.Property("IntegrationComponent") And Upper(XMLParameters.IntegrationComponent) = "TRUE"; 
	Parameters.MainDriverIsInstalled = XMLParameters.Property("MainDriverInstalled") And Upper(XMLParameters.MainDriverInstalled) = "TRUE"; 
	Parameters.DriverLogIsEnabled        = XMLParameters.Property("LogIsEnabled") And Upper(XMLParameters.LogIsEnabled) = "TRUE"; 
	Parameters.SupportedLocalization = XMLParameters.Property("LocalizationSupported") And Upper(XMLParameters.LocalizationSupported) = "TRUE"; 
	Parameters.ThisIsEmulator               = XMLParameters.Property("IsEmulator") And Upper(XMLParameters.IsEmulator) = "TRUE"; 
	Parameters.InformationAboutEnvironment     = ?(XMLParameters.Property("EnvironmentInformation"), XMLParameters.EnvironmentInformation, ""); 
	Parameters.AutoHardwareConfiguration = XMLParameters.Property("AutoSetup") And Upper(XMLParameters.AutoSetup) = "TRUE";
	
	Return Parameters;
	
EndFunction

// Generates an array of local error handling.
// 
// Parameters:
//  LocalErrorHandling - Array of Structure
//
Procedure FillInErrorHandlingField(LocalErrorHandling) Export
	
	MessageText = NStr("vi = 'Vui lòng kiểm tra dữ liệu trước khi tạo phương thức tính toán này.';
						|ru = 'Пожалуйста, проверьте данные для формирования данного способа расчета.';
						|en = 'Please check the data for generating this calculation method.'; fa = 'Please check the data for generating this calculation method.';
						|it = 'Please check the data for generating this calculation method.';
						|pl = 'Please check the data for generating this calculation method.';
						|tr = 'Bu hesaplama yöntemini oluşturmak için lütfen verileri kontrol edin.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Khi tính toán trong mạng lưới';
										|ru = 'При расчете в сети';
										|en = 'Upon online settlements'; fa = 'Upon online settlements';
										|it = 'Upon online settlements';
										|pl = 'Upon online settlements';
										|tr = 'Ağda hesaplanırken'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);
	
	MessageText = NStr("vi = 'Vui lòng kiểm tra xem có giấy trong thiết bị in hay không và thực hiện lại thao tác.';
						|ru = 'Пожалуйста, проверьте наличие бумаги в печатающем устройстве и повторно выполните операцию.';
						|en = 'Please check if there is paper in the printing device and try again.'; fa = 'Please check if there is paper in the printing device and try again.';
						|it = 'Пожалуйста, проверьте наличие бумаги в печатающем устройстве и повторно выполните операцию.';
						|pl = 'Please check if there is paper in the printing device and try again.';
						|tr = 'Yazdıran cihazda kağıt bulunup bulunmadığını kontrol edin ve işlemi tekrar gerçekleştirmeyi deneyin.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Không có giấy';
										|ru = 'Нет бумаги';
										|en = 'No paper'; fa = 'No paper';
										|it = 'Нет бумаги';
										|pl = 'No paper';
										|tr = 'Kağıt yok'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Mở nắp';
										|ru = 'Открыта крышка';
										|en = 'Lid is open'; fa = 'Lid is open';
										|it = 'Открыта крышка';
										|pl = 'Lid is open';
										|tr = 'Открыта крышка'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);           
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Lỗi máy cắt';
										|ru = 'Ошибка отрезчика';
										|en = 'Cutter error'; fa = 'Cutter error';
										|it = 'Ошибка отрезчика';
										|pl = 'Cutter error';
										|tr = 'Ошибка отрезчика'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);           
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Lỗi máy móc của thiết bị in';
										|ru = 'Механическая ошибка печатающего устройства';
										|en = 'Mechanical error of the printing device'; fa = 'Mechanical error of the printing device';
										|it = 'Механическая ошибка печатающего устройства';
										|pl = 'Mechanical error of the printing device';
										|tr = 'Yazdıran cihazın mekanizmasında hata'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);
	
	MessageText = NStr("vi = 'Đã hết nguồn lưu trữ dữ liệu tài chính. Chưa chuyển dữ liệu đến OFD trong 30 ngày qua.';
						|ru = 'Ресурс хранения ФД исчерпан. Данные не передавались в ОФД последние 30 дней.';
						|en = 'FD storage resource is exhausted. The data has not been transferred to FDO for the last 30 days.'; fa = 'FD storage resource is exhausted. The data has not been transferred to FDO for the last 30 days.';
						|it = 'FD storage resource is exhausted. The data has not been transferred to FDO for the last 30 days.';
						|pl = 'FD storage resource is exhausted. The data has not been transferred to FDO for the last 30 days.';
						|tr = 'FD depolama kaynağı tükendi. Son 30 gündür MVO''ya veri iletilmedi.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Đã hết nguồn lưu trữ dữ liệu tài chính';
										|ru = 'Ресурс хранения фд исчерпан';
										|en = 'FD storage resource is exhausted'; fa = 'FD storage resource is exhausted';
										|it = 'FD storage resource is exhausted';
										|pl = 'FD storage resource is exhausted';
										|tr = 'FB depolama kaynağı tükendi'")); 
	LocalError.Insert("MessageText", MessageText);     
	LocalErrorHandling.Add(LocalError);             

	MessageText = NStr("vi = 'Có thể đã hết hạn sử dụng bộ nhớ máy tính tiền.Vui lòng liên hệ với đơn vị cung cấp dịch vụ cho thiết bị MTT.';
						|ru = 'Возможно, истёк срок действия фискального накопителя. Пожалуйста, обратитесь в организацию обслуживающую ККТ.';
						|en = 'The fiscal storage might have expired. Please contact the cash register service provider.'; fa = 'The fiscal storage might have expired. Please contact the cash register service provider.';
						|it = 'The fiscal storage might have expired. Please contact the cash register service provider.';
						|pl = 'The fiscal storage might have expired. Please contact the cash register service provider.';
						|tr = 'Mali biriktiricinin süresi dolmuş olabilir. Lütfen yazar kasa ekipmanlarına hizmet veren iş yeriyle iletişime geçin.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Bộ nhớ máy tính tiền đã hết dung lượng';
										|ru = 'Исчерпал ресурс КС ФН';
										|en = 'The fiscal storage cryptoprocessor resource is exhausted'; fa = 'The fiscal storage cryptoprocessor resource is exhausted';
										|it = 'The fiscal storage cryptoprocessor resource is exhausted';
										|pl = 'The fiscal storage cryptoprocessor resource is exhausted';
										|tr = 'Mali depolama aygıtının kriptografik yardımcı işlemcisi kaynağı tükendi'")); 
	LocalError.Insert("MessageText", MessageText);     
	LocalErrorHandling.Add(LocalError);            
	
	MessageText = NStr("vi = 'Cần đóng phiên làm việc trên MTT để làm việc tiếp theo.';
						|ru = 'Необходимо закрыть смену на ККТ для дальнейшей работы.';
						|en = 'Close the cash register shift to continue operations.'; fa = 'Close the cash register shift to continue operations.';
						|it = 'Необходимо закрыть смену на ККТ для дальнейшей работы.';
						|pl = 'Close the cash register shift to continue operations.';
						|tr = 'Daha fazla işlem için Yazar Kasa Ekipmanları vardiyasının kapatılması gerekir.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Phiên làm việc vượt quá 24 giờ';
										|ru = 'Смена превысила 24 часа';
										|en = 'The shift exceeded 24 hours'; fa = 'The shift exceeded 24 hours';
										|it = 'Смена превысила 24 часа';
										|pl = 'The shift exceeded 24 hours';
										|tr = 'Vardiya, 24 saati aşmış'")); 
	LocalError.Insert("MessageText", MessageText);     
	LocalErrorHandling.Add(LocalError);             
	
	MessageText = NStr("vi = 'Cần mở phiên làm việc trên MTT để làm việc tiếp theo.';
						|ru = 'Необходимо открыть смену на ККТ для дальнейшей работы.';
						|en = 'It is necessary to open the shift at the cash register to continue working.'; fa = 'It is necessary to open the shift at the cash register to continue working.';
						|it = 'Необходимо открыть смену на ККТ для дальнейшей работы.';
						|pl = 'It is necessary to open the shift at the cash register to continue working.';
						|tr = 'Daha fazla işlem için Yazar Kasa Ekipmanları vardiyasının açılması gerekir.'");     
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Phiên thu ngân chưa mở hoặc đã hết hạn';
										|ru = 'Кассовая смена не открыта или истекла';
										|en = 'POS shift is not opened or expired'; fa = 'POS shift is not opened or expired';
										|it = 'Кассовая смена не открыта или истекла';
										|pl = 'POS shift is not opened or expired';
										|tr = 'Kasa vardiyası açık değil veya süresi dolmuş'")); 
	LocalError.Insert("MessageText", MessageText);     
	LocalErrorHandling.Add(LocalError);             

	MessageText = NStr("vi = 'Nhãn hiệu kiểm soát chưa được thử nghiệm trước đây.';
						|ru = 'Контрольная марка не была проверена ранее.';
						|en = 'The control mark was not checked previously.'; fa = 'The control mark was not checked previously.';
						|it = 'Контрольная марка не была проверена ранее.';
						|pl = 'The control mark was not checked previously.';
						|tr = 'Kontrol mührü daha önce doğrulanmamış.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Chưa xác minh nhãn hiệu kiểm soát';
										|ru = 'Контрольная марка не проверена';
										|en = 'The control mark not checked'; fa = 'The control mark not checked';
										|it = 'Контрольная марка не проверена';
										|pl = 'The control mark not checked';
										|tr = 'Kontrol mührü doğrulanmamış'")); 
	LocalError.Insert("MessageText", MessageText);     
	LocalErrorHandling.Add(LocalError);
	
	MessageText = NStr("vi = 'Đã mở từ trước phiên thu ngân trên MTT.';
						|ru = 'Кассовая смена на ККТ была открыта ранее.';
						|en = 'POS shift was opened at the cash register earlier.'; fa = 'POS shift was opened at the cash register earlier.';
						|it = 'Кассовая смена на ККТ была открыта ранее.';
						|pl = 'POS shift was opened at the cash register earlier.';
						|tr = 'Yazar Kasa Ekipmanları POS vardiyası daha önce açılmış.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Đã mở phiên làm việc';
										|ru = 'Смена открыта';
										|en = 'Shift is opened'; fa = 'شیفت باز است';
										|it = 'Смена открыта';
										|pl = 'Zmiana otwarta';
										|tr = 'Vardiya açıldı'")); 
	LocalError.Insert("MessageText", MessageText);        
	LocalErrorHandling.Add(LocalError);
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Đã mở phiên thu ngân.';
										|ru = 'Кассовая смена уже открыта';
										|en = 'POS shift is already opened'; fa = 'POS shift is already opened';
										|it = 'Кассовая смена уже открыта';
										|pl = 'POS shift is already opened';
										|tr = 'Kasa vardiyası açık'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);   
	
	MessageText = NStr("vi = 'Кассовая смена на ККТ была закрыта ранее.';
						|ru = 'Кассовая смена на ККТ была закрыта ранее.';
						|en = 'POS shift was closed at the cash register earlier.'; fa = 'POS shift was closed at the cash register earlier.';
						|it = 'Кассовая смена на ККТ была закрыта ранее.';
						|pl = 'POS shift was closed at the cash register earlier.';
						|tr = 'Кассовая смена на ККТ была закрыта ранее.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Đã đóng phiên';
										|ru = 'Смена закрыта';
										|en = 'The shift is closed'; fa = 'The shift is closed';
										|it = 'Смена закрыта';
										|pl = 'The shift is closed';
										|tr = 'Vardiya kapalı'")); 
	LocalError.Insert("MessageText", MessageText);       
	LocalErrorHandling.Add(LocalError);
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Đã đóng phiên thu ngân';
										|ru = 'Кассовая смена уже закрыта';
										|en = 'The POS shift is already closed'; fa = 'The POS shift is already closed';
										|it = 'Кассовая смена уже закрыта';
										|pl = 'The POS shift is already closed';
										|tr = 'Kasa vardiyası kapalı'")); 
	LocalError.Insert("MessageText", MessageText);        
	LocalErrorHandling.Add(LocalError);          
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = '73h';
										|ru = '73h';
										|en = '73h'; fa = '73h';
										|it = '73h';
										|pl = '73h';
										|tr = '73h'")); 
	LocalError.Insert("MessageText", MessageText);        
	LocalErrorHandling.Add(LocalError);          
	
	MessageText = NStr("vi = 'Đã vượt quá dung lượng tối đa của phiếu. Cần giảm dòng hàng hóa (mục tài chính) trong phiếu.';
						|ru = 'Превышен максимальный допустимый размер чека. Необходимо уменьшить количество фискальных позиций в чеке..';
						|en = 'Exceeded the maximum allowed receipt size. Reduce the number of fiscal items in the receipt.'; fa = 'Exceeded the maximum allowed receipt size. Reduce the number of fiscal items in the receipt.';
						|it = 'Exceeded the maximum allowed receipt size. Reduce the number of fiscal items in the receipt.';
						|pl = 'Exceeded the maximum allowed receipt size. Reduce the number of fiscal items in the receipt.';
						|tr = 'İzin verilen maksimum çek boyutu aşıldı. Çekin içerisindeki mali kalemlerin sayısının azaltılması gerekmektedir.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Dung lượng phiếu';
										|ru = 'Размер чека';
										|en = 'Receipt size'; fa = 'Receipt size';
										|it = 'Receipt size';
										|pl = 'Receipt size';
										|tr = 'Çek ebatları'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);  
	
	MessageText = NStr("vi = 'Vui lòng kiểm tra kết nối thiết bị và thực hiện lại thao tác.';
						|ru = 'Пожалуйста, проверьте подключение оборудования и повторно выполните операцию.';
						|en = 'Please check the equipment connection and try again.'; fa = 'Please check the equipment connection and try again.';
						|it = 'Пожалуйста, проверьте подключение оборудования и повторно выполните операцию.';
						|pl = 'Please check the equipment connection and try again.';
						|tr = 'Bağlı donanımı lütfen kontrol edin ve işlemi yeniden gerçekleştirin.'");
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Không có liên kết';
										|ru = 'Нет связи';
										|en = 'No connection'; fa = 'No connection';
										|it = 'Нет связи';
										|pl = 'No connection';
										|tr = 'Bağlantı yok'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);   
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'FFFFFFFFh, Không có liên kết';
										|ru = 'FFFFFFFFh, Нет связи';
										|en = 'FFFFFFFFh, No connection'; fa = 'FFFFFFFFh, No connection';
										|it = 'FFFFFFFFh, Нет связи';
										|pl = 'FFFFFFFFh, No connection';
										|tr = 'FFFFFFFFh, Bağlantı yok'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);   
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Cổng không khả dụng';
										|ru = 'Порт недоступен';
										|en = 'The port is not available'; fa = 'The port is not available';
										|it = 'Порт недоступен';
										|pl = 'The port is not available';
										|tr = 'Port mevcut değil'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);   
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'FFFFFFF8h, Connect timed out';
										|ru = 'FFFFFFF8h, Connect timed out';
										|en = 'FFFFFFF8h, Connect timed out'; fa = 'FFFFFFF8h, Connect timed out';
										|it = 'FFFFFFF8h, Connect timed out';
										|pl = 'FFFFFFF8h, Connect timed out';
										|tr = 'FFFFFFF8h, Connect timed out'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);   
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'FFFFFFFEh, cổng СOM không khả dụng';
										|ru = 'FFFFFFFEh, СOM порт недоступен';
										|en = 'FFFFFFFEh, COM port is not available'; fa = 'FFFFFFFEh, COM port is not available';
										|it = 'FFFFFFFEh, СOM порт недоступен';
										|pl = 'FFFFFFFEh, COM port is not available';
										|tr = 'FFFFFFFEh, COM bağlantı noktası kullanılabilir değil'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);   
	
	LocalError = New Structure();     
	LocalError.Insert("ErrorText", NStr("vi = 'Không có liên kết với thiết bị';
										|ru = 'Нет связи с устройством';
										|en = 'No connection to the device'; fa = 'No connection to the device';
										|it = 'Нет связи с устройством';
										|pl = 'No connection to the device';
										|tr = 'Cihaza bağlanılmadı'")); 
	LocalError.Insert("MessageText", MessageText);      
	LocalErrorHandling.Add(LocalError);   
	
	MessageText = NStr("vi = 'Hãy cập nhật bộ cài đặt chính của driver và cập nhật phần mềm máy tính tiền. Nếu sự cố vẫn tiếp diễn, hãy liên hệ với bộ phận hỗ trợ kỹ thuật của nhà phát triển driver.';
						|ru = 'Обновите основную поставку драйвера, выполните обновление прошивки ККТ. Если проблема повторяется, требуется обращение в техническую поддержку разработчика драйвера.';
						|en = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.'; fa = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.';
						|it = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.';
						|pl = 'Update the main distribution package of the driver and the cash register firmware. If the issue persists, contact the technical support of the driver developer.';
						|tr = 'Sürücünün ana sürümünü güncelleyin, yazar kasa yazılımını güncelleyin. Sorun devam ederse, sürücü geliştiricisinin teknik destek ekibiyle iletişime geçilmesi gerekir.'");
	
	LocalError = New Structure();
	LocalError.Insert("ErrorText", NStr("vi = 'tax';
										|ru = 'tax';
										|en = 'tax'; fa = 'tax';
										|it = 'tax';
										|pl = 'tax';
										|tr = 'tax'"));
	LocalError.Insert("MessageText", MessageText);
	LocalErrorHandling.Add(LocalError);
	
EndProcedure

#EndRegion

#Region Workplace         

// Performs the update the computer name in the option session of "CustomerWorkplace".
//
// Returns:
//  Boolean
//
Function UpdateClientWorkplace() Export
	
	Result = True;
	
	Workplace = CustomerWorkplace();
	If Not ValueIsFilled(Workplace) Then
		
		Peripherals = Peripherals();
		MACAddresses = Peripherals.MACAddresses;
		IsPeripherals = Peripherals.IsPeripherals;
		If CommonCELClient.IsWebClient() And IsPeripherals Then  
			If MACAddresses.Count() = 0 Then
				Notification = New CallbackDescription("BeginGettingMACAddressesCompletion", ThisObject);
				InstallBrowserExtension = True;
				BeginGettingMACAddresses(Notification, InstallBrowserExtension);
			Else
				BeginGettingMACAddressesCompletion(MACAddresses, Undefined);
			EndIf;
		Else
			WorkplaceAttributes = CurrentWorkplaceAttributes();
			Workplace = EquipmentManagerServerCall.CreateCustomerWorkplace(WorkplaceAttributes);
			EstablishWorkplace(Workplace);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// The procedure for choice of jobs in the current session.
//
// Parameters:
//  CommandParameter - Arbitrary - the source where the command is implemented
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure SelectWorkplaceOfCurrentSession(CommandParameter, CommandExecuteParameters) Export
	
	Notification = New CallbackDescription("SuggestChoiceOfWorkplaceCompletion", ThisObject);
	SuggestChoiceOfWorkplace(Notification);
	
EndProcedure

// This function provides a dialog for selecting a workplace.
// 
// Parameters:
//  NotificationProcessing - CallbackDescription - notification description event.
//  ClientID - String - client ID
//
Procedure SuggestChoiceOfWorkplace(NotificationProcessing, ClientID = "") Export

	SetConnectionModeOfComputerInformationExtension(True);
	UpdateClientWorkplace();
	FormParameters = New Structure();
	FormParameters.Insert("ClientID", ClientID);
	
	OpenForm("Catalog.Peripherals.Form.SelectionFormOfWorkplace", FormParameters,,,  ,, NotificationProcessing, FormWindowOpeningMode.LockWholeInterface);

EndProcedure

// Completing the workplace selection.
// 
// Parameters:
//  Result - Structure - the result of the operation.
//  Parameters - Structure - The operation parameters.
//
Procedure SuggestChoiceOfWorkplaceCompletion(Result, Parameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.Property("Workplace") Then 
		EstablishWorkplace(Result.Workplace);
	EndIf;
		
EndProcedure

// The function sets the workplace.
// 
// Parameters:
//  Workplace - CatalogRef.Workplaces - the client's workplace.
//
Procedure EstablishWorkplace(Workplace) Export
	
	EquipmentManagerServerCall.SetClientSWorkplace(Workplace);
	Peripherals = Peripherals();
	Peripherals.WorkplaceParameters.Workplace = Workplace;
	Notify("ChangedCurSessionWorkplace", Workplace);
	
EndProcedure

// Returns the Cur workplace on the client.
//
// Parameters:
//  RequestOnServer - Boolean - if True, then in the case when the workplace is missing on the client, 
//                         a request to the server will be executed.
//
// Returns:
//  CatalogRef.Workplaces
//
Function CustomerWorkplace(RequestOnServer = True) Export
	
	Peripherals = Peripherals();
	Workplace = Peripherals.WorkplaceParameters.Workplace;
	If RequestOnServer And Not ValueIsFilled(Workplace) Then
		InformationAboutWorkplace = EquipmentManagerServerCall.InformationAboutClientSWorkplace();
		Workplace = InformationAboutWorkplace.Workplace;
		Peripherals.WorkplaceParameters.Workplace = Workplace;
		Peripherals.IsPeripherals = InformationAboutWorkplace.IsPeripherals;
	EndIf;
	
	Return Workplace;
	
EndFunction

// Returns an array containing workplaces according to the found parameters.
//
// Parameters:
//  ClientID - String - Client ID for the workplace       
//  ComputerName - String - computer name   
//  MACAddress - String - 
//
// Returns:
//  Array
Function FindWorkplacesById(ClientID, ComputerName, MACAddress = "") Export
	
	Return EquipmentManagerClientCached.FindWorkplacesById(ClientID, ComputerName, MACAddress);
	
EndFunction

// Opening the list of jobs form.
// 
// Parameters:
//  CommandParameter - Structure - command parameters.
//  CommandExecuteParameters - Structure:
//   *Source - ClientApplicationForm - the parent form.
//   *Uniqueness - UUID - unique form ID.
//   *Window - ClientApplicationWindow - application window.
//
Procedure OpenJobs(CommandParameter, CommandExecuteParameters) Export
	
	FormParameters = New Structure();
	OpenForm("Catalog.Workplaces.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

// The client ID for the workplace.
// 
// Returns:
//  String - Client ID for the workplace
Function ClientIDForWorkplace() Export
	
	Return EquipmentManagerClientServer.ClientIDForWorkplace();
	
EndFunction

#EndRegion

#Region CommonDriverMethods

#Region TypesOfEquipment

// Returns the structure of possible types of equipment
// 
// Returns:
//  Structure
Function ParametersTypesOfEquipment() Export
	
	TypesOfEquipment = EquipmentManagerClientCached.ParametersTypesOfEquipment();
	Return CommonCELClient.CopyRecursive(TypesOfEquipment);
	
EndFunction

// Returns hardware types as an array of enumerations
// 
// Parameters:
//   SoftwareTypes - Array of String, String, Structure - type of equipment.
// 
// Returns:
//   Array of DefinedType.PeripheralTypes
//           
Function ArrayOfEquipmentTypes(SoftwareTypes) Export
	
	TypesArray = New Array();
	CompatibilityOfEquipmentTypes = CompatibilityOfEquipmentTypes();
	If TypeOf(SoftwareTypes) = Type("String") Then
		
		TypesInArray = StrSplit(SoftwareTypes, ",", False);
		For Each EquipmentType In TypesInArray Do
			TypesArray.Add(CompatibilityOfEquipmentTypes.Get(TrimAll(EquipmentType)));
		EndDo;
		
	ElsIf TypeOf(SoftwareTypes) = Type("Array") Then
		
		AvailableTypesOfEquipment = AvailableTypesOfEquipment();
		For Each EquipmentType In SoftwareTypes Do   
			
			If TypeOf(EquipmentType) = Type("String") Then 
				TypesArray.Add(CompatibilityOfEquipmentTypes.Get(TrimAll(EquipmentType)));
			ElsIf AvailableTypesOfEquipment.Find(EquipmentType) <> Undefined Then
				TypesArray.Add(EquipmentType);
			EndIf;
			
		EndDo;
		
	ElsIf TypeOf(SoftwareTypes) = Type("Structure") Then
		
		For Each KeyAndValue In SoftwareTypes Do
			
			If KeyAndValue.Value Then
				TypesArray.Add(CompatibilityOfEquipmentTypes.Get(KeyAndValue.Key));
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return TypesArray; 
	
EndFunction

// The function returns a structure with driver data.
//
// Parameters:
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//
// Returns:
//  Structure:
//   * Description - String
Function HardwareDriverData(DriverID) Export
	
	Return EquipmentManagerClientCached.HardwareDriverData(DriverID);
	
EndFunction

// Search by the ID of a previously connected device. 
//
// Parameters:
//  DeviceID - CatalogRef.Peripherals - an instance of the connected hardware.
//
// Returns:
//  CatalogRef.Peripherals
//
Function GetConnectedDevice(DeviceID) Export
	
	Peripherals = Peripherals();
	ConnectionsList = Peripherals.SoftwareConnectionParameters;
	
	ConnectedDevice = Undefined;  
	
	If ConnectionsList <> Undefined Then
		For Each Connection In ConnectionsList Do
			If Connection.Ref = DeviceID Then
				ConnectedDevice = Connection;
				Break;
			EndIf;
		EndDo;  
	EndIf; 
	
	Return ConnectedDevice;
	
EndFunction

// Returns a match containing the types of equipment,
// the key is a string in Russian and English, and the value is a link to the enumeration
//
// Returns:
//  Map of KeyAndValue
Function CompatibilityOfEquipmentTypes() Export
	
	ParameterName = "BPO.CompatibilityOfEquipmentTypes";
	Return CommonCELClient.ParameterOfApplication(ParameterName);
	
EndFunction

// Returns a match containing the types of equipment,
// the key is a string in Russian and English, and the value is a link to the enumeration
//
// Returns:
//  Map
Function AvailableTypesOfEquipment() Export
	
	ParameterName = "BPO.AvailableTypesOfEquipment";
	Return CommonCELClient.ParameterOfApplication(ParameterName);
	
EndFunction

#EndRegion

// Search by type of previously connected devices.
//
// Parameters:
//  PeripheralTypes - Structure, Array of String, String - type of equipment.
//
// Returns:
//  Array of CatalogRef.Peripherals
//
Function GetConnectedDevices(PeripheralTypes) Export
	
	ConnectedDevices = New Array();
	
	Peripherals = Peripherals();
	ConnectionsList = Peripherals.SoftwareConnectionParameters;
	
	If ConnectionsList = Undefined Then
		Return ConnectedDevices;
	EndIf;
		
	If TypeOf(PeripheralTypes) = Type("Structure") Then  
		For Each Connection In ConnectionsList Do
			For Each KeyAndValue In PeripheralTypes Do   
				// We find a device of one suitable type.
				If KeyAndValue.Value Then     
					KeyValue = False;
					If Connection.TypesOfEquipment.Property(KeyAndValue.Key, KeyValue) And KeyValue Then
						ConnectedDevices.Add(Connection);
						Break;
					EndIf;
				EndIf;
			EndDo; 
		EndDo;
	Else
		TypesOfEquipment = ArrayOfEquipmentTypes(PeripheralTypes);
		For Each Connection In ConnectionsList Do
			If TypesOfEquipment.Find(Connection.EquipmentType) <> Undefined Then 
				ConnectedDevices.Add(Connection);
			EndIf; 
		EndDo;    
	EndIf;
	
	Return ConnectedDevices;
	
EndFunction

// Search by type of previously connected devices.
//
// Parameters:
//  ObjectID - CatalogRef.Peripherals - an instance of the connected hardware.
//
// Returns:
//  Array
//
Function ConnectedDevicesByObjectId(ObjectID) Export
	
	Peripherals = Peripherals();
	ConnectionsList = Peripherals.SoftwareConnectionParameters;
	
	ConnectedDevices = New Array();
	For Each Connection In ConnectionsList Do
		If Connection.ObjectID = ObjectID Then
			ConnectedDevices.Add(Connection);
		EndIf;
	EndDo;
	
	Return ConnectedDevices;
	
EndFunction

// Gets a description of the driver.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//  DriverData - See EquipmentManagerServerCall.HardwareDriverData
//
Procedure StartGettingDescriptionOfDriver(NotificationOnCompletion, DriverID = Undefined, DriverData = Undefined) Export
	
	If DriverID <> Undefined Then
		DriverData = EquipmentManagerServerCall.HardwareDriverData(DriverID);
	EndIf;
	
	New_Connection = DriverConnectionParameters(DriverData);
	
	DriverHandler = New_Connection.DriverHandler;
	DriverHandler.StartGettingDescriptionOfDriver(NotificationOnCompletion, New_Connection); 
	
EndProcedure

// Gets a description of the driver.
//
// Parameters:
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//  DriverData - See EquipmentManagerServerCall.HardwareDriverData
//
// Returns:
//   Structure - hardware driver description
//
Async Function GettingDriverDescriptionAsync(DriverID = Undefined, DriverData = Undefined) Export

	If DriverID <> Undefined Then
		DriverData = EquipmentManagerServerCall.HardwareDriverData(DriverID);
	EndIf;
	
	New_Connection = DriverConnectionParameters(DriverData);
	
	DriverHandler = New_Connection.DriverHandler;
	Result = Await DriverHandler.DriverDescriptionAsync(New_Connection);
	
	Return Result;
	
EndFunction

// Gets a description of the equipment.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  HardwareId - CatalogRef.Peripherals - ID of the driver.
//  EquipmentData - See EquipmentManagerServerCall.DeviceData  
//
Procedure StartGettingDescriptionOfEquipment(NotificationOnCompletion, HardwareId = Undefined, EquipmentData = Undefined) Export
	
	If HardwareId <> Undefined Then
		EquipmentData = EquipmentManagerServerCall.DeviceData(HardwareId);
	EndIf;
	
	If Not ValueIsFilled(EquipmentData) Then
		ErrorDescription = NStr("vi = 'Không thể nhận mô tả thiết bị, có thể là thiết bị đã được đánh dấu là không sử dụng.';
								|ru = 'Не удалось получить описание оборудования, возможно устройство отмечено не используемым.';
								|en = 'Cannot get the peripheral details. The device might be marked as unused.'; fa = 'Cannot get the peripheral details. The device might be marked as unused.';
								|it = 'Не удалось получить описание оборудования, возможно устройство отмечено не используемым.';
								|pl = 'Cannot get the peripheral details. The device might be marked as unused.';
								|tr = 'Donanım ayrıntıları alınamadı, cihaz kullanımda değil olarak işaretlenmiş olabilir.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription, HardwareId);
		If NotificationOnCompletion <> Undefined Then
			RunCallback(NotificationOnCompletion, ExecutionResult);
		EndIf;
		Return;
	EndIf;
	
	New_Connection = DeviceConnectionParameters(EquipmentData);
	If Not IsBlankString(EquipmentData.ObjectID) Then
		ConnectionsList = ConnectedDevicesByObjectId(EquipmentData.ObjectID);
		New_Connection.NumberOfConnectedDevices = ConnectionsList.Count();
	EndIf;
	
	DriverHandler = New_Connection.DriverHandler;     
	DriverHandler.StartGettingDescriptionOfDriver(NotificationOnCompletion, New_Connection);
	
EndProcedure

// Start executing an additional command to the driver that does not require the device to be connected to the system first.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  DeviceID - CatalogRef.Peripherals - ID of the driver.
//  DeviceParameters - Structure - Device settings.
//
Procedure StartDeviceTest(NotificationOnCompletion, DeviceID, DeviceParameters = Undefined) Export
	
	// Search for the connected device.
	ConnectedDevice = GetConnectedDevice(DeviceID);
	If ConnectedDevice = Undefined Then
		EquipmentData = EquipmentManagerServerCall.DeviceData(DeviceID, Undefined, DeviceParameters);
		
		New_Connection = DeviceConnectionParameters(EquipmentData);
		DriverHandler = New_Connection.DriverHandler;    
		DriverHandler.StartDeviceTest(NotificationOnCompletion, New_Connection, Undefined);
	Else
		// Report an error that the device is connected.
		ErrorDescription = NStr("vi = 'Thiết bị đã được kết nối, không thể thực hiện giao dịch. Để vô hiệu hóa thiết bị, cần đóng tất cả biểu mẫu ứng dụng dành cho cơ sở thông tin này.';
								|ru = 'Устройство подключено, операция не может быть выполнена. Для отключения устройства требуется закрыть все формы приложения для текущей информационной базы.';
								|en = 'Device is connected, the operation cannot be performed. To disable the device, close all application forms for the current infobase.'; fa = 'Device is connected, the operation cannot be performed. To disable the device, close all application forms for the current infobase.';
								|it = 'Dispositivo connesso, l''operazione non può essere eseguita. Per disattivare il dispositivo è richiesta la chiusura di tutti i moduli dell''applicazione per l''infobase corrente.';
								|pl = 'Urządzenie jest połączone, operacja nie może być wykonana. W celu wyłączenia urządzenia należy zamknąć wszystkie formularze aplikacji dla bieżącej bazy informacyjnej.';
								|tr = 'Cihaz bağlı, işlem gerçekleştirilemiyor. Bir cihazı devre dışı bırakmak için mevcut infobase''in tüm başvuru formlarını kapat.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
		RunCallback(NotificationOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure    

// Start executing an additional command to the driver that does not require the device to be connected to the system first.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  DeviceID - CatalogRef.Peripherals - ID of the driver.
//  DeviceParameters - Structure - Device settings.
//
Procedure StartAutoTuningDevice(NotificationOnCompletion, DeviceID, DeviceParameters = Undefined) Export
	
	// Search for the connected device.
	ConnectedDevice = GetConnectedDevice(DeviceID);
	If ConnectedDevice = Undefined Then
		EquipmentData = EquipmentManagerServerCall.DeviceData(DeviceID, Undefined, DeviceParameters);
		
		New_Connection = EquipmentManagerClient.DeviceConnectionParameters(EquipmentData);
		DriverHandler = New_Connection.DriverHandler;    
		DriverHandler.StartAutoTuningDevice(NotificationOnCompletion, New_Connection, Undefined);
	Else
		// Report an error that the device is connected.
		ErrorDescription = NStr("vi = 'Đã kết nối thiết bị, không thể thực hiện giao dịch. Để vô hiệu hóa thiết bị, cần đóng tất cả biểu mẫu ứng dụng dành cho cơ sở thông tin này.';
								|ru = 'Устройство подключено, операция не может быть выполнена. Для отключения устройства требуется закрыть все формы приложения для текущей информационной базы.';
								|en = 'Device is connected, the operation cannot be performed. To disable the device, close all application forms for the current infobase.'; fa = 'Device is connected, the operation cannot be performed. To disable the device, close all application forms for the current infobase.';
								|it = 'Устройство подключено, операция не может быть выполнена. Для отключения устройства требуется закрыть все формы приложения для текущей информационной базы.';
								|pl = 'Urządzenie jest połączone, operacja nie może być wykonana. W celu wyłączenia urządzenia należy zamknąć wszystkie formularze aplikacji dla bieżącej bazy informacyjnej.';
								|tr = 'Cihaz bağlı, işlem gerçekleştirilemiyor. Bir cihazı devre dışı bırakmak için mevcut infobase''in tüm başvuru formlarını kapat.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
		RunCallback(NotificationOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure    

// Start executing an additional command to the driver that does not require the device to be connected to the system first.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  DeviceID - CatalogRef.Peripherals - ID of the driver.
//  DeviceParameters - Structure - Device settings.
//  ExecutionParameters - Structure - the parameters of the command.
// 
Procedure Start_ExecutingAdditionalCommand(NotificationOnCompletion, DeviceID, DeviceParameters = Undefined, ExecutionParameters = Undefined) Export
	
	// Search for the connected device.
	ConnectedDevice = GetConnectedDevice(DeviceID);
	If ConnectedDevice = Undefined Then
		EquipmentData = EquipmentManagerServerCall.DeviceData(DeviceID);
		New_Connection = DeviceConnectionParameters(EquipmentData);
		New_Connection.Parameters = ?(DeviceParameters = Undefined, EquipmentData.Parameters, DeviceParameters);
		
		DriverHandler = New_Connection.DriverHandler;   
		DriverHandler.StartPerformAdditionalAction(NotificationOnCompletion, New_Connection, ExecutionParameters)
	Else
		// Report an error that the device is connected.
		ErrorDescription = NStr("vi = 'Thiết bị đã được kết nối, không thể thực hiện giao dịch. Để vô hiệu hóa thiết bị, cần đóng tất cả biểu mẫu ứng dụng dành cho cơ sở thông tin này.';
								|ru = 'Устройство подключено, операция не может быть выполнена. Для отключения устройства требуется закрыть все формы приложения для текущей информационной базы.';
								|en = 'Device is connected, the operation cannot be performed. To disable the device, close all application forms for the current infobase.'; fa = 'Device is connected, the operation cannot be performed. To disable the device, close all application forms for the current infobase.';
								|it = 'Dispositivo collegato, l''operazione non può essere eseguita. Per disattivare il dispositivo è richiesta la chiusura di tutti i moduli dell''applicazione per l''infobase corrente.';
								|pl = 'Urządzenie jest połączone, operacja nie może być wykonana. W celu wyłączenia urządzenia należy zamknąć wszystkie formularze aplikacji dla bieżącej bazy informacyjnej.';
								|tr = 'Cihaz bağlı, işlem gerçekleştirilemiyor. Bir cihazı devre dışı bırakmak için mevcut infobase''in tüm başvuru formlarını kapat.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
		RunCallback(NotificationOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure

// Install the hardware connection component.
//
// Parameters:
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//
// Returns:
//  See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware.
// 
Async Function InstallHardwareDriverAsync(DriverID) Export
	
	DriverData = HardwareDriverData(DriverID);
	If Not ValueIsFilled(DriverData) Then
		ErrorDescription = NStr("vi = 'Không tìm thấy driver.';
								|ru = 'Драйвер не найден.';
								|en = 'Driver is not found.'; fa = 'Driver is not found.';
								|it = 'Driver non trovato.';
								|pl = 'Nie znaleziono sterownika.';
								|tr = 'Sürücü bulunmadı.'");
		Raise ErrorDescription;
	EndIf;
	                 
	MessageText = StrTemplate(NStr("vi = 'Để tiếp tục làm việc, cần cài đặt cấu phần ngoài ""%1""';
									|ru = 'Для продолжения работы требуется установка внешней компоненты ""%1""';
									|en = 'To continue, install the ""%1"" add-in.'; fa = 'To continue, install the ""%1"" add-in.';
									|it = 'Для продолжения работы требуется установка внешней компоненты ""%1""';
									|pl = 'To continue, install the ""%1"" add-in.';
									|tr = 'Devam etmek için ""%1"" dış bileşeninin yüklenmesi gerekiyor'"), DriverData.Description); 
	If DriverData.ConnectingFromTemplate Or CommonCELClientServer.IsMobileClient() Then
		If Not DriverData.TemplateIsAvailable Then
			ErrorDescription = StrTemplate(NStr("vi = 'Không tìm thấy khuôn in driver ""%1"".';
												|ru = 'Макет драйвера ""%1"" не найден.';
												|en = 'The ""%1"" driver template is not found.'; fa = 'The ""%1"" driver template is not found.';
												|it = 'Макет драйвера ""%1"" не найден.';
												|pl = 'The ""%1"" driver template is not found.';
												|tr = 'Sürücü şablonu ""%1"" bulunamadı.'"), DriverData.DriverTemplateName); 
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
			ExecutionResult.ObjectID    = DriverData.ObjectID;
			ExecutionResult.DeviceID = DriverData.Ref;
			Return ExecutionResult;
		Else
			If YouCanInstallComponents(DriverData.DriverTemplateName) Then
				InstallationParameters = AddInsCELClient.InstallationParameters();
				InstallationParameters.ExplanationText = MessageText;
				Result = Await AddInsCELClient.InstallAddInFromTemplateAsync(DriverData.DriverTemplateName, InstallationParameters); // Structure
			Else
				ErrorDescription = StrTemplate(NStr("vi = 'Không hỗ trợ làm việc đối với cấu phần %1 trong web-client.';
													|ru = 'Для компоненты %1 не предусмотрена работа в web-клиенте.';
													|en = 'For the %1 add-in, web client is not available.'; fa = 'For the %1 add-in, web client is not available.';
													|it = 'Для компоненты %1 не предусмотрена работа в web-клиенте.';
													|pl = 'For the %1 add-in, web client is not available.';
													|tr = '%1 add-in bir web istemcisinde çalışması öngörülmemiştir.'"), DriverData.Description);
				ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
				Return ExecutionResult;
			EndIf;
		EndIf;
	Else
		InstallationParameters = AddInsCELClient.InstallationParameters();
		InstallationParameters.SuggestToImport  = Not DriverData.NoLongerSupported;
		InstallationParameters.SuggestInstall = True;
		InstallationParameters.ExplanationText = MessageText; 
		Result = Await AddInsCELClient.InstallAddInSSLAsync(DriverData.ObjectID, Undefined, InstallationParameters);  // Structure
	EndIf;

	ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(Result.IsSet, Result.ErrorDescription);
	ExecutionResult.ObjectID    = DriverData.ObjectID;
	ExecutionResult.DeviceID = DriverData.Ref;
	Return ExecutionResult;
	
EndFunction

// Install the hardware connection component.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//
Procedure InstallHardwareDriver(NotificationOnCompletion, DriverID) Export
		
	// Performance Measurement
	KeyOperation = "CommonModule.EquipmentManagerClient.InstallHardwareDriver";
	CommonCELClient.BPOTimeMeasurement(KeyOperation, NotificationOnCompletion);
	
	
	DriverData = HardwareDriverData(DriverID);
	If Not ValueIsFilled(DriverData) Then
		ErrorDescription = NStr("vi = 'Không tìm thấy driver.';
								|ru = 'Драйвер не найден.';
								|en = 'Driver is not found.'; fa = 'Driver is not found.';
								|it = 'Driver non trovato.';
								|pl = 'Nie znaleziono sterownika.';
								|tr = 'Sürücü bulunmadı.'");
		Raise ErrorDescription;
	EndIf;
	
	Context = New Structure();
	Context.Insert("NotificationOnCompletion", NotificationOnCompletion);
	Context.Insert("DriverData", DriverData);
	Notification = New CallbackDescription("InstallHardwareDriverCompletion", ThisObject, Context);
	
	MessageText = StrTemplate(
		NStr("vi = 'Để tiếp tục làm việc, cần cài đặt cấu phần ngoài ""%1"".';
			|ru = 'Для продолжения работы требуется установка внешней компоненты ""%1"".';
			|en = 'To continue, set the ""%1"" add-in.'; fa = 'To continue, set the ""%1"" add-in.';
			|it = 'Per continuare il lavoro è richiesta l''installazione della componente esterna ""%1"".';
			|pl = 'Aby kontynuować pracę wymagana jest instalacja komponentu zewnętrznego ""%1"".';
			|tr = 'Devam etmek için ""%1"" dış bileşeninin yüklenmesi gerekiyor.'"),
		DriverData.Description);
	
	If DriverData.ConnectingFromTemplate Or CommonCELClientServer.IsMobileClient() Then
		If Not DriverData.TemplateIsAvailable Then
			ErrorDescription = StrTemplate(NStr("vi = 'Không tìm thấy khuôn in driver ""%1"".';
												|ru = 'Макет драйвера ""%1"" не найден.';
												|en = 'The ""%1"" driver template is not found.'; fa = 'The ""%1"" driver template is not found.';
												|it = 'Макет драйвера ""%1"" не найден.';
												|pl = 'The ""%1"" driver template is not found.';
												|tr = 'Sürücü şablonu ""%1"" bulunamadı.'"), DriverData.DriverTemplateName); 
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
			RunCallback(NotificationOnCompletion, ExecutionResult);
		Else
			If YouCanInstallComponents(DriverData.DriverTemplateName) Then
				InstallationParameters = AddInsCELClient.InstallationParameters();
				InstallationParameters.ExplanationText = MessageText;
				AddInsCELClient.InstallAddInFromTemplate(Notification, DriverData.DriverTemplateName, InstallationParameters);
			Else
				ErrorDescription = StrTemplate(NStr("vi = 'Không hỗ trợ làm việc đối với cấu phần %1 trong web-client.';
													|ru = 'Для компоненты %1 не предусмотрена работа в web-клиенте.';
													|en = 'For the %1 add-in, web client is not available.'; fa = 'For the %1 add-in, web client is not available.';
													|it = 'Для компоненты %1 не предусмотрена работа в web-клиенте.';
													|pl = 'For the %1 add-in, web client is not available.';
													|tr = '%1 add-in bir web istemcisinde çalışması öngörülmemiştir.'"), DriverData.Description);
				ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
				RunCallback(NotificationOnCompletion, ExecutionResult);
			EndIf;
		EndIf;
	Else
		InstallationParameters = AddInsCELClient.InstallationParameters();
		InstallationParameters.ExplanationText       = MessageText; 
		InstallationParameters.SuggestToImport  = Not DriverData.NoLongerSupported;;
		InstallationParameters.SuggestInstall = True;
		AddInsCELClient.InstallAddInSSL(Notification, DriverData.ObjectID, Undefined, InstallationParameters);
	EndIf;
	
EndProcedure

// End of hardware driver installation
// 
// Parameters:
//  Result - Structure
//  Context - Structure
//
Procedure InstallHardwareDriverCompletion(Result, Context) Export
	
	If Context.NotificationOnCompletion <> Undefined Then
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(Result.IsSet, Result.ErrorDescription);
		ExecutionResult.ObjectID    = Context.DriverData.ObjectID;
		ExecutionResult.DeviceID = Context.DriverData.Ref;
		RunCallback(Context.NotificationOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectDevice

// Procedure for selecting a device from the available ones linked to the current workplace.
//
// Parameters:
//  Filter - Structure, Array of String, String - the type of equipment to select the device.
//          See EquipmentManagerClientServer.ListOfEquipmentSelection
//  SelectionHeaderText - String - The title of the selection window.
//  MessageIsNotConnected - String - The text of the message about not connected devices
//  MessageWasNotSelected - String - The text of the message about not selected devices
//
// Returns:
//  See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//
Async Function SelectDeviceAsync(Filter, SelectionHeaderText, MessageIsNotConnected = "", MessageWasNotSelected = "") Export
	
	If Not UpdateClientWorkplace() Then
		MessageText = NStr("vi = 'Trước tiên, cần chọn chỗ làm việc cho thiết bị kết nối của phiên làm việc hiện tại.';
							|ru = 'Предварительно необходимо выбрать рабочее место подключаемого оборудования текущего сеанса.';
							|en = 'First, you need to select the workplace for peripherals to use in the current session.'; fa = 'First, you need to select the workplace for peripherals to use in the current session.';
							|it = 'È necessario selezionare prima la postazione di lavoro dell''apparecchiatura plug-in della sessione corrente.';
							|pl = 'Uprzednio należy wybrać miejsce pracy podłączanych urządzeń bieżącej sesii.';
							|tr = 'Önce mevcut oturumun bağlı ekipmanının çalışma alanı seçilmeli.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageText);
		Return ExecutionResult;
	EndIf;
	
	If IsBlankString(MessageIsNotConnected) Then
		MessageIsNotConnected = NStr("vi = 'Các thiết bị cần thiết không được kết nối với chỗ làm việc hiện tại.';
									|ru = 'Необходимые устройства не подключены к текущему рабочему месту.';
									|en = 'Required devices are not connected to the current workplace.'; fa = 'Required devices are not connected to the current workplace.';
									|it = 'I dispositivi necessari non sono connessi alla postazione di lavoro corrente.';
									|pl = 'Potrzebne urządzenie nie są podłączone do bieżącego miejsca pracy.';
									|tr = 'Gerekli cihazlar mevcut çalışma alanına bağlı değil.'");
	EndIf;
	
	If IsBlankString(MessageWasNotSelected) Then
		MessageWasNotSelected = NStr("vi = 'Chưa chọn thiết bị.';
									|ru = 'Устройство не выбрано.';
									|en = 'Device is not selected.'; fa = 'Device is not selected.';
									|it = 'Dispositivo non selezionato.';
									|pl = 'Nie wybrano urządzenia.';
									|tr = 'Cihaz seçilmedi.'");
	EndIf;
	
	If TypeOf(Filter) = Type("Structure") Then
		If Filter.Property("SoftwareTypes") Then
			ListOfEquipmentSelection = Filter; 
		Else
			ListOfEquipmentSelection = EquipmentManagerClientServer.ListOfEquipmentSelection();
			ListOfEquipmentSelection.SoftwareTypes = Filter;
		EndIf;                  
	Else
		ListOfEquipmentSelection = EquipmentManagerClientServer.ListOfEquipmentSelection();
		ListOfEquipmentSelection.SoftwareTypes = Filter;
	EndIf;                  
		
	ListOfAvailableDevices = EquipmentManagerServerCall.EquipmentList(ListOfEquipmentSelection);
	ListOfDevices          = New ValueList();
	For Each Devices In ListOfAvailableDevices Do
		ListOfDevices.Add(Devices.Ref, Devices.Description);
	EndDo;
	
	If ListOfDevices.Count() = 0 Then
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageIsNotConnected);
	ElsIf ListOfDevices.Count() = 1 Then
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
		ExecutionResult.DeviceID = ListOfDevices[0].Value;
	Else
		Result = Await ListOfDevices.ChooseItemAsync(SelectionHeaderText);
		If Result = Undefined Then 
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageWasNotSelected);
		Else
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
			ExecutionResult.DeviceID = Result.Value;
		EndIf;
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

// Procedure for selecting a device from the available ones linked to the current workplace.
//
// Parameters:
//  ChoiceNotification - CallbackDescription - notification description event.
//  Filter - String - the type of equipment to select the device.
//        - Array of String
//        - See EquipmentManagerClientServer.ListOfEquipmentSelection
//  SelectionHeaderText - String - The title of the selection window.
//  MessageIsNotConnected - String - The text of the message about not connected devices
//  MessageWasNotSelected - String - The text of the message about not selected devices
//
Procedure SelectDevice(ChoiceNotification, Filter, SelectionHeaderText, MessageIsNotConnected = "", MessageWasNotSelected = "") Export
	
	If Not UpdateClientWorkplace() Then
		MessageText = NStr("vi = 'Trước tiên, cần chọn chỗ làm việc cho thiết bị kết nối của phiên làm việc hiện tại.';
							|ru = 'Предварительно необходимо выбрать рабочее место подключаемого оборудования текущего сеанса.';
							|en = 'First, you need to select the workplace for peripherals to use in the current session.'; fa = 'First, you need to select the workplace for peripherals to use in the current session.';
							|it = 'È necessario selezionare prima la postazione di lavoro dell''apparecchiatura plug-in della sessione corrente.';
							|pl = 'Uprzednio należy wybrać miejsce pracy podłączanych urządzeń bieżącej sesii.';
							|tr = 'Önce mevcut oturumun bağlı ekipmanının çalışma alanı seçilmeli.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageText);
		RunCallback(ChoiceNotification, ExecutionResult);
		Return;
	EndIf;
	
	If IsBlankString(MessageIsNotConnected) Then
		MessageIsNotConnected = NStr("vi = 'Các thiết bị cần thiết không được kết nối với chỗ làm việc hiện tại.';
									|ru = 'Необходимые устройства не подключены к текущему рабочему месту.';
									|en = 'Required devices are not connected to the current workplace.'; fa = 'Required devices are not connected to the current workplace.';
									|it = 'I dispositivi necessari non sono connessi alla postazione di lavoro corrente.';
									|pl = 'Potrzebne urządzenie nie są podłączone do bieżącego miejsca pracy.';
									|tr = 'Gerekli cihazlar mevcut çalışma alanına bağlı değil.'");
	EndIf;
	
	If IsBlankString(MessageWasNotSelected) Then
		MessageWasNotSelected = NStr("vi = 'Chưa chọn thiết bị.';
									|ru = 'Устройство не выбрано.';
									|en = 'Device is not selected.'; fa = 'Device is not selected.';
									|it = 'Dispositivo non selezionato.';
									|pl = 'Nie wybrano urządzenia.';
									|tr = 'Cihaz seçilmedi.'");
	EndIf;
		
	If TypeOf(Filter) <> Type("Structure") Then
		ListOfEquipmentSelection = EquipmentManagerClientServer.ListOfEquipmentSelection();
		ListOfEquipmentSelection.SoftwareTypes = Filter;
	ElsIf Not Filter.Property("SoftwareTypes") Then
		ListOfEquipmentSelection = EquipmentManagerClientServer.ListOfEquipmentSelection();
		ListOfEquipmentSelection.SoftwareTypes = Filter;
	Else
		ListOfEquipmentSelection = Filter;
	EndIf;
	
	ListOfAvailableDevices = EquipmentManagerServerCall.EquipmentList(ListOfEquipmentSelection);
	ListOfDevices          = New ValueList();
	For Each Devices In ListOfAvailableDevices Do
		ListOfDevices.Add(Devices.Ref, Devices.Description);
	EndDo;
	
	If ListOfDevices.Count() = 0 Then
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageIsNotConnected);
		RunCallback(ChoiceNotification, ExecutionResult);
	ElsIf ListOfDevices.Count() = 1 Then
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
		ExecutionResult.DeviceID = ListOfDevices[0].Value;
		RunCallback(ChoiceNotification, ExecutionResult);
	Else
		Context = New Structure;
		Context.Insert("ChoiceNotification"  , ChoiceNotification);
		Context.Insert("MessageWasNotSelected", MessageWasNotSelected);
		CallbackDescription = New CallbackDescription("SelectDeviceCompletion", ThisObject, Context);
		ListOfDevices.ShowChooseItem(CallbackDescription, SelectionHeaderText);
	EndIf;
	
EndProcedure

// Completion of device selection.
// 
// Parameters:
//  Result - Structure
//  Context - Structure
// 
Procedure SelectDeviceCompletion(Result, Context) Export
	
	If Result = Undefined Then 
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, Context.MessageWasNotSelected);
		RunCallback(Context.ChoiceNotification, ExecutionResult);
	Else
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
		ExecutionResult.DeviceID = Result.Value;
		RunCallback(Context.ChoiceNotification, ExecutionResult);
	EndIf;
	
EndProcedure

#EndRegion

#Region EnablingEquipmentDisconnection                 

// Start connecting devices.
//
// Parameters:
//  ClientID - UUID - the unique identifier of the client.
//  SoftwareTypes - Structure, Array of String, String - the type of equipment to select the device.
//  DeviceID - Array of String, CatalogRef.Peripherals - connected device.
//  NetworkEquipment - Boolean - use network equipment when connecting.
//
// Returns:
//  Array of See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware - Results of connecting devices.
//
Async Function ConnectingEquipmentAsync(ClientID, SoftwareTypes = Undefined, DeviceID = Undefined, NetworkEquipment = True) Export
	
	// Performance Measurement
	KeyOperation = "CommonModule.EquipmentManagerClient.ConnectingEquipmentAsync";
	MeasurementUUID = CommonCELClient.BPOTimeMeasurement(KeyOperation);     
	
	Peripherals_ = New Array(); // Device connection results
	
	If Not UpdateClientWorkplace() Then
		ErrorDescription = NStr("vi = 'Trước tiên, cần chọn chỗ làm việc cho thiết bị kết nối của phiên làm việc hiện tại.';
								|ru = 'Предварительно необходимо выбрать рабочее место подключаемого оборудования текущего сеанса.';
								|en = 'First, you need to select the workplace for peripherals to use in the current session.'; fa = 'First, you need to select the workplace for peripherals to use in the current session.';
								|it = 'È necessario selezionare prima la postazione di lavoro dell''apparecchiatura plug-in della sessione corrente.';
								|pl = 'Uprzednio należy wybrać miejsce pracy podłączanych urządzeń bieżącej sesii.';
								|tr = 'Önce mevcut oturumun bağlı ekipmanının çalışma alanı seçilmeli.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);   
		Peripherals_.Add(ExecutionResult);
		// Performance Measurement
		CommonCELClient.CompleteBPOTimeMeasurement(MeasurementUUID, True);
		Return Peripherals_;
	EndIf;
	
	DevicesForConnection = DevicesForConnection(ClientID, SoftwareTypes, DeviceID, NetworkEquipment);
	Peripherals_ = DevicesForConnection.Peripherals_;
	EquipmentForConnection = DevicesForConnection.EquipmentForConnection;
	
	For Each Device In EquipmentForConnection Do
		
		New_Connection = DeviceConnectionParameters(Device);
		ConnectionResult = Await New_Connection.DriverHandler.ConnectDeviceAsync(New_Connection);
		If ConnectionResult.Result Then
			New_Connection.Customers.Add(ClientID);
			New_Connection.NumberOfConnectedDevices = 1;
			Peripherals = Peripherals();
			Peripherals.SoftwareConnectionParameters.Add(New_Connection);
			Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, Undefined, Device.Ref);
			Result.ConnectedDevice = New_Connection;
			Peripherals_.Add(Result);
		Else
			ErrorDescription = StrTemplate(NStr("vi = 'Không thể kết nối thiết bị (%1): %2';
												|ru = 'Не удалось подключить устройство (%1): %2';
												|en = 'Cannot connect the (%1) device: %2'; fa = 'Cannot connect the (%1) device: %2';
												|it = 'Non è stato possibile connettere il dispositivo (%1): %2';
												|pl = 'Nie udało się podłączyć urządzenia (%1): %2';
												|tr = 'Cihaz bağlanamadı (%1): %2'"), DeviceID, ConnectionResult.ErrorDescription);
			Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription, Device.Ref);
			Result.LoadingError = ConnectionResult.LoadingError;
			Peripherals_.Add(Result);
		EndIf;
		
	EndDo;
	
	// Performance Measurement
	CommonCELClient.CompleteBPOTimeMeasurement(MeasurementUUID, True);
	
	Return Peripherals_;
	
EndFunction

// Start connecting the device.
//
// Parameters:
//  NotificationWhenConnecting - CallbackDescription - notification description event.
//  ClientID - UUID - the unique identifier of the client.
//  SoftwareTypes - Structure, Array of String, String - the type of equipment to select the device.
//  DeviceID - Array of String, CatalogRef.Peripherals - connected device.
//  NetworkEquipment - Boolean - use network equipment when connecting.
//
Procedure StartConnectingEquipment(NotificationWhenConnecting, ClientID, SoftwareTypes = Undefined, DeviceID = Undefined, NetworkEquipment = False) Export
	
	// Performance Measurement
	KeyOperation = "CommonModule.EquipmentManagerClient.StartConnectingEquipment";
	MeasurementUUID = CommonCELClient.BPOTimeMeasurement(KeyOperation);     
	
	If Not UpdateClientWorkplace() Then
		ErrorDescription = NStr("vi = 'Trước tiên, cần chọn chỗ làm việc cho thiết bị kết nối của phiên làm việc hiện tại.';
								|ru = 'Предварительно необходимо выбрать рабочее место подключаемого оборудования текущего сеанса.';
								|en = 'First, you need to select the workplace for peripherals to use in the current session.'; fa = 'First, you need to select the workplace for peripherals to use in the current session.';
								|it = 'È necessario selezionare prima la postazione di lavoro dell''apparecchiatura plug-in della sessione corrente.';
								|pl = 'Uprzednio należy wybrać miejsce pracy podłączanych urządzeń bieżącej sesii.';
								|tr = 'Önce mevcut oturumun bağlı ekipmanının çalışma alanı seçilmeli.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);   
		// Performance Measurement
		CommonCELClient.CompleteBPOTimeMeasurement(MeasurementUUID, True);
		RunCallback(NotificationWhenConnecting, ExecutionResult); 
		Return;
	EndIf;
	
	DevicesForConnection = DevicesForConnection(ClientID, SoftwareTypes, DeviceID, NetworkEquipment);
	Peripherals_ = DevicesForConnection.Peripherals_;
	For Each ConnectionResult In Peripherals_ Do
		RunCallback(NotificationWhenConnecting, ConnectionResult); 
	EndDo;
	
	EquipmentForConnection = DevicesForConnection.EquipmentForConnection;
	If EquipmentForConnection.Count() > 0 Then 
		Context = New Structure();  
		Context.Insert("ConnectionParameters");
		Context.Insert("ClientID",       ClientID);
		Context.Insert("NotificationWhenConnecting",   NotificationWhenConnecting);
		Context.Insert("EquipmentForConnection", EquipmentForConnection);
		StartConnectingEquipmentRecursively(Undefined, Context);
	EndIf;
	
EndProcedure  

// Connects available hardware using the list of SOFTWARE types
//
// Parameters:
//  NotificationWhenConnecting - CallbackDescription - notification description event.
//  ClientID - UUID
//  SoftwareTypes - Structure, Array of String, String - the type of equipment for connecting devices.
//
Procedure StartConnectingEquipmentByType(NotificationWhenConnecting, ClientID, SoftwareTypes) Export
	
	StartConnectingEquipment(NotificationWhenConnecting, ClientID, SoftwareTypes);
	 
 EndProcedure

// Start connecting a single instance of the device defined by the ID.
//
// Parameters:
//  NotificationWhenConnecting - CallbackDescription - notification description event.
//  ClientID - UUID - the unique identifier of the client.
//  DeviceID - Array of String, CatalogRef.Peripherals - connected device.
//
Procedure StartConnectingEquipmentById(NotificationWhenConnecting, ClientID, DeviceID) Export
	
	StartConnectingEquipment(NotificationWhenConnecting, ClientID, , DeviceID);
	
EndProcedure

// Start disabling devices by hardware type.
//
// Parameters:
//  DisconnectionAlert - CallbackDescription - notification description event.
//  ClientID - UUID
//  SoftwareTypes - Structure, Array of String, String - the type of equipment for disconnecting devices.
//
Procedure StartEquipmentDisablingByType(DisconnectionAlert, ClientID, SoftwareTypes) Export
	
	StartDisconnectionEquipment(DisconnectionAlert, ClientID, SoftwareTypes);
	
EndProcedure

// Start disabling devices by hardware type.
//
// Parameters:
//  DisconnectionAlert - CallbackDescription - notification description event.
//  ClientID - UUID
//  SoftwareTypes - Structure, Array of String, String - the type of equipment for disconnecting devices.
//
Procedure StartDisablingEquipmentByType(DisconnectionAlert, ClientID, SoftwareTypes) Export
	
	StartDisconnectionEquipment(DisconnectionAlert, ClientID, SoftwareTypes);
	
EndProcedure

// To start turn off the device specified by the identifier.
//
// Parameters:
//  DisconnectionAlert - CallbackDescription - notification description event.
//  ClientID - UUID
//  DeviceID -  Array of String, CatalogRef.Peripherals - the device being disconnected.
//
Procedure Start_DisablingEquipmentById(DisconnectionAlert, ClientID, DeviceID) Export
	
	StartDisconnectionEquipment(DisconnectionAlert, ClientID, Undefined, DeviceID);
	
EndProcedure

// This function connects devices by hardware type.
//
// Parameters:
//  ClientID - UUID
//  SoftwareTypes - Structure, Array of String, String - the type of equipment for disconnecting devices.
//  DeviceID - CatalogRef.Peripherals - the device being disconnected.
//      
// Returns:
//  Array of See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware - Results of device disconnection.
//  
Async Function DisablingEquipmentAsync(ClientID, SoftwareTypes = Undefined, DeviceID = Undefined) Export
	
	DisabledEquipment = New Array(); // Device shutdown results  
	Peripherals = Peripherals();
	
	ConnectedDevices = DevicesForDisconnection(SoftwareTypes, DeviceID);
	For Each DeviceBeingDisconnected In ConnectedDevices Do // Structure
		ConnectionClient = DeviceBeingDisconnected.Customers.Find(ClientID);
		If ConnectionClient <> Undefined Then  
			// Necessary device
			If DeviceBeingDisconnected.NumberOfConnectedDevices = 1 Then
				OperationResult = Await DeviceBeingDisconnected.DriverHandler.DisableDeviceAsync(DeviceBeingDisconnected);
				If OperationResult.Result Then
					// Disconnect the device.
					DeviceBeingDisconnected .NumberOfConnectedDevices = 0;
					ArrayLineNumber = Peripherals.SoftwareConnectionParameters.Find(DeviceBeingDisconnected);
					If ArrayLineNumber <> Undefined Then
						Peripherals.SoftwareConnectionParameters.Delete(ArrayLineNumber);
					EndIf;
					ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
					ExecutionResult.DeviceID = DeviceBeingDisconnected.Ref;
				Else
					ErrorDescription = StrTemplate(
						NStr("vi = 'Khi vô hiệu hóa thiết bị ""%1"", đã xảy ra lỗi.';
							|ru = 'При отключении устройства ""%1"" произошла ошибка.';
							|en = 'An error occurred when disconnecting device ""%1"".'; fa = 'An error occurred when disconnecting device ""%1"".';
							|it = 'Durante la disattivazione del dispositivo ""%1"" si è verificato un errore.';
							|pl = 'Podczas odłączenia urządzenia ""%1"" wystąpił błąd.';
							|tr = '""%1"" cihazı devre dışı bırakılırken hata oluştu.'"), 
						DeviceBeingDisconnected.Description);
					ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
					ExecutionResult.DeviceID = DeviceBeingDisconnected.Ref;
				EndIf;
				DisabledEquipment.Add(ExecutionResult);
			Else
				DeviceBeingDisconnected.NumberOfConnectedDevices = DeviceBeingDisconnected.NumberOfConnectedDevices - 1;
				DeviceBeingDisconnected.Customers.Delete(ConnectionClient);
				ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, DeviceBeingDisconnected.Ref);
				DisabledEquipment.Add(ExecutionResult);
			EndIf;
		EndIf;
	EndDo;    
	
	Return DisabledEquipment;
	
EndFunction  

// This function connects devices by hardware type.
//
// Parameters:
//  DisconnectionAlert - CallbackDescription - notification description event.
//  ClientID - UUID
//  SoftwareTypes - Structure, Array of String, String - the type of equipment for disconnecting devices.
//  DeviceID - Array of String, CatalogRef.Peripherals - the device being disconnected.
//
Procedure StartDisconnectionEquipment(DisconnectionAlert, ClientID, SoftwareTypes = Undefined, DeviceID = Undefined) Export
	
	ConnectedDevices = DevicesForDisconnection(SoftwareTypes, DeviceID);
	
	For IndexOf = 0 To ConnectedDevices.UBound() Do
		DeviceBeingDisconnected = ConnectedDevices[IndexOf];
		ConnectionClient = DeviceBeingDisconnected.Customers.Find(ClientID);
		If ConnectionClient <> Undefined Then  
			If DeviceBeingDisconnected.NumberOfConnectedDevices = 1 Then
				Context = New Structure();
				Context.Insert("DeviceBeingDisconnected",  DeviceBeingDisconnected);
				Context.Insert("DisconnectionAlert", DisconnectionAlert);
				Context.Insert("ThisIsDisablingLastDriver", (ConnectedDevices.UBound() = IndexOf));
				Notification = New CallbackDescription("StartDisconnectionEquipmentCompletion", ThisObject, Context);
				DeviceBeingDisconnected.DriverHandler.StartDisconnectingDevice(Notification, DeviceBeingDisconnected);
			Else
				DeviceBeingDisconnected.NumberOfConnectedDevices = DeviceBeingDisconnected.NumberOfConnectedDevices - 1;
				DeviceBeingDisconnected.Customers.Delete(ConnectionClient);
			EndIf;
		EndIf;
	EndDo;    
	
EndProcedure  

// Completion of equipment shutdown.
// 
// Parameters:
//  ExecutionResult - Structure
//  Context - Structure:
//   * ConnectedDevice - Structure:
//      * Description - String - Device name
//   * DisconnectionAlert - CallbackDescription
// 
Procedure StartDisconnectionEquipmentCompletion(ExecutionResult, Context) Export
	
	DeviceBeingDisconnected = Context.DeviceBeingDisconnected; // Structure
	If ExecutionResult.Result Then
		// Disconnect the device.
		DeviceBeingDisconnected.NumberOfConnectedDevices = 0;
		Peripherals = Peripherals();
		IndexOf = Peripherals.SoftwareConnectionParameters.Find(DeviceBeingDisconnected);
		If IndexOf <> Undefined Then
			Peripherals.SoftwareConnectionParameters.Delete(IndexOf);
		EndIf;
		Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
		Result.DeviceID = DeviceBeingDisconnected.Ref;
	Else
		ErrorDescription = StrTemplate(
			NStr("vi = 'Khi vô hiệu hóa thiết bị ""%1"", đã xảy ra lỗi.';
				|ru = 'При отключении устройства ""%1"" произошла ошибка.';
				|en = 'An error occurred when disconnecting device ""%1"".'; fa = 'An error occurred when disconnecting device ""%1"".';
				|it = 'Durante la disattivazione del dispositivo ""%1"" si è verificato un errore.';
				|pl = 'Podczas odłączenia urządzenia ""%1"" wystąpił błąd.';
				|tr = '""%1"" cihazı devre dışı bırakılırken hata oluştu.'"), 
			DeviceBeingDisconnected.Description);
		Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
		Result.DeviceID = DeviceBeingDisconnected.Ref;
	EndIf;
	
	If Context.ThisIsDisablingLastDriver And CommonCELClient.ThereIsDataForRecordingOfOperationsOfEquipment() Then
		DataExchangeWithServer();
	EndIf;
	
	If Context.DisconnectionAlert <> Undefined Then
		RunCallback(Context.DisconnectionAlert, Result);
	EndIf;
	
EndProcedure

// Forcibly disconnects all connected equipment, regardless of the number of connection links.
//
// Returns:
//  Boolean
// 
Async Function DisconnectionOfAllAsyncEquipment() Export
	
	Peripherals = Peripherals();
	For Each ConnectedDevice In Peripherals.SoftwareConnectionParameters Do
		OperationResult = Await GenericDriverClient.DisableDeviceAsync(ConnectedDevice);
 		If Not OperationResult.Result Then
			MessageText = StrTemplate(NStr("vi = 'Khi vô hiệu hóa thiết bị, đã xảy ra lỗi: %1';
											|ru = 'При отключении оборудования произошла ошибка: %1';
											|en = 'An error occurred when disconnecting the equipment: %1.'; fa = 'An error occurred when disconnecting the equipment: %1.';
											|it = 'Durante la disattivazione dell''apparecchiatura si è verificato un errore: %1';
											|pl = 'Podczas odłączania sprzętu wystąpił błąd:%1';
											|tr = 'Ekipman kapatılırken hata oluştu: %1'"), OperationResult.ErrorDescription);
			CommonCELClient.MessageToUser(MessageText);
		EndIf;
		ConnectedDevice.NumberOfConnectedDevices = 0;
	EndDo;
	
	NumberOfConnectedClients = 0;
	For Each ConnectedDevice In Peripherals.SoftwareConnectionParameters Do
		NumberOfConnectedClients = NumberOfConnectedClients + ConnectedDevice.NumberOfConnectedDevices;
	EndDo;
	
	Peripherals.SoftwareConnectionParameters.Clear();        
	
	Return True;
	
EndFunction

// Forcibly disconnects all connected equipment, regardless of the number of connection links.
//
// Parameters:
//  DisconnectionAlert - CallbackDescription - notification description event.
//
Procedure StartShuttingDownAllHardware(DisconnectionAlert = Undefined) Export
	
	Peripherals = Peripherals();
	SoftwareConnectionParameters   = Peripherals.SoftwareConnectionParameters;
	
	For IndexOf = 0 To SoftwareConnectionParameters.UBound() Do
		ConnectedDevice = SoftwareConnectionParameters[IndexOf];
		Context = New Structure();
		Context.Insert("ThisIsDisablingLastDriver", (SoftwareConnectionParameters.UBound() = IndexOf));
		Notification = New CallbackDescription("StartShuttingDownAllHardwareCompletion", ThisObject, Context);
		ConnectedDevice.DriverHandler.StartDisconnectingDevice(Notification, ConnectedDevice);
		ConnectedDevice.NumberOfConnectedDevices = 0;
	EndDo;
	SoftwareConnectionParameters.Clear();
	
EndProcedure

// Complete shutdown of all equipment.
// 
// Parameters:
//  ExecutionResult - Structure
//  Parameters - Structure
// 
Procedure StartShuttingDownAllHardwareCompletion(ExecutionResult, Parameters) Export
	
	If Not ExecutionResult.Result Then
		MessageText = StrTemplate(NStr("vi = 'Khi vô hiệu hóa thiết bị, đã xảy ra lỗi: %1';
										|ru = 'При отключении оборудования произошла ошибка: %1';
										|en = 'An error occurred when disconnecting the equipment: %1.'; fa = 'An error occurred when disconnecting the equipment: %1.';
										|it = 'Durante la disattivazione dell''apparecchiatura si è verificato un errore: %1';
										|pl = 'Podczas odłączania sprzętu wystąpił błąd:%1';
										|tr = 'Ekipman kapatılırken hata oluştu: %1'"), ExecutionResult.ErrorDescription);
		CommonCELClient.MessageToUser(MessageText);
	EndIf;
	If Parameters.ThisIsDisablingLastDriver Then
		DataExchangeWithServer();
	EndIf;
	
EndProcedure

// The function returns whether the equipment is connected.
// 
// Parameters: 
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Boolean - The device is connected
//
Function DeviceIsConnected(DeviceID) Export
	
	Peripherals = Peripherals();
	For Each Connection In Peripherals.SoftwareConnectionParameters Do
		If Connection.Ref = DeviceID Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForConnectingDisconnectingEquipmentInFormOf

// Start connecting the required hardware types when opening the form.
//
// Parameters:
//	NotificationWhenConnecting - CallbackDescription - notification when connecting.
//	Form - ClientApplicationForm - the form to open.
//	SupportedPeripheralTypes - String - Contains a comma-separated list of types of connected hardware.
//
Procedure StartConnectingDevicesWhenYouOpenForm(NotificationWhenConnecting, Form, SupportedPeripheralTypes = Undefined) Export
	
	// Performance Measurement
	KeyOperation = "CommonModule.EquipmentManagerClient.ConnectingEquipmentWhenOpeningForm";
	MeasurementUUID = CommonCELClient.BPOTimeMeasurement(KeyOperation, NotificationWhenConnecting);
	
	If NotificationWhenConnecting = Undefined Then
		NotificationWhenConnecting = New CallbackDescription("ConnectHardwareCompletionByDefault", EquipmentManagerClient);
	EndIf;
	
	Peripherals = AttachableEquipmentOnForm(Form);
	If Peripherals <> Undefined Then
		
		If Peripherals.RequestForListOfEquipmentOnClientIsRequired Then
			Filter = EquipmentManagerClientServer.ListOfEquipmentSelection();
			Filter.SoftwareTypes = Peripherals.SoftwareTypes;
			UpdateClientWorkplace();
			Peripherals.EquipmentList = EquipmentManagerServerCall.EquipmentList(Filter);
		EndIf;
		
		ListOnForm = Form.AttachableBPOEquipment.EquipmentList;
		If ListOnForm.Count() = 0 Then
			Return;
		EndIf;
		Context = New Structure();
		Context.Insert("Form", Form);
		Context.Insert("NotificationWhenConnecting", NotificationWhenConnecting);
		Notification = New CallbackDescription("StartConnectingDevicesWhenYouOpenFormCompletion", ThisObject, Context);
		EquipmentList = New Array();
		For Each Item In ListOnForm Do
			EquipmentList.Add(Item);
		EndDo;
		ListOnForm.Clear();
		
		If ThereAreDetailsOnForm(Form, "SupportedPeripheralTypes") Then
			FillInSupportedTypesOfConnectedEquipmentOnForm(Form, Peripherals.SoftwareTypes);
		EndIf;
		If ThereAreDetailsOnForm(Form, "UsePeripherals") Then
			Form.UsePeripherals = True;
		EndIf;
		
		StartConnectingEquipment(
			Notification, Form.UUID, EquipmentList);
			
	Else
		If ThereAreDetailsOnForm(Form, "UsePeripherals, SupportedPeripheralTypes") Then
			
			FillInSupportedTypesOfConnectedEquipmentOnForm(Form, SupportedPeripheralTypes);
			
			If Form.UsePeripherals Then
				StartConnectingEquipmentByType(
					NotificationWhenConnecting,
					Form.UUID,
					GetTypesOfEquipment(Form.SupportedPeripheralTypes));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Start connecting the required hardware types when opening the form.
//
// Parameters:
//  Result - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware.
//  Context - Structure
//
Procedure StartConnectingDevicesWhenYouOpenFormCompletion(Result, Context) Export
	
	If Result.Result Then
		ConnectedDevice =  New Structure();
		ConnectedDevice.Insert("DeviceID", Result.ConnectedDevice.DeviceID);
		ConnectedDevice.Insert("EquipmentTypeName", Result.ConnectedDevice.EquipmentTypeName);
		Context.Form.AttachableBPOEquipment.EquipmentList.Add(ConnectedDevice);
	EndIf;
	
	If Context.NotificationWhenConnecting <> Undefined Then
		RunCallback(Context.NotificationWhenConnecting, Result);
	EndIf;
	
EndProcedure

// Default notification handler
//
// Parameters:
//	ExecutionResult - Structure - the result of the operation.
//	Parameters - Arbitrary - an additional parameter passed to the notification.
//
Procedure ConnectHardwareCompletionByDefault(ExecutionResult, Parameters) Export
	
	If Not ExecutionResult.Result Then
		MessageText = StrTemplate(NStr("vi = 'Khi kết nối thiết bị, đã xảy ra lỗi: ""%1"".';
										|ru = 'При подключении оборудования произошла ошибка:""%1"".';
										|en = 'An error occurred when connecting the peripherals:""%1"".'; fa = 'An error occurred when connecting the peripherals:""%1"".';
										|it = 'Durante la connessione dell''apparecchiatura si è verificato un errore: %1';
										|pl = 'Przy podłączeniu urządzenia wystąpił błąd: ""%1"".';
										|tr = 'Ekipman bağlanırken hata oluştu: ""%1"".'"), ExecutionResult.ErrorDescription); 
		CommonCELClient.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

// To start off the equipment by type when the form is closed.
//
// Parameters:
//	DisconnectionAlert - CallbackDescription - notification when disconnecting.
//	Form - ClientApplicationForm - the form to be closed.
//
Procedure StartDisablingHardwareWhenClosingForm(DisconnectionAlert, Form) Export
	
	// Performance Measurement
	KeyOperation = "CommonModule.EquipmentManagerClient.DisablingEquipmentWhenClosingForm";
	MeasurementUUID = CommonCELClient.BPOTimeMeasurement(KeyOperation, DisconnectionAlert);
	
	If DisconnectionAlert = Undefined Then
		DisconnectionAlert = New CallbackDescription("DisableHardwareCompletionByDefault", EquipmentManagerClient);
	EndIf;
	
	Peripherals = AttachableEquipmentOnForm(Form);
	If Peripherals <> Undefined Then
		SoftwareTypes = New Array();
		For Each Item In Peripherals.EquipmentList Do
			SoftwareTypes.Add(Item.EquipmentTypeName);
		EndDo;
		StartDisconnectionEquipment(DisconnectionAlert, Form.UUID, SoftwareTypes);
	Else
		If ThereAreDetailsOnForm(Form, "SupportedPeripheralTypes") Then
			StartEquipmentDisablingByType(
				DisconnectionAlert,
				Form.UUID,
				ArrayOfEquipmentTypes(Form.SupportedPeripheralTypes));
		EndIf;
	EndIf;
	
EndProcedure

// Handler for notification of equipment shutdown when the form is closed by default
// 
// Parameters:
//  ExecutionResult - Structure
//  Parameters - Structure
// 
Procedure DisableHardwareCompletionByDefault(ExecutionResult, Parameters) Export
	
	If Not ExecutionResult.Result Then
		MessageText = StrTemplate(NStr("vi = 'Khi vô hiệu hóa thiết bị, đã xảy ra lỗi: %1';
										|ru = 'При отключении оборудования произошла ошибка: %1';
										|en = 'An error occurred when disconnecting the equipment: %1.'; fa = 'An error occurred when disconnecting the equipment: %1.';
										|it = 'Durante la disattivazione dell''apparecchiatura si è verificato un errore: %1';
										|pl = 'Podczas odłączania sprzętu wystąpił błąd:%1';
										|tr = 'Ekipman kapatılırken hata oluştu: %1'"), ExecutionResult.ErrorDescription);
		CommonCELClient.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

// Connecting the necessary types of equipment when opening the form.
//
// Parameters:
//   Form - ClientApplicationForm - the form to open.
// 
// Returns:
//   Array of See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware.
// 
Async Function ToConnectEquipmentWhenOpeningAsyncForm(Form) Export
	
	ConnectionResults = New Array();
	
	Peripherals = AttachableEquipmentOnForm(Form);
	If Peripherals <> Undefined Then
		
		ConnectionResults = Await ConnectingEquipmentAsync(
			Form.UUID,
			Peripherals.EquipmentList);
			
		Form.AttachableBPOEquipment.EquipmentList = Undefined;
		EquipmentList = New Array();
		For Each Result In ConnectionResults Do
			If Result.Result Then
				ConnectionParameters = EquipmentManagerClientServer.ConnectionParameters(Result.ConnectedDevice);
				ConnectionParameters.Delete("LocalizationPattern");
				EquipmentList.Add(New FixedStructure(ConnectionParameters));
			EndIf;
		EndDo;
		Form.AttachableBPOEquipment.EquipmentList = New FixedArray(EquipmentList);
		
		If ThereAreDetailsOnForm(Form, "SupportedPeripheralTypes") Then
			FillInSupportedTypesOfConnectedEquipmentOnForm(Form, Peripherals.SoftwareTypes);
		EndIf;
		If ThereAreDetailsOnForm(Form, "UsePeripherals") Then
			Form.UsePeripherals = True;
		EndIf;
		
	EndIf;
	
	Return ConnectionResults;
	
	
EndFunction

// Disabling hardware when closing the form.
//
// Parameters:
//   Form - ClientApplicationForm - the form to be closed.
//
// Returns:
//   Array of See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware.
// 
Async Function TurnOffEquipmentWhenClosingAsyncForm(Form) Export
	
	// Performance Measurement
	KeyOperation = "CommonModule.EquipmentManagerClient.DisablingEquipmentWhenClosingForm";
	MeasurementUUID = CommonCELClient.BPOTimeMeasurement(KeyOperation);
	
	Result = New Array();
	Peripherals = AttachableEquipmentOnForm(Form);
	If Peripherals <> Undefined Then
		Result = Await DisablingEquipmentAsync(Form.UUID, Peripherals.SoftwareTypes);
	EndIf;
	
	#If Not MobileAppClient Then 
	CommonCELClient.CompleteBPOTimeMeasurement(MeasurementUUID);
	#EndIf
	
	Return Result;
	
EndFunction

#EndRegion

#Region PrintingDevice

// Start connecting the printer
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  ClientID - UUID - the unique identifier of the client.
//  DeviceID - CatalogRef.Peripherals - connected device.
//
Procedure StartConnectingPrinter(NotificationOnCompletion, ClientID, DeviceID = Undefined) Export
	
	ParametersExecution = New Structure();
	ParametersExecution.Insert("NotificationOnCompletion", NotificationOnCompletion);
	ParametersExecution.Insert("ClientID"   , ClientID);
	ParametersExecution.Insert("DeviceID", DeviceID);
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.ReceiptPrinter = True;
		SupportedTypes.CREWithDataTransfer = True;
		
		Notification = New CallbackDescription("StartConnectingPrinter_SelectEnd", ThisObject, ParametersExecution);
		SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn thiết bị để in';
				|ru = 'Выберите устройство для печати';
				|en = 'Select a print device'; fa = 'Select a print device';
				|it = 'Selezionare il dispositivo per la stampa';
				|pl = 'Wybierz urządzenia do drukowania';
				|tr = 'Yazdırma için cihaz seç'"),
			NStr("vi = 'Đối với chỗ làm việc này không có thiết bị in hợp lệ.';
				|ru = 'Для данного рабочего места нет доступных устройств для печати.';
				|en = 'There are no print devices available for this workplace.'; fa = 'There are no print devices available for this workplace.';
				|it = 'Per questa postazione da lavoro non vi sono dispositivi per la stampa disponibili.';
				|pl = 'Dla tego miejsca pracy nie ma dostępnych urządzeń do drukowania.';
				|tr = 'Bu çalışma alanı için kullanılabilir yazdırma cihazı yok.'"), 
			NStr("vi = 'Chưa chọn thiết bị để in.';
				|ru = 'Устройство для печати не выбрано.';
				|en = 'Print device is not selected.'; fa = 'Print device is not selected.';
				|it = 'Dispositivo per la stampa non selezionato.';
				|pl = 'Nie wybrano urządzenia do drukowania.';
				|tr = 'Yazdırma cihazı seçilmedi.'"));
	Else
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, Undefined, DeviceID); 
		StartConnectingPrinter_SelectEnd(ExecutionResult, ParametersExecution);
	EndIf;
	
EndProcedure

// Completing the connection of the printing device.
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersExecution - Structure
// 
Procedure StartConnectingPrinter_SelectEnd(ExecutionResult, ParametersExecution) Export
	
	If ExecutionResult.Result Then
		ParametersExecution.DeviceID = ExecutionResult.DeviceID; 
		// Search for the connected device.
		ConnectedDevice = GetConnectedDevice(ParametersExecution.DeviceID);                                                
		If ConnectedDevice = Undefined Then
			StartConnectingEquipmentById(ParametersExecution.NotificationOnCompletion, ParametersExecution.ClientID, ParametersExecution.DeviceID);
		Else
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, Undefined, ParametersExecution.DeviceID); 
			ExecutionResult.Insert("PrintingDeviceWasConnected", True);
			RunCallback(ParametersExecution.NotificationOnCompletion, ExecutionResult);
		EndIf;
	Else
		RunCallback(ParametersExecution.NotificationOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure

#EndRegion

#Region CommandExecution

// Executing a handler command for a connected device.
//
// Parameters:
//  ConnectedDevice - CatalogRef.Peripherals
//  ParametersCommandExecution - Structure
//
Procedure ExecutingHandlerCommand(ConnectedDevice, ParametersCommandExecution) Export
	
	Command = ParametersCommandExecution.Command;
	
	// We call the "Data Processor" module responsible for preparing data for executing a command on the hardware.
	If ParametersCommandExecution.PrepareData Or ParametersCommandExecution.PrepareDataClient Then
		
		If ParametersCommandExecution.PrepareData Then
			ConnectionParametersServer = EquipmentManagerClientServer.ConnectionParameters(ConnectedDevice);
			ProcessorOfData = ParametersCommandExecution.ProcessorOfData;   
			// Preparing data for of operation on the server.
			OperationData = EquipmentManagerServerCall.PrepareOperationData(ConnectionParametersServer, ProcessorOfData, Command, ParametersCommandExecution.OperationParametersList); 
			
			If OperationData = Undefined Then
				ErrorText = NStr("vi = 'Lỗi chuẩn bị dữ liệu cho giao dịch.';
								|ru = 'Ошибка подготовки данных для операции.';
								|en = 'An error occurred while preparing data for the operation.'; fa = 'An error occurred while preparing data for the operation.';
								|it = 'Errore di preparazione dati per l''operazione.';
								|pl = 'Błąd przygotowania danych dla operacji.';
								|tr = 'İşlem için veriler hazırlanırken hata oluştu.'");
				ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorText, ParametersCommandExecution.DeviceID);
				DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
				Return;
			ElsIf Not OperationData.Result Then
				ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, OperationData.ErrorText, ParametersCommandExecution.DeviceID);
				DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
				Return;
			EndIf; 
		EndIf;
		If ParametersCommandExecution.PrepareDataClient Then
			ConnectionParametersServer = EquipmentManagerClientServer.ConnectionParameters(ConnectedDevice);
			ProcessorOfData = ParametersCommandExecution.ProcessorOfData + "Client";
			// Preparing data for of operation on the server.
			OperationData = PrepareOperationData(ConnectionParametersServer, ProcessorOfData, Command, ParametersCommandExecution.OperationParametersList, OperationData); 
			
			If OperationData = Undefined Then
				ErrorText = NStr("vi = 'Lỗi chuẩn bị dữ liệu cho giao dịch.';
								|ru = 'Ошибка подготовки данных для операции.';
								|en = 'An error occurred while preparing data for the operation.'; fa = 'An error occurred while preparing data for the operation.';
								|it = 'Errore di preparazione dati per l''operazione.';
								|pl = 'Błąd przygotowania danych dla operacji.';
								|tr = 'İşlem için veriler hazırlanırken hata oluştu.'");
				ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorText, ParametersCommandExecution.DeviceID);
				DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
				Return;
			ElsIf Not OperationData.Result Then
				ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, OperationData.ErrorText, ParametersCommandExecution.DeviceID);
				DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
				Return;
			EndIf;
		EndIf;
	Else
		OperationData = ParametersCommandExecution.OperationParametersList;
		If OperationData = Undefined Then
			OperationData = New Structure();
		EndIf; 
	EndIf;
	
	DriverHandler = ConnectedDevice.DriverHandler;
	If DriverHandler = Undefined Then
		// Report an error that the driver could not be loaded.
		ErrorText = NStr("vi = 'Không thể kết nối hàm sự kiện của driver.';
						|ru = 'Не удалось подключить обработчик драйвера.';
						|en = 'Cannot attach the driver handler.'; fa = 'Cannot attach the driver handler.';
						|it = 'Impossibile collegare il gestore del driver.';
						|pl = 'Nie udało się podłączyć program przetwarzania sterownika.';
						|tr = 'Sürücü işleyicisi bağlanamadı '");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorText, ParametersCommandExecution.DeviceID);
		RunCallback(ParametersCommandExecution.NotificationOnCompletion, ExecutionResult);
	Else
		ParametersCommandExecution.Insert("OperationData", OperationData);
		ParametersCommandExecution.Insert("ConnectedDevice", ConnectedDevice);
		
		If Command = "CheckFiscalization"
			And ParametersCommandExecution.Property("NotificationAfterReceiptOpening")
			And ParametersCommandExecution.NotificationAfterReceiptOpening <> Undefined Then
			
			CallbackDescription = New CallbackDescription("StartExecuting_CommandAfterOpeningReceipt", ThisObject, ParametersCommandExecution);
			DriverHandler.StartCommandExecution(CallbackDescription, ConnectedDevice, "GetCurrentStatus", OperationData.CurrentStatus);
		Else        
			CallbackDescription = New CallbackDescription("StartCommandExecution_Completion", ThisObject, ParametersCommandExecution);
			DriverHandler.StartCommandExecution(CallbackDescription, ConnectedDevice, Command, OperationData);
		EndIf;
		
	EndIf;
	
EndProcedure

// The notification handler "After opening the receipt" is called during the "CheckFiscalization" command.
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartExecuting_CommandAfterOpeningReceipt(ExecutionResult, ParametersCommandExecution)  Export
	
	OperationData = ParametersCommandExecution.OperationData;
	ConnectedDevice = ParametersCommandExecution.ConnectedDevice;

	ExecutionParameters = New Structure();
	ExecutionParameters.Insert("InputParameters", ParametersCommandExecution.OperationData);
	ExecutionParameters.Insert("ErrorDescription"  , Undefined); 
	ExecutionParameters.Insert("ContinuePrinting", True);
	
	If CommonCELClient.CheckPrintingDevicesAreUsed() Then
		ModuleHardwareReceiptPrintingDevicesServerCall = CommonCELClient.CommonModule("EquipmentReceiptPrintersServerCall");
		CurrentStatus = OperationData.CurrentStatus;
		FiscalDataStructure = ModuleHardwareReceiptPrintingDevicesServerCall.GetShiftParametersFromXMLPackage(
			CurrentStatus.XMLResult, ConnectedDevice.InterfaceRevision, CurrentStatus.CREShiftNumber, CurrentStatus.KKTReceiptNumber);
		FillInParametersOfReceiptSigningOperation(ExecutionParameters, FiscalDataStructure.CREShiftNumber, Number(FiscalDataStructure.KKTReceiptNumber) + 1, OperationData.ManufaturerNumberOfFiscalStorage); 
	EndIf;

	Notification = New CallbackDescription("StartExecuting_EndOfPrintingCommand", ThisObject, ParametersCommandExecution);
	ExecutionParameters.Insert("ContinueNotification", Notification);
	RunCallback(ParametersCommandExecution.NotificationAfterReceiptOpening, ExecutionParameters);
	
EndProcedure

// The "Print Completion" notification handler is called after the receipt is opened.
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartExecuting_EndOfPrintingCommand(ExecutionResult, ParametersCommandExecution)  Export
	
	USAISData = New Structure;
	USAISData.Insert("Completed2", ExecutionResult.ContinuePrinting);
	USAISData.Insert("ErrorDescription", "");
	USAISData.Insert("ReceiptAddress", "");
	USAISData.Insert("ReceiptSignature", "");
	USAISData.Insert("IncomingMessage");
	USAISData.Insert("OutgoingMessage");
	USAISData.Insert("MessageHasBeenTransmitted", False);
	FillPropertyValues(USAISData, ExecutionResult);
	OperationData = ParametersCommandExecution.OperationData;
	OperationData.Insert("RecordingOfOperationUSAIS", USAISData);
	
	If ExecutionResult.ContinuePrinting Then        
		
		OperationParametersList = ParametersCommandExecution.OperationParametersList;
		ConnectedDevice = ParametersCommandExecution.ConnectedDevice;
		
		AdditionalParameters = New Structure();
		FillInParametersOfReceiptSigningOperation(AdditionalParameters);
		FillPropertyValues(AdditionalParameters, ExecutionResult);
		AdditionalParameters.Insert("ReceiptAddress"  , ?(ExecutionResult.Property("ReceiptAddress"), ExecutionResult.ReceiptAddress, Undefined));
		AdditionalParameters.Insert("ReceiptSignature", ?(ExecutionResult.Property("ReceiptSignature"), ExecutionResult.ReceiptSignature, Undefined));
		OperationData.Insert("ReceiptSignature", AdditionalParameters);
		OperationParametersList.Insert("AdditionalParameters", AdditionalParameters);
		 
		DriverHandler = ParametersCommandExecution.ConnectedDevice.DriverHandler;
		CallbackDescription = New CallbackDescription("StartCommandExecution_Completion", ThisObject, ParametersCommandExecution);
		DriverHandler.StartCommandExecution(CallbackDescription, ConnectedDevice, ParametersCommandExecution.Command, ParametersCommandExecution.OperationData);
		
	Else
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ExecutionResult.ErrorDescription, ParametersCommandExecution.DeviceID);
		RunCallback(ParametersCommandExecution.NotificationOnCompletion, ExecutionResult);
	EndIf;

EndProcedure

// Fill in the parameters of the receipt signing operation.
// 
// Parameters:
//  OperationParametersList - Structure
//  ShiftNumber - Number - The number of the open/closed shift.
//  ReceiptNumber - Number - Fiscal receipt number.
//  ManufaturerNumberOfFiscalStorage - Number - The factory number of the fiscal drive
//
Procedure FillInParametersOfReceiptSigningOperation(OperationParametersList, ShiftNumber = Undefined, 
	ReceiptNumber = Undefined, ManufaturerNumberOfFiscalStorage = Undefined) Export; 
	
	OperationParametersList.Insert("TIN"       , Undefined);
	OperationParametersList.Insert("CRTR"       , Undefined);
	
	OperationParametersList.Insert("ShiftNumber", ShiftNumber);
	OperationParametersList.Insert("ReceiptNumber" , ReceiptNumber);
	OperationParametersList.Insert("CheckoutNumber"      , Undefined);
	OperationParametersList.Insert("ManufaturerNumberOfFiscalStorage", ManufaturerNumberOfFiscalStorage);
	OperationParametersList.Insert("CompanyName", Undefined);
	
EndProcedure

// Start executing a command to the responsible driver handler
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  ClientID - UUID - the unique identifier of the client.
//  DeviceID - CatalogRef.Peripherals - connected device.
//  OperationParametersList - Structure
//  ParametersCommandExecution - Structure
//  PrintingDevice - CatalogRef.Peripherals - ID of the printing device.
//
Procedure StartCommandExecution(NotificationOnCompletion, ClientID, DeviceID, OperationParametersList, ParametersCommandExecution, PrintingDevice = Undefined) Export
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		If NotificationOnCompletion <> Undefined Then
			ErrorDescription = NStr("vi = 'Chưa chọn thiết bị hoặc không có kết nối.';
									|ru = 'Устройство не выбрано или не подключено.';
									|en = 'Device is not selected or not connected.'; fa = 'Device is not selected or not connected.';
									|it = 'Dispositivo non selezionato oppure non connesso.';
									|pl = 'Urządzenie nie jest wybrane lub podłączone.';
									|tr = 'Cihaz seçilmedi veya bağlı değil.'");
			OperationResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
			RunCallback(NotificationOnCompletion, OperationResult);
		EndIf;
		Return; 
	EndIf;          
	
#If Not MobileAppClient Then 
	// Performance measurement.
	KeyOperation = StrTemplate("CommonModule.EquipmentManagerClient.StartCommandExecution.%1", ParametersCommandExecution.Command);
	CommonCELClient.BPOTimeMeasurement(KeyOperation, NotificationOnCompletion);
#EndIf          
	
	ParametersCommandExecution.Insert("NotificationOnCompletion"   , NotificationOnCompletion);  
	ParametersCommandExecution.Insert("ClientID"      , ClientID);
	ParametersCommandExecution.Insert("DeviceID"   , DeviceID);
	ParametersCommandExecution.Insert("OperationParametersList"         , OperationParametersList);
	ParametersCommandExecution.Insert("Attached"                , False);
	ParametersCommandExecution.Insert("ConnectedDevice"    , Undefined);
	ParametersCommandExecution.Insert("PrintingDevice"           , PrintingDevice);
	ParametersCommandExecution.Insert("PrinterIsConnected"      , False);   
	ParametersCommandExecution.Insert("PrintingDeviceWasConnected", False);   
	ParametersCommandExecution.Insert("NetworkEquipment");
	ParametersCommandExecution.Insert("PrinterOfAdditionalDocuments"); 
	ParametersCommandExecution.Insert("ConnectedPrinterOfAdditionalDocuments");
	
	// Search for the connected device.
	ConnectedDevice = GetConnectedDevice(DeviceID);                                                
	If ConnectedDevice = Undefined Then
		CallbackDescription = New CallbackDescription("StartCommandExecution_ConnectionCompletion", ThisObject, ParametersCommandExecution);
		StartConnectingEquipmentById(CallbackDescription, ClientID, DeviceID);
	Else
		ParametersCommandExecution.ConnectedDevice = ConnectedDevice;
		// Whether to use a printer.
		If ParametersCommandExecution.UsePrintingDevice And ParametersCommandExecution.PrintingSlipReceipt
			And Not ConnectedDevice.PrintSlipOnTerminal Then
			CallbackDescription = New CallbackDescription("StartExecutingPrinterS_CommandEnd", ThisObject, ParametersCommandExecution);
			StartConnectingPrinter(CallbackDescription, ParametersCommandExecution.ClientID, PrintingDevice); 
		Else
			ExecutingHandlerCommand(ConnectedDevice, ParametersCommandExecution);
		EndIf;
	EndIf;
	                                    
EndProcedure

// Completing the hardware connection
// 
// Parameters:
//  ConnectionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartCommandExecution_ConnectionCompletion(ConnectionResult, ParametersCommandExecution) Export
	
	If ConnectionResult.Result Then  
		
		ConnectedDevice = ConnectionResult.ConnectedDevice;
		ParametersCommandExecution.ConnectedDevice = ConnectedDevice;
		ParametersCommandExecution.Attached = True;
		
		// Whether to use a printer.
		If ParametersCommandExecution.UsePrintingDevice And ParametersCommandExecution.PrintingSlipReceipt
			And Not ConnectedDevice.PrintSlipOnTerminal Then
			CallbackDescription = New CallbackDescription("StartExecutingPrinterS_CommandEnd", ThisObject, ParametersCommandExecution);
			StartConnectingPrinter(CallbackDescription, ParametersCommandExecution.ClientID, ParametersCommandExecution.PrintingDevice); 
		Else
			ExecutingHandlerCommand(ConnectedDevice, ParametersCommandExecution);
		EndIf;
		
	Else
		MessageText = StrTemplate(NStr("vi = 'Khi kết nối thiết bị, đã xảy ra lỗi: %1';
										|ru = 'При подключении оборудования произошла ошибка: %1';
										|en = 'Equipment connection error: %1.'; fa = 'Equipment connection error: %1.';
										|it = 'Durante la connessione dell''apparecchiatura si è verificato un errore: %1';
										|pl = 'Przy podłączeniu sprzętu wystąpił błąd: %1';
										|tr = 'Ekipman bağlanırken hata oluştu: %1'"), ConnectionResult.ErrorDescription);
		OperationResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageText);
		OperationResult.DeviceID = ParametersCommandExecution.DeviceID;
		RunCallback(ParametersCommandExecution.NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Completing the printer connection
// 
// Parameters:
//  ConnectionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartExecutingPrinterS_CommandEnd(ConnectionResult, ParametersCommandExecution) Export
	
	If ConnectionResult.Result Then  
		ParametersCommandExecution.PrintingDevice = ConnectionResult.DeviceID;
		ParametersCommandExecution.PrinterIsConnected = True;  
		
		If ConnectionResult.Property("PrintingDeviceWasConnected") And ConnectionResult.PrintingDeviceWasConnected Then
			ParametersCommandExecution.PrintingDeviceWasConnected = True;
		EndIf;
		ExecutingHandlerCommand(ParametersCommandExecution.ConnectedDevice, ParametersCommandExecution);
	Else
		MessageText = StrTemplate(NStr("vi = 'Khi kết nối thiết bị in, đã xảy ra lỗi: %1';
										|ru = 'При подключении печатающего устройства произошла ошибка: %1';
										|en = 'An error occurred when connecting a printer: %1'; fa = 'An error occurred when connecting a printer: %1';
										|it = 'Durante la connessione del dispositivo di stampa si è verificato un errore: %1';
										|pl = 'Przy podłączeniu urządzenia drukującego wystąpił błąd: %1.';
										|tr = 'Yazdırma cihaz; bağlanırken hata oluştu: %1'"), ConnectionResult.ErrorDescription); 
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageText);
		ExecutionResult.DeviceID = ConnectionResult.DeviceID;
		// Disconnecting equipment when completing
		DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
	EndIf;
	
EndProcedure

// Completing the command execution
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersCommandExecution - Structure:
//   * OperationParametersList - Structure:
//      ** ProcessData__ - Boolean
//      ** ProcessDataInCaseOfError - Boolean
//      ** UsePrintingDevice - Boolean
//      ** AdditionalParameters - Structure
// 
Procedure StartCommandExecution_Completion(ExecutionResult, ParametersCommandExecution) Export
	
	// Processing data on the server after executing the command
	If (ExecutionResult.Result And ParametersCommandExecution.ProcessData__)
		Or (ParametersCommandExecution.Property("ProcessDataInCaseOfError") And ParametersCommandExecution.ProcessDataInCaseOfError) Then
		
		ConnectionParametersServer = EquipmentManagerClientServer.ConnectionParameters(ParametersCommandExecution.ConnectedDevice);   
		ConnectionParametersServer.Insert("DeviceID", ParametersCommandExecution.DeviceID);
		ProcessorOfData = ParametersCommandExecution.ProcessorOfData;
		Command = ParametersCommandExecution.Command;
		// We call the module responsible for data processing after executing the Commands on the equipment.
		EquipmentManagerServerCall.ProcessOperationData(ConnectionParametersServer, ProcessorOfData, Command, ExecutionResult, ParametersCommandExecution.OperationData); 
	EndIf;
	
	If (ExecutionResult.Result And ParametersCommandExecution.ProcessData__Client) Then
		ConnectionParametersServer = EquipmentManagerClientServer.ConnectionParameters(ParametersCommandExecution.ConnectedDevice);   
		ConnectionParametersServer.Insert("DeviceID", ParametersCommandExecution.DeviceID);
		ProcessorOfData = ParametersCommandExecution.ProcessorOfData + "Client";
		Command = ParametersCommandExecution.Command;
		// We call the module responsible for data processing after executing the Commands on the equipment.
		EquipmentManagerClient.ProcessOperationData(ConnectionParametersServer, ProcessorOfData, Command, ExecutionResult, ParametersCommandExecution.OperationData); 
	EndIf;
	
	If ExecutionResult.Property("DeviceID") And Not ValueIsFilled(ExecutionResult.DeviceID) Then 
		ExecutionResult.DeviceID = ParametersCommandExecution.DeviceID;
	EndIf;
	
	If ExecutionResult.Result Then
		If ParametersCommandExecution.Property("OperationParametersList") 
			And ParametersCommandExecution.OperationParametersList <> Undefined
			And ParametersCommandExecution.OperationParametersList.Property("AdditionalParameters") Then
			ExecutionResult.Insert("AdditionalParameters", ParametersCommandExecution.OperationParametersList.AdditionalParameters);
		EndIf;
		
		If ParametersCommandExecution.Command = "CheckFiscalization" Then                                                                                   
			If ExecutionResult.Property("MTDisposalReport") And ExecutionResult.MTDisposalReport.Count()>0 Then                  
				EquipmentManagerClientOverridable.WhenFiscalizingReceiptWithMarkedGoods(ParametersCommandExecution.DeviceID, ExecutionResult.MTDisposalReport);
			EndIf;
		EndIf;
	Else          
		AdditionalErrorHandling(ExecutionResult);
		If ParametersCommandExecution.Command = "CheckFiscalization"
			And ParametersCommandExecution.Property("NotificationInCaseOfReceiptPrintingError")
			And ParametersCommandExecution.NotificationInCaseOfReceiptPrintingError <> Undefined Then
				OperationData = ParametersCommandExecution.OperationData;
				ExecutionParameters = New Structure();
				ExecutionParameters.Insert("InputParameters", ParametersCommandExecution.OperationData);
				ExecutionParameters.Insert("ErrorDescription"  , Undefined); 
				ExecutionParameters.Insert("ContinuePrinting", True);
				ExecutionParameters.Insert("ContinueNotification", Undefined);
				FillInParametersOfReceiptSigningOperation(ExecutionParameters, OperationData.CREShiftNumber, OperationData.KKTReceiptNumber, OperationData.ManufaturerNumberOfFiscalStorage); 
				RunCallback(ParametersCommandExecution.NotificationInCaseOfReceiptPrintingError, ExecutionParameters);
		EndIf;
	EndIf;                        
	
	If ParametersCommandExecution.UsePrintingDevice 
		And ParametersCommandExecution.PrinterIsConnected And ExecutionResult.Property("TestReceipts") Then
		// Search for the connected device.
		PrintingDevice = GetConnectedDevice(ParametersCommandExecution.PrintingDevice);                                                
		If PrintingDevice = Undefined Then
			ErrorText = NStr("vi = 'Lỗi in phiếu cuối. Đã hủy giao dịch.';
							|ru = 'Ошибка печати слип чека. Операция отменена.';
							|en = 'An error occurred when printing the sales slip. The transaction is canceled.'; fa = 'An error occurred when printing the sales slip. The transaction is canceled.';
							|it = 'Errore di stampa stile scontrino. Operazione annullata.';
							|pl = 'Błąd drukowania paragonu z terminalu. Operacja została anulowana.';
							|tr = 'Slip fiş yazdırılırken hata oluştu. İşlem iptal edildi.'");
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorText, ParametersCommandExecution.DeviceID);
			// Equipment shutdown.
			DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
		Else
			If ExecutionResult.Property("SlipReceiptText") And Not IsBlankString(ExecutionResult.SlipReceiptText) Then
				Peripherals = Peripherals();
				Peripherals.Insert("LastSlipCheck", ExecutionResult.SlipReceiptText);
			EndIf;
			// The result of the original operation
			ParametersCommandExecution.Insert("ExecutionResult", ExecutionResult);
			CallbackDescription = New CallbackDescription("StartExecuting_PrintEndCommand", ThisObject, ParametersCommandExecution);
			PrintingDevice.DriverHandler.StartCommandExecution(CallbackDescription, PrintingDevice, "PrintText", ExecutionResult);
		EndIf;
	ElsIf ParametersCommandExecution.Property("OperationParametersList")
		And ParametersCommandExecution.OperationParametersList <> Undefined
		And ParametersCommandExecution.OperationParametersList.Property("PrintDevice")
		And ParametersCommandExecution.OperationParametersList.Property("DocumentsPackage") 
		And (ValueIsFilled(ParametersCommandExecution.OperationParametersList.PrintDevice) 
		Or ValueIsFilled(ParametersCommandExecution.OperationParametersList.DocumentsPackage)) Then
			StartConnectingDeviceForPrintingAdditionalDocuments(ExecutionResult, ParametersCommandExecution);
	Else
		// Equipment shutdown.
		DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
	EndIf;
	
EndProcedure

// Connection of printing equipment.
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartConnectingDeviceForPrintingAdditionalDocuments(ExecutionResult, ParametersCommandExecution) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ExecutionResult", ExecutionResult);
	AdditionalParameters.Insert("ParametersCommandExecution", ParametersCommandExecution);
	AdditionalParameters.Insert("DevicesToConnect", 0);
	AdditionalParameters.Insert("DevicesToBeConnected", 0);
	AdditionalParameters.Insert("ArrayOfDevicesToConnect", New Array);
	AdditionalParameters.Insert("CopyOfReceiptMustBePrinted", True);
	
	PrintingDevice = GetConnectedDevice(ParametersCommandExecution.OperationParametersList.PrintDevice);
	If PrintingDevice = Undefined And ValueIsFilled(ParametersCommandExecution.OperationParametersList.PrintDevice) Then
		AdditionalParameters.ArrayOfDevicesToConnect.Add(ParametersCommandExecution.OperationParametersList.PrintDevice);
		AdditionalParameters.DevicesToConnect = 1;
	ElsIf PrintingDevice <> Undefined Then
		AdditionalParameters.ParametersCommandExecution.ConnectedPrinterOfAdditionalDocuments = PrintingDevice;
		AdditionalParameters.ParametersCommandExecution.PrinterOfAdditionalDocuments = PrintingDevice.DeviceID;
	Else
		AdditionalParameters.CopyOfReceiptMustBePrinted = False;
	EndIf;
	
	For Each DeviceCompliance In ParametersCommandExecution.OperationParametersList.DocumentsPackage Do
		If AdditionalParameters.ArrayOfDevicesToConnect.Find(DeviceCompliance.Value) = Undefined 
			And GetConnectedDevice(DeviceCompliance.Value) = Undefined Then
			AdditionalParameters.ArrayOfDevicesToConnect.Add(DeviceCompliance.Value);
			AdditionalParameters.DevicesToConnect = AdditionalParameters.DevicesToConnect + 1;
		EndIf;
	EndDo;
	
	If AdditionalParameters.DevicesToConnect > 0 Then
		CallbackDescription = New CallbackDescription("StartCommandExecution_PrintingAdditionalDocuments", ThisObject, AdditionalParameters);
		StartConnectingEquipmentById(CallbackDescription, ParametersCommandExecution.ClientID, AdditionalParameters.ArrayOfDevicesToConnect);
	Else
		StartCommandExecution_PrintingAdditionalDocuments(ExecutionResult, AdditionalParameters);
	EndIf;
	
EndProcedure

// Printing additional documents.
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersExecution - Structure
// 
Procedure StartCommandExecution_PrintingAdditionalDocuments(ExecutionResult, ParametersExecution) Export
	
	If ExecutionResult.Result Then
		
		ParametersExecution.DevicesToBeConnected = ParametersExecution.DevicesToBeConnected + 1;
		If ParametersExecution.DevicesToBeConnected < ParametersExecution.DevicesToConnect Then
			Return;
		EndIf;
		
		If ParametersExecution.ParametersCommandExecution.Property("CopyIsPrintedOut") And ParametersExecution.ParametersCommandExecution.CopyIsPrintedOut 
			Or Not ParametersExecution.CopyOfReceiptMustBePrinted Then
			
			Command = "PrintText";
			PrintCompliance = ParametersExecution.ParametersCommandExecution.OperationData.AdditionalDocuments_;
			DocumentSeals = PrintCompliance.Get(0); 

			PrintDevice = GetConnectedDevice(DocumentSeals.PrintDevice);
			OperationData = New Structure;
			OperationData.Insert("TestReceipts", New Array);
			OperationData.TestReceipts = DocumentSeals.PrintText_;

			ParametersExecution.Insert("ExecutionResult", ExecutionResult);
			ParametersExecution.ParametersCommandExecution.OperationData.AdditionalDocuments_.Delete(0);
			CallbackDescription = New CallbackDescription("StartCommandExecution_PrintingAdditionalDocumentsCompletion", ThisObject, ParametersExecution);
			PrintDevice.DriverHandler.StartCommandExecution(CallbackDescription, PrintDevice, Command, OperationData);
			
		Else
			
			ParametersCommandExecution = ParametersExecution.ParametersCommandExecution;
			Command                    = "PrintText";
			OperationData             = ParametersCommandExecution.OperationData;
			If Not ValueIsFilled(ParametersCommandExecution.PrinterOfAdditionalDocuments) Then
				ParametersCommandExecution.PrinterOfAdditionalDocuments = ExecutionResult.DeviceID;
				ParametersCommandExecution.ConnectedPrinterOfAdditionalDocuments = ExecutionResult.ConnectedDevice;
			EndIf;
			ConnectionParameters = ParametersCommandExecution.ConnectedPrinterOfAdditionalDocuments;
			DriverHandler = ParametersCommandExecution.ConnectedPrinterOfAdditionalDocuments.DriverHandler;
			
			ParametersExecution.Insert("ExecutionResult", ExecutionResult); 
			CallbackDescription = New CallbackDescription("StartCommandExecution_PrintingAdditionalDocumentsCompletion", ThisObject, ParametersExecution);
			DriverHandler.StartCommandExecution(CallbackDescription, ConnectionParameters, Command, OperationData);
		
		EndIf;
		
	Else
		StartCommandExecution_PrintingAdditionalDocumentsCompletion(ExecutionResult, ParametersExecution);
	EndIf;
	
EndProcedure

// End printing additional documents.
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersExecution - Structure
// 
Procedure StartCommandExecution_PrintingAdditionalDocumentsCompletion(ExecutionResult, ParametersExecution) Export
	
	If ExecutionResult.Result Then
		AdditionalDocuments_ = ParametersExecution.ParametersCommandExecution.OperationData.AdditionalDocuments_;
		If ParametersExecution.ParametersCommandExecution.Property("CopyIsPrintedOut") And ParametersExecution.ParametersCommandExecution.CopyIsPrintedOut And AdditionalDocuments_.Count() > 0 Then
			StartCommandExecution_PrintingAdditionalDocuments(ExecutionResult, ParametersExecution);
		ElsIf Not ParametersExecution.ParametersCommandExecution.Property("CopyIsPrintedOut") And AdditionalDocuments_.Count() > 0 Then
			ParametersExecution.ParametersCommandExecution.Insert("CopyIsPrintedOut", True);
			StartCommandExecution_PrintingAdditionalDocuments(ExecutionResult, ParametersExecution);
		Else
			// Equipment shutdown.
			DisableHardwareAfterExecutingCommand(ParametersExecution.ParametersCommandExecution, ParametersExecution.ExecutionResult);
		EndIf;
	Else
		
		MessageText = StrTemplate(
		NStr("vi = 'Khi in chứng từ bổ sung, đã xảy ra lỗi: %1';
			|ru = 'При печати дополнительных документов произошла ошибка: %1';
			|en = 'An error occurred when printing additional documents: %1'; fa = 'An error occurred when printing additional documents: %1';
			|it = 'При печати дополнительных документов произошла ошибка: %1';
			|pl = 'An error occurred when printing additional documents: %1';
			|tr = 'Ek belgeler yazdırılırken hata oluştu: %1'"),
		ExecutionResult.ErrorDescription);
		CommonCELClient.MessageToUser(MessageText);
		If CommonCELClient.BasicFunctionalityIsUsed() Then
			
			If ExecutionResult.Property("ErrorDescription") Then
				MessageText = MessageText + Chars.LF + ExecutionResult.ErrorDescription;
			EndIf;
			
			Try
				ClientRegistrationLogModule = CommonCELClient.CommonModule("EventLogClient");
				ClientRegistrationLogModule.AddMessageForEventLog(
				NStr("vi = 'Thiết bị kết nối.';
					|ru = 'Подключаемое оборудование.';
					|en = 'Peripherals.'; fa = 'Peripherals.';
					|it = 'Apparecchiatura collegata';
					|pl = 'Urządzenia peryferyjne.';
					|tr = 'Bağlanabilir donanım.'"),
				"Error", 
				MessageText);
			Except
				CommonCELClient.MessageToUser(ExecutionResult.ErrorDescription);
			EndTry;
		EndIf;
		
		// Equipment shutdown.
		DisableHardwareAfterExecutingCommand(ParametersExecution.ParametersCommandExecution, ParametersExecution.ExecutionResult);
		
	EndIf;
	
EndProcedure

// Finishing printing
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartExecuting_PrintEndCommand(ExecutionResult, ParametersCommandExecution) Export
	
	If ExecutionResult.Result Then
		// Equipment shutdown.
		DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ParametersCommandExecution.ExecutionResult);
	Else
		// With the "AuthorizeVoid" command, an emergency cancellation of the last cancellation operation cannot be performed
		If ParametersCommandExecution.Command = "AuthorizeVoid" Then
			// Equipment shutdown.
			DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ParametersCommandExecution.ExecutionResult);
		// with the "Settlement" command, an emergency cancellation of the last operation cannot be performed
		ElsIf ParametersCommandExecution.Command = "Settlement" Then
			
			MessageText = StrTemplate(
				NStr("vi = 'Khi nhận tổng kết ngày theo thẻ, đã xảy ra lỗi in phiếu cuối.
					|Trên thiết bị in không hỗ trợ in các tài liệu văn bản.
					|Thiết bị: %1
					|Thiết bị in: %2';
					|ru = 'При получении итогов дня по картам, произошла ошибка печати слип чека.
					|На печатающем устройстве не поддерживается печать текстовых документов.
					|Терминал: %1
					|Печатающее устройство: %2';
					|en = 'When receiving totals reconciliation by cards, an error occurred when printing a sales slip.
					|The printer does not print text documents.
					| Terminal: %1
					|Printer: %2'; fa = 'When receiving totals reconciliation by cards, an error occurred when printing a sales slip.
					|The printer does not print text documents.
					| Terminal: %1
					|Printer: %2';
					|it = 'Si è verificato un errore di stampa dello scontrino durante la ricezione dei totali delle carte del giorno.
					|Il dispositivo di stampa non supporta la stampa di documenti di testo.
					|Terminale: %1
					|Dispositivo di stampa: %2';
					|pl = 'Podczas otrzymania wyników dnia według kart, wystąpił błąd drukowania paragonu karty płatniczej.
					|Na drukarce nie jest obsługiwane drukowanie dokumentów tekstowych.
					|Terminal: %1
					|Drukarka: %2';
					|tr = 'Kartlardaki günün sonuçları alınırken slip fişi yazdırılırken hata oluştu.
					|Yazdırma cihazı metin belgelerinin yazdırılmasını desteklemiyor.
					|Terminal: %1
					|Yazdırma cihazı: %2'"),
				ParametersCommandExecution.DeviceID,
				ParametersCommandExecution.PrintingDevice);
			CommonCELClient.MessageToUser(MessageText);
			If CommonCELClient.BasicFunctionalityIsUsed() Then
				
				If ExecutionResult.Property("ErrorDescription") Then
					MessageText = MessageText + Chars.LF + ExecutionResult.ErrorDescription;
				EndIf;
				
				Try
					CommonCELClient.WriteErrorToEventLog(
						NStr("vi = 'Thiết bị kết nối.';
							|ru = 'Подключаемое оборудование.';
							|en = 'Peripherals.'; fa = 'Peripherals.';
							|it = 'Apparecchiatura collegata';
							|pl = 'Urządzenia peryferyjne.';
							|tr = 'Bağlanabilir donanım.'"),
						MessageText);
				Except
					CommonCELClient.MessageToUser(ExecutionResult.ErrorDescription);
				EndTry;
			EndIf;
			
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, MessageText, ParametersCommandExecution.DeviceID);
			// Equipment shutdown.
			DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
		Else
			
			ParametersCommandExecution.Insert("ErrorDescription", ExecutionResult.ErrorDescription);
			MessageText = ExecutionResult.ErrorDescription + Chars.LF
				+ NStr("vi = 'Tiếp tục không in phiếu cuối?';
						|ru = 'Продолжить без печати слип-чека?';
						|en = 'Continue without printing a sales slip?'; fa = 'Continue without printing a sales slip?';
						|it = 'Продолжить без печати слип-чека?';
						|pl = 'Continue without printing a sales slip?';
						|tr = 'Slip çek yazdırmadan devam edilsin mi?'") + Chars.LF
				+ NStr("vi = 'CHÚ Ý:';
						|ru = 'ВНИМАНИЕ:';
						|en = 'WARNING:'; fa = 'WARNING:';
						|it = 'ВНИМАНИЕ:';
						|pl = 'WARNING:';
						|tr = 'DİKKAT:'") + Chars.LF
				+ NStr("vi = 'Khi hủy, sẽ thực hiện hủy bỏ giao dịch trên thiết bị thanh toán thẻ.';
						|ru = 'При отмене выполнится отмена операции на эквайринговом терминале.';
						|en = 'Upon cancellation, the transaction on the POS terminal will be canceled.'; fa = 'Upon cancellation, the transaction on the POS terminal will be canceled.';
						|it = 'При отмене выполнится отмена операции на эквайринговом терминале.';
						|pl = 'Upon cancellation, the transaction on the POS terminal will be canceled.';
						|tr = 'İptal işlemi, PoS terminalindeki işlemi iptal edecektir.'") + Chars.LF
				+ NStr("vi = 'Chuẩn bị thẻ ngân hàng của người mua.';
						|ru = 'Подготовьте банковскую карту покупателя.';
						|en = 'Prepare the customer bank card.'; fa = 'Prepare the customer bank card.';
						|it = 'Подготовьте банковскую карту покупателя.';
						|pl = 'Prepare the customer bank card.';
						|tr = 'Alıcının banka kartını hazırlayın.'");
			Notification = New CallbackDescription("StartExecuting_CommandsAfterClosingQuestion", ThisObject, ParametersCommandExecution);
			ShowQueryBox(Notification, MessageText, QuestionDialogMode.OKCancel, ,, NStr("vi = 'Xảy ra lỗi khi in phiếu cạnh phiếu cuối';
																						|ru = 'При печати слип-чека произошла ошибка';
																						|en = 'An error occurred when printing a sales slip'; fa = 'An error occurred when printing a sales slip';
																						|it = 'При печати слип-чека произошла ошибка';
																						|pl = 'An error occurred when printing a sales slip';
																						|tr = 'Slip çek yazdırılırken bir hata oluştu'"));  
			
		EndIf;
	EndIf;
	
EndProcedure  

// Completing the cancellation of the operation
// 
// Parameters:
//  ExecutionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartCommandExecution_CancelingOperationAndEndingIt(ExecutionResult, ParametersCommandExecution) Export
	
	If CommonCELClient.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystemsClientServer = CommonCELClient.CommonModule("PeripheralsPaymentSystemsServerClientServer");
		OperationParametersList = ModuleEquipmentPaymentSystemsClientServer.ParametersOfAcquiringOperation();
		FillPropertyValues(OperationParametersList, ParametersCommandExecution.OperationData, , "QueryID");
		LoggingOfCELOperationsInternalServerCall.RecordPaymentOfOperation(PredefinedValue("Enum.PaymentTransactionTypes.AbnormalCancellation"), OperationParametersList, ExecutionResult);
	EndIf;
	
	If ExecutionResult.Result Then
		MessageText = NStr("vi = 'Đã hủy giao dịch thanh toán thẻ - lỗi in phiếu cuối đã xảy ra lỗi.';
							|ru = 'Эквайринговая операция отменена - ошибка печати слип чека возникла ошибка.';
							|en = 'Acquiring transaction is canceled - an error occurred when printing a sales slip.'; fa = 'Acquiring transaction is canceled - an error occurred when printing a sales slip.';
							|it = 'Operazione di acquisizione annullata - errore di stampa ricevuta POS si è verificato un errore.';
							|pl = 'Operacja acquiringu została anulowana - błąd drukowania paragonu z terminalu wystąpił błąd.';
							|tr = 'PoS işlemi iptal edildi; slip fiş yazdırılırken hata oluştu.'");
	Else
		MessageText = NStr("vi = 'Lỗi hủy giao dịch trực tác. Hãy liên hệ với ngân hàng.';
							|ru = 'Ошибка отмены операции транзакции. Обратитесь в банк.';
							|en = 'An error occurred when canceling the transaction operation. Contact your bank.'; fa = 'An error occurred when canceling the transaction operation. Contact your bank.';
							|it = 'Errore annullate operazioni di transazione. Rivolgersi alla banca.';
							|pl = 'Błąd anulowania operacji transakcji. Zwróć się do banku.';
							|tr = 'İşlem operasyonu iptal edilirken hata oluştu. Bankayla iletişime geç.'");
	EndIf;
	
	If ParametersCommandExecution.Property("ErrorDescription") Then
		MessageText = MessageText + Chars.LF + ParametersCommandExecution.ErrorDescription;
	EndIf;
	
	ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageText, ParametersCommandExecution.DeviceID);
	// Equipment shutdown.
	DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ExecutionResult);
	
EndProcedure  

// Disabling equipment 
// 
// Parameters:
//  ParametersCommandExecution - Structure
//  OperationResult - Structure
//
Procedure DisableHardwareAfterExecutingCommand(ParametersCommandExecution, OperationResult = Undefined) Export
	
	If ParametersCommandExecution.Property("PrinterOfAdditionalDocuments") And ValueIsFilled(ParametersCommandExecution.PrinterOfAdditionalDocuments) Then
		Start_DisablingEquipmentById(Undefined, ParametersCommandExecution.ClientID, ParametersCommandExecution.PrinterOfAdditionalDocuments);
	EndIf;
	
	ContextUsedToPerformCheck = New Structure();   
	ContextUsedToPerformCheck.Insert("OperationResult", OperationResult);
	ContextUsedToPerformCheck.Insert("ParametersCommandExecution", ParametersCommandExecution);
	
	If ParametersCommandExecution.PrinterIsConnected And Not ParametersCommandExecution.PrintingDeviceWasConnected Then                               
			DisconnectionAlert = New CallbackDescription("DisableEquipmentAfterExecutingCommands_DisablePrinterEnd", ThisObject, ContextUsedToPerformCheck);
		Start_DisablingEquipmentById(DisconnectionAlert, ParametersCommandExecution.ClientID, ParametersCommandExecution.PrintingDevice);
	Else
		DisableEquipmentAfterExecutingCommands_DisablePrinterEnd(Undefined, ContextUsedToPerformCheck);
	EndIf;     
	
EndProcedure                  

// End of equipment shutdown
// 
Procedure DisableEquipmentAfterExecutingCommands_DisablePrinterEnd(ShutdownResult, ContextUsedToPerformCheck) Export
	
	ParametersCommandExecution = ContextUsedToPerformCheck.ParametersCommandExecution;
	OperationResult = ContextUsedToPerformCheck.OperationResult;    
	
	NetworkEquipment = ParametersCommandExecution.ConnectedDevice.NetworkEquipment;
	DisablingEquipment = ParametersCommandExecution.Attached;
	LeaveConnected = False;
	
	If ParametersCommandExecution.Property("LeaveConnected") And ParametersCommandExecution.LeaveConnected Then
		DisablingEquipment = False;
		LeaveConnected = ParametersCommandExecution.LeaveConnected;
	EndIf;
	
	If DisablingEquipment Or (NetworkEquipment And Not LeaveConnected) Then
		
			If OperationResult <> Undefined Then
				ContextUsedToPerformCheck = New Structure();   
				ContextUsedToPerformCheck.Insert("OperationResult", OperationResult);
				ContextUsedToPerformCheck.Insert("ParametersCommandExecution", ParametersCommandExecution);
				DisconnectionAlert = New CallbackDescription("DisableEquipmentAfterExecutingCommands_DisableEnd", ThisObject, ContextUsedToPerformCheck);
			Else  
				DisconnectionAlert = Undefined;
			EndIf; 
			
		Start_DisablingEquipmentById(DisconnectionAlert, ParametersCommandExecution.ClientID, ParametersCommandExecution.DeviceID);
		
	Else   
		If OperationResult <> Undefined Then
			EndExecutionOfCommand(OperationResult, ParametersCommandExecution);
		EndIf;
	EndIf;
	
EndProcedure 

// End of equipment shutdown
// 
Procedure DisableEquipmentAfterExecutingCommands_DisableEnd(ShutdownResult, ContextUsedToPerformCheck) Export
	
	ParametersCommandExecution = ContextUsedToPerformCheck.ParametersCommandExecution;
	OperationResult = ContextUsedToPerformCheck.OperationResult;           
	
	EndExecutionOfCommand(OperationResult, ParametersCommandExecution);
	
EndProcedure 

// Start getting device parameters
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification description event.
//  ClientID - UUID - the unique identifier of the client.
//  DeviceID - CatalogRef.Peripherals - connected device.
//
Procedure BeginGettingOfDeviceParameters(NotificationOnCompletion, ClientID, DeviceID) Export
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then
		If NotificationOnCompletion <> Undefined Then
			ErrorDescription = NStr("vi = 'Chưa chọn thiết bị hoặc không kết nối.';
									|ru = 'Устройство не выбрано или не подключено.';
									|en = 'Device is not selected or not connected.'; fa = 'Device is not selected or not connected.';
									|it = 'Dispositivo non selezionato oppure non connesso.';
									|pl = 'Urządzenie nie jest wybrane lub podłączone.';
									|tr = 'Cihaz seçilmedi veya bağlı değil.'");
			OperationResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
			RunCallback(NotificationOnCompletion, OperationResult);
		EndIf;
		Return;
	EndIf;

	// Search for the connected device.
	ConnectedDevice = GetConnectedDevice(DeviceID);      
	If ConnectedDevice = Undefined Then
		ParametersCommandExecution = New Structure();
		ParametersCommandExecution.Insert("NotificationOnCompletion", NotificationOnCompletion);  
		ParametersCommandExecution.Insert("ClientID"   , ClientID);
		ParametersCommandExecution.Insert("DeviceID", DeviceID);
		CallbackDescription = New CallbackDescription("StartGettingDeviceParameters_ConnectionEnd", ThisObject, ParametersCommandExecution);
		StartConnectingEquipmentById(CallbackDescription, ClientID, DeviceID);
	Else                                                                                                                       
		OfDeviceParameters = EquipmentManagerClientServer.ConnectionParameters(ConnectedDevice);
		OperationResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, Undefined, DeviceID);
		OperationResult.ConnectedDevice = ConnectedDevice; 
		OperationResult.Insert("OfDeviceParameters", OfDeviceParameters);
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;    
	
EndProcedure

// Completing the hardware connection
// 
// Parameters:
//  ConnectionResult - Structure
//  ParametersCommandExecution - Structure
// 
Procedure StartGettingDeviceParameters_ConnectionEnd(ConnectionResult, ParametersCommandExecution) Export
	
	If ConnectionResult.Result Then  
		ConnectedDevice = ConnectionResult.ConnectedDevice;   
		OfDeviceParameters = EquipmentManagerClientServer.ConnectionParameters(ConnectedDevice);  
		ConnectionResult.Insert("OfDeviceParameters", OfDeviceParameters);
		RunCallback(ParametersCommandExecution.NotificationOnCompletion, ConnectionResult);
		Start_DisablingEquipmentById(Undefined, ParametersCommandExecution.ClientID, ParametersCommandExecution.DeviceID);
	Else
		RunCallback(ParametersCommandExecution.NotificationOnCompletion, ConnectionResult);
	EndIf;
	
EndProcedure

// Starts of operation on the acquiring terminal.
// 
Procedure StartExecuting_CommandsAfterClosingQuestion(Result, ParametersCommandExecution) Export
	
	If Result = DialogReturnCode.Cancel Then    
		ConnectedDevice = ParametersCommandExecution.ConnectedDevice;
		CallbackDescription = New CallbackDescription("StartCommandExecution_CancelingOperationAndEndingIt", ThisObject, ParametersCommandExecution);
		ConnectedDevice.DriverHandler.StartCommandExecution(CallbackDescription, ConnectedDevice, "EmergencyVoid", ParametersCommandExecution.OperationData);  
	Else
		// Equipment shutdown.
		DisableHardwareAfterExecutingCommand(ParametersCommandExecution, ParametersCommandExecution.ExecutionResult);
	EndIf;
	
EndProcedure  

// The function calls the procedure for preparing of operation data on the server.
//
// Parameters:
//  ConnectionParameters - Structure - hardware connection parameters.   
//  ProcessorOfData - String - Data processing module. 
//  Command - String - name of the command to run. 
//  OperationParametersList - Structure - Parameters of operation being performed.   
//
// Returns:
//  Structure
//
Function PrepareOperationData(ConnectionParameters, ProcessorOfData, Command, OperationParametersList, OperationData) Export 
	
	ModuleDataProcessor = CommonCELClient.CommonModule(ProcessorOfData);
	Return ModuleDataProcessor.PrepareOperationData(ConnectionParameters, Command, OperationParametersList, OperationData);
	
EndFunction

// The function calls the procedure for preparing of operation data on the server.
//
// Parameters:
//  ConnectionParameters - Structure - hardware connection parameters.   
//  ProcessorOfData - String - Data processing module. 
//  Command - String - Name of the command being executed. 
//  Operation parameters - Structure - Parameters of the operation being performed.   
//
// Returns:
//  Structure
//
Procedure ProcessOperationData(ConnectionParameters, ProcessorOfData, Command, ExecutionResult, OperationData) Export 
	
	ModuleDataProcessor = CommonCELClient.CommonModule(ProcessorOfData);
	ModuleDataProcessor.ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData);
	
EndProcedure

#EndRegion

#Region Interface_1
 
// To set up the equipment.
// 
// Parameters:
//  Id - CatalogRef.Peripherals
//  NotificationOnCompletion - CallbackDescription - notification description event.
// 
Procedure ConfigureHardware(Id, NotificationOnCompletion = Undefined) Export
	
#If Not MobileAppClient Then 
	// Performance measurement.
	KeyOperation = "CommonModule.EquipmentManagerClient.ConfigureHardware";
	CommonCELClient.BPOTimeMeasurement(KeyOperation, Undefined, False, True);
#EndIf
	
	FormSettings = "Catalog.Peripherals.Form.FormSettings";
	CurrentLanguage = CurrentLanguage();
	If TypeOf(CurrentLanguage) = Type("String") Then
		LanguageCode = CurrentLanguage;
	Else
		LanguageCode = CurrentLanguage.LanguageCode;
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("Id", Id);       
	FormParameters.Insert("LanguageCode", LanguageCode);       
	
	CommandParameters = New Structure("NotificationOnCompletion", NotificationOnCompletion);
	Handler = New CallbackDescription("ConfigureHardware_Completion", ThisObject, CommandParameters);
	
	OpenForm(FormSettings, FormParameters,,,  ,, Handler, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// The completion of the hardware settings.
// 
// Parameters:
//  Result - Structure - the result returned by the form when closing.
//  Parameters - Structure - command parameters.
// 
Procedure ConfigureHardware_Completion(Result, Parameters) Export
	
	CompletionResult = False;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Id") And Result.Property("EquipmentParameters") Then
			CompletionResult = EquipmentManagerServerCall.SaveDeviceSettings(Result.Id, Result.EquipmentParameters);
		EndIf;
		
		If CompletionResult Then 
			RefreshReusableValues();
		Else
			ErrorMessage = NStr("vi = 'Không thể lưu tham số thiết bị.';
								|ru = 'Не удалось сохранить параметры устройства.';
								|en = 'Cannot save the device parameters.'; fa = 'Cannot save the device parameters.';
								|it = 'Non è stato possibile salvare i parametri del dispositivo.';
								|pl = 'Nie udało się zapisać parametry urządzenia.';
								|tr = 'Cihaz parametreleri kaydedilemiyor.'");
			CommonCELClient.MessageToUser(ErrorMessage);
		EndIf;
		
	EndIf;
	
	If Parameters.NotificationOnCompletion <> Undefined Then
		RunCallback(Parameters.NotificationOnCompletion, CompletionResult);
	EndIf;
	
EndProcedure

// Opening the form for connected Equipment.
//
// Parameters:
//  CommandParameter - Arbitrary - the source where the command is implemented
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenPeripherals(CommandParameter, CommandExecuteParameters) Export
	
#If Not MobileAppClient Then 
	// Performance measurement.
	KeyOperation = "CommonModule.EquipmentManagerClient.OpenPeripherals";
	CommonCELClient.BPOTimeMeasurement(KeyOperation, Undefined, False, True);
#EndIf
	
	FormParameters = New Structure();
	OpenForm("Catalog.Peripherals.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

// Open the hardware drivers form.
//
// Parameters:
//  CommandParameter - Arbitrary - the source where the command is implemented
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenHardwareDrivers(CommandParameter, CommandExecuteParameters) Export
	
#If Not MobileAppClient Then 
	// Performance measurement.
	KeyOperation = "CommonModule.EquipmentManagerClient.OpenHardwareDrivers";
	CommonCELClient.BPOTimeMeasurement(KeyOperation, Undefined, False, True);
#EndIf
	
	FormParameters = New Structure();
	OpenForm("Catalog.HardwareDrivers.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

// Opening a form for the list of payment transactions
//
// Parameters:
//  CommandParameter - Arbitrary - the source where the command is implemented
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenPaymentTransactions(CommandParameter, CommandExecuteParameters) Export
	
	// ++ Non-mobile application
#If Not MobileAppClient Then 
	// Performance measurement.
	KeyOperation = "CommonModule.EquipmentManagerClient.OpenPaymentTransactions";
	CommonCELClient.BPOTimeMeasurement(KeyOperation, Undefined, False, True);
#EndIf
	
	FormParameters = New Structure();
	OpenForm("InformationRegister.PaymentTransactions.ListForm", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window);
	// -- Non-mobile application
	
EndProcedure

// Opening the list of fiscal transactions form
//
// Parameters:
//  CommandParameter - Arbitrary - the source where the command is implemented
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenFiscalTransactions(CommandParameter, CommandExecuteParameters) Export
	
#If Not MobileAppClient Then 
	// Performance measurement.
	KeyOperation = "CommonModule.EquipmentManagerClient.OpenFiscalTransactions";
	CommonCELClient.BPOTimeMeasurement(KeyOperation, Undefined, False, True);
#EndIf
	
	FormParameters = New Structure();
	OpenForm("InformationRegister.FiscalTransactions.ListForm", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window);
	
EndProcedure

// Opening a form for the list of operations in the receipt queue
//
// Parameters:
//  CommandParameter - Arbitrary - the source where the command is implemented
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenReceiptQueue(CommandParameter, CommandExecuteParameters) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.OpenReceiptQueue(CommandParameter, CommandExecuteParameters);
	EndIf;
	
EndProcedure

// Opening the list form of operation with connected equipment
//
// Parameters:
//  Peripherals - CatalogRef.Peripherals
//
Procedure OpenHardwareOperations(Peripherals) Export
	
	// ++ Non-mobile application
	If CommonCELClient.LoggingSubsystemIsUsed() Then
		FormParameters = New Structure();
		FormParameters.Insert("Filter", New Structure("Equipment", Peripherals));
		OpenForm("InformationRegister.OperationsWithPeripherals.ListForm", FormParameters);
	EndIf;
	// -- Non-mobile application
	
EndProcedure


#EndRegion


#Region Other

// Convert the data from the scanner into an array.
// 
// Parameters:
//  Parameter - Structure:
//   * Barcode - String - barcode.
//   * Count - Number - Quantity.
// 
// Returns:
//  Array of Structure
//
Function ConvertDataFromScannerToArray(Parameter) Export
	
	EquipmentManagerClientOverridable.ProcessEvent(); // APK:222 - For backward compatibility
	
	Data = New Array;
	Data.Add(ConvertDataFromScannerToStructure(Parameter));
	
	Return Data;
	
EndFunction

// Convert the data from the scanner into a structure.
// 
// Parameters:
//  Parameter - Structure - Parameter:
//   * Barcode - String - barcode.
//   * Count - Number - Quantity.
// 
// Returns:
//  Structure - Convert Data From Scanner To Structure:
//   * Barcode - String - barcode from the scanner.
//   * Count - Number - amount of goods.
//
Function ConvertDataFromScannerToStructure(Parameter) Export
	
	EquipmentManagerClientOverridable.ProcessEvent(); // APK:222 - For backward compatibility
	
	If Parameter[1] = Undefined Then
		Data = New Structure("Barcode, Count", Parameter[0], 1);    // We get the barcode from the main data
	Else
		Data = New Structure("Barcode, Count", Parameter[1][1], 1); // We get the barcode from the additional data
	EndIf;
	
	Return Data;
	
EndFunction

// Performs asynchronous loading of the hardware driver log archive.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//      the hardware for which the driver logs are loaded
//   HardwareDriver - CatalogRef.HardwareDrivers - 
//   	link to the hardware driver
//
// Returns:
//   Structure - The result of loading the log archive containing information of operation success and possible errors:
//      * Success - Boolean - Success flag for uploading the log archive
//      * ErrorText - String - Error text if of operation was not completed successfully
//      * DriverData - Structure, Undefined - Loaded driver data
//
Async Function DownloadArchiveOfAsyncDriverLogs(Peripherals, HardwareDriver, InstallFileSystemExtension = False) Export
	
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("ErrorText", "");
	Result.Insert("DriverData", Undefined);
	
	If Not ValueIsFilled(Peripherals) Then
		Result.ErrorText = NStr("vi = 'Chưa chỉ định thiết bị kết nối';
								|ru = 'Не указано подключаемое оборудование.';
								|en = 'The peripherals are not specified.'; fa = 'The peripherals are not specified.';
								|it = 'The peripherals are not specified.';
								|pl = 'The peripherals are not specified.';
								|tr = 'Bağlanabilir donanım belirtilmedi.'");
		Return Result;
	EndIf;

	If Not ValueIsFilled(HardwareDriver) Then
		Result.ErrorText = NStr("vi = 'Chưa chỉ định driver thiết bị.';
								|ru = 'Не указан драйвер оборудования.';
								|en = 'The hardware driver is not specified.'; fa = 'The hardware driver is not specified.';
								|it = 'The hardware driver is not specified.';
								|pl = 'The hardware driver is not specified.';
								|tr = 'Donanım sürücüsü belirtilmedi.'");
		Return Result;
	EndIf;
	
	If CommonCELClient.IsWebClient() Then
		
		If Not Await AttachFileSystemExtensionAsync() Then
			
			ErrorText = NStr("vi = 'Lỗi kết nối phần mở rộng làm việc với tệp. Không thể kết nhập.';
							|ru = 'Ошибка подключения расширения работы с файлами. Загрузка недоступна.';
							|en = 'An error occurred while attaching 1C:Enterprise Extension. Import is unavailable.'; fa = 'An error occurred while attaching 1C:Enterprise Extension. Import is unavailable.';
							|it = 'An error occurred while attaching 1C:Enterprise Extension. Import is unavailable.';
							|pl = 'An error occurred while attaching 1C:Enterprise Extension. Import is unavailable.';
							|tr = 'Dosya uzantısına bağlanırken hata oluştu. Yükleme yapılamıyor.'");
			If Not InstallFileSystemExtension Then
				Result.ErrorText = ErrorText;
				Return Result;
			EndIf;
				
			Await InstallFileSystemExtensionAsync();
			
			If Not Await AttachFileSystemExtensionAsync() Then
				Result.ErrorText = ErrorText;
				Return Result;
			EndIf;
		EndIf;
		
	EndIf;
	
	DescriptionResult = Await GettingDriverDescriptionAsync(HardwareDriver);
	If Not DescriptionResult.Result Then
		Result.ErrorText = NStr("vi = 'Không thể lấy mô tả driver. Nên cài đặt lại driver.';
								|ru = 'Не удалось получить описание драйвера. Рекомендуется переустановить драйвер.';
								|en = 'Cannot get the driver description. We recommend that you reinstall the driver.'; fa = 'Cannot get the driver description. We recommend that you reinstall the driver.';
								|it = 'Cannot get the driver description. We recommend that you reinstall the driver.';
								|pl = 'Cannot get the driver description. We recommend that you reinstall the driver.';
								|tr = 'Sürücü açıklaması alınamadı. Sürücüyü yeniden yüklemeniz önerilmektedir.'");
		Return Result;
	EndIf;
	
	DriverDescription = DescriptionResult.DriverDescription;
	If DriverDescription = Undefined Then
		Result.ErrorText = NStr("vi = 'Không thể lấy mô tả driver. Nên cài đặt lại driver.';
								|ru = 'Не удалось получить описание драйвера. Рекомендуется переустановить драйвер.';
								|en = 'Cannot get the driver description. We recommend that you reinstall the driver.'; fa = 'Cannot get the driver description. We recommend that you reinstall the driver.';
								|it = 'Cannot get the driver description. We recommend that you reinstall the driver.';
								|pl = 'Cannot get the driver description. We recommend that you reinstall the driver.';
								|tr = 'Sürücü açıklaması alınamadı. Sürücüyü yeniden yüklemeniz önerilmektedir.'");
		Return Result;
	EndIf;
	
	If DriverDescription.DriverLogIsEnabled = Undefined Then
		DriverDescription.DriverLogIsEnabled = False;
	EndIf;
	If DriverDescription.DriverLogFilePath = Undefined Then
		DriverDescription.DriverLogFilePath = "";
	EndIf;
	
	// log files are not used
	If Not DriverDescription.DriverLogIsEnabled Then
		Result.ErrorText = NStr("vi = 'Chức năng ghi nhận nhật ký thao tác của driver đang bị tắt. Nên bật ghi nhận nhật ký thao tác của driver.';
								|ru = 'У драйвера отключено логирование операций. Рекомендуется включить логирование операций драйвера.';
								|en = 'Operation logging is disabled for the driver. We recommend that you enable logging of driver operations.'; fa = 'Operation logging is disabled for the driver. We recommend that you enable logging of driver operations.';
								|it = 'Operation logging is disabled for the driver. We recommend that you enable logging of driver operations.';
								|pl = 'Operation logging is disabled for the driver. We recommend that you enable logging of driver operations.';
								|tr = 'Sürücünün işlem günlüğü kaydı devre dışı. Sürücü işlem günlüğünün etkinleştirilmesi önerilmektedir.'");
		Return Result;
	EndIf;
	
	If IsBlankString(DriverDescription.DriverLogFilePath ) Then
		Result.ErrorText = NStr("vi = 'Driver chưa đặt đường dẫn đến các tệp ghi nhận nhật ký thao tác. Nên tùy chỉnh ghi nhận nhật ký thao tác của driver.';
								|ru = 'У драйвера не задан путь к файлам логирования операций. Рекомендуется настроить логирование операций драйвера.';
								|en = 'The path to the operation logging files is not set for the driver. We recommend that you configure logging of driver operations.'; fa = 'The path to the operation logging files is not set for the driver. We recommend that you configure logging of driver operations.';
								|it = 'The path to the operation logging files is not set for the driver. We recommend that you configure logging of driver operations.';
								|pl = 'The path to the operation logging files is not set for the driver. We recommend that you configure logging of driver operations.';
								|tr = 'Sürücüde işlem günlüğü dosyalarının yolu belirtilmedi. Sürücünün işlem günlüğünü ayarlamanız önerilmektedir.'");
		Return Result;
	EndIf;
	
	File = New File(DriverDescription.DriverLogFilePath);
	FileExists = Await File.ExistsAsync();
	If Not FileExists Then
		Result.ErrorText = NStr("vi = 'Không có các tệp ghi nhận nhật ký. Nên kiểm tra đường dẫn đến nhật ký thao tác của driver.';
								|ru = 'Отсутсвуют файлы логирования. Рекомендуется проверить путь к логированию операций драйвера.';
								|en = 'There are no logging files. We recommend that you check the logging path of the driver operations.'; fa = 'There are no logging files. We recommend that you check the logging path of the driver operations.';
								|it = 'There are no logging files. We recommend that you check the logging path of the driver operations.';
								|pl = 'There are no logging files. We recommend that you check the logging path of the driver operations.';
								|tr = 'Günlük dosyaları eksik. Sürücü işlemlerinin günlük kaydı yolunun kontrol edilmesi önerilmektedir.'");
		Return Result;
	EndIf;
	
	IsDirectory = Await File.IsDirectoryAsync();
	If IsDirectory Then
		// Log files are stored in the directory
		FilesFound  = TrimAll(DriverDescription.DriverLogFilePath);
		PathSeparator = GetPathSeparator();
		If Right(FilesFound, 1) <> PathSeparator Then
			FilesFound = FilesFound + PathSeparator;
		EndIf;
		FilesPath = FilesFound;
		FileMask = GetAllFilesMask();
		OneFile = False;
		
	Else
		// Log files are stored in one file
		FilesPath = File.FullName;
		FileMask = Undefined;
		OneFile = True;
	EndIf;
	
	ArchiveData = New Structure;
	ArchiveData.Insert("BaseDirectory", FilesPath);
	ArchiveData.Insert("OneFile", OneFile);
	
	Try
		If CommonCELClient.IsWebClient() Then
			TransmissionResult = Await TransferLogFilesATServer(FilesPath, FileMask);
			If TransmissionResult.Success Then
				Data = TransmissionResult.TransferredFileDescriptions;
			Else
				Result.ErrorText = TransmissionResult.ErrorText;
				Return Result;
			EndIf;
		Else
			Data = CreateArchiveOfLogsOnClient(FilesPath);
		EndIf;
	
		EquipmentManagerServerCall.RecordArchiveOfDriverLogs(
			Peripherals, 
			Data);
		Result.Success = True;
		
	Except
		ErrorTemplate =NStr("vi = 'Không thể lưu tệp nén nhật ký thao tác. %1';
							|ru = 'Не удалось сохранить архив логов. %1';
							|en = 'Cannot save the log archive. %1'; fa = 'Cannot save the log archive. %1';
							|it = 'Cannot save the log archive. %1';
							|pl = 'Cannot save the log archive. %1';
							|tr = 'Günlük arşivi kaydedilemedi. %1'"); 
		Result.ErrorText = StrTemplate(ErrorTemplate,
			ErrorProcessing.ErrorDescriptionForUser(ErrorInfo()));
			
		CommonCELClient.WriteErrorToEventLog(
			NStr("vi = 'Chuyển tệp nhật ký thao tác driver.';
				|ru = 'Передача файлов логов драйверов.';
				|en = 'Transfer driver log files.'; fa = 'Transfer driver log files.';
				|it = 'Transfer driver log files.';
				|pl = 'Transfer driver log files.';
				|tr = 'Sürücü günlüğü dosyalarının aktarılması.'"),
			StrTemplate(ErrorTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo())));
			
	EndTry;
	
	Return Result;
	
EndFunction

// Processes the request received from the server to archive the hardware driver logs.
//
// Parameters:
//   QueryData - Structure - log archiving request data:
//    * Workplace - CatalogRef.Workplaces
//    * Peripherals - CatalogRef.Peripherals
//    * HardwareDriver - CatalogRef.HardwareDrivers
//   AdditionalParameters - Arbitrary - additional request processing parameters
//
Async Procedure ProcessRequestForArchiveOfDriverLogs(QueryData, AdditionalParameters) Export
	
	If TypeOf(QueryData) <> Type("Structure") Then
		Return;
	EndIf;
	
	If QueryData.Workplace <> CustomerWorkplace() Then
		Return;
	EndIf;
	
	ImportResult1 = Await DownloadArchiveOfAsyncDriverLogs(
		QueryData.Peripherals, 
		QueryData.HardwareDriver);
	
	EquipmentManagerServerCall.
		SendResponseToDriverLogArchiveEntry(QueryData, ImportResult1);
	
EndProcedure

// Processes the confirmation for the request to archive the hardware driver logs.
//
// Parameters:
//   ResponseData - Structure - log archiving request data:
//    * Peripherals - CatalogRef.Peripherals - link to the hardware instance
//    * HardwareDriver - CatalogRef.HardwareDrivers - link to the hardware driver
//
Async Procedure ProcessResponseToRequestForDriverLogArchive(ResponseData) Export
	
	Workplace = EquipmentManagerClient.CustomerWorkplace();
	If ResponseData.WorkplaceSender <> Workplace Then
		Return;
	EndIf;
	
	Notify("BPO.ArchiveOfDriverLogsHasBeenUploaded");
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Peripherals", ResponseData.Peripherals);
	AdditionalParameters.Insert("FormUniqueID", ResponseData.FormUniqueID);
	WhenClickingUserAlerts = New CallbackDescription("ProcessResponseToRequestForDriverLogArchiveWhenNotificationIsPressed", ThisObject, AdditionalParameters);
	
	If ResponseData = Undefined Then
		Title = NStr("vi = 'Lỗi.';
					|ru = 'Ошибка.';
					|en = 'Error.'; fa = 'Error.';
					|it = 'Error.';
					|pl = 'Error.';
					|tr = 'Hata.'");
		Text = NStr("vi = 'Không có phản hồi từ client';
					|ru = 'Нет ответа от клиента';
					|en = 'No response from the client'; fa = 'No response from the client';
					|it = 'No response from the client';
					|pl = 'No response from the client';
					|tr = 'İstemciden yanıt yok'");
		ShowUserNotification(
			Title, 
			WhenClickingUserAlerts,
			Text,
			PictureLib.AppearanceCrossIcon, 
			UserNotificationStatus.Important);
		
	ElsIf ResponseData.Success Then
		Title = NStr("vi = 'Thành công.';
					|ru = 'Успех.';
					|en = 'Success.'; fa = 'Success.';
					|it = 'Success.';
					|pl = 'Success.';
					|tr = 'Başarılı.'");
		Text = NStr("vi = 'Đã lấy thành công tệp nén nhật ký.';
					|ru = 'Архив логов успешно получен.';
					|en = 'The log archive is successfully received.'; fa = 'The log archive is successfully received.';
					|it = 'The log archive is successfully received.';
					|pl = 'The log archive is successfully received.';
					|tr = 'Günlük arşivi başarıyla alındı.'");
		ShowUserNotification(
			Title, 
			WhenClickingUserAlerts,
			Text,
			PictureLib.AppearanceCheckIcon, 
			UserNotificationStatus.Important);
		
	Else
		Title = NStr("vi = 'Lỗi.';
					|ru = 'Ошибка.';
					|en = 'Error.'; fa = 'Error.';
					|it = 'Error.';
					|pl = 'Error.';
					|tr = 'Hata.'");
		Text = ResponseData.ErrorText;
		ShowUserNotification(
			Title, 
			WhenClickingUserAlerts,
			Text,
			PictureLib.AppearanceCrossIcon, 
			UserNotificationStatus.Important);
	EndIf;
	
EndProcedure

Procedure ProcessResponseToRequestForDriverLogArchiveWhenNotificationIsPressed(AdditionalParameters) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", AdditionalParameters.Peripherals);
	OpenForm("Catalog.Peripherals.Form.ItemForm", FormParameters, , AdditionalParameters.FormUniqueID);
	
EndProcedure


#EndRegion

#Region SimplifyingParameterSettings

// Starts asynchronous filling of key equipment parameters by ID
//
// Parameters:
//  CompletionNotification  - CallbackDescription - notification that will be triggered based on the results of filling in the parameters
//  Id - CatalogRef.Peripherals - Hardware Id
Procedure StartGettingKeyParameters(CompletionNotification, Id) Export
	
	Context = New Structure();
	Context.Insert("KeyParameters",    New Structure());
	Context.Insert("CompletionNotification", CompletionNotification);
	Context.Insert("Id",        Id);

	Notification = New CallbackDescription("StartGettingKeyParametersCompletion", ThisObject, Context);
	EquipmentManagerClient.StartGettingDescriptionOfEquipment(Notification, Id);

EndProcedure

// Completes asynchronous filling of key hardware parameters by ID
//
// Parameters:
//  Result - Structure
//  Context - Structure
Procedure StartGettingKeyParametersCompletion(Result, Context) Export
	
	CompletionNotification = Context.CompletionNotification;

	If Result.Result Then
	
		Id      = Context.Id;
		KeyParameters  = Context.KeyParameters;
		InterfaceDescription = Result.DriverDescription.DriverParameters;
		
		ReadAttributesOfKeyParameters(InterfaceDescription, KeyParameters);
	
		Peripherals = Peripherals();
		If Not Peripherals.Property("OwnHardwareParameters") Then
			Peripherals.Insert("OwnHardwareParameters", New Map());
		EndIf;
		Peripherals.OwnHardwareParameters.Insert(Id, KeyParameters);
		
		// add general parameters
		If Not KeyParameters.Property("LogEnabled") Then
			AddDriverLogParameterEnabled(KeyParameters, Result.DriverDescription.DriverLogIsEnabled);
		EndIf;
		If Not KeyParameters.Property("LogPath") Then
			AddDriverLogParameterFilePath(KeyParameters, Result.DriverDescription.DriverLogFilePath);
		EndIf;
		
		
		RunCallback(CompletionNotification, True);
	Else
		RunCallback(CompletionNotification, False);
	EndIf;
	
EndProcedure

// Returns attributes of the equipment parameter by the standard parameter name. The name is checked using the dictionary of possible options
//
// Parameters:
//  Id - CatalogRef.Peripherals - Hardware Id
//  ParameterName - String - the standard name of the hardware parameter
//
// Returns:
//  - Undefined
//  - Structure - See NewParameterAttributes
//
Function ParameterAttributes(Id, ParameterName) Export

	Peripherals = Peripherals();
	If Not Peripherals.Property("OwnHardwareParameters") Then
		Return Undefined;
	EndIf;
	
	KeyParameters = Peripherals.OwnHardwareParameters.Get(Id);
	If KeyParameters = Undefined Then
		Return Undefined;
	EndIf;
	
	ParameterAttributes = Undefined;
	If Not KeyParameters.Property(ParameterName, ParameterAttributes) Then
		Return Undefined;
	EndIf;
	
	Return ParameterAttributes;

EndFunction

// Returns True if the parameter with the name of the parameter name exists, the name is checked against the dictionary of possible options
//
// Parameters:
//  Id - CatalogRef.Peripherals - Hardware Id
//  ParameterName - String - the standard name of the hardware parameter
//
// Returns:
//  Boolean - 
Function ParameterExists(Id, ParameterName) Export

	ParameterAttributes = ParameterAttributes(Id, ParameterName);
	Return ParameterAttributes <> Undefined;

EndFunction

// Returns the type of the hardware parameter by the standard parameter name, the name is checked by the dictionary of possible options
//
// Parameters:
//  Id - CatalogRef.Peripherals - Hardware Id
//  ParameterName - String - the standard name of the hardware parameter
//
// Returns:
//   Type - Type - Type of parameter value (Number, String, Boolean)
Function ParameterType(Id, ParameterName) Export
	
	ParameterAttributes = ParameterAttributes(Id, ParameterName);
	If ParameterAttributes = Undefined Then
		Return Undefined;
	EndIf;
	
	Return ParameterAttributes.Type;

EndFunction

// Returns the value of the hardware parameter by the standard parameter name, the name is checked by the dictionary of possible options
//
// Parameters:
//  Id - CatalogRef.Peripherals - Hardware Id
//  ParameterName - String - the standard name of the hardware parameter
//
// Returns:
//  Number, String, Boolean, Undefined - set parameter value
Function ParameterValue(Id, ParameterName) Export

	ParameterAttributes = ParameterAttributes(Id, ParameterName);
	If ParameterAttributes = Undefined Then
		Return Undefined;
	EndIf;
	
	If ParameterAttributes.Standard Then
		Return ParameterAttributes.ValueOfStandard;
	EndIf;
	
	DeviceParameters = EquipmentManagerServerCall.DeviceParameters(Id);
	AttributeName        = ParameterAttributes.AttributeName;
	ParameterValue   = Undefined;
	If Not DeviceParameters.Property(AttributeName, ParameterValue) Then
		Return Undefined;
	EndIf;
	
	If ParameterAttributes.Transformation_ = "Invert" And ParameterAttributes.Type = Type("Boolean") Then
		ParameterValue = Not ParameterValue;
	EndIf;
	
	Return ParameterValue;

EndFunction

// Sets the value of the equipment parameter by the standard parameter name, the name is checked by the dictionary of possible options
//
// Parameters:
//  Id - CatalogRef.Peripherals - Hardware Id
//  ParameterName - String - the standard name of the hardware parameter
//  NewValue - Number, String, Boolean, Undefined - the new value of the parameter that you want to set
// 
// Returns:
//  Boolean - The result of executing
Function SetParameterValue(Id, ParameterName, NewValue) Export
	
	ParameterAttributes = ParameterAttributes(Id, ParameterName);
	If ParameterAttributes = Undefined Then
		Return False;
	EndIf;
	
	If ParameterAttributes.ReadOnly Then
		Return False;
	EndIf;
	
	DeviceParameters = EquipmentManagerServerCall.DeviceParameters(Id);
	AttributeName        = ParameterAttributes.AttributeName;
	If ParameterAttributes.Transformation_ = "Invert" And ParameterAttributes.Type = Type("Boolean") Then
		NewValue = Not NewValue;
	EndIf;
	DeviceParameters.Insert(AttributeName, NewValue);
	
	
	Return EquipmentManagerServerCall.SaveDeviceSettings(Id, DeviceParameters);
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

#Region System

// Deprecated: You should use the Client Integration system.Before starting the work of the system.
// Called before the system starts.
//
Procedure BeforeStart() Export
	
	PELSubsystemsIntegrationClient.BeforeStart();
	
EndProcedure

// Deprecated: You should use the Client Integration system.When starting a worksystem.
// A function that is called when the system starts working.
//
Procedure OnStart() Export
	
	PELSubsystemsIntegrationClient.OnStart();
	
EndProcedure

// Deprecated: You should use the Client Integration system.Before completing the work of the system.
//
Procedure BeforeExit() Export
	
	PELSubsystemsIntegrationClient.BeforeExit();
	
EndProcedure

// Deprecated: You should use a general-purpose client.A data session.
// Returns the Cur date set to the time zone of the session.
// It is intended to be used instead of the Current Date() function.
//
// Returns:
//  Date
//
Function SessionDate() Export
	
	Return CommonCELClient.SessionDate();
	
EndFunction

#If Not WebClient Then

// Deprecated: no longer in use.
// Install or reinstall drivers marked with flags.
//
Procedure ReinstallMarkedSuppliedDrivers() Export
	
	ClientRunParameters = PELSubsystemsIntegrationClient.ClientParametersOnStart();
	
	EquipmentForReinstalling = New Array;
	For Each DriverTemplateName In ClientRunParameters.EquipmentForReinstalling Do
		EquipmentForReinstalling.Add(DriverTemplateName);
	EndDo;

	AddInsCELClient.ReinstallComponents(EquipmentForReinstalling);
	
EndProcedure

#EndIf

// Deprecated: no longer in use.
// Returns the values of the parameters required for the client configuration code
// to work without additional server calls.
// 
// Returns:
//   See PELSubsystemsIntegrationClient.ClientParametersOnStart
//
Function ClientParametersOnStart() Export
	
	Return PELSubsystemsIntegrationClient.ClientParametersOnStart();
	
EndFunction

// Deprecated: You should use the Client Integration system.Processing of external events.
// Performs processing of an external event, called from the global module
//
// Parameters:
//  Source - String
//  Event - String
//  Data - String
Procedure ExternEventProcessing(Source, Event, Data) Export
	
	PELSubsystemsIntegrationClient.ExternEventProcessing(Source, Event, Data);
	
EndProcedure

// Outdated: You should use an array of types of equipment.
// Forming an array of equipment types
// 
// Parameters:
//   Types - Array of String, String - type of equipment.
// Returns:
//   Array of EnumRef.PeripheralTypes -  
//           
Function GetTypesOfEquipment(Types) Export
	
	Return ArrayOfEquipmentTypes(Types); 
	
EndFunction

#EndRegion

#Region DistributedFiscalization

// Deprecated: You should use a distributed Client visualization.Connecting the interaction system.
// Connects the handlers of the notification system for use in distributed fiscalization
//
Procedure ConnectingInteractionSystem() Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.ConnectingInteractionSystem(Undefined);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.Processing of the notification of the connection of the notification of the fiscalization.
// Ending the connection of the notification system handler
// 
// Parameters:
//  AdditionalParameters - Arbitrary
// 
Procedure HandlingNotificationsEnablingFiscalizationMessages(AdditionalParameters) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.HandlingNotificationsEnablingFiscalizationMessages(AdditionalParameters);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.Processing of publicationsreferencesfiscalization.
// Handler for the appearance of new messages in the discussion 
//
// Parameters:
//  Message - CollaborationSystemMessage
//  AdditionalParameters - Arbitrary
// 
Procedure HandlingNotificationOfFiscalizationMessages(Message, AdditionalParameters) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.HandlingNotificationOfFiscalizationMessages(Message, AdditionalParameters);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.Fiscalizationcheck queue_After opening the cell.
// Handler after opening the receipt.
//
// Parameters:
//  ExecutionParameters - Structure - Command Execution Parameters
//  AdditionalParameters - Arbitrary
//
Procedure FiscalizationOfReceiptsInQueue_AfterOpeningReceipt(ExecutionParameters, AdditionalParameters) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.FiscalizationOfReceiptsInQueue_AfterOpeningReceipt(ExecutionParameters, AdditionalParameters);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.Fiscalizationcheck queue_After the printing error.
// Handler after a receipt printing error.
//
// Parameters:
//  ExecutionParameters - Structure - Command Execution Parameters
//  AdditionalParameters - Arbitrary
//
Procedure FiscalizationOfReceiptsInQueue_AfterReceiptPrintingError(ExecutionParameters, AdditionalParameters) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.FiscalizationOfReceiptsInQueue_AfterReceiptPrintingError(ExecutionParameters, AdditionalParameters);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.fiscalizationcheck_read_performance.
// End of fiscalization of checks in the queue
// 
// Parameters:
//  ExecutionResult - Structure
//  CommonParameters - Structure
// 
Procedure FiscalizationOfChecksInQueue_Completion(ExecutionResult, CommonParameters) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.FiscalizationOfChecksInQueue_Completion(ExecutionResult, CommonParameters);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.fiscalizationcheck_read_complementation of the package operation.
// End of fiscalization of operation in the queue
// 
// Parameters:
//  ExecutionResult - See PeripheralsReceiptPrintersClient.ResultIsSaleWithCashWithdrawal
//  CommonParameters - Structure
// 
Procedure FiscalizationOfChecksInQueue_EndOfBatchOperation(ExecutionResult, CommonParameters) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.FiscalizationOfChecksInQueue_EndOfBatchOperation(ExecutionResult, CommonParameters);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.Fiscalizationcheck queue_The beginning.
// Start fiscalization of checks in the queue
// 
// Parameters:
//  Parameters - See CheckQueueFiscalizationParameters
Procedure FiscalizationOfChecksInQueue_Start(Parameters = Undefined) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.FiscalizationOfChecksInQueue_Start(Parameters);
	EndIf;
	
EndProcedure

// Deprecated: You should use a distributed Client visualization.Parametersfiscalization of check lists.
// Returns the structure of parameters for performing fiscalization of the receipt queue
// 
// Returns:
//  Structure:
//   * Form - ClientApplicationForm
//   * CashRegister - DefinedType.CashAccountCEL
Function CheckQueueFiscalizationParameters() Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		Return ModuleDistributedFiscalizationClient.CheckQueueFiscalizationParameters();
	EndIf;
	
EndFunction

// Deprecated: You should use a distributed Client visualization.Fiscalizationcheck queue.
// Perform fiscalization of receipts in the queue
//
// Parameters:
//  AutomaticFiscalizationIsAllowed - Boolean
//  Parameters - See CheckQueueFiscalizationParameters.
Procedure FiscalizationOfChecksInQueue(AutomaticFiscalizationIsAllowed = True, Parameters = Undefined) Export
	
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.FiscalizationOfChecksInQueue(AutomaticFiscalizationIsAllowed, Parameters);
	EndIf;
	
EndProcedure

#EndRegion

// Deprecated: no longer in use
// Displays the text in the State panel.
//
// Parameters:
//  MessageText - String
//  Progress - Number - progress indicator
//  Explanation - String
//
Procedure ProcessState(MessageText, Progress = Undefined, Explanation = Undefined) Export
	
#If Not MobileClient Then
	Status(MessageText, Progress);
#EndIf 
	
EndProcedure

// Deprecated: you should use the Select device.
// The procedure for selecting a device from the available ones linked to the Cur workplace.
//
// Parameters:
//  ChoiceNotification - CallbackDescription - notification description event.
//  EquipmentType - Structure, Array, String - the type of equipment to select the device.
//  SelectionHeaderText - String - The title of the selection window.
//  MessageIsNotConnected - String - The text of the message about not connected devices
//  MessageWasNotSelected - String - The text of the message about not selected devices
//
Procedure SuggestSelectingDevice(ChoiceNotification, EquipmentType, SelectionHeaderText, MessageIsNotConnected = "", MessageWasNotSelected = "") Export
	
	If Not UpdateClientWorkplace() Then
		MessageText = NStr("vi = 'Trước tiên, cần chọn chỗ làm việc cho thiết bị kết nối của phiên làm việc hiện tại.';
							|ru = 'Предварительно необходимо выбрать рабочее место подключаемого оборудования текущего сеанса.';
							|en = 'First, you need to select the workplace for peripherals to use in the current session.'; fa = 'First, you need to select the workplace for peripherals to use in the current session.';
							|it = 'È necessario selezionare prima la postazione di lavoro dell''apparecchiatura plug-in della sessione corrente.';
							|pl = 'Uprzednio należy wybrać miejsce pracy podłączanych urządzeń bieżącej sesii.';
							|tr = 'Önce mevcut oturumun bağlı ekipmanının çalışma alanı seçilmeli.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageText);
		RunCallback(ChoiceNotification, ExecutionResult);
		Return;
	EndIf;
	
	If IsBlankString(MessageIsNotConnected) Then
		MessageIsNotConnected = NStr("vi = 'Các thiết bị cần thiết không được kết nối với chỗ làm việc hiện tại.';
									|ru = 'Необходимые устройства не подключены к текущему рабочему месту.';
									|en = 'Required devices are not connected to the current workplace.'; fa = 'Required devices are not connected to the current workplace.';
									|it = 'I dispositivi necessari non sono connessi alla postazione di lavoro corrente.';
									|pl = 'Potrzebne urządzenie nie są podłączone do bieżącego miejsca pracy.';
									|tr = 'Gerekli cihazlar mevcut çalışma alanına bağlı değil.'");
	EndIf;
	
	If IsBlankString(MessageWasNotSelected) Then
		MessageWasNotSelected = NStr("vi = 'Chưa chọn thiết bị.';
									|ru = 'Устройство не выбрано.';
									|en = 'Device is not selected.'; fa = 'Device is not selected.';
									|it = 'Dispositivo non selezionato.';
									|pl = 'Nie wybrano urządzenia.';
									|tr = 'Cihaz seçilmedi.'");
	EndIf;
		
	SelectionList = EquipmentManagerClientServer.ListOfEquipmentSelection();   
	SelectionList.SoftwareTypes = EquipmentType;                  
	ListOfAvailableDevices = EquipmentManagerServerCall.EquipmentList(SelectionList);   
	
	If ListOfAvailableDevices.Count() = 0 Then
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageIsNotConnected);
		RunCallback(ChoiceNotification, ExecutionResult);
	Else
		ListOfDevices = New ValueList();
		For Each Devices In ListOfAvailableDevices Do
			ListOfDevices.Add(Devices.Ref, Devices.Description);
		EndDo;
		If ListOfDevices.Count() = 1 Then
			Id = ListOfDevices[0].Value;
			ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, Undefined, Id);
			RunCallback(ChoiceNotification, ExecutionResult);
		Else
			Context = New Structure;
			Context.Insert("ChoiceNotification"   , ChoiceNotification);
			Context.Insert("MessageWasNotSelected" , MessageWasNotSelected);
			CallbackDescription = New CallbackDescription("SuggestSelectingDeviceCompletion", ThisObject, Context);
			ListOfDevices.ShowChooseItem(CallbackDescription, SelectionHeaderText);
		EndIf;
	EndIf;
	
EndProcedure

// Deprecated: no longer in use
// End device selection
// 
// Parameters:
//  Result - Structure
//  Parameters - Structure
// 
Procedure SuggestSelectingDeviceCompletion(Result, Parameters) Export
	
	If Result = Undefined Then 
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, Parameters.MessageWasNotSelected);
		RunCallback(Parameters.ChoiceNotification, ExecutionResult);
	Else
		Id = ?(Result = Undefined, Undefined, Result.Value);
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, Undefined, Id);
		RunCallback(Parameters.ChoiceNotification, ExecutionResult);
	EndIf;
	
EndProcedure

#Region SelectingTypeCodeOfNomenclatureClassification

// Deprecated: no longer in use
// The procedure opens a form for selecting a code for the type of nomenclature classification
//
// Parameters:
//  NotificationWhenSelecting - CallbackDescription - notification description event.
//
Procedure StartSelectingCodeForTypeOfNomenclatureClassification(NotificationWhenSelecting) Export
	
	
EndProcedure

// Deprecated: no longer in use
// End of the selection 
// 
// Parameters:
//  Result - Structure
//  Parameters - Structure
// 
Procedure StartSelectingCodeForTypeOfNomenclatureClassification_Completion(Result, Parameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
			If Parameters.NotificationWhenSelecting <> Undefined Then
			RunCallback(Parameters.NotificationWhenSelecting, Result);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region CREWithDataTransfer

// Outdated: It is necessary to use the equipment of the printing device Client.To begin the opening of the registration session.
// Performs the opening of the KM registration session.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - the handler of the result.
//  UUID - UUID - the ID of the form.
//  Parameters - Structure - Contains parameters for performing the operation.
//  DeviceID - CatalogRef.Peripherals - Device.
//
Procedure StartOpeningRegistrationSession(NotificationOnCompletion, UUID, Parameters = Undefined, DeviceID = Undefined) Export
	
	If CommonCELClient.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
		ModuleEquipmentReceiptPrintingDevicesClient.StartOpeningRegistrationSession(NotificationOnCompletion, UUID, DeviceID, Parameters); 
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị in phiếu';
												|ru = 'Подсистема Чекопечатающие устройства не используется';
												|en = 'Receipt printers subsystem is not used'; fa = 'Receipt printers subsystem is not used';
												|it = 'Il sottosistema Dispositivi di stampa non è utilizzato';
												|pl = 'Podsystem Urządzenia do drukowania paragonów nie jest używany';
												|tr = 'Alt sistem Fiş yazıcıları kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Outdated: It is necessary to use the equipment of the printing device Client.Start closing the Registration session.
// At the end of the KM registration session.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - the handler of the result.
//  UUID - UUID - the ID of the form.
//  Parameters - Structure - Contains parameters for performing the operation.
//  DeviceID - CatalogRef.Peripherals - Device.
//
Procedure StartClosingRegistrationSession(NotificationOnCompletion, UUID, Parameters = Undefined, DeviceID = Undefined) Export
	
	If CommonCELClient.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
		ModuleEquipmentReceiptPrintingDevicesClient.StartClosingRegistrationSession(NotificationOnCompletion, UUID, DeviceID, Parameters); 
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị in phiếu';
												|ru = 'Подсистема Чекопечатающие устройства не используется';
												|en = 'Receipt printers subsystem is not used'; fa = 'Receipt printers subsystem is not used';
												|it = 'Il sottosistema Dispositivi di stampa non è utilizzato';
												|pl = 'Podsystem Urządzenia do drukowania paragonów nie jest używany';
												|tr = 'Alt sistem Fiş yazıcıları kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Outdated: It is necessary to use the equipment of the printing device Client.Get started.
// Performs KM request.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - the handler of the result.
//  UUID - UUID - the ID of the form.
//  Parameters - Structure - Contains parameters for performing the operation.
//  DeviceID - CatalogRef.Peripherals - Device.
//
Procedure StartKmRequest(NotificationOnCompletion, UUID, Parameters, DeviceID = Undefined) Export
	
	If CommonCELClient.CheckPrintingDevicesAreUsed() Then
		AdditionalParameters = EquipmentManagerClientServer.AdditionalOperationParameters(True);
		ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
		ModuleEquipmentReceiptPrintingDevicesClient.StartKmRequest(NotificationOnCompletion, UUID, DeviceID, Parameters, AdditionalParameters);
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị in phiếu';
												|ru = 'Подсистема Чекопечатающие устройства не используется';
												|en = 'Receipt printers subsystem is not used'; fa = 'Receipt printers subsystem is not used';
												|it = 'Il sottosistema Dispositivi di stampa non è utilizzato';
												|pl = 'Podsystem Urządzenia do drukowania paragonów nie jest używany';
												|tr = 'Alt sistem Fiş yazıcıları kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Outdated: It is necessary to use the equipment of the printing device Client.Begin to get the results of the requests.
// Start receiving KM query results.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - the handler of the result.
//  UUID - UUID - the ID of the form.
//  Parameters - Structure - Contains parameters for performing the operation.
//  DeviceID - CatalogRef.Peripherals - Device.
//
Procedure GettingKmQueryResults(NotificationOnCompletion, UUID, Parameters, DeviceID = Undefined) Export
	
	If CommonCELClient.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
		ModuleEquipmentReceiptPrintingDevicesClient.GettingKmQueryResults(NotificationOnCompletion, UUID, DeviceID, Parameters);
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị in phiếu';
												|ru = 'Подсистема Чекопечатающие устройства не используется';
												|en = 'Receipt printers subsystem is not used'; fa = 'Receipt printers subsystem is not used';
												|it = 'Il sottosistema Dispositivi di stampa non è utilizzato';
												|pl = 'Podsystem Urządzenia do drukowania paragonów nie jest używany';
												|tr = 'Alt sistem Fiş yazıcıları kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Outdated: It is necessary to use the equipment of the printing device Client.Start confirmation.
// Start KM confirmation.
//
// Parameters:
//  NotificationOnCompletion - CallbackDescription - the handler of the result.
//  UUID - UUID - the ID of the form.
//  Parameters - Structure - Contains parameters for performing the operation.
//  DeviceID - CatalogRef.Peripherals - Device.
//
Procedure StartKMConfirmation(NotificationOnCompletion, UUID, Parameters, DeviceID = Undefined) Export
	
	If CommonCELClient.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevicesClient = CommonCELClient.CommonModule("PeripheralsReceiptPrintersClient");
		ModuleEquipmentReceiptPrintingDevicesClient.StartKMConfirmation(NotificationOnCompletion, UUID, DeviceID, Parameters);
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị in phiếu';
												|ru = 'Подсистема Чекопечатающие устройства не используется';
												|en = 'Receipt printers subsystem is not used'; fa = 'Receipt printers subsystem is not used';
												|it = 'Il sottosistema Dispositivi di stampa non è utilizzato';
												|pl = 'Podsystem Urządzenia do drukowania paragonów nie jest używany';
												|tr = 'Alt sistem Fiş yazıcıları kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

#EndRegion

#Region TSD

// Outdated: You should use the equipmentdeterminalssboradannyhclient.Start loading the data from the SD card.
// Start downloading data from the data collection terminal.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   UUID - ClientApplicationForm -the ID of the form.
//   CollapseData_ - Boolean
//
Procedure StartDownloadingDataFromTSD(NotificationOnCompletion, UUID, CollapseData_ = False) Export
	
	If CommonCELClient.DataCollectionTerminalsAreUsed() Then
		ModuleEquipmentDataCollectionTerminalsClient = CommonCELClient.CommonModule("PeripheralsPortableDataTerminalsServerClient");
		ModuleEquipmentDataCollectionTerminalsClient.StartDownloadingDataFromTSD(NotificationOnCompletion, UUID);
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị thu thập dữ liệu';
												|ru = 'Подсистема Терминалы сбора данных не используется';
												|en = 'Portable data terminals subsystem is not used'; fa = 'Portable data terminals subsystem is not used';
												|it = 'Il sottosistema Terminale di assemblaggio dati non è utilizzato';
												|pl = 'Podsystem Kolektory danych nie jest używany';
												|tr = 'Alt sistem Veri toplama terminalleri kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Outdated: It is necessary to use the equipmentdeterminalssboradannyhclient.To begin loading the sudannyevtsd.
// Start uploading data to the data collection terminal.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   UUID - ClientApplicationForm -the ID of the form.
//   TableOfUnloadingOfGoods - ValueTable - 
//   FullUpload - Boolean -
//
Procedure StartUploadingVTSDData(NotificationOnCompletion, UUID, TableOfUnloadingOfGoods, FullUpload = True) Export
	
	If CommonCELClient.DataCollectionTerminalsAreUsed() Then              
		ModuleEquipmentDataCollectionTerminalsClientServer = CommonCELClient.CommonModule("PeripheralsPortableDataTerminalsServerClientServer");
		OperationParametersList = ModuleEquipmentDataCollectionTerminalsClientServer.VTSDUploadParameters();     
		OperationParametersList.TableOfGoods = TableOfUnloadingOfGoods;    
		OperationParametersList.PartialUnloading = Not FullUpload;
		
		ModuleEquipmentDataCollectionTerminalsClient = CommonCELClient.CommonModule("PeripheralsPortableDataTerminalsServerClient");
		ModuleEquipmentDataCollectionTerminalsClient.StartUploadingVTSDData(NotificationOnCompletion, UUID, Undefined, OperationParametersList);
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị thu thập dữ liệu';
												|ru = 'Подсистема Терминалы сбора данных не используется';
												|en = 'Portable data terminals subsystem is not used'; fa = 'Portable data terminals subsystem is not used';
												|it = 'Il sottosistema Terminale di assemblaggio dati non è utilizzato';
												|pl = 'Podsystem Kolektory danych nie jest używany';
												|tr = 'Alt sistem Veri toplama terminalleri kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Outdated: You should use the equipmentdeterminalssboradannyhclient.Start cleaning up the cleaning process.
// Start data cleaning in the data collection terminal.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   UUID - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//
Procedure StartCleaningVTSDData(NotificationOnCompletion, UUID, DeviceID = Undefined) Export
	
	If CommonCELClient.DataCollectionTerminalsAreUsed() Then
		ModuleEquipmentDataCollectionTerminalsClient = CommonCELClient.CommonModule("PeripheralsPortableDataTerminalsServerClient");
		ModuleEquipmentDataCollectionTerminalsClient.StartCleaningVTSDData(NotificationOnCompletion, UUID, DeviceID);
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị thu thập dữ liệu';
												|ru = 'Подсистема Терминалы сбора данных не используется';
												|en = 'Portable data terminals subsystem is not used'; fa = 'Portable data terminals subsystem is not used';
												|it = 'Il sottosistema Terminale di assemblaggio dati non è utilizzato';
												|pl = 'Podsystem Kolektory danych nie jest używany';
												|tr = 'Alt sistem Veri toplama terminalleri kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

#EndRegion

#Region DigitalRetailScales

// Outdated: It is necessary to use the equipmentweighing equipmentclient.Begin to receive the most electronic weights
// Receives weight from electronic scales.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   UUID - ClientApplicationForm - the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   DisplayMessages     - Boolean
//
Procedure StartGettingWeightWithElectronicScales(NotificationOnCompletion, UUID, DeviceID = Undefined, DisplayMessages = False) Export
	
	If CommonCELClient.WeightEquipmentIsUsed() Then
		ModuleEquipmentWeighingEquipmentCustomer = CommonCELClient.CommonModule("PeripheralsWeighingEquipmentServerClient");
		ModuleEquipmentWeighingEquipmentCustomer.StartGettingWeightWithElectronicScales(NotificationOnCompletion, UUID, DeviceID, Undefined); 
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị cân';
												|ru = 'Подсистема Весовое оборудование не используется';
												|en = 'Weighing equipment subsystem is not used'; fa = 'Weighing equipment subsystem is not used';
												|it = 'Il sottosistema Apparecchiatura di pesatura non è utilizzato';
												|pl = 'Podsystem Sprzęt do ważenia nie jest używany';
												|tr = 'Alt sistem Ağırlık ekipmanı kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

// Outdated: It is necessary to use the equipmentweighing equipmentclient.To begin installingesataryelectronic weights
// Start setting the tare weight on an electronic scale.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   UUID - ClientApplicationForm - the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   Weight                     - Number - tare weight.
//
Procedure StartTareWeightSetting(NotificationOnCompletion, UUID, DeviceID = Undefined, Weight = Undefined) Export
	
	If CommonCELClient.WeightEquipmentIsUsed() Then
		
		ModuleEquipmentWeighingEquipmentCustomerServer = CommonCELClient.CommonModule("PeripheralsWeighingEquipmentServerClientServer");
		ModuleEquipmentWeighingEquipmentCustomer = CommonCELClient.CommonModule("PeripheralsWeighingEquipmentServerClient");
		
		OperationParametersList = ModuleEquipmentWeighingEquipmentCustomerServer.OperationParametersElectronicScales(Weight);
		ModuleEquipmentWeighingEquipmentCustomer.StartSettingTareWeightOfElectronicScales(NotificationOnCompletion, UUID, DeviceID, OperationParametersList); 
		
	Else
		OperationResult                = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware();
		OperationResult.Result      = False;
		OperationResult.ErrorDescription = NStr("vi = 'Không sử dụng phân hệ Thiết bị cân';
												|ru = 'Подсистема Весовое оборудование не используется';
												|en = 'Weighing equipment subsystem is not used'; fa = 'Weighing equipment subsystem is not used';
												|it = 'Il sottosistema Apparecchiatura di pesatura non è utilizzato';
												|pl = 'Podsystem Sprzęt do ważenia nie jest używany';
												|tr = 'Alt sistem Ağırlık ekipmanı kullanılmıyor'");
		RunCallback(NotificationOnCompletion, OperationResult);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

// Connecting equipment recursively
// 
// Parameters:
//  ConnectionResult - Structure
//  Context - Structure
//   * Connection Parameters - Structure
//   * Notification of connection - Description of the announcement
Procedure StartConnectingEquipmentRecursively(ConnectionResult, Context) Export
	
	EquipmentForConnection = Context.EquipmentForConnection;
	If ConnectionResult <> Undefined Then
		EquipmentForConnection.Delete(EquipmentForConnection.UBound());
		If ConnectionResult.Result Then
			ConnectionParameters = Context.ConnectionParameters; // Structure
			ConnectionParameters.Customers.Add(Context.ClientID);
			ConnectionParameters.NumberOfConnectedDevices = 1;
			Peripherals = Peripherals();
			Peripherals.SoftwareConnectionParameters.Add(ConnectionParameters);
			
			If Context.NotificationWhenConnecting <> Undefined Then
				Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True);
				Result.ConnectedDevice  = ConnectionParameters;
				Result.DeviceID = ConnectionParameters.DeviceID;
				RunCallback(Context.NotificationWhenConnecting, Result);
			EndIf;
		Else
			If Context.NotificationWhenConnecting <> Undefined Then
				ConnectionParameters = Context.ConnectionParameters; // Structure
				ErrorDescription = StrTemplate(
					NStr("vi = 'Không thể kết nối thiết bị (%1): %2';
						|ru = 'Не удалось подключить устройство (%1): %2';
						|en = 'Cannot connect the (%1) device: %2'; fa = 'Cannot connect the (%1) device: %2';
						|it = 'Non è stato possibile connettere il dispositivo (%1): %2';
						|pl = 'Nie udało się podłączyć urządzenia (%1): %2';
						|tr = 'Cihaz bağlanamadı (%1): %2'"), 
					ConnectionParameters.Description, 
					ConnectionResult.ErrorDescription);
				Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
				Result.DeviceID = ConnectionParameters.DeviceID;
				Result.LoadingError = ConnectionResult.LoadingError;
				RunCallback(Context.NotificationWhenConnecting, Result);
			EndIf;
		EndIf;
	EndIf;
	
	If EquipmentForConnection.Count()>0 Then
		Notification       = New CallbackDescription("StartConnectingEquipmentRecursively", ThisObject, Context);
		Device       = EquipmentForConnection[EquipmentForConnection.UBound()];
		New_Connection = DeviceConnectionParameters(Device);
		Context.ConnectionParameters = New_Connection;
		New_Connection.DriverHandler.StartConnectingDevice(Notification, New_Connection);
	EndIf;
	
EndProcedure

// Returns a driver object from the local cache of the client application
// 
// Parameters:
//   ObjectID - String -
// 
// Returns:
//   AddInObject
// 
Function DriverObjectFromCache(ObjectID) Export
	
	Peripherals = Peripherals();
	Result = Peripherals.HardwareDrivers.Get(ObjectID);
	
	Return Result;
	
EndFunction

// Adds a driver object to the local cache of the client application
// 
// Parameters:
//   ObjectID - String -
//   AddInObject - 
// 
Procedure AddDriverToCache(ObjectID, AddInObject) Export
	
	Peripherals = EquipmentManagerClient.Peripherals();
	Peripherals.HardwareDrivers.Insert(ObjectID, AddInObject);
	
EndProcedure        


Procedure DataExchangeWithServer() Export
	
	DataForServerByValue = New Structure;
	DataForServer = New Structure;
	
	If CommonCELClient.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPOClient = CommonCELClient.CommonModule("LoggingOfCELOperationsClient");
		LoggingRecords = ModuleLoggingOfOperationsOfBPOClient.DataForServer();
		If ValueIsFilled(LoggingRecords) Then
			DataForServerByValue.Insert("LoggingRecords", LoggingRecords);
		EndIf;
	EndIf;
	
	StatusesOfCashShifts = Peripherals().StatusesOfCashShifts;
	For Each ShiftStatus In StatusesOfCashShifts Do
		StatusesOfCashShifts.Insert(ShiftStatus.Key, Undefined);
	EndDo;
	DataForServer.Insert("StatusesOfCashShifts", StatusesOfCashShifts);
	
	Try
	EquipmentManagerServerCall.ExchangeWithServer(DataForServer, DataForServerByValue);
	Except
		CommonCELClient.WriteErrorToEventLog(
			NStr("vi = 'Bản ghi thao tác thiết bị';
				|ru = 'Запись операций оборудования';
				|en = 'Record peripheral operations'; fa = 'Record peripheral operations';
				|it = 'Record peripheral operations';
				|pl = 'Record peripheral operations';
				|tr = 'Ekipman işlemlerinin kaydı'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Peripherals().StatusesOfCashShifts = DataForServer.StatusesOfCashShifts;
	
EndProcedure

Function ClientNotificationsAreAvailable() Export

	Return Peripherals().ClientNotificationsAreAvailable;

EndFunction

Function YouCanInstallComponents(TemplateName) Export

#If WebClient Then
	If CommonCELClient.BSPIsUsed() Then
		Attributes = EquipmentManagerServerCall.CompatibilityOfExternalComponentFromFile(TemplateName);
		If ValueIsFilled(Attributes) Then
			Result = CurrentClientIsSupportedByAddIn(Attributes);
			Return Result = True; // The result may contain Indeterminate
		Else
			Return False;
		EndIf;
	Else
		Return True;
	EndIf;
#Else
	Return True;
#EndIf

EndFunction

Procedure SetConnectionModeOfComputerInformationExtension(Mode) Export
	
	If CommonCELClient.IsWebClient() Then
		ParameterName = "BPO.PerformInstallationOfComputerInformationExtension";
		CommonCELClient.Set_ApplicationParameter(ParameterName, Mode);
		EquipmentManagerClientOverridable.SetConnectionModeOfComputerInformationExtension(Mode);
	EndIf;
	
EndProcedure

#Region Workplaces

Procedure BeginGettingMACAddresses(NotificationProcessing, ShouldInstallExtension = True, LaunchingApplication = False) Export
	
#If WebClient Then
	Context = New Structure();
	Context.Insert("NotificationProcessing", NotificationProcessing);
	Context.Insert("ShouldInstallExtension", ShouldInstallExtension);
	Context.Insert("LaunchingApplication", LaunchingApplication);

	Notification = New CallbackDescription("BeginAttachingComputerInformationExtension_Completion", ThisObject, Context);
	BeginAttachingComputerInformationExtension(Notification);
#Else 
	GetInformationAboutNetworkAdapters(NotificationProcessing);
#EndIf
	
EndProcedure

Procedure BeginGettingMACAddressesCompletion(MACAddresses, Context) Export
	
	WorkplaceParameters = Peripherals().WorkplaceParameters;
	OldWorkplace = WorkplaceParameters.Workplace;
	
	CreateAWorkplace = True;
	DefineWorkplace(CreateAWorkplace);
	
	NewWorkPlace = WorkplaceParameters.Workplace;
	If OldWorkplace <> NewWorkPlace Then
		Notify("ChangedCurSessionWorkplace", NewWorkPlace);
	EndIf;
	
EndProcedure

// Performs the display of a list of workplaces for selecting a workplace to the Cur current web client ID
//
// Parameters:
//   ClientID - String
//   MACAddress - String
//
Procedure LinkWorkplaceToMACAddress(ClientID, MACAddress) Export
	
	ListOfWorkplaces = EquipmentManagerServerCall.LinkWorkplaceToMACAddress(ClientID, MACAddress); 
	If ListOfWorkplaces.Count()=0 Then
		Return;
	EndIf;
	Workplace = ListOfWorkplaces[0];
	Peripherals().Workplace = Workplace;
	Notify("ChangedCurSessionWorkplace", Workplace);
	
EndProcedure

Procedure DefineWorkplace(CreateAWorkplace = False) Export
	
	Peripherals = EquipmentManagerClient.Peripherals();
	WorkplaceParameters = Peripherals.WorkplaceParameters;
	RecordedAttributes = WorkplaceParameters.RecordedSearchAttributes;
	Current_Attributes = WorkplaceParameters.CurrentSearchAttributes;
	RecordedAttributesOfWorkplaceHaveChanged = False;
	ActualAttributesOfWorkplaceHaveChanged = False;
	
	// ++ Non-mobile application
	If Not CommonCELClient.IsWebClient() Then
		If IsBlankString(Current_Attributes.ComputerName) Then
			Current_Attributes.ComputerName = CommonCELClient.ClientSComputerName();
			ActualAttributesOfWorkplaceHaveChanged = True;
		EndIf;
		If RecordedAttributes.ComputerName <> Current_Attributes.ComputerName Then
			RecordedAttributesOfWorkplaceHaveChanged = True;
		EndIf;
	EndIf;
	
	MACAddressesFound = Peripherals.MACAddresses;
	If Current_Attributes.MACAddresses.Count() = 0 And MACAddressesFound.Count() > 0 Then
		Current_Attributes.MACAddresses = MACAddressesFound;
		ActualAttributesOfWorkplaceHaveChanged = True;
	EndIf;
	
	If Current_Attributes.MACAddresses.Count() > 0 Then
		MACAddressesAreDifferent = Not CommonCELClientServer.ArraysMatch(
			RecordedAttributes.MACAddresses, Current_Attributes.MACAddresses);
		If MACAddressesAreDifferent Then
			RecordedAttributesOfWorkplaceHaveChanged = True;
		EndIf;
	EndIf;
	// -- Non-mobile application
	
	Workplace = WorkplaceParameters.Workplace;
	If ValueIsFilled(Workplace) Then
		If RecordedAttributesOfWorkplaceHaveChanged Then
			EquipmentManagerServerCall.UpdateWorkplaceAttributes(Workplace, Current_Attributes);
			WorkplaceParameters.RecordedSearchAttributes = Current_Attributes;
		EndIf;
	Else
		If ActualAttributesOfWorkplaceHaveChanged Or CreateAWorkplace Then
			Workplace = EquipmentManagerServerCall.UpdateClientWorkplace(Current_Attributes, CreateAWorkplace);
			WorkplaceParameters.Workplace = Workplace;
			WorkplaceParameters.RecordedSearchAttributes = Current_Attributes;
		EndIf;
	EndIf;
	
	// called at the start of the system
	//  initial data:
	//   ID, Computer name, Arr address is not yet known
	//   try to find a workplace by ID, computer name
	//   in the web client you do not need to search by computer name because the computer name is not available
	
	
	// called after receiving Arr addresses
	//   ID, Computer name, Arr addresses
	//   if the rcvisits are filled in, then find the workplace by ID, computer name, Arr addresses
	//   if the actual Attributes and Attributes from the database differ
	//   , overwrite the workplace
	
	// called after receiving the Arr addresses and installing the extension component
	
	
EndProcedure

// ++ Non-mobile application 

Procedure DefineRDPWorkplace() Export
	
	Peripherals = Peripherals();
	WorkplaceParameters = Peripherals.WorkplaceParameters;
	RecordedAttributes = WorkplaceParameters.RecordedSearchAttributes;
	Current_Attributes = WorkplaceParameters.CurrentSearchAttributes;
	
	Workplace = WorkplaceParameters.Workplace;
	If ValueIsFilled(Workplace) Then
		ClientID = ClientIDForWorkplace();
		If RecordedAttributes.ClientID <> ClientID Then
			Parameters = New Structure;
			Parameters.Insert("ClientID", ClientID);
			Parameters.Insert("ComputerName", RecordedAttributes.ComputerName);
			Parameters.Insert("MACAddresses", RecordedAttributes.MACAddresses);
			QuestionIsToCreateWorkplaceAsync(WorkplaceParameters);
		EndIf;
	Else
		CreateAWorkplace = True;
		Workplace = EquipmentManagerServerCall.UpdateClientWorkplace(Current_Attributes, CreateAWorkplace);
		WorkplaceParameters.Workplace = Workplace;
	EndIf;
	
EndProcedure

// -- Non-mobile application 

#EndRegion

Function LibraryClassifiers() Export
	
	Peripherals = EquipmentManagerClient.Peripherals();
	Return Peripherals.LibraryClassifiers;
	
EndFunction

Function NewConnectionParameters() Export
	
	Result = New Structure;
	Result.Insert("CallingAtServer", False);
	Result.Insert("Host", "");
	Result.Insert("Port", 80);
	Result.Insert("Timeout", 2);
	Result.Insert("ResourceAddress", "");
	Result.Insert("Headers", New Map);
	Result.Insert("AccessToken", "");
	Return Result;
	
EndFunction

Async Function CallHTTPMethodAsync(Method, ConnectionParameters) Export
	
	If ConnectionParameters = Undefined Then
		ConnectionParameters = NewConnectionParameters();
	EndIf;
	
	Peripherals = Peripherals();
	CallingAtServer = Peripherals.CheckingMaxSAgeAtServer;
	If CallingAtServer Then
		Result = EquipmentManagerServerCall.CallHTTPMethodServer(Method, ConnectionParameters);
		If Result.Timeout Then
			Result = Await CallHTTPMethodClientAsync(Method, ConnectionParameters);
		EndIf;
	Else
		Result = Await CallHTTPMethodClientAsync(Method, ConnectionParameters);
		If Result.Timeout Then
			Result = EquipmentManagerServerCall.CallHTTPMethodServer(Method, ConnectionParameters);
		EndIf;
	EndIf;
	Peripherals.CheckingMaxSAgeAtServer = Result.CallingAtServer;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Processes event data received from the client.
// 
// Parameters:
//   Connection - Structure
//  EventDescription1 - Structure:
//   * Source - String - Source of the external event.
//   * Event - String - name of the event.
//   * Data - String - the data for the event.
//  ErrorDescription - String - error description
//
// Returns:
//  Boolean
//
Function ProcessEventFromNonCertifiedDriver(Connection, EventDescription1, ErrorDescription = "") Export
	
	Data = EventDescription1.Data;
	Event = EventDescription1.Event;
	Result = True;
	StandardProcessing = True;
	If CommonCELClient.NonCertifiedEquipmentIsUsed() Then
		ModuleNonCertifiedEquipmentClientOverridable = CommonCELClient.CommonModule("UncertifiedPeripheralsClientOverridable");
		ModuleNonCertifiedEquipmentClientOverridable.ProcessEvent(Connection, Event, Data, StandardProcessing);
		If StandardProcessing Then
			Event = Connection.EventNames.Find(EventDescription1.Event);
			If Event <> Undefined Then
				If Result Then 
					Notify(Event, Data, "Peripherals");
				Else
					Result = False;
					ErrorDescription = EventDescription1.Event;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#Region GettingMACAddress

Procedure BeginAttachingComputerInformationExtension_Completion(Result, Context) Export
	
	NotificationProcessing = Context.NotificationProcessing;
	ShouldInstallExtension = Context.ShouldInstallExtension;
	LaunchingApplication = Context.LaunchingApplication;
	
	If Result Then
		GetInformationAboutNetworkAdapters(NotificationProcessing);
	Else
		If LaunchingApplication Then
			// When launching the application, you do not need to create a workplace, 
			// because the browser extension has not yet been installed, the extension
			// will be installed later when accessing the hardware.
			Return;
		EndIf;
		If ShouldInstallExtension Then
			InstallExtensionUsingBPO(NotificationProcessing);
		Else
			If NotificationProcessing <> Undefined Then 
				RunCallback(NotificationProcessing, Undefined);
			EndIf;     
		EndIf;
			
	EndIf;
		
EndProcedure

Procedure InstallExtensionUsingBPO(NotificationProcessing)
	
	ParameterName = "BPO.PerformInstallationOfComputerInformationExtension";
	Perform_Installation = CommonCELClient.ParameterOfApplication(ParameterName);
	If Perform_Installation = Undefined Then
		Perform_Installation = True;
	EndIf;
	If Perform_Installation Then
		Notification = New CallbackDescription("ShowStartConnectionExtensionQuestion_Completion", ThisObject, NotificationProcessing);
		Try
			OpenForm("CommonForm.QuestionOfInstallingExtensionForWorkingWithComputerCEL",,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		Except
			CommonCELClient.WriteErrorToEventLog(
				NStr("vi = 'Cài đặt phần mở rộng Thư viện thiết bị được kết nối';
					|ru = 'Установка расширения БПО';
					|en = 'Install PEL extension'; fa = 'Install PEL extension';
					|it = 'Install PEL extension';
					|pl = 'Install PEL extension';
					|tr = 'EDK uzantısının yüklenmesi'"),
				NStr("vi = 'Không thể mở biểu mẫu hỏi cài đặt phần mở rộng, có thể là không đủ quyền xem biểu mẫu chỉ định.';
					|ru = 'Не удается открыть форму вопроса об установке расширения, возможно нет права просмотра для указанной формы.';
					|en = 'Cannot open the extension installation question form. You might have no right to view the specified form.'; fa = 'Cannot open the extension installation question form. You might have no right to view the specified form.';
					|it = 'Cannot open the extension installation question form. You might have no right to view the specified form.';
					|pl = 'Cannot open the extension installation question form. You might have no right to view the specified form.';
					|tr = 'Uzantının yüklenmesiyle ilgili soru formu açılamıyor, belirtilen form için görüntüleme yetkisi olmayabilir.'"));
			If NotificationProcessing <> Undefined Then 
				RunCallback(NotificationProcessing, Undefined);
			EndIf;     
		EndTry;
	Else
		If NotificationProcessing <> Undefined Then 
			RunCallback(NotificationProcessing, Undefined);
		EndIf;     
	EndIf;
	
EndProcedure

Procedure ShowStartConnectionExtensionQuestion_Completion(Result, NotificationProcessing) Export
	
	If Result = DialogReturnCode.Yes Then
#If WebClient Then
		Notification = New CallbackDescription("BeginInstallingComputerInformationExtension_Completion", ThisObject, NotificationProcessing);
		BeginInstallingComputerInformationExtension(Notification);
#EndIf
	Else
		
		SetConnectionModeOfComputerInformationExtension(False);
		
		If NotificationProcessing <> Undefined Then 
			RunCallback(NotificationProcessing, Undefined);
		EndIf;     
	EndIf;     
	
EndProcedure

Procedure BeginInstallingComputerInformationExtension_Completion(NotificationProcessing) Export
	
	Context = New Structure();
	Context.Insert("NotificationProcessing", NotificationProcessing);
	Context.Insert("ShouldInstallExtension", False); // if the extension is not installed, do not re-install
	Context.Insert("LaunchingApplication", False);
	
#If WebClient Then
	Notification = New CallbackDescription("BeginAttachingComputerInformationExtension_Completion", ThisObject, Context);  
	BeginAttachingComputerInformationExtension(Notification);
#EndIf
	
EndProcedure 

Procedure GetInformationAboutNetworkAdapters(NotificationProcessing) Export
	
#If MobileClient Or MobileAppClient Then
	
	BeginGettingNetworkAdaptersInformationCompletion(New Array(), NotificationProcessing);
	
#Else
	Notification = New CallbackDescription("BeginGettingNetworkAdaptersInformationCompletion", ThisObject, NotificationProcessing);   
	BeginGettingNetworkAdaptersInformation(Notification);
	
#EndIf
	
EndProcedure 

Procedure BeginGettingNetworkAdaptersInformationCompletion(Result, NotificationProcessing) Export
	
	MACAddresses = New Array;
	For Each AdapterInformation In Result Do
		MACAddresses.Add(AdapterInformation.MACAddress);
	EndDo;
	Peripherals().MACAddresses = MACAddresses;
	
	If NotificationProcessing <> Undefined Then 
		RunCallback(NotificationProcessing, MACAddresses);
	EndIf;
	
EndProcedure

#EndRegion

#Region ConnectingEquipment

// Start connecting devices.
//
// Parameters:
//  ClientID - UUID - the unique identifier of the client.
//  SoftwareTypes - Structure, Array of String, String - the type of equipment to select the device.
//  DeviceID - Array of String, CatalogRef.Peripherals - connected device.
//  NetworkEquipment - Boolean - use network equipment when connecting.
//
// Returns:
//  Structure - Results of connecting devices.
//
Function DevicesForConnection(ClientID, SoftwareTypes = Undefined, DeviceID = Undefined, NetworkEquipment = False)

	Peripherals_ = New Array(); // Device connection results
	EquipmentForConnection = New Array();
	
	CurrentLanguage = CurrentLanguage();
	UserLanguageCode = ?(TypeOf(CurrentLanguage) = Type("String"), CurrentLanguage, CurrentLanguage.LanguageCode); 
	
	If ThisIsListOfEquipment(SoftwareTypes) Then
		EquipmentList = SoftwareTypes;
	Else
		EquipmentSelection = EquipmentManagerClientServer.ListOfEquipmentSelection();
		EquipmentSelection.SoftwareTypes = SoftwareTypes;
		EquipmentSelection.Id = DeviceID;
		EquipmentSelection.NetworkEquipment = NetworkEquipment;
		EquipmentSelection.LanguageCode = UserLanguageCode;
		EquipmentList = EquipmentManagerServerCall.EquipmentList(EquipmentSelection); 
	EndIf;
	
	If EquipmentList.Count() > 0 Then
		For Each Device In EquipmentList Do
			// Let's check if the device is not connected earlier.
			ConnectedDevice = GetConnectedDevice(Device.Ref);
			If ConnectedDevice = Undefined Then // If the device has not been connected before.
				
				If Device.NetworkEquipment And Not Device.AvailableToCurrentUser Then
					ErrorDescription = NStr("vi = 'Không có quyền sử dụng đối với người sử dụng này.';
											|ru = 'Нет прав на использование для текущего пользователя.';
											|en = 'There are no access rights to use for the current user.'; fa = 'There are no access rights to use for the current user.';
											|it = 'Non vi sono diritti di utilizzo per l''utente corrente.';
											|pl = 'Brak praw do użycia dla bieżącego użytkownika.';
											|tr = 'Mevcut kullanıcı için kullanım yetkisi yoktur.'");
					Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
					Result.ObjectID = Device.ObjectID;
					Peripherals_.Add(Result);
					Continue;
				EndIf;
				
				EquipmentForConnection.Add(Device);
				
			Else // The device was connected earlier.
				// We will increase the number of users of this connection.
				ConnectedDevice.Customers.Add(ClientID);
				ConnectedDevice.NumberOfConnectedDevices = ConnectedDevice.NumberOfConnectedDevices + 1;
				Result = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, Undefined, Device.Ref);
				Result.ConnectedDevice = ConnectedDevice;
				Result.ObjectID   = Device.ObjectID;
				Peripherals_.Add(Result);
			EndIf;
		EndDo;
		
	ElsIf DeviceID <> Undefined Then
		ErrorDescription = 
			NStr("vi = 'Thiết bị không có tại chỗ làm việc hiện tại và không thể được sử dụng để kết nối. Hãy chỉ ra thiết bị khác.';
				|ru = 'Устройство отсутствует на текущем рабочем месте и не может использоваться для подключения. Укажите другое устройство.';
				|en = 'The device is missing from the current workplace. You cannot use it for connection. Specify another device.'; fa = 'The device is missing from the current workplace. You cannot use it for connection. Specify another device.';
				|it = 'Устройство отсутствует на текущем рабочем месте и не может использоваться для подключения. Укажите другое устройство.';
				|pl = 'The device is missing from the current workplace. You cannot use it for connection. Specify another device.';
				|tr = 'Cihaz mevcut çalışma alanında değil ve bağlanmak için kullanılamaz. Farklı bir cihaz belirt.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
		Peripherals_.Add(ExecutionResult);
	ElsIf SoftwareTypes = Undefined And DeviceID = Undefined Then
		ErrorDescription =  NStr("vi = 'Không có thiết bị khả dụng để kết nối.';
								|ru = 'Нет доступного оборудования для подключения.';
								|en = 'No available peripherals for connection.'; fa = 'No available peripherals for connection.';
								|it = 'Nessun hardware disponibile per la connessione.';
								|pl = 'Brak dostępnych urządzeń do podłączenia.';
								|tr = 'Bağlanacak kullanılabilir ekipman mevcut değil.'");
		ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, ErrorDescription);
		Peripherals_.Add(ExecutionResult);
	EndIf; 
	
	Result = New Structure();
	Result.Insert("Peripherals_", Peripherals_);
	Result.Insert("EquipmentForConnection", EquipmentForConnection);
	Return Result;
	
EndFunction

Procedure FillInSupportedTypesOfConnectedEquipmentOnForm(Form, SupportedPeripheralTypes)
	
	If SupportedPeripheralTypes = Undefined Then
		SupportedPeripheralTypes = "";
	EndIf;
	
	If TypeOf(Form.SupportedPeripheralTypes) = Type("String") Then
		
		If TypeOf(SupportedPeripheralTypes) = Type("Structure") Then
			Form.SupportedPeripheralTypes = StructureTypeOfEquipmentPerLine(SupportedPeripheralTypes);
		Else
			Form.SupportedPeripheralTypes = SupportedPeripheralTypes;
		EndIf;
		
	ElsIf TypeOf(Form.SupportedPeripheralTypes) = Type("Structure") Then
		
		Form.SupportedPeripheralTypes = SupportedPeripheralTypes;
		
	ElsIf TypeOf(Form.SupportedPeripheralTypes) = Type("Array") Then
		
		TypesOfEquipment = ArrayOfEquipmentTypes(SupportedPeripheralTypes);
		Form.SupportedPeripheralTypes = TypesOfEquipment;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DisablingEquipment

// The function disables devices
//
// Parameters:
//  Client ID - Unique identifier
//  SoftwareTypes - Structure, Array of String, String - the type of equipment for disconnecting devices.
//  DeviceID - CatalogRef.Peripherals - the device being disconnected.
//      
// Returns:
//  Array of CatalogRef.Peripherals - Results of device disconnection.
//  
Function DevicesForDisconnection(SoftwareTypes = Undefined, DeviceID = Undefined) Export
	
	DisabledEquipment  = New Array(); // Device shutdown results  
	Peripherals = Peripherals();
	
	If SoftwareTypes <> Undefined Then
		ConnectedDevices = GetConnectedDevices(SoftwareTypes);
	ElsIf DeviceID <> Undefined Then   
		ConnectedDevice = GetConnectedDevice(DeviceID);
		If ConnectedDevice <> Undefined Then        
			ConnectedDevices = New Array();
			ConnectedDevices.Add(ConnectedDevice);
		Else
			Return DisabledEquipment; 
		EndIf;   
	Else
		Return DisabledEquipment; 
	EndIf;
	
	Return ConnectedDevices;
	
EndFunction  

#EndRegion

#Region CREWithDataTransfer

// Additional error handling procedure.
// 
// Parameters:
//  ExecutionResult - Structure 
//
Procedure AdditionalErrorHandling(ExecutionResult)     
	
	ErrorDescription = ExecutionResult.ErrorDescription;
	
	If StrFind(Upper(ErrorDescription), Upper(NStr("vi = 'Không hỗ trợ trong phiên bản này';
													|ru = 'Не поддерживается в данной версии';
													|en = 'Not supported in this version'; fa = 'Not supported in this version';
													|it = 'Не поддерживается в данной версии';
													|pl = 'Not supported in this version';
													|tr = 'Bu sürümde desteklenmemektedir'"))) > 0 Then
		ErrorDescription = NStr("vi = 'Không hỗ trợ trong phiên bản này.';
								|ru = 'Не поддерживается в данной версии.';
								|en = 'Not supported in this version.'; fa = 'Not supported in this version.';
								|it = 'Не поддерживается в данной версии.';
								|pl = 'Not supported in this version.';
								|tr = 'Bu sürümde desteklenmemektedir.'") 
		+ Chars.NBSp + NStr("vi = 'Hãy cập nhật phần lõi MTT đến phiên bản mới nhất.';
							|ru = 'Обновите прошивку ККТ до актуальной версии.';
							|en = 'Update the cash register firmware to the latest version.'; fa = 'Update the cash register firmware to the latest version.';
							|it = 'Обновите прошивку ККТ до актуальной версии.';
							|pl = 'Update the cash register firmware to the latest version.';
							|tr = 'YKE donanım yazılımını en son sürüme güncelleyin.'");
	EndIf;
	
	ExecutionResult.ErrorDescription = ErrorDescription; 
	
EndProcedure

// The function returns the ID of the open session for the fiscal device.
// 
// Parameters:
//  DeviceID - UUID - Device ID
// 
// Returns:
//  Undefined - Marking code verification session
Function MarkingCodeVerificationSession(DeviceID) Export
	
	Peripherals = Peripherals();
	FiscalDevices = Peripherals.FiscalDevices;
	
	SessionID = Undefined;
	For Each FiscalDevice In FiscalDevices Do
		If FiscalDevice.DeviceID = DeviceID Then
			SessionID = FiscalDevice.SessionID;
			Break;
		EndIf;
	EndDo;
	
	Return SessionID;
	
EndFunction

// The procedure saves the ID of the open session for the fiscal device.
//
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device.
//  SessionID - String
//  QueryID - String
//
Procedure EstablishMarkingCodeVerificationSession(DeviceID, SessionID = Undefined, QueryID = Undefined) Export
	
	Peripherals = Peripherals();
	FiscalDevices = Peripherals.FiscalDevices;
	
	For Each FiscalDevice In FiscalDevices Do
		If FiscalDevice.DeviceID = DeviceID Then
			FiscalDevice.SessionID = SessionID;
			Return;
		EndIf;
	EndDo;
	
	FiscalDevice = New Structure();
	FiscalDevice.Insert("DeviceID", DeviceID);
	FiscalDevice.Insert("SessionID" , SessionID);
	FiscalDevice.Insert("QueryID", QueryID);
	FiscalDevices.Add(FiscalDevice);
	
EndProcedure

// The function returns whether the device checks the marking code.
// 
// Parameters:
//  DeviceID - UUID -Device ID
// 
// Returns:
//  Structure - Checking The Marking Code:
//   * SessionID - UUID
//   * QueryID - UUID
//
Function CheckingMarkingCode(DeviceID) Export
	
	Result = New Structure();
	Result.Insert("SessionID");
	Result.Insert("QueryID");   
	Result.Insert("DeviceID", DeviceID);     
	
	Peripherals = Peripherals();
	FiscalDevices = Peripherals.FiscalDevices;
	
	For Each FiscalDevice In FiscalDevices Do
		If FiscalDevice.DeviceID = DeviceID Then
			Result.SessionID  = FiscalDevice.SessionID;
			Result.QueryID = FiscalDevice.QueryID;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// The procedure retains the status of checking the marking code.
// 
// Parameters:
//  DeviceID - UUID - Device ID.
//  QueryID - Undefined - Request ID
//
Procedure InstallMarkingCodeVerification(DeviceID, QueryID = Undefined) Export
	
	Peripherals = Peripherals();
	FiscalDevices = Peripherals.FiscalDevices;
	
	For Each FiscalDevice In FiscalDevices Do
		If FiscalDevice.DeviceID = DeviceID Then
				FiscalDevice.QueryID = QueryID;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

// The result of checking the marking code.
// 
// Parameters:
//  DeviceID - UUID - Device ID
//  SessionID - UUID - session ID
//  KmRequestParameters_ -Structure - KM request parameters.
// 
// Returns:
//  Undefined - Result of checking the marking code
Function ResultOfCheckingMarkingCode(DeviceID, SessionID, KmRequestParameters_) Export
	
	CheckResult  = Undefined;
	Peripherals = Peripherals();
	MarkingCodeChecks = Peripherals.MarkingCodeChecks;
	
	For Each CheckingMarkingCode In MarkingCodeChecks Do
		If CheckingMarkingCode.DeviceID = DeviceID
			And CheckingMarkingCode.SessionID = SessionID
			And CheckingMarkingCode.KmRequestParameters_.ControlMark = KmRequestParameters_.ControlMark  
			And CheckingMarkingCode.KmRequestParameters_.Count = KmRequestParameters_.Count
			And CheckingMarkingCode.KmRequestParameters_.PlannedProductStatus = KmRequestParameters_.PlannedProductStatus Then
				CheckResult = CheckingMarkingCode.CheckResult;
			Break;
		EndIf;
	EndDo;
	
	Return CheckResult;
	
EndFunction

// The procedure establishes the result of checking the marking code.
// 
// Parameters:
//  DeviceID - UUID - Device ID.
//  SessionID - UUID
//  KmRequestParameters_ - Structure
//  CheckResult - Structure
//  QueryID - UUID
//
Procedure SetResultOfCheckingMarkingCode(DeviceID, SessionID, KmRequestParameters_, CheckResult, QueryID = Undefined) Export
	
	Peripherals = Peripherals();
	FiscalDevices = Peripherals.FiscalDevices;
	For Each FiscalDevice In FiscalDevices Do
		If FiscalDevice.DeviceID = DeviceID Then
			   FiscalDevice.QueryID = QueryID;
			Break;
		EndIf;
	EndDo;
	
	MarkingCodeChecks = Peripherals.MarkingCodeChecks;
	For Each CheckingMarkingCode In MarkingCodeChecks Do
		If CheckingMarkingCode.DeviceID = DeviceID
			And CheckingMarkingCode.SessionID = SessionID
			And CheckingMarkingCode.KmRequestParameters_.ControlMark = KmRequestParameters_.ControlMark  
			And CheckingMarkingCode.KmRequestParameters_.Count = KmRequestParameters_.Count
			And CheckingMarkingCode.KmRequestParameters_.PlannedProductStatus = KmRequestParameters_.PlannedProductStatus Then
				CheckingMarkingCode.CheckResult = CheckResult;
			Return;
		EndIf;
	EndDo;                             
	
	CheckingMarkingCode = New Structure();
	CheckingMarkingCode.Insert("DeviceID", DeviceID);
	CheckingMarkingCode.Insert("SessionID", SessionID);
	CheckingMarkingCode.Insert("KmRequestParameters_" , KmRequestParameters_);
	CheckingMarkingCode.Insert("CheckResult"  , CheckResult);  
	
	MarkingCodeChecks.Add(CheckingMarkingCode);
	
EndProcedure


#EndRegion

#Region CommandExecution

// End execution of the command
// 
// Parameters:
//  OperationResult - Structure
//  ParametersCommandExecution - Structure
//
Procedure EndExecutionOfCommand(OperationResult, ParametersCommandExecution) Export
	
	If ParametersCommandExecution.Property("MessagesToTechSupportService") 
		And ParametersCommandExecution.MessagesToTechSupportService 
		And CommonCELClient.UsedMessagesToTechnicalSupportService() Then
		
		MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
		
		// ++ Non-mobile application
		If Not OperationResult.Result Then
			
			ErrorAnalysisResult = HardwareErrorTextAnalysis(ParametersCommandExecution.DeviceID, OperationResult.ErrorDescription);
			OperationResult.ErrorDescription = ErrorAnalysisResult.ErrorDescription;
			LocalError_Handling = ErrorAnalysisResult.LocalError_Handling;
			If Not LocalError_Handling Then  
				ParametersCommandExecution.Insert("ResultOfOperation", OperationResult);
				CallbackDescription = New CallbackDescription("EndExecutionOf_Command_ResultCheck", ThisObject, ParametersCommandExecution);
				
				ErrorDescription = ErrorAnalysisResult.ErrorDescription;
				ShortDescription = ErrorAnalysisResult.ShortDescription;
				AdditionalData = New Structure();
				AdditionalData.Insert("Operation",          ParametersCommandExecution.Command);
				AdditionalData.Insert("ErrorDescription",    ErrorDescription);
				AdditionalData.Insert("OperationParametersList", ParametersCommandExecution.OperationParametersList);
				
				QueryText = StrTemplate(NStr("vi = '%1
				|
				|Tạo thông báo về lỗi đến bộ phận hỗ trợ?';
				|ru = '%1
				|
				|Создать сообщение об ошибке в службу поддержки?';
				|en = '%1
				|
				|Create a message about an error to support team?'; fa = '%1
				|
				|Create a message about an error to support team?';
				|it = '%1
				|
				|Создать сообщение об ошибке в службу поддержки?';
				|pl = '%1
				|
				|Create a message about an error to support team?';
				|tr = '%1
				|
				|Destek hizmeti hatası mesajı oluşturulsun mu?'"), ErrorDescription);
			
				Parameters = MessageModuleToBPOTechnicalSupportServiceClient.ParametersForSendingErrorMessage();
				Parameters.Insert("HardwareId", ParametersCommandExecution.DeviceID);
				Parameters.Insert("ErrorText",               ShortDescription + ". " + OperationResult.ErrorDescription);
				Parameters.Insert("AdditionalData",      AdditionalData);
				Parameters.Insert("QueryText",              QueryText);
			
				MessageModuleToBPOTechnicalSupportServiceClient.ShowMandrelIssueErrorMessages(CallbackDescription, Parameters);
				
				Return; // The alert call will be executed in the command completion procedure_Checking the result
			EndIf;
			
		EndIf;
		// -- Non-mobile application
		
	EndIf;
	
	RunCallback(ParametersCommandExecution.NotificationOnCompletion, OperationResult); 
	
EndProcedure

// Completes verification of the operation result
// 
// Parameters:
//  Result - Structure
//  ParametersCommandExecution - see Operation Result check parametersreferences     
//
Procedure EndExecutionOf_Command_ResultCheck(Result, ParametersCommandExecution) Export
	
	If ParametersCommandExecution.NotificationOnCompletion <> Undefined Then
		RunCallback(ParametersCommandExecution.NotificationOnCompletion, ParametersCommandExecution.ResultOfOperation);
	EndIf;
	
EndProcedure

// ++ Non-mobile application

Function HardwareErrorTextAnalysis(DeviceID, ErrorDescription) 
	
	ConnectionParameters = GetConnectedDevice(DeviceID);
	ConnectionParametersServer = New Structure;
	ConnectionParametersServer.Insert("DeviceID_");
	ConnectionParametersServer.Insert("DriverVersion");
	If ConnectionParameters <> Undefined Then
		FillPropertyValues(ConnectionParametersServer, ConnectionParameters);
	EndIf;
	
	Return EquipmentManagerServerCall.HardwareErrorTextAnalysis(DeviceID, ConnectionParametersServer, ErrorDescription);
	
	
EndFunction

// -- Non-mobile application

#EndRegion

#Region Workplaces

Function CurrentWorkplaceAttributes()
	
	WorkplaceAttributes = EquipmentManagerClientServer.NewWorkplaceSearchAttributes();
	
	WorkplaceAttributes.ClientID = EquipmentManagerClientServer.ClientIDForWorkplace();
	WorkplaceAttributes.ComputerName = CommonCELClient.ClientSComputerName();
	WorkplaceAttributes.MACAddresses = Peripherals().MACAddresses;
	
	Return WorkplaceAttributes;
	
EndFunction

// ++ Non-mobile application 

Async Procedure QuestionIsToCreateWorkplaceAsync(WorkplaceParameters)
	
	CurCurrentRM = EquipmentManagerClient.CustomerWorkplace();
	QueryText = StrTemplate(NStr("vi = 'Đối với người sử dụng hiện tại %1 không trùng ID của client tại chỗ làm việc này %2.
					  |Có thể là, đã thay đổi các đặc tính của server RDP.
					  |Hãy chọn thao tác sau đây hoặc liên hệ với người quản trị:
					  |1. Cập nhật ID tại chỗ làm việc hiện tại.
					  |2. Tạo mới chỗ làm việc.
					  |3. Tiếp tục làm việc.';
					  |ru = 'Для текущего пользователя %1 не совпадает идентификатор клиента на текущем рабочем месте %2.
					  |Возможно поменялись характеристики сервера RDP.
					  |Выберите дальнейшее действие, или обратитесь к администратору:
					  |1. Обновить идентификатор у текущего рабочего места.
					  |2. Создать новое рабочее место.
					  |3. Продолжить работу.';
					  |en = 'For the current user (%1), the client ID at the current workplace (%2) does not match.
					  |The RDP server characteristics might change.
					  |Select a further action or contact the administrator:
					  |1. Update the ID of the current workplace.
					  |2. Create a new workplace.
					  |3. Continue working.'; fa = 'For the current user (%1), the client ID at the current workplace (%2) does not match.
					  |The RDP server characteristics might change.
					  |Select a further action or contact the administrator:
					  |1. Update the ID of the current workplace.
					  |2. Create a new workplace.
					  |3. Continue working.';
					  |it = 'Для текущего пользователя %1 не совпадает идентификатор клиента на текущем рабочем месте %2.
					  |Возможно поменялись характеристики сервера RDP.
					  |Выберите дальнейшее действие, или обратитесь к администратору:
					  |1. Обновить идентификатор у текущего рабочего места.
					  |2. Создать новое рабочее место.
					  |3. Продолжить работу.';
					  |pl = 'For the current user (%1), the client ID at the current workplace (%2) does not match.
					  |The RDP server characteristics might change.
					  |Select a further action or contact the administrator:
					  |1. Update the ID of the current workplace.
					  |2. Create a new workplace.
					  |3. Continue working.';
					  |tr = 'Mevcut %2 çalışma alanında mevcut %1 kullanıcısı için istemci kimliği eşleşmiyor. 
					  |RDP sunucusunun özellikleri değiştirilmiş olabilir. 
					  |Başka bir eylem seçin veya yöneticinize danışın: 
					  |1. Mevcut çalışma alanının kimliğini güncelleyin. 
					  |2. Yeni bir çalışma alanı oluşturun. 
					  |3. Çalışmaya devam edin.'"), UserName(), CurCurrentRM);
		
	Buttons = New ValueList();
	Buttons.Add("Refresh", NStr("vi = 'Cập nhật';
								|ru = 'Обновить';
								|en = 'Update'; fa = 'به‌روزرسانی';
								|it = 'Обновить';
								|pl = 'Zaktualizuj';
								|tr = 'Güncelle'"));
	Buttons.Add("Create", NStr("vi = 'Tạo mới';
								|ru = 'Создать';
								|en = 'Create'; fa = 'ایجاد';
								|it = 'Создать';
								|pl = 'Utwórz';
								|tr = 'Oluştur'"));
	Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
								|ru = 'Продолжить';
								|en = 'Continue'; fa = 'ادامه';
								|it = 'Продолжить';
								|pl = 'Continue';
								|tr = 'Devam et'"));
	Response = Await DoQueryBoxAsync(QueryText, Buttons, , "Refresh");
	Current_Attributes = WorkplaceParameters.CurrentSearchAttributes;
	If Response = "Create" Then
		CreateAWorkplace = True;
		Workplace = EquipmentManagerServerCall.CreateCustomerWorkplace(Current_Attributes);
		WorkplaceParameters.Workplace = Workplace;
	ElsIf Response = "Refresh" Then
		EquipmentManagerServerCall.UpdateWorkplaceId(
			CurCurrentRM, Current_Attributes.ClientID);
	EndIf;
	
EndProcedure

// -- Non-mobile application 

#EndRegion

#Region SimplifyingParameterSettings

// returns a dictionary of Attributes and possible names of driver manufacturer parameters
//
// Returns:
//  See EquipmentManagerClientCached.DictionaryOfKeyProperties
Function DictionaryOfKeyProperties() 
	
	Return EquipmentManagerClientCached.DictionaryOfKeyProperties();
	
EndFunction

// Returns the parameter name based on the parameter name specified in the XML file
//
// Parameters:
//  NameOfXMLParameter - String - the name of the hardware parameter specified in the XML file
//  Transformation_ - Boolean
//
// Returns:
//  String, Undefined - if the parameter name is found in the dictionary, returns the name of the standard parameter
Function KeyParameterName(NameOfXMLParameter, Transformation_ = Undefined)
	
	Dictionary = DictionaryOfKeyProperties();
	
	For Each KeyValue In Dictionary Do
		If KeyValue.Value.Property(NameOfXMLParameter, Transformation_) Then
			Return KeyValue.Key;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns the structure attributes of the parameter
//
// Returns:
//  Structure:
//   * Standard - Boolean - the Attribute is provided by the bpo standards
//   * NameOfXMLParameter - String - the name of the parameter as it is set by the hardware manufacturer
//   * ParameterName - String - name of the standard parameter
//   * AttributeName - String - the name of the Attribute under which the value of this parameter is stored in the Catalog
//   * ReadOnly - Boolean - the parameter is read-only
//   * Type - Type - Type of parameter value (Number, String, Boolean)
//   * Title - String - Parameter Header
//   * DefaultValue - Number, String, Boolean - default parameter value
//   * LongDesc - String - parameter description
//   * FormattingString - String - parameter formatting string
//   * ChoiceList - ValueList of String - possible options for the parameter value
// 
Function NewParameterAttributes()
	
	Result = New Structure();
	Result.Insert("Standard",          False);
	Result.Insert("ValueOfStandard", "");
	Result.Insert("NameOfXMLParameter",      "");
	Result.Insert("ParameterName",         "");
	Result.Insert("AttributeName",         "");
	Result.Insert("ReadOnly",         False);
	Result.Insert("Type",                  Type("Number"));
	Result.Insert("Title",            "");
	Result.Insert("DefaultValue",  "");
	Result.Insert("LongDesc",             "");
	Result.Insert("FormattingString", "");
	Result.Insert("ChoiceList",         New ValueList());
	Result.Insert("Transformation_",       "");
	
	Return Result;
EndFunction

// Returns the structure attributes of the parameter
//
// Parameters:
//  XMLReader - XMLReader - an XML object that is open for reading
//
// Returns:
//  Structure - See NewParameterAttributes
Function ReadParameterAttributes(XMLReader)
	
	NameOfXMLParameter =  XMLReader.AttributeValue("Name");
	Transformation_  = Undefined;
	ParameterName    = KeyParameterName(NameOfXMLParameter, Transformation_);
	If ParameterName = Undefined Then
		Return Undefined;
	EndIf;
	
	AttributeValue = Upper(XMLReader.AttributeValue("ReadOnly"));
	ReadOnly     = (AttributeValue = "TRUE" Or AttributeValue = "TRUE");
	
	AttributeValue = Upper(XMLReader.AttributeValue("TypeValue"));
	ParameterType      = ?(Not IsBlankString(AttributeValue), AttributeValue, "STRING");
	
	Result = NewParameterAttributes();
	Result.NameOfXMLParameter = NameOfXMLParameter;
	Result.ParameterName    = ParameterName;
	Result.Type             = Type(ParameterType);
	Result.ReadOnly    = ReadOnly;
	Result.AttributeName    = ?(ReadOnly, "R_", "P_") + NameOfXMLParameter;
	Result.Title       = XMLReader.AttributeValue("Caption");
	Result.LongDesc        = XMLReader.AttributeValue("Description");
	Result.Transformation_  = Transformation_;
	Result.DefaultValue  = XMLReader.AttributeValue("DefaultValue");
	Result.FormattingString = XMLReader.AttributeValue("FieldFormat");
	
	Return Result;
EndFunction

// Fills in the selection list in the parameter attributes from XML
//
// Parameters:
//  ParameterAttributes - Structure - in which you need to enter the selection list
//  XMLReader - XMLReader - an XML object that is open for reading
Procedure ReadSelectionList(ParameterAttributes, XMLReader)
	
	#If Not WebClient Then
	ChoiceList = New ValueList();
	ParameterAttributes.Insert("ChoiceList", ChoiceList);
	
	While XMLReader.Read() Do
		If XMLReader.Name = "ChoiceList" And XMLReader.NodeType = XMLNodeType.EndElement Then  
			Break;
		ElsIf XMLReader.Name = "Item" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			Value = XMLReader.AttributeValue("Value");
		ElsIf XMLReader.Name = "#text" And XMLReader.NodeType = XMLNodeType.Text Then  
			Presentation = XMLReader.Value;
		ElsIf XMLReader.Name = "Item" And XMLReader.NodeType = XMLNodeType.EndElement Then  
			ChoiceList.Add(Value, Presentation);
		EndIf;
	EndDo;
	#EndIf

EndProcedure

// Fill in the structure of standard parameters according to the interface description
//
// Parameters:
//  InterfaceDescription - String - the XML string containing the interface description
//  KeyParameters - Structure - a structure containing the found key parameters and their attributes
Procedure ReadAttributesOfKeyParameters(InterfaceDescription, KeyParameters)
	
	#If Not WebClient Then
	XMLReader = New XMLReader; 
	XMLReader.SetString(InterfaceDescription);
	XMLReader.MoveToContent();
	
	ParameterAttributes = Undefined;
	If XMLReader.Name = "Settings" And XMLReader.NodeType = XMLNodeType.StartElement Then
		While XMLReader.Read() Do  
			If XMLReader.Name = "ChoiceList" And XMLReader.NodeType = XMLNodeType.StartElement Then  
				If ParameterAttributes <> Undefined Then
					ReadSelectionList(ParameterAttributes, XMLReader);
				EndIf;
			ElsIf XMLReader.Name = "Parameter" And XMLReader.NodeType = XMLNodeType.StartElement Then  
				ParameterAttributes = ReadParameterAttributes(XMLReader);
				If ParameterAttributes <> Undefined Then
					KeyParameters.Insert(ParameterAttributes.ParameterName, ParameterAttributes);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	#EndIf
	
EndProcedure

Procedure AddDriverLogParameterEnabled(KeyParameters, Value)
	
	ParameterAttributes = NewParameterAttributes();
	ParameterAttributes.Standard     = True;
	ParameterAttributes.NameOfXMLParameter = "";
	ParameterAttributes.ParameterName    = "LogEnabled";
	ParameterAttributes.Type             = Type("Boolean");
	ParameterAttributes.ReadOnly    = True;
	ParameterAttributes.AttributeName    = "";
	ParameterAttributes.Title       = NStr("vi = 'Đã bật sử dụng nhật ký';
											|ru = 'Включен лог';
											|en = 'The log is enabled'; fa = 'The log is enabled';
											|it = 'Включен лог';
											|pl = 'The log is enabled';
											|tr = 'Log etkin'");
	ParameterAttributes.LongDesc        = "";
	ParameterAttributes.Transformation_  = "";
	ParameterAttributes.ValueOfStandard = Value;
	ParameterAttributes.DefaultValue  = False;
	ParameterAttributes.FormattingString = "";
	
	KeyParameters.Insert(ParameterAttributes.ParameterName, ParameterAttributes);

EndProcedure

Procedure AddDriverLogParameterFilePath(KeyParameters, Value)
	
	ParameterAttributes = NewParameterAttributes();
	ParameterAttributes.Standard     = True;
	ParameterAttributes.NameOfXMLParameter = "";
	ParameterAttributes.ParameterName    = "LogPath";
	ParameterAttributes.Type             = Type("String");
	ParameterAttributes.ReadOnly    = True;
	ParameterAttributes.AttributeName    = "";
	ParameterAttributes.Title       = NStr("vi = 'Đường dẫn đến tệp nhật ký';
											|ru = 'Путь к log-файлу';
											|en = 'Log file path'; fa = 'Log file path';
											|it = 'Путь к log-файлу';
											|pl = 'Log file path';
											|tr = 'Log-dosyasına yol'");
	ParameterAttributes.LongDesc        = "";
	ParameterAttributes.Transformation_  = "";
	ParameterAttributes.ValueOfStandard = Value;
	ParameterAttributes.DefaultValue  = "";
	ParameterAttributes.FormattingString = "";
	
	KeyParameters.Insert(ParameterAttributes.ParameterName, ParameterAttributes);

EndProcedure

#EndRegion

#Region DriverLogsArchive

// Creates an archive of logs on the client from files on the specified path.
//
// Parameters:
//   FilesPath - String - Path to the log files for archiving
//
// Returns:
//   BinaryData, Undefined - Archive of logs, or Undefined in case 
//    of an error or when working in a web client
//
Function CreateArchiveOfLogsOnClient(FilesPath)
	
#If Not WebClient Then
	
	Try
		Archive = New ZipFileWriter();
		Archive.Add(FilesPath, 
			ZIPStorePathMode.StoreRelativePath, 
			ZIPSubDirProcessingMode.ProcessRecursively);
		BinaryData = Archive.GetBinaryData();
		Return BinaryData;
	Except
		CommonCELClient.WriteErrorToEventLog(
			NStr("vi = 'Bản ghi lưu trữ nhật ký';
				|ru = 'Запись архива логов';
				|en = 'Record log archive'; fa = 'Record log archive';
				|it = 'Record log archive';
				|pl = 'Record log archive';
				|tr = 'Günlüklerin arşiv kaydı'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return Undefined;
	EndTry;

#Else
	Return Undefined;
#EndIf
	
EndFunction

// Transfers log files to the server.
//
// Parameters:
//   FilesPath - String - the path to the directory with the log files to Transfer
//   FileMask - String - mask for selecting files, Undefined by default
//
// Returns:
//   Structure - result of file Transfer:
//   
//
Async Function TransferLogFilesATServer(FilesPath, FileMask = Undefined)
	
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("ErrorText", "");
	Result.Insert("TransferredFileDescriptions", New Array);
	
	Files = Await FindFilesAsync(FilesPath, FileMask, True);
	TransferredFileDescriptions = New Array;
	For Each File In Files Do
		If Not Await File.IsDirectoryAsync() Then
			TransferredFileDescriptions.Add(New TransferableFileDescription (File.FullName));
		EndIf;
	EndDo;
	
	Try
		PassedFiles = Await PutFilesToServerAsync(,,TransferredFileDescriptions);
	Except
		ErrorTemplate = NStr("vi = 'Không thể sắp xếp tệp trên server: %1';
							|ru = 'Не удалось поместить файлы на сервер: %1';
							|en = 'Cannot place the files on the server: %1'; fa = 'Cannot place the files on the server: %1';
							|it = 'Cannot place the files on the server: %1';
							|pl = 'Cannot place the files on the server: %1';
							|tr = 'Dosyalar sunucuya yerleştirilemedi: %1'");
		CommonCELClient.WriteErrorToEventLog(
			NStr("vi = 'Bản ghi lưu trữ nhật ký';
				|ru = 'Запись архива логов';
				|en = 'Record log archive'; fa = 'Record log archive';
				|it = 'Record log archive';
				|pl = 'Record log archive';
				|tr = 'Günlüklerin arşiv kaydı'"),
			StrTemplate(ErrorTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Result.ErrorText = StrTemplate(
			NStr("vi = 'Không thể sắp xếp tệp trên server: %1';
				|ru = 'Не удалось поместить файлы на сервер: %1';
				|en = 'Cannot place the files on the server: %1'; fa = 'Cannot place the files on the server: %1';
				|it = 'Cannot place the files on the server: %1';
				|pl = 'Cannot place the files on the server: %1';
				|tr = 'Dosyalar sunucuya yerleştirilemedi: %1'"),
			ErrorProcessing.ErrorDescriptionForUser(ErrorInfo()));
		Return Result;
	EndTry;
	
	For Each LongDesc In PassedFiles Do
		
		If LongDesc.PutFileCanceled Then
			Continue;
		EndIf;
		
		TransferredFile = New TransferableFileDescription;
		TransferredFile.Location = LongDesc.Address;
		TransferredFile.Name =  
			Mid(LongDesc.FileRef.File.FullName, StrLen(FilesPath) + 1);
		Result.TransferredFileDescriptions.Add(TransferredFile);
		
	EndDo;
	
	Result.Success = True;
	Return Result;
	
EndFunction

#EndRegion


Async Function CallHTTPMethodClientAsync(Method, ConnectionParameters)
	
	Result = EquipmentManagerClientServer.ResultOfCallingHTTPMethod();
	Result.CallingAtServer = False;
	Proxy = Undefined;
	
	If ConnectionParameters.Port = 443 Then
		SecureConnection = CommonCELClientServer.NewSecureConnection();
		Join = New HTTPConnection(
			ConnectionParameters.Host, ConnectionParameters.Port, , , Proxy, ConnectionParameters.Timeout, SecureConnection);
	Else
		Join = New HTTPConnection(
			ConnectionParameters.Host, ConnectionParameters.Port, , , Proxy, ConnectionParameters.Timeout);
	EndIf;
		
	If ValueIsFilled(ConnectionParameters.AccessToken) Then
		ConnectionParameters.Headers.Insert("Authorization", ConnectionParameters.AccessToken);
	EndIf;
	HTTPRequest = New HTTPRequest(ConnectionParameters.ResourceAddress, ConnectionParameters.Headers);
	
	Try
		HTTPResponse = Await Join.CallHTTPMethodAsync(Method, HTTPRequest);
		Result.ResponseCode = HTTPResponse.StatusCode;
		Result.ResponseBody = HTTPResponse.GetBodyAsString();
	Except
		Result.Success = False;
		ErrorInfo = ErrorInfo();
		If ErrorInfo.IsErrorOfCategory(ErrorCategory.NetworkError) Then
			Result.Timeout = True;
		Else
			CommonCELClient.WriteErrorToEventLog(
				NStr("vi = 'Lỗi truy cập vào dịch vụ xác minh độ tuổi Max';
					|ru = 'Ошибка доступа к сервису проверки возраста Макс';
					|en = 'Error accessing the Max age verification service'; fa = 'Error accessing the Max age verification service';
					|it = 'Error accessing the Max age verification service';
					|pl = 'Error accessing the Max age verification service';
					|tr = 'Maks yaş doğrulama hizmetine erişim hatası'"), 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
		Result.ErrorDescription = ErrorProcessing.ErrorDescriptionForUser(ErrorInfo);
	EndTry;
	
	Return Result;
	
EndFunction

Function AttachableEquipmentOnForm(Form)

	PropertiesValues = New Structure("AttachableBPOEquipment", Null);
	FillPropertyValues(PropertiesValues, Form);

	Result = PropertiesValues.AttachableBPOEquipment;
	
	If TypeOf(Result) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	
	Return Result;

EndFunction

Function ThisIsListOfEquipment(List)
	Return TypeOf(List) = Type("Array") And List.Count() > 0 And TypeOf(List[0]) = Type("Structure");
EndFunction

// Checking whether Attributes exist on the form
// Parameters:
//  Form - ClientApplicationForm
//  AttributesNames - String - Comma-separated names of form Attributes 
//
Function ThereAreDetailsOnForm(Form, AttributesNames)
	
	AttributesArray = StrSplit(AttributesNames,",", False);
	
	PropertiesValues = New Structure(AttributesNames);
	For Each AttributeName In AttributesArray Do
		PropertiesValues.Insert(AttributeName, Null);
	EndDo;
	
	FillPropertyValues(PropertiesValues, Form);
	
	For Each KeyValue In PropertiesValues Do
		If KeyValue.Value = Null Then
			Return False;
		EndIf;
	EndDo;     
	
	Return True;
	
EndFunction

Function CurrentClientIsSupportedByAddIn(Attributes)
	
	SystemInfo = New SystemInfo;
	
	Browser = Undefined;
#If WebClient Then
	String = SystemInfo.UserAgentInformation;
	
	If StrFind(String, "Chrome/") > 0 Then
		Browser = "Chrome";
	ElsIf StrFind(String, "MSIE") > 0 Then
		Browser = "MSIE";
	ElsIf StrFind(String, "Safari/") > 0 Then
		Browser = "Safari";
	ElsIf StrFind(String, "Firefox/") > 0 Then
		Browser = "Firefox";
	EndIf;
#EndIf
	
	If Attributes.Property("TargetPlatforms") Then
		TargetPlatforms = Attributes.TargetPlatforms;
	Else
		TargetPlatforms = Attributes;
	EndIf;
	If SystemInfo.PlatformType = PlatformType.Linux_x86 Then
		
		If Browser = Undefined Then
			Return TargetPlatforms.Linux_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return TargetPlatforms.Linux_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return TargetPlatforms.Linux_x86_Chrome;
		EndIf;
			
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86_64 Then
		
		If Browser = Undefined Then
			Return TargetPlatforms.Linux_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return TargetPlatforms.Linux_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return TargetPlatforms.Linux_x86_64_Chrome;
		EndIf;
		
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86_64 Then
		
		If Browser = Undefined Then
			Return TargetPlatforms.MacOS_x86_64;
		EndIf;
		
		If Browser = "Safari" Then
			Return TargetPlatforms.MacOS_x86_64_Safari;
		EndIf;
		
		If Browser = "Firefox" Then
			Return TargetPlatforms.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return TargetPlatforms.MacOS_x86_64_Chrome;
		EndIf;
		
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86 Then
		
		If Browser = Undefined Then
			Return TargetPlatforms.Windows_x86;
		EndIf;
		
		If Browser = "Firefox" Then
			Return TargetPlatforms.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return TargetPlatforms.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return TargetPlatforms.Windows_x86_MSIE;
		EndIf;
		
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		
		If Browser = Undefined Then
			Return TargetPlatforms.Windows_x86_64;
		EndIf;
		
		If Browser = "Firefox" Then
			Return TargetPlatforms.Windows_x86_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return TargetPlatforms.Windows_x86_Chrome;
		EndIf;
		
		If Browser = "MSIE" Then
			Return TargetPlatforms.Windows_x86_64_MSIE;
		EndIf;
	
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86 Then
		// The platform type may be incorrectly determined in the browser.
	
		If Browser = "Firefox" Then
			Return TargetPlatforms.MacOS_x86_64_Firefox;
		EndIf;
		
		If Browser = "Chrome" Then
			Return TargetPlatforms.MacOS_x86_64_Chrome;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Function StructureTypeOfEquipmentPerLine(SoftwareTypes)
	
	TypesArray = New Array();
	For Each KeyAndValue In SoftwareTypes Do
		If KeyAndValue.Value Then
			TypesArray.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	Return StrConcat(TypesArray, ",");
	
EndFunction

#EndRegion