
#Region Public

#Region System

// Gets a revision of the requirements for the connected hardware drivers.
//
// Returns:
//  Number - 
//
Function RevisionOfDriverInterface() Export
	
	InterfaceRevision = 4007;
	Return InterfaceRevision;
	
EndFunction

// The function fills in the name of the client's workplace by the user's name.
//
// Parameters:
//  Object - CatalogObject.Workplaces - workplace of the current session.
//  UserName - String - UserName
//
Procedure FillInWorkplaceName(Object, UserName) Export
	
	NameEmptyUser = NStr("vi = '<Người sử dụng>';
						|ru = '<Пользователь>';
						|en = '<User>'; fa = '<User>';
						|it = '<Utente>';
						|pl = '<Użytkownik>';
						|tr = '<Kullanıcı>'");
	
	If IsBlankString(Object.Description) Then

		UserName = ?(IsBlankString(UserName), NameEmptyUser, String(UserName));
		Workplace_Name = ?(IsBlankString(Object.ComputerName), Object.Code, Object.ComputerName);
		Description = StrTemplate(NStr("vi = '%1 (%2)';
										|ru = '%1 (%2)';
										|en = '%1 (%2)'; fa = '%1 (%2)';
										|it = '%1 (%2)';
										|pl = '%1 (%2)';
										|tr = '%1 (%2)'"), UserName, Workplace_Name);
		NewName_ = Description;
		StandardProcessingIsPerformed = True;
		EquipmentManagerClientServerOverridable.ProcessingOfFillingInWorkplaceName(NewName_, UserName, StandardProcessingIsPerformed);
		Object.Description = ?(Not StandardProcessingIsPerformed, NewName_, Description); 
		
	ElsIf Not IsBlankString(String(UserName)) And Find(Object.Description, NameEmptyUser) > 0 Then
		Object.Description = StrReplace(Object.Description, NameEmptyUser, String(UserName));
	EndIf;

EndProcedure

// Called when receiving the name of the cashier and his TIN.
//
// Returns:
//   Structure
//   *Cashier's name - String, Undefined - Text used to fill in the document  
//   *INNKassira - String, Undefined - The text used to fill in the document
//
Function CurCurrentCashierForFiscalTransactions() Export
	
	Cashier = "";
	StandardProcessingIsPerformed = True; 
	EquipmentManagerClientServerOverridable.ProcessingFillingCashierSName(Cashier, StandardProcessingIsPerformed); 
	Cashier = ?(Not StandardProcessingIsPerformed, Cashier, NStr("vi = 'Người quản trị';
																|ru = 'Администратор';
																|en = 'Administrator'; fa = 'مدیر سیستم';
																|it = 'Amministratore';
																|pl = 'Administrator';
																|tr = 'Yönetici'")); 
	
	CashierTIN = "";
	StandardProcessingIsPerformed = True;
	EquipmentManagerClientServerOverridable.ProcessingCashierSTin(CashierTIN, StandardProcessingIsPerformed); 
	CashierTIN = ?(Not StandardProcessingIsPerformed, CashierTIN, "");
	
	OperationResult = New Structure();    
	OperationResult.Insert("Cashier"   , Cashier);
	OperationResult.Insert("CashierTIN", CashierTIN);
	Return OperationResult;
	
EndFunction

// Returns the selection structure for getting the list of equipment
//
// Returns:
//  Structure:
//  * Id - Array, reference link.Plug-in equipment
//  * SoftwareTypes - String, Structure, Array
//  * Workplace - CatalogRef.Workplaces
//  * Organization - DefinedType.Organization
//  * NetworkEquipment - Boolean - select only network equipment, False by default       
//  * LanguageCode - String - Driver language code
//
Function ListOfEquipmentSelection() Export
	
	Filter = New Structure();
	Filter.Insert("Id" , Undefined);
	Filter.Insert("SoftwareTypes",        ParametersTypesOfEquipment());
	Filter.Insert("Workplace",  Undefined);
	Filter.Insert("Organization",   Undefined);
	Filter.Insert("NetworkEquipment"  , True);    
	Filter.Insert("ServerEquipment", False);
	Filter.Insert("LanguageCode",      Undefined);        
	Filter.Insert("AutomaticFiscalizationIsAllowed", False);
	Return Filter;
	
EndFunction

#EndRegion

#Region TypesOfEquipment

// Structure types of equipment
//
// Returns:
//  Structure
//
Function ParametersTypesOfEquipment() Export
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return EquipmentManager.ParametersTypesOfEquipment();
	#Else
	Return EquipmentManagerClient.ParametersTypesOfEquipment();
	#EndIf
	
EndFunction

#EndRegion

#Region Constructors

// Fills in the structure for performing an operation on Hardware.
//
// Parameters:
//  Result - Boolean - the result of the operation.
//  ErrorDescription - ErrorInfo - information about the error.
//  DeviceID - CatalogRef.Peripherals - connected equipment.
// 
// Returns:
//  Structure:
//   * Result - Boolean
//   * ErrorDescription - String
//   * DeviceID - CatalogRef.Peripherals
//   * ConnectedDevice - Undefined, See EquipmentManagerClient.DeviceConnectionParameters.
//   * LoadingError - Boolean
//   * ObjectID - String
//
Function ParametersForPerformingOperationOnHardware(Result = False, ErrorDescription = Undefined, DeviceID = Undefined) Export; 
	
	ExecutionResult = New Structure();
	ExecutionResult.Insert("Result"              , Result);
	ExecutionResult.Insert("ErrorDescription"         , ErrorDescription);
	ExecutionResult.Insert("DeviceID", DeviceID);
	ExecutionResult.Insert("ConnectedDevice" , Undefined);
	ExecutionResult.Insert("LoadingError"         , False);
	ExecutionResult.Insert("ObjectID"   , ""); 
	ExecutionResult.Insert("StatusInCloudCashAccount"   , "");
	Return ExecutionResult;
	
EndFunction

// Parameters for creating a new driver.
// 
// Returns:
//  Structure - Parameters For Creating A New Driver:
//   *EquipmentType - EnumRef.PeripheralTypes - .
//   *ObjectID - UUID
//   *NameOfDriver - String - .
//   *Description - String - .
//   *DriverVersion - String - .
//   *ConnectionMethod - EnumRef.DriverConnectionMethod - .
//   *DriverTemplateName - String - 
//   *NoLongerSupported - Boolean -     
//   *MessageWhenUsing - Boolean -  
//   *Predefined - Boolean -
//   *LocalMode_ - Boolean -
//   *NetworkMode - Boolean -
//   *ServerMode - Boolean -
//   *SafeConnection - Boolean -          
//   *RecommendedUse - Boolean - 
//
Function ParametersForCreatingNewDriver() Export
	
	CreationParameters = New Structure();
	CreationParameters.Insert("EquipmentType");
	CreationParameters.Insert("ObjectID");
	CreationParameters.Insert("NameOfDriver");
	CreationParameters.Insert("Description");
	CreationParameters.Insert("DriverVersion"); 
	CreationParameters.Insert("ConnectionMethod"); 
	CreationParameters.Insert("SafeConnection", False);      
	CreationParameters.Insert("RecommendedUse", False);      
	CreationParameters.Insert("DriverTemplateName");
	CreationParameters.Insert("NoLongerSupported"  , False);  
	CreationParameters.Insert("MessageWhenUsing" , True);  
	CreationParameters.Insert("Predefined", False);
	CreationParameters.Insert("LocalMode_"  , True);
	CreationParameters.Insert("NetworkMode"    , False);
	CreationParameters.Insert("ServerMode"  , False);   
	Return CreationParameters;
	
EndFunction

// Parameters for creating new connected equipment.
// 
// Returns:
//  Structure - Parameters For Creating A New Attachable Hardware:  
//   *Description - String -  
//   *EquipmentType - EnumRef.PeripheralTypes - 
//   *AttachmentType - EnumRef.PeripheralsTypes -
//   *HardwareDriver - CatalogRef.HardwareDrivers - 
//   *Organization - DefinedType.CompanyCEL -   
//   *Workplace - CatalogRef.Workplaces -   
//   *SerialNumber - String -      
//   *MethodOfFormatLogicalControl - EnumRef.MethodsOfFormatLogicalControl -    
//   *AllowableDiscrepancyOfFormatLogicalControl - Number -   
//   *Use36MonthsFSUTIIIs - Boolean - 
//
Function ParametersForCreatingNewAttachableHardware() Export
	
	CreationParameters = New Structure();           
	CreationParameters.Insert("Description");
	CreationParameters.Insert("DeviceIsInUse", True);
	CreationParameters.Insert("EquipmentType"       , Undefined);
	CreationParameters.Insert("AttachmentType"        , PredefinedValue("Enum.PeripheralsTypes.LocalConnection"));
	CreationParameters.Insert("HardwareDriver"   , Undefined);
	CreationParameters.Insert("Organization"); 
	CreationParameters.Insert("Workplace", EquipmentManagerServerCall.CustomerWorkplace());
	CreationParameters.Insert("SerialNumber");
	CreationParameters.Insert("MethodOfFormatLogicalControl", PredefinedValue("Enum.MethodsOfFormatLogicalControl.DivideRows"));;    
	CreationParameters.Insert("AllowableDiscrepancyOfFormatLogicalControl", 0.01);      
	CreationParameters.Insert("Use36MonthsFSUTIIIs", False);
	Return CreationParameters;
	
EndFunction

// Parameters of the driver description.
// 
// Returns:
//  Structure - Driver Description Parameters:
//   *Is_Specified - Boolean -
//   *DriverVersion - String - 
//   *VersionOfIntegrationComponent - String -
//   *DriverName - String -
//   *DriverDescription - String -
//   *EquipmentType - String -
//   *IntegrationComponent - Boolean -
//   *MainDriverIsInstalled - Boolean -
//   *InterfaceRevision - Number -
//   *DriverDownloadURL - String -
//   *DriverParameters - String -
//   *AdditionalActions - String -
//   *DriverVersionInTheTemplate - String -
//   *DescriptionOfXMLDriver - String -
//   *DriverLogIsEnabled - Boolean -
//   *DriverLogFilePath - String -  
//   *ThisIsEmulator - Boolean -
//   *InformationAboutEnvironment - String - 
//
Function DescriptionParametersDriver() Export
	
	Result = New Structure();
	Result.Insert("Is_Specified", False);
	Result.Insert("DriverVersion");
	Result.Insert("VersionOfIntegrationComponent");
	Result.Insert("DriverName", "");
	Result.Insert("DriverDescription"    , "");
	Result.Insert("EquipmentType"     , "" );
	Result.Insert("IntegrationComponent"  , False);
	Result.Insert("MainDriverIsInstalled", False);
	Result.Insert("InterfaceRevision"        , RevisionOfDriverInterface());
	Result.Insert("InterfaceRevisionPresentation");
	Result.Insert("DriverDownloadURL"      , "");
	Result.Insert("DriverParameters"        , "");
	Result.Insert("AdditionalActions"   , "");    
	Result.Insert("SupportedLocalization", False);    
	Result.Insert("LocalizationPattern"        , "");
	Result.Insert("DriverVersionInTheTemplate"    , "");
	Result.Insert("DescriptionOfXMLDriver"      , "");
	Result.Insert("DriverLogIsEnabled"       , False);
	Result.Insert("DriverLogFilePath"    , "");     
	Result.Insert("ThisIsEmulator"              , False);  
	Result.Insert("InformationAboutEnvironment"    , "");            
	Result.Insert("AutoHardwareConfiguration", False);            
	
	Return Result;
	
EndFunction

// Connection parameters.
// 
// Parameters:
//  DriverData - Structure - Driver Data
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
//   *TemplateIsAvailable - Boolean
//   *InterfaceRevision - String
//   *LineWidth_ - String
//   *TerminalId - String
//   *PrintSlipOnTerminal - Boolean 
//   *ShortSlipChecks - Boolean
//   *CashWithdrawals - Boolean
//   *PaymentByElectronicCertificates - Boolean 
//   *PartialCancellation - Boolean 
//   *ListOfCardTransactions - Boolean
//   *ConsumerPresentedQR - Boolean   
//   *PurchaseWithCreditCard - Boolean  
//   *ColumnsOnDisplay - Number
//   *LinesOnDisplay - Number 
//   *DisplayDisplaysText - Boolean
//   *DisplayDisplaysGraphics - Boolean
//   *DisplayDisplaysQRCode - Boolean
//   *DeviceID - UUID
//
Function ConnectionParameters(DriverData) Export
	
	Connection = New Structure();
	
	Connection.Insert("Description"            , DriverData.Description);
	Connection.Insert("TypesOfEquipment"        , DriverData.TypesOfEquipment);   
	Connection.Insert("EquipmentType"         , DriverData.EquipmentType);
	Connection.Insert("EquipmentTypeName"      , DriverData.EquipmentTypeName);
	Connection.Insert("ConnectingFromTemplate"     , DriverData.ConnectingFromTemplate);
	
	Connection.Insert("ConnectingLocallyById", DriverData.ConnectingLocallyById);
	Connection.Insert("ObjectID"     , DriverData.ObjectID);
	Connection.Insert("DriverVersion"           , DriverData.DriverVersion);
	Connection.Insert("DriverTemplateName"        , DriverData.DriverTemplateName);
	Connection.Insert("TemplateIsAvailable"            , DriverData.TemplateIsAvailable);        
	Connection.Insert("NoLongerSupported"           , DriverData.NoLongerSupported);      
	Connection.Insert("MessageWhenUsing", DriverData.MessageWhenUsing); 
	Connection.Insert("SafeConnection"    , DriverData.SafeConnection);    
	
	Connection.Insert("LocalizationPattern", ?(DriverData.Property("LocalizationPattern"), DriverData.LocalizationPattern, Undefined));   
	Connection.Insert("SupportedLocalization", ?(DriverData.Property("SupportedLocalization"), DriverData.SupportedLocalization, False));   
	
	Connection.Insert("NonCertified"  , DriverData.NonCertified);
	
	Connection.Insert("InterfaceRevision", ?(DriverData.Property("InterfaceRevision"), DriverData.InterfaceRevision, 0));  
	Connection.Insert("InterfaceRevisionPresentation", ?(DriverData.Property("InterfaceRevisionPresentation"), DriverData.InterfaceRevisionPresentation, ""));  
	
	Connection.Insert("LineWidth_"     , ?(DriverData.Property("LineWidth_"), DriverData.LineWidth_, 0));
	Connection.Insert("ThisIsEmulator"      , ?(DriverData.Property("ThisIsEmulator"), DriverData.ThisIsEmulator, False)); 
	
	Connection.Insert("TerminalId"         , ?(DriverData.Property("TerminalId"), DriverData.TerminalId, ""));  
	Connection.Insert("AcquirerBankID"     , ?(DriverData.Property("AcquirerBankID"), DriverData.AcquirerBankID, ""));  
	Connection.Insert("PrintSlipOnTerminal"     , ?(DriverData.Property("PrintSlipOnTerminal"), DriverData.PrintSlipOnTerminal, False));
	Connection.Insert("ShortSlipChecks"               , ?(DriverData.Property("ShortSlipChecks"), DriverData.ShortSlipChecks, False));
	Connection.Insert("CashWithdrawals"  , ?(DriverData.Property("CashWithdrawals"), DriverData.CashWithdrawals, False));
	Connection.Insert("PaymentByElectronicCertificates", ?(DriverData.Property("PaymentByElectronicCertificates"), DriverData.PaymentByElectronicCertificates, False));
	Connection.Insert("PartialCancellation"                , ?(DriverData.Property("PartialCancellation"), DriverData.PartialCancellation, False));
	Connection.Insert("ListOfCardTransactions"         , ?(DriverData.Property("ListOfCardTransactions"), DriverData.ListOfCardTransactions, False));
	Connection.Insert("ReturnElectronicCertificateByBasketID"    , ?(DriverData.Property("ReturnElectronicCertificateByBasketID"), DriverData.ReturnElectronicCertificateByBasketID, False)); 
	Connection.Insert("ConsumerPresentedQR"            , ?(DriverData.Property("ConsumerPresentedQR"), DriverData.ConsumerPresentedQR, False)); 
	Connection.Insert("PurchaseWithCreditCard"     , ?(DriverData.Property("PurchaseWithCreditCard"), DriverData.PurchaseWithCreditCard, False));  

	Connection.Insert("ColumnsOnDisplay"       , ?(DriverData.Property("ColumnsOnDisplay"), DriverData.ColumnsOnDisplay, 20));
	Connection.Insert("LinesOnDisplay"          , ?(DriverData.Property("LinesOnDisplay"), DriverData.LinesOnDisplay, 2));
	Connection.Insert("DisplayDisplaysText"  , ?(DriverData.Property("DisplayDisplaysText"), DriverData.DisplayDisplaysText, True));
	Connection.Insert("DisplayDisplaysGraphics", ?(DriverData.Property("DisplayDisplaysGraphics"), DriverData.DisplayDisplaysGraphics, False));
	Connection.Insert("DisplayDisplaysQRCode"  , ?(DriverData.Property("DisplayDisplaysQRCode"), DriverData.DisplayDisplaysQRCode, False));
	Connection.Insert("DisplayDisplaysHTML"   , ?(DriverData.Property("DisplayDisplaysHTML"), DriverData.DisplayDisplaysHTML, False));
	Connection.Insert("DISPLAYShowsStatus" , ?(DriverData.Property("DISPLAYShowsStatus"), DriverData.DISPLAYShowsStatus, False));
	Connection.Insert("DisplayShowsStatusOfRM", ?(DriverData.Property("DisplayShowsStatusOfRM"), DriverData.DisplayShowsStatusOfRM, False));
	Connection.Insert("DisplayWorksOutClicks"  , ?(DriverData.Property("DisplayWorksOutClicks"), DriverData.DisplayWorksOutClicks, False));
	
	Connection.Insert("ScalesSupportTaring", ?(DriverData.Property("ScalesSupportTaring"), DriverData.ScalesSupportTaring, False));
	Connection.Insert("WeightGainEvent"      , ?(DriverData.Property("WeightGainEvent"), DriverData.WeightGainEvent, False)); 

	Connection.Insert("DeviceID" , ?(DriverData.Property("Ref"), DriverData.Ref, Undefined));
	
	Return Connection;
	
EndFunction

// APK: 142-off backward compatibility

// Command execution parameters.
// 
// Parameters:
//  Command - FormCommand - .
//  ProcessorOfData - DataCompositionProcessor - Data Processor
//  AdditionalParameters - Undefined - advanced setting
//  PrepareData - Boolean - Prepare data
//  ProcessData__ - Boolean - Process data
//  UsePrintingDevice - Boolean - Use A Printing Device
//  ProcessDataInCaseOfError - Boolean
// 
// Returns:
//  Structure - Parameters Command Execution:
//   *Command - FormCommand - .
//   *ProcessorOfData - DataCompositionProcessor - Data Processor
//   *PrepareData - Boolean -.
//   *ProcessData__ - Boolean -.
//   *UsePrintingDevice - Boolean -.
//   *MessagesToTechSupportService - Boolean - An error message will be generated to the technical support service. 
//
Function ParametersCommandExecution(Command, ProcessorOfData, AdditionalParameters = Undefined, PrepareData = True, 
	ProcessData__ = True, UsePrintingDevice = False, ProcessDataInCaseOfError = False) Export
	
	ParametersExecution = New Structure();
	ParametersExecution.Insert("Command"          , Command);
	ParametersExecution.Insert("ProcessorOfData"  , ProcessorOfData);
	ParametersExecution.Insert("PrepareData", PrepareData);
	ParametersExecution.Insert("ProcessData__" , ProcessData__);
	ParametersExecution.Insert("PrepareDataClient", False);
	ParametersExecution.Insert("ProcessData__Client" , False);
	ParametersExecution.Insert("ProcessDataInCaseOfError", ProcessDataInCaseOfError);  
	ParametersExecution.Insert("UsePrintingDevice", UsePrintingDevice);
	ParametersExecution.Insert("PrintingSlipReceipt", True);      
	ParametersExecution.Insert("FullSlipReceipt" , True); 
	ParametersExecution.Insert("MessagesToTechSupportService" , False);

	If AdditionalParameters <> Undefined Then
		For Each AdditionalParameter In AdditionalParameters Do
			ParametersExecution.Insert(AdditionalParameter.Key, AdditionalParameter.Value);
		EndDo;
	EndIf;
	Return ParametersExecution;
	
EndFunction

// APK: 142-on

// Additional parameters of the operation.
// 
// Parameters:
//  LeaveConnected - Boolean - Leave connected
// 
// Returns:
//  Structure - Additional Operation Parameters:
//   *LeaveConnected - Boolean -
//   *NotificationAfterReceiptOpening - Undefined - 
//   *NotificationInCaseOfReceiptPrintingError - Undefined - 
//
Function AdditionalOperationParameters(LeaveConnected = False) Export
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("LeaveConnected", LeaveConnected);
	AdditionalParameters.Insert("NotificationAfterReceiptOpening");
	AdditionalParameters.Insert("NotificationInCaseOfReceiptPrintingError");
	Return AdditionalParameters;
	
EndFunction
 #EndRegion

#Region SoftwareInterfaceMarking

// The function determines the barcode type by the code value.
// 
// Parameters:
//  Barcode - String - Barcode value.
//
// Returns:
//  String
//
Function DetermineBarcodeType(Val Barcode) Export
	
	BarcodeTypeVal = "";	
	BarcodeLength = StrLen(Barcode);
	
	If BarcodeLength = 0 Then
		Return BarcodeTypeVal;
	EndIf;
	
	If BarcodeLength = 14 Then // ITF14
		
		If CalculateControlSymbolGTIN14(Barcode) = Right(Barcode, 1) Then
			BarcodeTypeVal = "ITF14";
 		EndIf;
		
	ElsIf BarcodeLength = 13 Then // EAN13
		
		If CalculateControlSymbolGTIN13(Barcode) = Right(Barcode, 1) Then
			BarcodeTypeVal = "EAN13";
		EndIf;
		
	ElsIf BarcodeLength = 8 Then // EAN8
		
		If CalculateGtin8ControlSymbol(Barcode) = Right(Barcode, 1) Then
			BarcodeTypeVal = "EAN8";
		EndIf;
		
	EndIf;
	
	If BarcodeTypeVal= "" Then // CODE39
		
		CODE39 = True;
		For Cnt = 1 To BarcodeLength Do
			TimeCharacterCode = CharCode(Barcode, Cnt);
			If (TimeCharacterCode <> 32)
				And (TimeCharacterCode < 36 Or TimeCharacterCode > 37)
				And (TimeCharacterCode <> 43)
				And (TimeCharacterCode < 45 Or TimeCharacterCode > 57)
				And (TimeCharacterCode < 65 Or TimeCharacterCode > 90) Then
				CODE39 = False;
				Break;
			EndIf;
		EndDo;
		
		If CODE39 Then
			BarcodeTypeVal = "CODE39";
		EndIf                                                     
		
	EndIf;
	
	If BarcodeTypeVal= ""  Then // CODE128
		// CODE128 ASCII characters from 0 to 127 (digits from "0" to "9", letters from "A" to "Z" and from "a" to "z") and special characters;
		CODE128 = True;
		For Cnt = 1 To BarcodeLength Do
			TimeCharacterCode = CharCode(Barcode, Cnt);
			If (TimeCharacterCode > 127) Then
				CODE128 = False;
			Break;
			EndIf;
		EndDo;
		
		If CODE128 Then
			BarcodeTypeVal = "CODE128";
		EndIf                                                     
		
	EndIf;
	
	If BarcodeTypeVal = "CODE128"  Then // EAN128
		// The CODE128 dictionary is regulated in the EAN128 code, but groups of codes are regulated, and GS separators are possible.
		If CharCode(Barcode, 1) = 40 Or StrFind(Barcode, CommonCELClientServer.GS1Separator()) > 0  Then
			BarcodeTypeVal = "EAN128";
		EndIf;
	EndIf;
	
	Return BarcodeTypeVal;
	
EndFunction

// The function returns an empty EPC record structure.
// 
// Returns:
//  Structure:
//   *Result       - Boolean - Decoding result (successful or not)
//   *EPC             - String - The EPC value as a HEX string
//   *EPC_BIN         - String - The EPC value as a binary string
//   *Format          - String - Recognized data format SGTIN-96 or SGTIN-198  
//   *GTIN            - String - GTIN 
//   *SerialNumber   - String - Serial Number SGTIN 
//   *CompanyPrefix_ - String - Company prefix
//   *URI             - String - EPC Tag URI.
//
Function GetEPCRecordStructure() Export
	
	EPCRecordStructure = New Structure;
	
	EPCRecordStructure.Insert("Result", False);  // Decoding result (successful or not)
	EPCRecordStructure.Insert("EPC");              // The EPC value as a HEX string
	EPCRecordStructure.Insert("EPC_BIN");          // The EPC value as a binary string
	EPCRecordStructure.Insert("Format");           // Recognized data format SGTIN-96 or SGTIN-198  
	EPCRecordStructure.Insert("GTIN");             // GTIN 
	EPCRecordStructure.Insert("SerialNumber");    // Serial Number SGTIN 
	EPCRecordStructure.Insert("CompanyPrefix_");  // Company prefix
	EPCRecordStructure.Insert("URI");              // EPC Tag URI
	
	Return EPCRecordStructure;
	
EndFunction

// Calculation of the check digit for GTIN-8. 
//
// Parameters:
//  GTIN - String - A text string with GTIN-8. It can contain numbers from 0 to 9. 
// 
// Returns:
//  Number - Control character (number) calculated by the algorithm for GTIN.
//
Function CalculateGtin8ControlSymbol(Val GTIN) Export
	
	Sum = 0;
	ZoomRatio = 3;
	
	For Cnt = 1 To 7 Do
		TimeCharacterCode = CharCode(GTIN, Cnt);
		Sum  = Sum + ZoomRatio * (TimeCharacterCode - 48);
		ZoomRatio = 4 - ZoomRatio;
	EndDo;
	Sum = (10 - Sum % 10) % 10;
	CheckCharacter = Char(Sum + 48);
	
	Return CheckCharacter;
	
EndFunction

// Calculation of the check digit for GTIN-12. 
//
// Parameters:
//  GTIN - String - A text string with GTIN-12. It can contain numbers from 0 to 9. 
// 
// Returns:
//  Number - Control character (number) calculated by the algorithm for GTIN.
//
Function CalculateControlSymbolGTIN12(Val GTIN) Export
	
	Sum = 0;
	ZoomRatio = 3;
	
	For Cnt = 1 To 11 Do
		TimeCharacterCode = CharCode(GTIN, Cnt);
		Sum  = Sum + ZoomRatio * (TimeCharacterCode - 48);
		ZoomRatio = 4 - ZoomRatio;
	EndDo;
	Sum = (10 - Sum % 10) % 10;
	CheckCharacter = Char(Sum + 48);
	
	Return CheckCharacter;
	
EndFunction

// Calculation of the check digit for GTIN-13. 
//
// Parameters:
//  GTIN - String -A text string with GTIN-13. It can contain numbers from 0 to 9.
// 
// Returns:
//  Number - Control character (number) calculated by the algorithm for GTIN.
//
Function CalculateControlSymbolGTIN13(Val GTIN) Export
	
	Sum = 0;
	ZoomRatio = 1;
	
	For Cnt = 1 To 12 Do
		TimeCharacterCode = CharCode(GTIN, Cnt);
		Sum  = Sum + ZoomRatio * (TimeCharacterCode - 48);
		ZoomRatio = 4 - ZoomRatio;
	EndDo;
	Sum = (10 - Sum % 10) % 10;
	CheckCharacter = Char(Sum + 48);
	
	Return CheckCharacter;
	
EndFunction

// Calculation of the check digit for GTIN-14. 
//
// Parameters:
//  GTIN - String - A text string with GTIN-14. It can contain numbers from 0 to 9. 
// 
// Returns:
//  Number - Control character (number) calculated by the algorithm for GTIN.
//
Function CalculateControlSymbolGTIN14(Val GTIN) Export
	
	Sum = 0;
	ZoomRatio = 3;
	
	For Cnt = 1 To 13 Do
		TimeCharacterCode = CharCode(GTIN, Cnt);
		Sum  = Sum + ZoomRatio * (TimeCharacterCode - 48);
		ZoomRatio = 4 - ZoomRatio;
	EndDo;
	Sum = (10 - Sum % 10) % 10;
	CheckCharacter = Char(Sum + 48);
	
	Return CheckCharacter;
	
EndFunction

// Universal function for calculating the GTIN check digit.
// GTIN allows in the format GTIN-8, GTIN-12, GTIN-13, GTIN-14 with a control character.
//
// Parameters:
//  GTIN - String - A text string with a GTIN(with a control character). It can contain numbers from 0 to 9.
// 
// Returns:
//  Number - Control character (number) calculated by the algorithm for GTIN.
//
Function CalculateControlSymbolGTIN(Val GTIN) Export
	
	Sum = 0;
	LengthGTIN = StrLen(GTIN);
	ZoomRatio = ?(LengthGTIN % 2 = 0, 3, 1); 
	
	For Cnt = 1 To LengthGTIN - 1 Do
		TimeCharacterCode = CharCode(GTIN, Cnt);
		Sum  = Sum + ZoomRatio * (TimeCharacterCode - 48);
		ZoomRatio = 4 - ZoomRatio;
	EndDo;
	Sum = (10 - Sum % 10) % 10;
	CheckCharacter = Char(Sum + 48);
	
	Return CheckCharacter;
	
EndFunction

// The function checks whether the GTIN is correct.
// GTIN allows in the format GTIN-8, GTIN-12, GTIN-13, GTIN-14 with a control character.
//
// Parameters:
//  GTIN - String - A text string with a GTIN(with a control character). It can contain numbers from 0 to 9.
// 
// Returns:
//  Boolean  
//
Function CheckCorrectGTIN(Val GTIN) Export
	
	Result = (StrLen(GTIN) = 8) Or (StrLen(GTIN) = 12) Or (StrLen(GTIN) = 13) Or (StrLen(GTIN) = 14);
	Return Result And CalculateControlSymbolGTIN(GTIN) = Right(GTIN, 1);
	
EndFunction

// Decoding the data according to the value of EPC(HEX string). The SGTIN-96 and SGTIN-198 formats are supported.
//
// Parameters:
//   EPC - String - A string containing the value of the EPC bank in HEX form.
// 
// Returns:
//  Structure:
//   *Result       - Boolean - Decoding result (successful or not)
//   *EPC             - String - The EPC value as a HEX string
//   *EPC_BIN         - String - The EPC value as a binary string
//   *Format          - String - Recognized data format SGTIN-96 or SGTIN-198  
//   *GTIN            - String - GTIN 
//   *SerialNumber   - String - Serial Number SGTIN 
//   *CompanyPrefix_ - String - Company prefix
//   *URI             - String - EPC Tag URI.
//
Function DecodingSGTINData(EPC) Export
	
	// Converting the HEX string value of the EPC bank into a binary string.
	BitArray = ConvertNonXBBinaryString(EPC);
	
	// We prepare the structure of the result.
	ResultStructure1 = GetEPCRecordStructure();
	ResultStructure1.EPC = EPC;
	ResultStructure1.EPC_BIN = BitArray; 
	
	// Getting the label title.
	Title = Mid(BitArray, 1, 8);
	
	If Title = "00110000" Then // The SGTIN-96 header is recognized.
		
		Format = "sgtin-96";
		// For SGTIN-96, the serial number length is 38 bit.
		SerialNumber = Mid(BitArray, 59); 
		// The serial number consists of decimal digits. The maximum value is 274,877,906,943
		SerialNumber = AddLeadingZeros(Format(ConvertBinaryStringToNumber(SerialNumber), "NG=0"), 12); 
		
	ElsIf Title = "00110110" Then // The SGTIN-198 header is recognized.
		
		Format = "sgtin-198";
		// For SGTIN-198, the long serial number is 140 bit.
		SerialNumberVrem = Mid(BitArray, 59); 
		// The serial number consists of 7 bit characters. Maximum of 20 characters.
		SerialNumber = "";
		While StrLen(SerialNumberVrem) > 0 Do
			CurChar  = Left(SerialNumberVrem, 7);
			CharCode = ConvertBinaryStringToNumber(CurChar);
			If CharCode > 31 Then
				SerialNumber = SerialNumber + Char(CharCode);
			EndIf;
			SerialNumberVrem = Mid(SerialNumberVrem, 8);
		EndDo;
		
	Else
		Return ResultStructure1; // The EPC data format is not recognized.
	EndIf;
	
	ResultStructure1.SerialNumber = SerialNumber;
	ResultStructure1.Format        = Format;
	
	Filter      = ConvertBinaryStringToNumber(Mid(BitArray, 9, 3));
	Separator = ConvertBinaryStringToNumber(Mid(BitArray, 12, 3));
	
	// We define the division of the company prefix.
	If Separator = 1 Then
		CompanyCategories = 37;
		CharacterCategories   = 11;
	ElsIf Separator = 2 Then
		CompanyCategories = 34;
		CharacterCategories   = 10;
	ElsIf Separator = 3 Then
		CompanyCategories = 30;
		CharacterCategories   = 9;
	ElsIf Separator = 4 Then
		CompanyCategories = 27;
		CharacterCategories   = 8;
	ElsIf Separator = 5 Then
		CompanyCategories = 24;
		CharacterCategories   = 7;
	ElsIf Separator = 6 Then
		CompanyCategories = 20;
		CharacterCategories   = 6;
	Else
		CompanyCategories = 40;
		CharacterCategories   = 12;
	EndIf;
	
	CompanyPrefix_ = Mid(BitArray, 15, CompanyCategories);
	GoodGroup    = Mid(BitArray, 15 + CompanyCategories, 44 - CompanyCategories);
	
	CompanyPrefix_ = AddLeadingZeros(Format(ConvertBinaryStringToNumber(CompanyPrefix_), "NG=0"), CharacterCategories); 
	GoodGroup    = AddLeadingZeros(Format(ConvertBinaryStringToNumber(GoodGroup), "NG=0"), 13 - CharacterCategories);
	
	URI = "urn:epc:tag:" + Format + ":" + Filter + "." + CompanyPrefix_ + "." + GoodGroup + "." + SerialNumber; 
	
	GTIN = Left(GoodGroup, 1) + CompanyPrefix_ + Right(GoodGroup, StrLen(GoodGroup) - 1);
	
	If StrLen(GTIN) = 13 Then
		GTIN = GTIN + CalculateControlSymbolGTIN14(GTIN) 
	EndIf;
	
	ResultStructure1.CompanyPrefix_ = CompanyPrefix_; 
	ResultStructure1.GTIN = GTIN;
	ResultStructure1.URI  = URI;
	ResultStructure1.Result = True;
	
	Return ResultStructure1;        
	
EndFunction

// This function determines whether the EPC contains meaningful information (GTIN or serial Number) in the SGTIN format.
//
// Parameters:
//  EPC - String -  A string containing the value of the EPC bank in HEX form.
// 
// Returns:
//  Boolean  
//
Function EmptyEPC(EPC) Export
	
	BitArray = ConvertNonXBBinaryString(EPC);
	SerialNumber = Right(BitArray, 38);
	GTIN = Mid(BitArray, 15, 44);
	
	SerialNumber = ConvertBinaryStringToNumber(SerialNumber);
	GTIN = ConvertBinaryStringToNumber(GTIN);
	
	FilledIn_ = (SerialNumber > 0) Or (GTIN > 0);                                  
	Return Not FilledIn_; 
	
EndFunction

// Generate the EPC value in SGTIN-96 format for the GTIN and serial number.
//  GTIN allows in the format GTIN-8, GTIN-12, GTIN-13, GTIN-14.
//
// Parameters:
//  GTIN          - String - GTIN of the product range. A text string with GTIN (with a control character).
//  SerialNumber - String - Serial number of the item.
//  Filter        - String - Filter
// 
// Returns:
//  String - HEX with the generated EPC for recording on the RFID tag.
//
Function GenerateSGTIN96Data(Val GTIN, Val SerialNumber, Val Filter = 3) Export
	
	TimeGTIN = AddLeadingZeros(GTIN, 14);
	TimeGTIN = Left(TimeGTIN, 13); // Discarding the control character.
	
	If StrLen(GTIN) > 13 And Left(GTIN, 1) <> "0" Then
		CompanyLogo_ = 9;
		Indicator = Left(TimeGTIN, 1);
		Company = Mid(TimeGTIN, 2, CompanyLogo_);
		ProductGroup_1 = Indicator + Right(TimeGTIN, 3);
	Else
		CompanyLogo_ = 7;
		Company = Left(TimeGTIN, CompanyLogo_ + 1);
		ProductGroup_1 = Mid(TimeGTIN, CompanyLogo_ + 2);
	EndIf;
	
	If CompanyLogo_ = 7 Then
		CompanyCategories = 24;
		Separator      = 5;
	ElsIf CompanyLogo_ = 9 Then
		CompanyCategories = 30;
		Separator = 3;
	Else
		Separator      = 3;
		CompanyCategories = 30;
	EndIf;
	
	// APK: 1353-off EPC - technical term
	SerialNumber = ?(IsBlankString(SerialNumber), "0", SerialNumber);
	EPC = "00110000";  // - We define the SGTIN-96 header.
	EPC = EPC + AddLeadingZeros(ConvertNumberToBinaryString(Filter), 3);      // Filter.
	EPC = EPC + AddLeadingZeros(ConvertNumberToBinaryString(Separator), 3); // Splitter
	EPC = EPC + AddLeadingZeros(ConvertNumberToBinaryString(Number(Company)), CompanyCategories);
	EPC = EPC + AddLeadingZeros(ConvertNumberToBinaryString(Number(ProductGroup_1)), 44 - CompanyCategories);
	EPC = EPC + AddLeadingZeros(ConvertNumberToBinaryString(Number(SerialNumber)), 38);
	
	Result = ConvertBinaryStringVNEX(EPC);
	Return Result;
	// APK: 1353-on

EndFunction

// Generate a serial number according to the rules of chip manufacturers.
//
// Parameters:
//  TID - String - GTIN of the product range. A text string with GTIN (with a control character).
//  EPC - String - Serial number of the item.
// 
// Returns:
//  Structure
//
Function SerialNumberByTID(Val TID, Val EPC = Undefined) Export
	
	ErrorDescription = NStr("vi = 'Lỗi khởi tạo số sê-ri TID.';
							|ru = 'Ошибка генерации серийного номера по TID.';
							|en = 'An error occurred when generating a serial number by TID.'; fa = 'An error occurred when generating a serial number by TID.';
							|it = 'Errore durante la generazione del numero di serie da TID.';
							|pl = 'Błąd generowania numeru seryjnego wg TID.';
							|tr = 'TID''de seri numarası oluşturma hatası.'");
	ExecutionResult = New Structure("Result, ErrorDescription, SerialNumber", False, ErrorDescription);
	
	G2Attribute = Left(TID, 2);
	If G2Attribute <> "E2" Then // Fixed value "E2" indicates that the type corresponds to EPC Class1Gen2. 
		ExecutionResult.ErrorDescription = NStr("vi = 'TID đã chỉ định không tương ứng với kiểu EPC Class1 Gen2.';
												|ru = 'Указанный TID не соответствует типу EPC Class1 Gen2.';
												|en = 'Specified TID does not match the EPC Class1 Gen2 type.'; fa = 'Specified TID does not match the EPC Class1 Gen2 type.';
												|it = 'Il TID indicato non corrisponde al tipo di EPC Class1 Gen2.';
												|pl = 'Podany TID nie jest zgodny z typem EPC Class1 Gen2.';
												|tr = 'Belirtilen TID, EPC Class1 Gen2 türüyle eşleşmiyor.'");
		Return ExecutionResult;
	EndIf;
	
	// Converting the HEX string value of the TID bank into a binary string.
	BitArray = ConvertNonXBBinaryString(TID);
	// We get the manufacturer's prefix.
	Manufacturer = Mid(TID, 3, 3);
	
	If Manufacturer = "001" Or Manufacturer = "801" Then // Impinj Chips
		
		ChipSeries = Mid(BitArray, 84, 2); // Chip Series00
		If ChipSeries = "00" Then
			SerialNumber = "000" 
						+ Mid(BitArray, 86, 8)
						+ Mid(BitArray, 66, 15)
						+ Mid(BitArray, 94, 3)
						+ Mid(BitArray, 65, 1)
						+ Mid(BitArray, 55, 4)
						+ Mid(BitArray, 61, 4);
		Else // Chip series 01,10,11
			SerialNumber = Mid(BitArray, 86, 11) 
						+ Mid(BitArray, 65, 16)
						+ Mid(BitArray, 52, 2)
						+ Mid(BitArray, 57, 1)
						+ Mid(BitArray, 55, 4)
						+ Mid(BitArray, 61, 4);
					EndIf;
					
	ElsIf Manufacturer = "006" Or Manufacturer = "806" Then // NXP Semiconductors Chips 
		
		ChipSeries = Mid(BitArray, 21, 11); // Chip Series 
		ChipSeries = ConvertBinaryStringVNEX(ChipSeries);
		If ChipSeries = "806" Or ChipSeries = "807" Then // G2iL or G2iL+
			SerialNumber = "111"
				+ Mid(BitArray, 24, 3) 
				+ Mid(BitArray, 33, 32);
		Else
			SerialNumber = Mid(BitArray, 59, 38);
		EndIf;
		
	ElsIf Manufacturer = "003" Or Manufacturer = "803" Then // Alien Technology Chips  
		
		// Words 2, 3, 4 and 5
		SerialNumber = Mid(BitArray, 59, 38);
		
	Else
		
		ExecutionResult.ErrorDescription = NStr("vi = 'Không hỗ trợ khởi tạo số sê-ri đối với nhà sản xuất chip đã chỉ định trong TID.';
												|ru = 'Генерация серийного номера для чипа производителя указанного в TID не поддерживается.';
												|en = 'Generation of a serial number for the manufacturer chip specified in the TID is not supported.'; fa = 'Generation of a serial number for the manufacturer chip specified in the TID is not supported.';
												|it = 'La generazione del numero di serie per il chip del produttore specificato nel TID non è supportata.';
												|pl = 'Generowanie numeru seryjnego dla chipu producenta, wskazanego w TID nie jest obsługiwana.';
												|tr = 'TID''de belirtilen üretici çipi için seri numarası oluşturulması desteklenmiyor.'");
		Return ExecutionResult;
		
	EndIf;
	
	ExecutionResult.Result = True;
	ExecutionResult.SerialNumber = ConvertBinaryStringToNumber(SerialNumber);
		
	Return ExecutionResult;
	
EndFunction

// Converts a HEX string to a string of characters.
//
// Parameters:
//  HEXString - String - A HEX string containing characters.  
// 
// Returns:
//  String - Character string
//
Function ConvertNonXBString(Val HEXString) Export
	
	Result = "";
	TimeLine = HEXString;
	CharCode = 0;
	
	While StrLen(TimeLine) > 0 Do
		CurChar  = Left(TimeLine, 2);
		CurChar  = ConvertNonXBBinaryString(CurChar);
		CharCode = ConvertBinaryStringToNumber(CurChar);
		If CharCode > 31 Then
			Result = Result + Char(CharCode);
		EndIf;
		TimeLine = Mid(TimeLine, 3);
	EndDo;
	
	Return Result;
	
EndFunction

// Converts a string of characters to a HEX string.
//
// Parameters:
//   String - String - Test string
// 
// Returns:
//   - String - A HEX string containing characters.  
//
Function ConvertStringVNEX(Val String) Export
	
	Result = "";
	SymbolIndex = 1;
	
	While SymbolIndex <= StrLen(String) Do
		CurCode = CharCode(String, SymbolIndex);
		CurChar = AddLeadingZeros(ConvertNumberToBinaryString(CurCode), 8);
		Result = Result + ConvertBinaryStringVNEX(CurChar);
		SymbolIndex = SymbolIndex + 1;
	EndDo;
	
	Result = AddLeadingZeros(Result, 8);
	Return Result;
	
EndFunction

// Function-Convert HEX to a binary string
//
// Parameters:
//  HEXString - String - A HEX string containing characters.  
// 
// Returns:
//  String - A text string in binary representation (Example "000010101"). 
//
Function ConvertNonXBBinaryString(Val HEXString) Export
	
	Result = "";
	
	For SymbolIndex = 1 To StrLen(HEXString) Do 
		CurChar = Mid(HEXString, SymbolIndex, 1);
		If CurChar = "0" Then 
			Result = Result + "0000"
		ElsIf CurChar = "1" Then 
			Result = Result + "0001"
		ElsIf CurChar = "2" Then 
			Result = Result + "0010"
		ElsIf CurChar = "3" Then 
			Result = Result + "0011"
		ElsIf CurChar = "4" Then 
			Result = Result + "0100"
		ElsIf CurChar = "5" Then 
			Result = Result + "0101"
		ElsIf CurChar = "6" Then 
			Result = Result + "0110"
		ElsIf CurChar = "7" Then 
			Result = Result + "0111"
		ElsIf CurChar = "8" Then 
			Result = Result + "1000"
		ElsIf CurChar = "9" Then 
			Result = Result + "1001"
		ElsIf CurChar = "A" Then 
			Result = Result + "1010"
		ElsIf CurChar = "B" Then 
			Result = Result + "1011"
		ElsIf CurChar = "C" Then 
			Result = Result + "1100"
		ElsIf CurChar = "D" Then 
			Result = Result + "1101"
		ElsIf CurChar = "E" Then 
			Result = Result + "1110"
		ElsIf CurChar = "F" Then 
			Result = Result + "1111"
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Function-Convert a binary string out OF
//
// Parameters:
//  BinaryString- String - A text string in binary representation (Example "000010101").
// 
// Returns:
//  String - A HEX string containing characters.  
//
Function ConvertBinaryStringVNEX(Val BinaryString) Export
	
	Result = "";
	TimeLine = BinaryString;
	
	While StrLen(TimeLine) > 0 Do
		CurChar = Left(TimeLine, 4);
		If CurChar = "0000" Then 
			Result = Result + "0";
		ElsIf CurChar = "0001" Then 
			Result = Result + "1";
		ElsIf CurChar = "0010" Then 
			Result = Result + "2";
		ElsIf CurChar = "0011" Then 
			Result = Result + "3";
		ElsIf CurChar = "0100" Then 
			Result = Result + "4";
		ElsIf CurChar = "0101" Then 
			Result = Result + "5";
		ElsIf CurChar = "0110" Then 
			Result = Result + "6";
		ElsIf CurChar = "0111" Then 
			Result = Result + "7";
		ElsIf CurChar = "1000" Then 
			Result = Result + "8";
		ElsIf CurChar = "1001" Then 
			Result = Result + "9";
		ElsIf CurChar = "1010" Then 
			Result = Result + "A";
		ElsIf CurChar = "1011" Then 
			Result = Result + "B";
		ElsIf CurChar = "1100" Then 
			Result = Result + "C";
		ElsIf CurChar = "1101" Then 
			Result = Result + "D";
		ElsIf CurChar = "1110" Then 
			Result = Result + "E";
		ElsIf CurChar = "1111" Then 
			Result = Result + "F";
		EndIf;
		TimeLine = Mid(TimeLine, 5);
	EndDo;
	
	Return Result;
	
EndFunction

// Function-Convert a binary string to a decimal number
//
// Parameters:
//  BinaryString - String - A text string in binary representation (Example "000010101"). 
// 
// Returns:
//  Number - Decimal number. 
//
Function ConvertBinaryStringToNumber(Val BinaryString) Export
	
	Result = 0;
	CurrentIndex = StrLen(BinaryString) - 1;
	
	For IndexSymbol = 1 To StrLen(BinaryString) Do
		CurChar = Mid(BinaryString, IndexSymbol, 1);
		If CurChar = "1" Then
			Result = Result + Pow(2, CurrentIndex); 
		EndIf;
		CurrentIndex = CurrentIndex - 1;
	EndDo;
	
	Return Result;
	
EndFunction

// Function-Convert a decimal number to a binary string
//
// Parameters:
//  Number - Number - The decimal number that will be converted to binary form. 
//  CharsCount - Number - the number of characters.
//  
// Returns:
//  String - A text string in binary representation (Example "000010101").
//
Function ConvertNumberToBinaryString(Val Number, Val CharsCount = 0) Export 
	
	Result = "";
	
	While Number > 0 Do
		Balance = Number % 2;
		Number = Int(Number / 2);
		Result = String(Balance) + Result;
	EndDo;
	
	Result =?(IsBlankString(Result), "0", Result); 
	
	If CharsCount > 0 Then
		While StrLen(Result) < CharsCount Do
			Result = "0" + Result;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

// Generate a serial number according to the rules of chip manufacturers.
// 
// Parameters:
//  TID - String - TID
//  EPC - Undefined - EPC
// 
// Returns:
//  Structure - Get Serial Number by TID:
//   *Result - Boolean -
//   *ErrorDescription - String -
//   *SerialNumber - String - 
//
Function GetSerialNumberByTID(Val TID, Val EPC = Undefined) Export
	
	ErrorDescription = NStr("vi = 'Lỗi khởi tạo số sê-ri theo TID.';
							|ru = 'Ошибка генерации серийного номера по TID.';
							|en = 'An error occurred when generating a serial number by TID.'; fa = 'An error occurred when generating a serial number by TID.';
							|it = 'Errore durante la generazione del numero di serie da TID.';
							|pl = 'Błąd generowania numeru seryjnego wg TID.';
							|tr = 'TID''de seri numarası oluşturma hatası.'");
	ExecutionResult = New Structure("Result, ErrorDescription, SerialNumber", False, ErrorDescription);
	
	G2Attribute = Left(TID, 2);
	If G2Attribute <> "E2" Then // Fixed value "E2" indicates that the type corresponds to EPC Class1Gen2. 
		ExecutionResult.ErrorDescription = NStr("vi = 'TID đã chỉ định không tương ứng với kiểu EPC Class1 Gen2.';
												|ru = 'Указанный TID не соответствует типу EPC Class1 Gen2.';
												|en = 'Specified TID does not match the EPC Class1 Gen2 type.'; fa = 'Specified TID does not match the EPC Class1 Gen2 type.';
												|it = 'Il TID indicato non corrisponde al tipo EPC Class1Gen2.';
												|pl = 'Podany TID nie jest zgodny z typem EPC Class1 Gen2.';
												|tr = 'Belirtilen TID, EPC Class1 Gen2 türüyle eşleşmiyor.'");
		Return ExecutionResult;
	EndIf;
	
	// Converting the HEX string value of the TID bank into a binary string.
	BitArray = ConvertNonXBBinaryString(TID);
	// We get the manufacturer's prefix.
	Manufacturer = Mid(TID, 3, 3);
	
	If Manufacturer = "001" Or Manufacturer = "801" Then // Impinj Chips
		
		ChipSeries = Mid(BitArray, 84, 2); // Chip Series00
		If ChipSeries = "00" Then
			SerialNumber = "000" 
						+ Mid(BitArray, 86, 8)
						+ Mid(BitArray, 66, 15)
						+ Mid(BitArray, 94, 3)
						+ Mid(BitArray, 65, 1)
						+ Mid(BitArray, 55, 4)
						+ Mid(BitArray, 61, 4);
		Else // Chip series 01,10,11
			SerialNumber = Mid(BitArray, 86, 11) 
						+ Mid(BitArray, 65, 16)
						+ Mid(BitArray, 52, 2)
						+ Mid(BitArray, 57, 1)
						+ Mid(BitArray, 55, 4)
						+ Mid(BitArray, 61, 4);
					EndIf;
					
	ElsIf Manufacturer = "006" Or Manufacturer = "806" Then // NXP Semiconductors Chips 
		
		ChipSeries = Mid(BitArray, 21, 11); // Chip Series 
		ChipSeries = ConvertBinaryStringVNEX(ChipSeries);
		If ChipSeries = "806" Or ChipSeries = "807" Then // G2iL or G2iL+
			SerialNumber = "111"
				+ Mid(BitArray, 24, 3) 
				+ Mid(BitArray, 33, 32);
		Else
			SerialNumber = Mid(BitArray, 59, 38);
		EndIf;
		
	ElsIf Manufacturer = "003" Or Manufacturer = "803" Then // Alien Technology Chips  
		
		// Words 2, 3, 4 and 5
		SerialNumber = Mid(BitArray, 59, 38);
		
	Else
		
		ExecutionResult.ErrorDescription = NStr("vi = 'Không hỗ trợ khởi tạo số sê-ri đối với nhà sản xuất chip đã chỉ ra trong TID.';
												|ru = 'Генерация серийного номера для чипа производителя указанного в TID не поддерживается.';
												|en = 'Generation of a serial number for the manufacturer chip specified in the TID is not supported.'; fa = 'Generation of a serial number for the manufacturer chip specified in the TID is not supported.';
												|it = 'La generazione del numero di serie per il chip del produttore specificato nel TID non è supportata.';
												|pl = 'Generowanie numeru seryjnego dla chipu producenta, wskazanego w TID nie jest obsługiwana.';
												|tr = 'TID''de belirtilen üretici çipi için seri numarası oluşturulması desteklenmiyor.'");
		Return ExecutionResult;
		
	EndIf;
	
	ExecutionResult.Result = True;
	ExecutionResult.SerialNumber = ConvertBinaryStringToNumber(SerialNumber);
		
	Return ExecutionResult;
	
EndFunction

#EndRegion

#Region RFID

// Get a table of RFID tags.
//
// Parameters:
//  LBLData - String
//
// Returns:
//  Array
// 
Function RFIDTags(LBLData) Export
	
	#If WebClient Then
	Return EquipmentManagerServerCall.RFIDTags(LBLData);
	#Else
	
	Result = New Array();
	If Not IsBlankString(LBLData) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(LBLData);
		XMLReader.MoveToContent();
		
		If XMLReader.Name = "Table" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			While XMLReader.Read() Do  
				If XMLReader.Name = "Tag" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					
					// APK: 1353-off TID, EPC, USER - abbreviation
					// Getting the memory banks of the read label.
					TID = XMLReader.AttributeValue("TID");
					EPC = XMLReader.AttributeValue("EPC");
					USER = XMLReader.AttributeValue("USER");
					// Decoding of the EPC bank according to the SGTIN format.  
					DataPosition = EquipmentManagerClientServer.DecodingSGTINData(EPC);
					DataPosition.Insert("TID" , TID);  // We add labels to the structure of the TID value of the chip.
					DataPosition.Insert("USER", USER); // Adding the values of the USER bank to the structure.
					DataPosition.Insert("UserMemory", EquipmentManagerClientServer.ConvertNonXBString(USER));
					// APK: 1353-on
					Result.Add(DataPosition);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return Result;
	#EndIf
	
EndFunction

#EndRegion


// Base64 to barcode.
// 
// Parameters:
//  BarcodeInBase64 - String - Barcode in base64
// 
// Returns:
//  String - Base64 to Barcode
Function Base64BBarcode(BarcodeInBase64) Export
	
	BinaryData = Base64Value(BarcodeInBase64);
	If BinaryData = Undefined Then
		Barcode = BarcodeInBase64;
	Else
		Barcode = GetStringFromBinaryData(BinaryData);
	EndIf;
	
	Return Barcode;
	
EndFunction

// Barcode in base64.
// 
// Parameters:
//  Barcode - String - Barcode
// 
// Returns:
//  String - Barcode in base64
Function BarcodeInBase64(Barcode) Export
	
	If Barcode = Undefined Then 
		RowBinaryData = Undefined;
	Else
		RowBinaryData = GetBinaryDataFromString(Barcode);
		BarcodeBASE64 = Base64String(RowBinaryData);
		BarcodeBASE64 = StrReplace(BarcodeBASE64, Chars.LF, "");
		BarcodeBASE64 = StrReplace(BarcodeBASE64, Chars.CR, "");
	EndIf;
	
	Return BarcodeBASE64; 
	
EndFunction

#EndRegion

#Region Internal

// Checks and converts the subscriber number (phone) to FFD +{C} format     
// 
// Parameters:
//  SubscriberNumber - String - Phone
// 
// Returns:
//  String - Subscriber number in FFD +{C} format 
//
Function SubscriberNumberFFDFormat(Val SubscriberNumber) Export
	
	NumberFFDFormat = "";
	
	If IsBlankString(SubscriberNumber) Then
		Return NumberFFDFormat;   
	EndIf;
		
	For IndexOf = 1 To StrLen(SubscriberNumber) Do
		CharCode = Mid(SubscriberNumber, IndexOf, 1);    
		If StrFind("0123456789", CharCode) > 0 Then 
			NumberFFDFormat = NumberFFDFormat + CharCode;
		EndIf;
	EndDo;
	
	PhoneNumberLength = StrLen(NumberFFDFormat);  
	If PhoneNumberLength = 10 Then
		NumberFFDFormat = "+7" + NumberFFDFormat;
	ElsIf PhoneNumberLength = 11 And Left(NumberFFDFormat, 1) = "8" Then
		NumberFFDFormat = "+7" + Mid(NumberFFDFormat, 2);
	Else
		NumberFFDFormat = "+" + NumberFFDFormat;
	EndIf;
	
	Return NumberFFDFormat; 
	
EndFunction

// The client ID for the workplace.
// 
// Returns:
//  String - Client ID for the workplace
Function ClientIDForWorkplace() Export
	
	SystemInfo = New SystemInfo();
	Return Upper(SystemInfo.ClientID);
	
EndFunction

Function NewWorkplaceSearchAttributes() Export
	
	Attributes = New Structure;
	Attributes.Insert("ClientID", "");
	Attributes.Insert("ComputerName", "");
	Attributes.Insert("MACAddresses", New Array);
	Return Attributes;
	
EndFunction

Function NewWorkplaceSettings() Export
	
	Parameters = New Structure;
	Parameters.Insert("Workplace");
	Parameters.Insert("RDPIsUsed", False);
	Parameters.Insert("IsPeripherals", True);
	
	Parameters.Insert("CurrentSearchAttributes", NewWorkplaceSearchAttributes());
	Parameters.Insert("RecordedSearchAttributes", NewWorkplaceSearchAttributes());
	
	Return Parameters;
	
EndFunction

// Returns the key for requesting the driver log archive to notify the client.
//
// Returns:
//   String
//
Function KeyForRequestingDriverLogArchive() Export
	Return "BPO.RequestingArchiveOfDriverLogs";
EndFunction

// Returns the response key to the request for the driver log archive to notify the client.
//
// Returns:
//   String
//
Function KeyForRespondingToRequestForDriverLogArchive() Export
	Return "BPO.ResponseToRequestForDriverLogArchive";
EndFunction


Function ThisIsBase64String(String) Export
	
	StringLength = StrLen(String);
	If StringLength < 16 Then
		Return False;
	EndIf;
	
	If StringLength % 4 <> 0 Then
		Return False;
	EndIf;
	
	If StrOccurrenceCount(String, "/") > 0 Then
		Return False;
	EndIf;
	If StrOccurrenceCount(String, "\") > 0 Then
		Return False;
	EndIf;
	If StrOccurrenceCount(String, ":") > 0 Then
		Return False;
	EndIf;
	If StrOccurrenceCount(String, ".") > 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function ResultOfCallingHTTPMethod() Export
	
	Result = New Structure;
	Result.Insert("Success", True);
	Result.Insert("ResponseCode", 0);
	Result.Insert("ResponseBody", "");
	Result.Insert("ErrorDescription", "");
	Result.Insert("CallingAtServer", Undefined);
	Result.Insert("Timeout", False);
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function AddLeadingZeros(Val String, Val LineLength) 
	
	FullText = String;
	While StrLen(FullText) < LineLength Do
		FullText = "0" + FullText;
	EndDo;
	          
	Return FullText;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated: no longer in use
// Fills in the parameter structure of the KM request.
// 
// Returns:
//  Structure:
// *QueryID - String - Unique Request ID
// *Count - Number - Count
// *FractionalQuantity - See PeripheralsReceiptPrintersClientServer.ParametersFractionalQuantity
// *ControlMark - String - The code of the control mark. Encoded by Base64 encoded text.
// *UnitCode - String -  The code of the unit of measurement in accordance with the All-Russian classifier of units of measurement.
// *PlannedProductStatus - EnumRef
//
Function KmRequestParameters() Export;
	
	If EquipmentManagerServerCall.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevicesClientServer = CommonModule("PeripheralsReceiptPrintersClientServer");
	EndIf;  
	
	Return ModuleEquipmentReceiptPrintingDevicesClientServer.KmRequestParameters();
	
EndFunction

// Deprecated: no longer in use
// Fills in the parameter structure of the KM request.
//
// Returns:
//   Structure:
//   * QueryID - String - Unique Request ID 
//
Function KmConfirmationParameters() Export;
	
	If EquipmentManagerServerCall.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevicesClientServer = CommonModule("PeripheralsReceiptPrintersClientServer");
	EndIf;  
	
	Return ModuleEquipmentReceiptPrintingDevicesClientServer.KmConfirmationParameters(); 
	
EndFunction

// Deprecated: no longer in use
// Returns a reference to the shared module or manager module by name.
//
// See CommonCEL.CommonModule
//
// Parameters:
//  Name - String - name of the shared module.
//
// Returns:
//  CommonModule - the general module.
//
// Example:
//	If the general purpose is PO.The subsystem exists("Standard subsystems.Configuration Update") Then
//		Configuration Update Module = General Purpose configuration.Common Module ("Configuration Update");
//		Configuration Update module.<Method name>();
//	The end if;
//
//	If the general purpose is PO.The subsystem exists("Standard subsystems.Full-text search") Then
//		Module Full Text Search Server = General purpose Search server.General module ("Full-text Search Server");
//		The module is an incomplete Text search server.<Method name>();
//	The end is here.
Function CommonModule(Name)
	
	Module = Eval(Name); // APK: 486 is not required to calculate in safe mode, because the check is reliable.
	
#If Not WebClient Then
	
	// It is not checked in the web client
	// because when accessing modules with a server call, the type of such module does not exist in the web client.
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StrTemplate(
			NStr("vi = 'Mô-đun chung ""%1"" không tồn tại.';
				|ru = 'Общий модуль ""%1"" не существует.';
				|en = 'Common module ""%1"" does not exist.'; fa = 'Common module ""%1"" does not exist.';
				|it = 'Modulo generale ""%1"" non esiste.';
				|pl = 'Moduł ogólny ""%1"" nie istnieje.';
				|tr = '""%1"" ortak modülü mevcut değil.'"), 
			Name);
	EndIf;
	
#EndIf
	
	Return Module;
	
EndFunction

#EndRegion

Function LaunchStringIsSafe(CommandLine1) Export
	
	// String data that does not contain the following characters are considered safe: "$", "`", "|", "||" ";", "&", "&&".
	DangerousCall = StrFind(CommandLine1, "$")>0
		Or StrFind(CommandLine1, "`")>0
		Or StrFind(CommandLine1, "|")>0
		Or StrFind(CommandLine1, "||")>0
		Or StrFind(CommandLine1, ";")>0
		Or StrFind(CommandLine1, "&")>0
		Or StrFind(CommandLine1, "&&")>0;
	Return Not DangerousCall;     
	
EndFunction

// Deprecated: You should use the general purpose client.A data session.
Function SessionDate() Export       
	
	Return CommonCELClientServer.SessionDate();   
	
EndFunction

#EndRegion