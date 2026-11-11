
#Region Public

// To complete the structure of the tax receipt
//
// Returns:
//  Structure
Function ReceiptFiscalizationParameters() Export
	
	FiscalizationParameters = New Structure();

	FiscalizationParameters.Insert("Cashier");
	FiscalizationParameters.Insert("CashierTIN");

	FiscalizationParameters.Insert("DocumentBasis");
	FiscalizationParameters.Insert("IDOfFiscalRecord");
	
	FiscalizationParameters.Insert("Organization");
	FiscalizationParameters.Insert("RetailFacility");
	FiscalizationParameters.Insert("DocumentToBeCorrected");
	FiscalizationParameters.Insert("ThereIsPersonalData", False);
	FiscalizationParameters.Insert("PersonalDataSubject");
	FiscalizationParameters.Insert("PersonalDataType");
	
	FiscalizationParameters.Insert("CalculationType");
	FiscalizationParameters.Insert("DocumentType");
	FiscalizationParameters.Insert("TypeOfCollection");
	
	FiscalizationParameters.Insert("InterfaceRevision");
	FiscalizationParameters.Insert("LineWidth_");
	FiscalizationParameters.Insert("CRERegistrationNumber");
	FiscalizationParameters.Insert("ManufaturerNumberOfFiscalStorage"); 
	FiscalizationParameters.Insert("AdditionalAttribute");
	
	FiscalizationParameters.Insert("CREShiftNumber"   , 0); // Shift number.
	FiscalizationParameters.Insert("KKTReceiptNumber"    , 0); // Fiscal receipt number.
	FiscalizationParameters.Insert("ShiftReceiptNumber", 0); // The number of the shift receipt.
	FiscalizationParameters.Insert("ReceiptDateAndTime"); // Date and time of fiscalization of the receipt for the CCT.      
	FiscalizationParameters.Insert("CurShift");
	
	FiscalizationParameters.Insert("ReceiptAmount", 0);
	FiscalizationParameters.Insert("CashAccountPayment" , 0);                   
	FiscalizationParameters.Insert("ElectronicalyPayment", 0);
	FiscalizationParameters.Insert("PaymentPrepayment", 0);  
	FiscalizationParameters.Insert("PaymentPayment", 0);
	FiscalizationParameters.Insert("PaymentConsideration", 0);
	
	FiscalizationParameters.Insert("FiscalFlag" , ""); // Fiscal attribute of the document.
	FiscalizationParameters.Insert("VerificationWebsiteAddress", ""); // The address of the FTS verification site.
	FiscalizationParameters.Insert("PrintError"      , False); // Error when printing the paper form of the receipt
	
	FiscalizationParameters.Insert("Electronically"       , False);
	FiscalizationParameters.Insert("Sends1CSMS"  , False);
	FiscalizationParameters.Insert("Sends1CEmail", False);
	FiscalizationParameters.Insert("Offline"  , False);
	FiscalizationParameters.Insert("BuyerEmail"   ); // String,Optional - The buyer's email address.
	FiscalizationParameters.Insert("BuyerNumber"   ); // String,Optional - The buyer's phone number. In the format +{C}.
	
	FiscalizationParameters.Insert("XMLReceiptData_");
	FiscalizationParameters.Insert("ReceiptDataAndPersonalData");
	FiscalizationParameters.Insert("ResultOfXMLOperation");
	FiscalizationParameters.Insert("MessageText");
	
	FiscalizationParameters.Insert("CurrentStatus", ParametersOfFiscalOperation());
	
	FiscalizationParameters.Insert("ReverseCorrectionCheck");
	FiscalizationParameters.Insert("GenerateCorrectionReceiptForReverse", True);     
	FiscalizationParameters.Insert("CorrectionReceiptForCCT", True);  
	
	FiscalizationParameters.Insert("CRENonApplication", True);
	FiscalizationParameters.Insert("VersionFDFCRE11" , False);
	
	FiscalizationParameters.Insert("Result", True);
	FiscalizationParameters.Insert("OperationRecorded", True);
	FiscalizationParameters.Insert("ErrorText");
	
	FiscalizationParameters.Insert("ShiftStatus", 0);
	FiscalizationParameters.Insert("TestReceipts", New Array);
	FiscalizationParameters.Insert("ReceiptText");
	FiscalizationParameters.Insert("CopyOfReceipt", New Array);
	FiscalizationParameters.Insert("AdditionalDocuments_", New Array);
	
	FiscalizationParameters.Insert("SingleReceipt", False);
	
	FiscalizationParameters.Insert("PaymentSystemPaymentID");
	FiscalizationParameters.Insert("PaymentSystemType");         
	
	FiscalizationParameters.Insert("PaymentDetailsAdded", False);
	FiscalizationParameters.Insert("QRCodeAdded", False);
	
	FiscalizationParameters.Insert("BarcodesOfManufacturedProducts", New Map);    
	FiscalizationParameters.Insert("MTDisposalReport");
	Return FiscalizationParameters;
	
EndFunction 

// Parameters of the fiscal operation.
// 
// Returns:
//   See PeripheralsReceiptPrintersClientServer.ParametersOfFiscalOperation.
Function ParametersOfFiscalOperation() Export
	
	Return PeripheralsReceiptPrintersClientServer.ParametersOfFiscalOperation();
	
EndFunction

#Region RegistrationParameters

// This procedure is used to save device registration parameters
// 
// Parameters:
//  Id - CatalogRef.Peripherals - Device ID - 
//  RegistrationParameters - Structure -  
//
// Returns:
//  Boolean
Function SaveDeviceRegistrationSettings(Id, RegistrationParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT TOP 1
	                      |	Peripherals.Ref AS Ref
	                      |FROM
	                      |	Catalog.Peripherals AS Peripherals
	                      |WHERE
	                      |	Peripherals.Ref = &Id");
	
	Query.SetParameter("Id", Id);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Result = False;
		Return Result;
	EndIf;
		
	BeginTransaction();
	Try
		DataLock        = New DataLock();
		LockItem       = DataLock.Add("Catalog.Peripherals");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Ref", Id);
		DataLock.Lock();
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		ObjectRef      = Selection.Ref; // CatalogRef.Peripherals
		ObjectOfCatalog = ObjectRef.GetObject();
		ObjectOfCatalog.RegistrationParameters.Clear();
		For Each RegistrationParameter In RegistrationParameters Do
			NewRow = ObjectOfCatalog.RegistrationParameters.Add();
			NewRow.ParameterName_ = RegistrationParameter.Key;
			If TypeOf(RegistrationParameter.Value) = Type("Boolean") Then
				NewRow.ParameterValue = XMLString(RegistrationParameter.Value);
			Else
				NewRow.ParameterValue = RegistrationParameter.Value;
			EndIf;
		EndDo;
		ObjectOfCatalog.Write();
		Result = True;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Result = False;
	EndTry;
	
	SetPrivilegedMode(False);
	
	Return Result;

EndFunction

// The function returns registration parameters based on the device ID.
// 
// Parameters:
//  Id - CatalogRef.Peripherals 
//
// Returns:
//  Structure
//
Function DeviceRegistrationParameters(Id) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Peripherals.Ref AS Ref,
		|	PeripheralsRegistrationParameters.ParameterName_ AS ParameterName_,
		|	PeripheralsRegistrationParameters.ParameterValue AS ParameterValue
		|FROM
		|	Catalog.Peripherals.RegistrationParameters AS PeripheralsRegistrationParameters
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON PeripheralsRegistrationParameters.Ref = Peripherals.Ref
		|WHERE
		|	(Peripherals.Ref = &Id)";
	
	Query.SetParameter("Id", Id);
	
	QueryResult = Query.Execute();
	
	HasData = False;
	StorageData_ = New Structure();
	
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		// Insert sample processing sampledetalnotesreferences
		StorageData_.Insert(SelectionDetailRecords.ParameterName_, SelectionDetailRecords.ParameterValue);
		HasData = True;
	EndDo;
	
	OperationResult = PeripheralsReceiptPrintersClientServer.CRERegistrationParameters();
	OperationResult.Insert("HasData", HasData);
	
	If HasData Then
		OperationResult.CRERegistrationNumber = StorageData_.CRERegistrationNumber;
		OperationResult.CompanyName     = StorageData_.CompanyName;
		OperationResult.CompanyTIN          = StorageData_.CompanyTIN;
		
		If StorageData_.Property("AddressOfSettlementsConduction") Then
			OperationResult.AddressOfSettlementsConduction = StorageData_.AddressOfSettlementsConduction; 
		EndIf;
		If StorageData_.Property("CalculationPlace") Then
			OperationResult.CalculationPlace = StorageData_.CalculationPlace; 
		EndIf;
		
		OperationResult.TaxationSystemCodes = StorageData_.TaxationSystemCodes;
		
		If StorageData_.Property("IndicatesOfflineMode") And Not IsBlankString(StorageData_.IndicatesOfflineMode) Then
			OperationResult.IndicatesOfflineMode = CommonCEL.ConvertToBoolean(StorageData_.IndicatesOfflineMode);
		EndIf;
		If StorageData_.Property("IndicatesThatDataIsEncrypted") And Not IsBlankString(StorageData_.IndicatesThatDataIsEncrypted) Then
			OperationResult.IndicatesThatDataIsEncrypted = CommonCEL.ConvertToBoolean(StorageData_.IndicatesThatDataIsEncrypted); 
		EndIf;
		If StorageData_.Property("IndicatesSettlementsForServices") And Not IsBlankString(StorageData_.IndicatesSettlementsForServices) Then
			OperationResult.IndicatesOfflineMode = CommonCEL.ConvertToBoolean(StorageData_.IndicatesOfflineMode);   
		EndIf;
		If StorageData_.Property("IndicatesThatAccountableFormsAreGenerated") And Not IsBlankString(StorageData_.IndicatesThatAccountableFormsAreGenerated) Then
			OperationResult.IndicatesThatAccountableFormsAreGenerated = CommonCEL.ConvertToBoolean(StorageData_.IndicatesThatAccountableFormsAreGenerated); 
		EndIf;
		If StorageData_.Property("IndicatesThatSettlementsAreMadeOnlyViaInternet") And Not IsBlankString(StorageData_.IndicatesThatSettlementsAreMadeOnlyViaInternet) Then
			OperationResult.IndicatesThatSettlementsAreMadeOnlyViaInternet = CommonCEL.ConvertToBoolean(StorageData_.IndicatesThatSettlementsAreMadeOnlyViaInternet); 
		EndIf;
		If StorageData_.Property("SellExcisableGoods") And Not IsBlankString(StorageData_.SellExcisableGoods) Then
			OperationResult.SellExcisableGoods = CommonCEL.ConvertToBoolean(StorageData_.SellExcisableGoods); 
		EndIf;
		If StorageData_.Property("GamblingConducting") And Not IsBlankString(StorageData_.GamblingConducting) Then
			OperationResult.GamblingConducting = CommonCEL.ConvertToBoolean(StorageData_.GamblingConducting); 
		EndIf;
		If StorageData_.Property("LotteryConducting") And Not IsBlankString(StorageData_.LotteryConducting) Then
			OperationResult.LotteryConducting = CommonCEL.ConvertToBoolean(StorageData_.LotteryConducting); 
		EndIf;
		If StorageData_.Property("InstallPrinterAutomatically") And Not IsBlankString(StorageData_.InstallPrinterAutomatically) Then
			OperationResult.InstallPrinterAutomatically = CommonCEL.ConvertToBoolean(StorageData_.InstallPrinterAutomatically); 
		EndIf;
		If StorageData_.Property("AutomaticVendingMachineSign") And Not IsBlankString(StorageData_.AutomaticVendingMachineSign) Then
			OperationResult.AutomaticVendingMachineSign = CommonCEL.ConvertToBoolean(StorageData_.AutomaticVendingMachineSign); 
		EndIf;
		If StorageData_.Property("WhetherPublicCateringServicesAreProvided") And Not IsBlankString(StorageData_.WhetherPublicCateringServicesAreProvided) Then
			OperationResult.WhetherPublicCateringServicesAreProvided = CommonCEL.ConvertToBoolean(StorageData_.WhetherPublicCateringServicesAreProvided); 
		EndIf;
		If StorageData_.Property("IndicatesWholesaleTradeWithOrganizations") And Not IsBlankString(StorageData_.IndicatesWholesaleTradeWithOrganizations) Then
			OperationResult.IndicatesWholesaleTradeWithOrganizations = CommonCEL.ConvertToBoolean(StorageData_.IndicatesWholesaleTradeWithOrganizations); 
		EndIf;
		
		If StorageData_.Property("AgentCharacteristics") Then
			OperationResult.AgentCharacteristics = StorageData_.AgentCharacteristics; 
		EndIf;
		
		OperationResult.MachineNumberForAutomaticMode = StorageData_.MachineNumberForAutomaticMode;
		OperationResult.OFDINNOrganization      = StorageData_.OFDINNOrganization;
		OperationResult.OrganizationOfdname = StorageData_.OrganizationOfdname;
		OperationResult.CREIdentificationNumber      = StorageData_.CREIdentificationNumber;
		OperationResult.ManufaturerNumberOfFiscalStorage       = StorageData_.ManufaturerNumberOfFiscalStorage;
		OperationResult.VersionFDFCRE           = StorageData_.VersionFDFCRE;
		OperationResult.FFDFNVersion            = StorageData_.FFDFNVersion;
		If StorageData_.Property("ShowsWhetherFiscalizationIsUsed") And Not IsBlankString(StorageData_.ShowsWhetherFiscalizationIsUsed) Then
			OperationResult.ShowsWhetherFiscalizationIsUsed = CommonCEL.ConvertToBoolean(StorageData_.ShowsWhetherFiscalizationIsUsed); 
		EndIf;
	EndIf;
	
	Return OperationResult;
	
EndFunction

// Updates the parameters of the CCT registration
//
// Parameters:
//   RegistrationParametersTable - ValueTable - 
//   RegistrationParameters - ValueTable - 
Procedure UpdateCCTRegistrationParameters(RegistrationParametersTable, RegistrationParameters) Export
	
	RegistrationParametersTable.Clear();
	
	For Each RegistrationParameter In RegistrationParameters Do
		
		Parameter = RegistrationParametersTable.Add();
		ParameterName_ = RegistrationParameter.ParameterName_;
		ParameterValue     = RegistrationParameter.ParameterValue;
		
		If ParameterName_ = "CRERegistrationNumber" Then
			ParameterName_ = NStr("vi = 'Số đăng ký máy tính tiền';
									|ru = 'Регистрационный номер ККТ';
									|en = 'Cash register registration number'; fa = 'شماره ثبت صندوق فروش';
									|it = 'Numero di registrazione del registratore di cassa';
									|pl = 'Numer rejestracyjny kasy';
									|tr = 'Yazar kasa kayıt numarası'")
		ElsIf ParameterName_ = "CompanyName" Then
			ParameterName_ = NStr("vi = 'Tên doanh nghiệp';
									|ru = 'Название организации';
									|en = 'Company name'; fa = 'نام شرکت';
									|it = 'Nome dell''azienda';
									|pl = 'Nazwa firmy';
									|tr = 'İş yerinin adı'")
		ElsIf ParameterName_ = "CompanyTIN" Then
			ParameterName_ = NStr("vi = 'MST của doanh nghiệp';
									|ru = 'ИНН организации';
									|en = 'Company TIN'; fa = 'شناسه مالیاتی شرکت';
									|it = 'Codice fiscale dell''azienda';
									|pl = 'NIP firmy';
									|tr = 'İş yeri VKN'")
		ElsIf ParameterName_ = "AddressOfSettlementsConduction" Then
			ParameterName_ = NStr("vi = 'Địa chỉ tiến hành hạch toán';
									|ru = 'Адрес проведения расчетов';
									|en = 'Cash register location'; fa = 'Cash register location';
									|it = 'Indirizzo di esecuzione dei conti';
									|pl = 'Adres rozliczeń';
									|tr = 'Hesaplamaların gerçekleştirildiği adres'")
		ElsIf ParameterName_ = "TaxationSystemCodes" Then
			ParameterName_ = NStr("vi = 'Hệ thống thuế';
									|ru = 'Системы налогообложения';
									|en = 'Taxation systems'; fa = 'نظام‌های مالیاتی';
									|it = 'Sistemi di tassazione';
									|pl = 'Systemu opodatkowania';
									|tr = 'Vergilendirme sistemleri'");
			TaxationSystems = StrSplit(ParameterValue, ",");
			ParameterValue = "";
			For Each TaxationSystem In TaxationSystems Do
				ParameterValue = ?(Not IsBlankString(ParameterValue), ParameterValue + ",", "");
				If Not IsBlankString(TaxationSystem) Then
					ParameterValue = ParameterValue + """"+ PeripheralsReceiptPrintersClientServer.NameOfTaxSystem(Number(TaxationSystem)) + """";
				EndIf;
			EndDo;
		ElsIf ParameterName_ = "IndicatesOfflineMode" Then
			ParameterName_ = NStr("vi = 'Chế độ ngoại tuyến';
									|ru = 'Автономный режим';
									|en = 'Offline'; fa = 'آفلاین';
									|it = 'Regime autonomo';
									|pl = 'Tryb offline';
									|tr = 'Otonom mod'")
		ElsIf ParameterName_ = "IndicatesAutomaticMode" Then
			ParameterName_ = NStr("vi = 'Chế độ tự động';
									|ru = 'Автоматический режим';
									|en = 'Auto mode'; fa = 'حالت خودکار';
									|it = 'Regime automatico';
									|pl = 'Tryb automatyczny';
									|tr = 'Otomatik mod'")
		ElsIf ParameterName_ = "MachineNumberForAutomaticMode" Then
			ParameterName_ = NStr("vi = 'Số tự động của chế độ tự động';
									|ru = 'Номер автомата для автоматического режима';
									|en = 'Machine number for automatic mode'; fa = 'Machine number for automatic mode';
									|it = 'Numero della macchina per il regime automatico';
									|pl = 'Numer automatu dla trybu automatycznego';
									|tr = 'Otomatik mod için makine numarası'")
		ElsIf ParameterName_ = "IndicatesThatDataIsEncrypted" Then
			ParameterName_ = NStr("vi = 'Mã hóa dữ liệu';
									|ru = 'Шифрование данных';
									|en = 'Data encryption'; fa = 'رمزگذاری داده‌ها';
									|it = 'Crittografia dei dati';
									|pl = 'Szyfrowanie danych';
									|tr = 'Veri şifrelemesi'")
		ElsIf ParameterName_ = "IndicatesSettlementsForServices" Then
			ParameterName_ = NStr("vi = 'Thanh toán dịch vụ';
									|ru = 'Расчет за услуги';
									|en = 'Payments for services'; fa = 'Payments for services';
									|it = 'Pagamento per i servizi';
									|pl = 'Rozliczenie za usługi';
									|tr = 'Hizmet ödemeleri'")
		ElsIf ParameterName_ = "IndicatesThatAccountableFormsAreGenerated" Then
			ParameterName_ = NStr("vi = 'Lập báo cáo quy định';
									|ru = 'Формирования БСО';
									|en = 'Accountable form generation'; fa = 'Accountable form generation';
									|it = 'Generazione del modulo di rendicontazione rigorosa';
									|pl = 'Tworzenie BSO';
									|tr = 'Mutabakat raporu oluşturulması'")
		ElsIf ParameterName_ = "IndicatesThatSettlementsAreMadeOnlyViaInternet" Then
			ParameterName_ = NStr("vi = 'Chỉ tính toán trên Internet';
									|ru = 'Расчет только в интернет';
									|en = 'Payments via Internet only'; fa = 'Payments via Internet only';
									|it = 'Pagamento solo tramite internet';
									|pl = 'Rozliczenie tylko przez Internet';
									|tr = 'Yalnızca internetten ödeme'")
		ElsIf ParameterName_ = "OFDINNOrganization" Then
			ParameterName_ = NStr("vi = 'OFD MST';
									|ru = 'ОФД ИНН';
									|en = 'FDO TIN'; fa = 'FDO TIN';
									|it = 'Operatori Dei Dati Fiscali Del Codice Fiscale';
									|pl = 'ODF NIP';
									|tr = 'Mali veri operatörüne ait VKN'")
		ElsIf ParameterName_ = "OrganizationOfdname" Then
			ParameterName_ = NStr("vi = 'Tên cơ quan điều hành dữ liệu tài chính';
									|ru = 'Наименование ОФД';
									|en = 'FDO name'; fa = 'FDO name';
									|it = 'Nome dell''operatore dei dati fiscali';
									|pl = 'Nazwa ODF';
									|tr = 'Mali veri operatörünün ismi'")
		ElsIf ParameterName_ = "CREIdentificationNumber" Then
			ParameterName_ = NStr("vi = 'Số kỹ thuật kiểm tra tiền mặt theo nhà máy';
									|ru = 'Заводской номер ККТ';
									|en = 'Cash register identification number'; fa = 'Cash register identification number';
									|it = 'Numero di serie del registratore di cassa';
									|pl = 'Numer fabryczny kasy';
									|tr = 'Fabrika yazar kasa numarası'")
		ElsIf ParameterName_ = "ShowsWhetherFiscalizationIsUsed" Then
			ParameterName_ = NStr("vi = 'Dấu hiệu tài chính';
									|ru = 'Признак фискализации';
									|en = 'Shows whether fiscalization is used'; fa = 'Shows whether fiscalization is used';
									|it = 'Segno di fiscalizzazione';
									|pl = 'Oznaka fiskalizacji';
									|tr = 'Malileştirme işareti'")
		ElsIf ParameterName_ = "ManufaturerNumberOfFiscalStorage" Then
			ParameterName_ = NStr("vi = 'Số sản xuất bộ nhớ máy tính tiền';
									|ru = 'Заводской номер ФН';
									|en = 'Fiscal memory device identification number'; fa = 'شماره شناسایی حافظه مالی';
									|it = 'Numero di serie del Deposito Fiscale';
									|pl = 'Numer fabryczny dysku fiskalnego';
									|tr = 'FN fabrika numarası'")
		ElsIf ParameterName_ = "FiscalizationDocumentNumber" Then
			ParameterName_ = NStr("vi = 'Số chứng từ tài chính';
									|ru = 'Номер документа фискализации';
									|en = 'Fiscalization document number'; fa = 'Fiscalization document number';
									|it = 'Numero del documento di fiscalizzazione';
									|pl = 'Numer dokumentu fiskalizacji';
									|tr = 'Malileştirme belgesi numarası'")
		ElsIf ParameterName_ = "DateAndTimeOfFiscalization" Then
			ParameterName_ = NStr("vi = 'Ngày và thời gian lập chứng từ tài chính';
									|ru = 'Дата и время фискализации';
									|en = 'Fiscalization date and time'; fa = 'Fiscalization date and time';
									|it = 'Data e ora della fiscalizzazione';
									|pl = 'Data i godzina fiskalizacji';
									|tr = 'Malileştirme tarihi ve saati'")
		ElsIf ParameterName_ = "VersionFDFCRE" Then
			ParameterName_ = NStr("vi = 'Phiên bản định dạng chứng từ tài chính MTT';
									|ru = 'Версия ФФД ККТ';
									|en = 'Version FDF cash register'; fa = 'Version FDF cash register';
									|it = 'Versione dei Formati Dei Documenti Fiscali del registratore di cassa';
									|pl = 'Wersja FDF kasy';
									|tr = 'FFD yazar kasa sürümü'")
		ElsIf ParameterName_ = "FFDFNVersion" Then
			ParameterName_ = NStr("vi = 'Phiên bản định dạng chứng từ tài chính bộ nhớ máy tính tiền';
									|ru = 'Версия ФФД ФН';
									|en = 'FDF fiscal memory device version'; fa = 'FDF fiscal memory device version';
									|it = 'Versione dei Formati Dei Documenti fiscali del deposito fiscale';
									|pl = 'Wersja FDF dysku fiskalnego';
									|tr = 'FFD FN sürümü'")
		// FFD 1.05 and FFD 1.1
		ElsIf ParameterName_ = "CalculationPlace" Then
			ParameterName_ = NStr("vi = 'Nơi tiến hành hạch toán';
									|ru = 'Место проведения расчетов';
									|en = 'Calculation place'; fa = 'Calculation place';
									|it = 'Luogo di esecuzione dei conti';
									|pl = 'Miejsce rozliczenia';
									|tr = 'Hesaplamaların gerçekleştirildiği yer'")
		ElsIf ParameterName_ = "SellExcisableGoods" Then
			ParameterName_ = NStr("vi = 'Bán hàng hóa chịu thuế tiêu thụ đặc biệt';
									|ru = 'Продажа подакцизного товара';
									|en = 'Sell excisable goods'; fa = 'Sell excisable goods';
									|it = 'Vendita di prodotti soggetti ad accisa';
									|pl = 'Sprzedaż towaru akcyzowego';
									|tr = 'Özel tüketim ürünlerinin satışları'")
		ElsIf ParameterName_ = "GamblingConducting" Then
			ParameterName_ = NStr("vi = 'Trò chơi có thưởng';
									|ru = 'Проведения азартных игр';
									|en = 'Gambling conducting'; fa = 'Gambling conducting';
									|it = 'Conduzione dei giochi d''azzardo';
									|pl = 'Prowadzenia gier hazardowych';
									|tr = 'Kumar oyunlarının gerçekleştirilmesi'")
		ElsIf ParameterName_ = "LotteryConducting" Then
			ParameterName_ = NStr("vi = 'Xổ số';
									|ru = 'Проведения лотерей';
									|en = 'Lottery conducting'; fa = 'Lottery conducting';
									|it = 'Conduzione di lotterie';
									|pl = 'Prowadzenie loterii';
									|tr = 'Piyangoların gerçekleştirilmesi'")
		ElsIf ParameterName_ = "AgentCharacteristics" Then
			ParameterName_ = NStr("vi = 'Dấu hiệu của đại lý';
									|ru = 'Признаки агента';
									|en = 'Agent characteristics'; fa = 'مشخصات نماینده';
									|it = 'Segni di un agente';
									|pl = 'Oznaki agenta';
									|tr = 'Aracı işareti'")
		ElsIf ParameterName_ = "InstallPrinterAutomatically" Then
			ParameterName_ = NStr("vi = 'Tự động cài đặt máy in';
									|ru = 'Установка принтера в автомате';
									|en = 'Install printer automatically'; fa = 'Install printer automatically';
									|it = 'Installazione di una stampante nella macchina';
									|pl = 'Instalacja drukarki w automacie';
									|tr = 'Makineye yazıcı kurulumu'")
		// FFD 1.2
		ElsIf ParameterName_ = "CarryingOutCalculationOnInternet" Then
			ParameterName_ = NStr("vi = 'Tiến hành tính toán trên Internet';
									|ru = 'Проведения расчета в интернет';
									|en = 'Online payment'; fa = 'Online payment';
									|it = 'Проведения расчета в интернет';
									|pl = 'Online payment';
									|tr = 'İnternette alacak/borç muhasebesi'")
		ElsIf ParameterName_ = "SaleOfMarkedGoods" Then
			ParameterName_ = NStr("vi = 'Bán hàng hóa có dán nhãn';
									|ru = 'Продажа маркированных товаров';
									|en = 'Sell marked goods'; fa = 'Sell marked goods';
									|it = 'Продажа маркированных товаров';
									|pl = 'Sell marked goods';
									|tr = 'Etiketli ürünlerin satışı'")
		ElsIf ParameterName_ = "PawnshopUsageFlag" Then
			ParameterName_ = NStr("vi = 'Áp dụng cho hiệu cầm đồ';
									|ru = 'Применения ломбардами';
									|en = 'Used by pawn shops'; fa = 'Used by pawn shops';
									|it = 'Применения ломбардами';
									|pl = 'Used by pawn shops';
									|tr = 'Rehinci uygulamaları'")
		ElsIf ParameterName_ = "IndicationOfInsuranceActivity" Then
			ParameterName_ = NStr("vi = 'Hoạt động bảo hiểm';
									|ru = 'Деятельность по страхованию';
									|en = 'Insurance activity'; fa = 'Insurance activity';
									|it = 'Деятельность по страхованию';
									|pl = 'Insurance activity';
									|tr = 'Sigorta faaliyetleri'")
		// FFD 1.2 - Order of the Federal Tax Service of Russia dated 12.04.2023 N ED-7-20/239@
		ElsIf ParameterName_ = "AutomaticVendingMachineSign" Then
			ParameterName_ = NStr("vi = 'Áp dụng tại chỗ bán hàng tự động';
									|ru = 'Применение в автоматическом торговом автомате';
									|en = 'Used in automatic vending machine'; fa = 'Used in automatic vending machine';
									|it = 'Применение в автоматическом торговом автомате';
									|pl = 'Used in automatic vending machine';
									|tr = 'Otomatik satış makinesinde uygulama'")
		ElsIf ParameterName_ = "WhetherPublicCateringServicesAreProvided" Then
			ParameterName_ = NStr("vi = 'Cung cấp dịch vụ ăn uống';
									|ru = 'Оказании услуг общественного питания';
									|en = 'Provision of food services'; fa = 'Provision of food services';
									|it = 'Оказании услуг общественного питания';
									|pl = 'Provision of food services';
									|tr = 'Yiyecek hizmetlerinin sağlanması'")
		ElsIf ParameterName_ = "IndicatesWholesaleTradeWithOrganizations" Then
			ParameterName_ = NStr("vi = 'Bán buôn với các doanh nghiệp và CNKD';
									|ru = 'Оптовая торговля с организациями и ИП';
									|en = 'Wholesale with companies and individual entrepreneurs'; fa = 'Wholesale with companies and individual entrepreneurs';
									|it = 'Оптовая торговля с организациями и ИП';
									|pl = 'Wholesale with companies and individual entrepreneurs';
									|tr = 'İş yerleri ve şahıs şirketleriyle toptan ticaret'")
		EndIf;
		Parameter.ParameterName_ = ParameterName_;
		Parameter.ParameterValue     = ParameterValue;
	EndDo;
	
EndProcedure

// The function returns whether the fiscal device supports.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID
// 
// Returns:
//  Boolean - The fiscal device supports checking the marking codes
Function FiscalDeviceSupportsVerificationOfMarkingCodes(DeviceID) Export
	
	Result = False;
	RegistrationParameters = DeviceRegistrationParameters(DeviceID);
	If RegistrationParameters <> Undefined Then
		Result = RegistrationParameters.Property("VersionFDFCRE") And RegistrationParameters.VersionFDFCRE = "1.2"
			And RegistrationParameters.Property("FFDFNVersion") And RegistrationParameters.FFDFNVersion = "1.2";
	EndIf;
		
	Return Result;
	
EndFunction

// The function returns the FFD version for the fiscal device.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Undefined - The fiscal device supports the FFD version
Function FiscalDeviceSupportsFFDVersion(DeviceID) Export
	
	Result = Undefined;
	RegistrationParameters = DeviceRegistrationParameters(DeviceID);
	If RegistrationParameters <> Undefined And RegistrationParameters.Property("VersionFDFCRE") Then
		Result = RegistrationParameters.VersionFDFCRE;
	EndIf;
		
	Return Result;
	
EndFunction


#EndRegion

#Region FiscalTransactions

// Write the operation to the fiscal transaction log.
//
// Parameters:
//   FiscalizationParameters - Structure - 
Procedure RecordFiscalTransaction(FiscalizationParameters) Export
	
	SetPrivilegedMode(True);
	
	If IsBlankString(FiscalizationParameters.IDOfFiscalRecord) Then
		RecordID = String(New UUID);
		FiscalizationParameters.IDOfFiscalRecord = RecordID;
	Else
		RecordID = FiscalizationParameters.IDOfFiscalRecord;
	EndIf;
	// FiscalTransactions
	RecordSet = InformationRegisters.FiscalTransactions.CreateRecordSet();
	RecordSet.Filter.DocumentBasis.Set(FiscalizationParameters.DocumentBasis, True);
	RecordSet.Filter.RecordID.Set(RecordID, True);
	
	NewRow = RecordSet.Add();
	NewRow.Date = FiscalizationParameters.ReceiptDateAndTime;
	NewRow.RecordID = RecordID;
	NewRow.DocumentBasis = FiscalizationParameters.DocumentBasis;
	NewRow.FiscalFlag = FiscalizationParameters.FiscalFlag;
	NewRow.DocumentType      = FiscalizationParameters.DocumentType; 
	NewRow.Organization       = FiscalizationParameters.Organization;
	NewRow.RetailFacility    = FiscalizationParameters.RetailFacility;
	NewRow.CalculationType        = FiscalizationParameters.CalculationType;
	NewRow.CashRegisterShiftNumber     = FiscalizationParameters.CREShiftNumber;
	NewRow.CashRegisterReceiptNumber      = FiscalizationParameters.KKTReceiptNumber;
	NewRow.Sum            = FiscalizationParameters.ReceiptAmount;
	NewRow.CashAccountPayment   = FiscalizationParameters.CashAccountPayment;
	NewRow.ElectronicalyPayment = FiscalizationParameters.ElectronicalyPayment;
	NewRow.PaymentPayment = FiscalizationParameters.PaymentPayment;
	NewRow.PaymentPrepayment = FiscalizationParameters.PaymentPrepayment;
	NewRow.PaymentConsideration = FiscalizationParameters.PaymentConsideration;
	NewRow.AdditionalAttribute  = FiscalizationParameters.AdditionalAttribute;
	NewRow.VerificationWebsiteAddress      = FiscalizationParameters.VerificationWebsiteAddress;
	NewRow.ManufaturerNumberOfFiscalStorage        = FiscalizationParameters.ManufaturerNumberOfFiscalStorage;
	NewRow.CRERegistrationNumber = FiscalizationParameters.CRERegistrationNumber; 
	NewRow.DocumentToBeCorrected  = FiscalizationParameters.DocumentToBeCorrected;
	NewRow.PersonalDataSubject = FiscalizationParameters.PersonalDataSubject;
	NewRow.SingleReceipt                 = FiscalizationParameters.SingleReceipt;
	NewRow.PaymentSystemType       = FiscalizationParameters.PaymentSystemType;
	NewRow.PaymentSystemPaymentID  = FiscalizationParameters.PaymentSystemPaymentID;    
	If FiscalizationParameters.XMLReceiptData_ <> Undefined Then
		NewRow.XMLData1 = New ValueStorage(FiscalizationParameters.XMLReceiptData_);
	EndIf;
	
	RecordSet.Write();
	
	If FiscalizationParameters.Property("RecordingOfOperationKM") Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		WriteParameters = ModuleEquipmentManagerMarking.ParametersForRecordingCRVerificationResult();
		WriteParameters.Key.SessionID = FiscalizationParameters.RecordingOfOperationKM.SessionID;
		WriteParameters.Key.QueryID = FiscalizationParameters.RecordingOfOperationKM.QueryID;
		If FiscalizationParameters.RecordingOfOperationKM.PurchaseConfirmationWasPerformed Then
			WriteParameters.PurchaseConfirmed = True;
		EndIf;
		ModuleEquipmentManagerMarking.UpdateResultsOfCheckingMarkingCodeInRegister(WriteParameters);
		ModuleEquipmentManagerMarking.UpdateIdOfFiscalOperationOfResultOfCheckingMarkingCode(
			FiscalizationParameters.RecordingOfOperationKM.SessionID, RecordID);
	EndIf;
	
	If FiscalizationParameters.Property("RecordingOfOperationUSAIS") Then
		
		RecordingOfOperationUSAIS = FiscalizationParameters.RecordingOfOperationUSAIS;
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		WriteParameters = ModuleEquipmentManagerMarking.ParametersForRecordingUSAISVerificationResult();;
		WriteParameters.FiscalTransactionID = RecordID;
		WriteParameters.Completed2 = RecordingOfOperationUSAIS.Completed2;
		WriteParameters.BarcodesOfManufacturedProducts = FiscalizationParameters.BarcodesOfManufacturedProducts;
		WriteParameters.QueryID = RecordingOfOperationUSAIS.ReceiptAddress;
		WriteParameters.ReceiptSignature = RecordingOfOperationUSAIS.ReceiptSignature;
		WriteParameters.IncomingMessage = RecordingOfOperationUSAIS.IncomingMessage;
		WriteParameters.OutgoingMessage = RecordingOfOperationUSAIS.OutgoingMessage;
		WriteParameters.MessageHasBeenTransmitted = RecordingOfOperationUSAIS.MessageHasBeenTransmitted;
		WriteParameters.ErrorText = RecordingOfOperationUSAIS.ErrorDescription;
		ModuleEquipmentManagerMarking.AddUSAISSubmissionResults(WriteParameters);
		
	EndIf;
	
EndProcedure

// APK: 142-off backward compatibility

// Get data from the fiscal transaction log.
//
// Parameters:
//  DocumentRef - DocumentRef - The Foundation document.
//  RecordID - InformationRegisterRecord.FiscalTransactions - record of a fiscal transaction.
//  DocumentTypes - EnumRef.TypesOfCREFiscalDocuments - types of documents.
//  CalculationType - EnumRef.CashSettlementTypes - Type of calculation.
//  FiscalFlag - String - The fiscal feature of the document
// 
// Returns:
//  Structure - Structure by properties:
//   * CashRegisterShiftNumber - Number - The check of KKM.
//   * Sum - Number - The amount.
//   * DocumentBasis - DocumentRef - The Foundation document.
//   * XMLData1 - ValueStorage - Check the data transferred to the CCP (XML).
//
Function FiscalOperationData(DocumentRef, RecordID = Undefined, DocumentTypes = Undefined, CalculationType = Undefined, FiscalFlag = Undefined) Export
	
	FiscalTransaction = Undefined;
	
	If Not (ValueIsFilled(DocumentRef) 
			Or ValueIsFilled(RecordID) 
			Or ValueIsFilled(DocumentTypes) 
			Or ValueIsFilled(CalculationType) 
			Or ValueIsFilled(FiscalFlag)) Then
		Return FiscalTransaction;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	FiscalTransactions.RecordID     AS RecordID,  
	|	FiscalTransactions.Date                    AS Date,
	|	FiscalTransactions.CashRegisterReceiptNumber            AS CashRegisterReceiptNumber,
	|	FiscalTransactions.CashRegisterShiftNumber           AS CashRegisterShiftNumber,
	|	FiscalTransactions.DocumentType            AS DocumentType,
	|	FiscalTransactions.CalculationType              AS CalculationType,
	|	FiscalTransactions.Organization             AS Organization,
	|	FiscalTransactions.RetailFacility          AS RetailFacility,
	|	FiscalTransactions.ManufaturerNumberOfFiscalStorage        AS ManufaturerNumberOfFiscalStorage, 
	|	FiscalTransactions.CRERegistrationNumber AS CRERegistrationNumber,
	|	FiscalTransactions.DocumentBasis       AS DocumentBasis, 
	|	FiscalTransactions.DocumentToBeCorrected  AS DocumentToBeCorrected,
	|	FiscalTransactions.Sum                   AS Sum,         
	|	FiscalTransactions.FiscalFlag       AS FiscalFlag,
	|	FiscalTransactions.AdditionalAttribute  AS AdditionalAttribute, 
	|	FiscalTransactions.SingleReceipt               AS SingleReceipt,
	|	FiscalTransactions.PaymentSystemPaymentID AS PaymentSystemPaymentID,  
	|	FiscalTransactions.PaymentSystemType     AS PaymentSystemType,
	|	FiscalTransactions.XMLData1               AS XMLData1
	|FROM
	|	InformationRegister.FiscalTransactions AS FiscalTransactions
	|WHERE TRUE "
		+ ?(ValueIsFilled(DocumentRef), " AND (FiscalTransactions.DocumentBasis = &DocumentRef)", "")
		+ ?(RecordID = Undefined, "", " AND (FiscalTransactions.RecordID = &RecordID)")
		+ ?(DocumentTypes = Undefined, "", " AND (FiscalTransactions.DocumentType IN (&DocumentTypes))")
		+ ?(CalculationType = Undefined, "", " AND (FiscalTransactions.CalculationType = &CalculationType)")
		+ ?(FiscalFlag = Undefined, "", " AND (FiscalTransactions.FiscalFlag = &FiscalFlag)")
		+ " ORDER BY FiscalTransactions.Date DESC, FiscalTransactions.CashRegisterShiftNumber DESC");
		
	If ValueIsFilled(DocumentRef) Then
		Query.SetParameter("DocumentRef", DocumentRef);
	EndIf;
	
	If RecordID <> Undefined Then
		Query.SetParameter("RecordID", RecordID);
	EndIf;
	
	If DocumentTypes <> Undefined Then
		// Preparation of document types for the request.
		ArrayDocumentTypes = New Array();
		If TypeOf(DocumentTypes) = Type("Array") Then
			For Each DocumentType In DocumentTypes Do
				ArrayDocumentTypes.Add(DocumentType);
			EndDo;
		Else
			ArrayDocumentTypes.Add(DocumentTypes);
		EndIf;
		Query.SetParameter("DocumentTypes", ArrayDocumentTypes);
	EndIf;
	
	If CalculationType <> Undefined Then
		Query.SetParameter("CalculationType", CalculationType);
	EndIf;

	If FiscalFlag <> Undefined Then
		Query.SetParameter("FiscalFlag", FiscalFlag);
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FiscalTransaction = New Structure;
		FiscalTransaction.Insert("RecordID");
		FiscalTransaction.Insert("Date");
		FiscalTransaction.Insert("CashRegisterReceiptNumber");
		FiscalTransaction.Insert("CashRegisterShiftNumber");
		FiscalTransaction.Insert("ManufaturerNumberOfFiscalStorage");
		FiscalTransaction.Insert("CRERegistrationNumber");
		FiscalTransaction.Insert("DocumentType");
		FiscalTransaction.Insert("CalculationType");
		FiscalTransaction.Insert("Organization");
		FiscalTransaction.Insert("RetailFacility");
		FiscalTransaction.Insert("Sum");
		FiscalTransaction.Insert("DocumentBasis");
		FiscalTransaction.Insert("DocumentToBeCorrected");
		FiscalTransaction.Insert("FiscalFlag");
		FiscalTransaction.Insert("AdditionalAttribute");  	
		FiscalTransaction.Insert("SingleReceipt");
		FiscalTransaction.Insert("XMLData1");
		FiscalTransaction.Insert("PaymentSystemPaymentID"); 
		FiscalTransaction.Insert("PaymentSystemType"); 
		FillPropertyValues(FiscalTransaction, Selection);
	EndIf;
	
	Return FiscalTransaction;
	
EndFunction

// APK: 142-on

// Get data from the fiscal transaction log.
//
// Parameters:
//  RecordID - InformationRegisterRecord.FiscalTransactions - The ID of the record.
// 
// Returns:
// InformationRegisterRecord.FiscalTransactions
Function FiscalOperationsByID(RecordID) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	FiscalTransactions.RecordID     AS RecordID,
	|	FiscalTransactions.Date                    AS Date,
	|	FiscalTransactions.CashRegisterReceiptNumber            AS CashRegisterReceiptNumber,
	|	FiscalTransactions.CashRegisterShiftNumber           AS CashRegisterShiftNumber,
	|	FiscalTransactions.DocumentType            AS DocumentType,
	|	FiscalTransactions.CalculationType              AS CalculationType,
	|	FiscalTransactions.Organization             AS Organization,
	|	FiscalTransactions.RetailFacility          AS RetailFacility,
	|	FiscalTransactions.ManufaturerNumberOfFiscalStorage        AS ManufaturerNumberOfFiscalStorage, 
	|	FiscalTransactions.CRERegistrationNumber AS CRERegistrationNumber,
	|	FiscalTransactions.DocumentBasis       AS DocumentBasis, 
	|	FiscalTransactions.DocumentToBeCorrected  AS DocumentToBeCorrected,
	|	FiscalTransactions.Sum                   AS Sum, 
	|	FiscalTransactions.FiscalFlag       AS FiscalFlag,
	|	FiscalTransactions.AdditionalAttribute  AS AdditionalAttribute,     
	|	FiscalTransactions.SingleReceipt               AS SingleReceipt,
	|	FiscalTransactions.PaymentSystemPaymentID AS PaymentSystemPaymentID,  
	|	FiscalTransactions.PaymentSystemType     AS PaymentSystemType,
	|	FiscalTransactions.XMLData1               AS XMLData1
	|FROM
	|	InformationRegister.FiscalTransactions AS FiscalTransactions
	|WHERE
	|	(RecordID = &RecordID)");
	
	Query.SetParameter("RecordID", RecordID);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FiscalTransaction = New Structure;
		FiscalTransaction.Insert("RecordID");
		FiscalTransaction.Insert("Date");
		FiscalTransaction.Insert("CashRegisterReceiptNumber");
		FiscalTransaction.Insert("CashRegisterShiftNumber");
		FiscalTransaction.Insert("ManufaturerNumberOfFiscalStorage");
		FiscalTransaction.Insert("CRERegistrationNumber");
		FiscalTransaction.Insert("DocumentType");
		FiscalTransaction.Insert("CalculationType");
		FiscalTransaction.Insert("Organization");
		FiscalTransaction.Insert("RetailFacility");
		FiscalTransaction.Insert("Sum");
		FiscalTransaction.Insert("DocumentBasis");
		FiscalTransaction.Insert("DocumentToBeCorrected");
		FiscalTransaction.Insert("FiscalFlag");
		FiscalTransaction.Insert("AdditionalAttribute");
		FiscalTransaction.Insert("SingleReceipt");
		FiscalTransaction.Insert("XMLData1");         
		FiscalTransaction.Insert("PaymentSystemPaymentID"); 
		FiscalTransaction.Insert("PaymentSystemType"); 
		FillPropertyValues(FiscalTransaction, Selection);
		Return FiscalTransaction;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Get a list of the fiscal transactions log.
//
// Parameters:
//  DocumentRef - DocumentRef - The Foundation document.
//  DocumentTypes - EnumRef.TypesOfCREFiscalDocuments - types of fiscal documents.
//  CalculationType - EnumRef.CashSettlementTypes - types of calculation.
// 
// Returns:
//  Array of Structure - Structure by properties:
//   * CashRegisterShiftNumber - Number - The check of KKM.
//   * Sum - Number - The amount.
//   * DocumentBasis - DefinedType.BaseDocumentForFiscalPLTransaction - The Foundation document.
//   * XMLData1 - ValueStorage - Check the data transferred to the CCP (XML).
//
Function ListOfFiscalTransactions(DocumentRef, DocumentTypes = Undefined, CalculationType = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT 
	|	FiscalTransactions.RecordID     AS RecordID,
	|	FiscalTransactions.CashRegisterReceiptNumber            AS CashRegisterReceiptNumber,
	|	FiscalTransactions.CashRegisterShiftNumber           AS CashRegisterShiftNumber,
	|	FiscalTransactions.DocumentType            AS DocumentType,
	|	FiscalTransactions.CalculationType              AS CalculationType,
	|	FiscalTransactions.Organization             AS Organization,
	|	FiscalTransactions.RetailFacility          AS RetailFacility,
	|	FiscalTransactions.ManufaturerNumberOfFiscalStorage        AS ManufaturerNumberOfFiscalStorage, 
	|	FiscalTransactions.CRERegistrationNumber AS CRERegistrationNumber,
	|	FiscalTransactions.DocumentBasis       AS DocumentBasis, 
	|	FiscalTransactions.DocumentToBeCorrected  AS DocumentToBeCorrected,
	|	FiscalTransactions.Sum                   AS Sum, 
	|	FiscalTransactions.FiscalFlag       AS FiscalFlag,
	|	FiscalTransactions.AdditionalAttribute  AS AdditionalAttribute,
	|	FiscalTransactions.XMLData1               AS XMLData1
	|FROM
	|	InformationRegister.FiscalTransactions AS FiscalTransactions
	|WHERE
	|	(FiscalTransactions.DocumentBasis = &DocumentRef)"
		+ ?(DocumentTypes = Undefined, "", " AND (FiscalTransactions.DocumentType IN (&DocumentTypes))")
		+ ?(CalculationType = Undefined, "", " AND (FiscalTransactions.CalculationType = &CalculationType)")
		+ " ORDER BY FiscalTransactions.Date DESC, FiscalTransactions.CashRegisterShiftNumber DESC");
		
	Query.SetParameter("DocumentRef", DocumentRef);
	
	If DocumentTypes <> Undefined Then
		// Preparation of document types for the request.
		ArrayDocumentTypes = New Array();
		If TypeOf(DocumentTypes) = Type("Array") Then
			For Each DocumentType In DocumentTypes Do
				ArrayDocumentTypes.Add(DocumentType);
			EndDo;
		Else
			ArrayDocumentTypes.Add(DocumentTypes);
		EndIf;
		Query.SetParameter("DocumentTypes", ArrayDocumentTypes);
	EndIf;
	
	If CalculationType <> Undefined Then
		Query.SetParameter("CalculationType", CalculationType);
	EndIf;
	
	TransactionList = New Array(); 
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FiscalTransaction = New Structure;
		FiscalTransaction.Insert("RecordID");
		FiscalTransaction.Insert("CashRegisterReceiptNumber");
		FiscalTransaction.Insert("CashRegisterShiftNumber");
		FiscalTransaction.Insert("ManufaturerNumberOfFiscalStorage");
		FiscalTransaction.Insert("CRERegistrationNumber");
		FiscalTransaction.Insert("DocumentType");
		FiscalTransaction.Insert("CalculationType");
		FiscalTransaction.Insert("Organization");
		FiscalTransaction.Insert("RetailFacility");
		FiscalTransaction.Insert("Sum");
		FiscalTransaction.Insert("DocumentBasis");
		FiscalTransaction.Insert("DocumentToBeCorrected");
		FiscalTransaction.Insert("FiscalFlag");
		FiscalTransaction.Insert("AdditionalAttribute");
		FiscalTransaction.Insert("XMLData1");
		FillPropertyValues(FiscalTransaction, Selection);
		TransactionList.Add(FiscalTransaction);
	EndDo;
	
	Return TransactionList;
	
EndFunction

#EndRegion

#Region GeneratingCCTData

// Returns which types of products the industry Attributes will be filled in for.
//
// Returns:
//   Structure: 
//  * FurskinsProducts - Boolean - Fillings for natural fur products. 
//  * VolumetricAndVarietalAccounting - Boolean - Fillings for goods of volumetric and varietal accounting.
//  * DairyManufacturedProductsWithUnreadableKM - Boolean - Fillings for dairy manufactured products with unreadable KM.
//
Function TypesOfProductsToFillInIndustryAttributes() Export;
	
	TypesOfGoods = New Structure();
	TypesOfGoods.Insert("FurskinsProducts", True);
	TypesOfGoods.Insert("VolumetricAndVarietalAccounting", True);
	TypesOfGoods.Insert("PublicCatering", True); 
	TypesOfGoods.Insert("DairyManufacturedProductsWithUnreadableKM", False);    
	TypesOfGoods.Insert("VeterinaryMedicine", True); 
	Return TypesOfGoods;
	
EndFunction   

// Returns which types of products the industry Attributes will be filled in for.
//
// Returns:
//   See TypesOfProductsToFillInIndustryAttributes  
//
Function IndustryAttributesAreFilledInForProductTypes() Export
	
	TypesOfGoods = TypesOfProductsToFillInIndustryAttributes();
	EquipmentManagerServerCallOverridable.IndustryAttributesAreFilledInForProductTypes(TypesOfGoods);
	Return TypesOfGoods;
	
EndFunction

// Returns volumetric varietal accounting.
//
// Returns:
//  Boolean
//           
Function VolumetricAndVarietalAccountingIsConducted() Export
	
	Result = False;
	VolumetricAndVarietalAccounting = Result; 
	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.VolumetricAndVarietalAccountingIsConducted(VolumetricAndVarietalAccounting, StandardProcessing);
	Result = ?(StandardProcessing, Result, VolumetricAndVarietalAccounting);
	Return Result; 
	
EndFunction

// Returns whether catering services are provided.
//
// Returns:
//  Boolean
//           
Function CateringServicesAreProvided() Export
	
	Result = False;
	PublicCatering = Result; 
	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.CateringServicesAreProvided(PublicCatering, StandardProcessing);
	Result = ?(StandardProcessing, Result, PublicCatering);
	Return Result; 
	
EndFunction

// Returns the activity of controlling the fiscalization of non-cash payments
//
// Returns:
//  Boolean
//  
Function ControlOfFiscalizationOfNonCashPayments() Export
	
	Result = False;
	Return Result;
	
EndFunction          

// Generate a table of parameters in XML for the operation with the FN.
// 
// Parameters:
//  ParametersStructure - Structure
//  InterfaceRevision - Number - Interface revision
//
// Returns:
//  XMLWriter
//
Function CreateTableOfParametersForFNOperation(ParametersStructure, InterfaceRevision = 0) Export
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	If InterfaceRevision >= 3000 Then  // Standard version 3.0 (OFD 1.1)
		
		XMLWriter.WriteStartElement("ParametersFiscal");
		XMLWriter.WriteAttribute("CashierName" , XMLString(?(ParametersStructure.Property("Cashier")   , XMLString(ParametersStructure.Cashier), NStr("vi = 'Người quản trị';
																																						|ru = 'Администратор';
																																						|en = 'Administrator'; fa = 'مدیر سیستم';
																																						|it = 'Администратор';
																																						|pl = 'Administrator';
																																						|tr = 'Yönetici'"))));
		XMLWriter.WriteAttribute("CashierINN"  , XMLString(?(ParametersStructure.Property("CashierTIN"), XMLString(ParametersStructure.CashierTIN), "")));
		If InterfaceRevision >= 3004 Then           
			// Codes of reasons for changing the information about the CCT. 
			If Not IsBlankString(ParametersStructure.CodesOfReasonsForChangingInformation) Then
				XMLWriter.WriteAttribute("RegistrationLabelCodes", XMLString(ParametersStructure.CodesOfReasonsForChangingInformation));
			EndIf;                 
		Else
			// The code of the reason for re-registration.
			XMLWriter.WriteAttribute("RegistrationReasonCode", XMLString(ParametersStructure.CodeOfReasonForReregistration));
		EndIf;                 
		XMLWriter.WriteAttribute("KKTNumber"         , XMLString(ParametersStructure.CRERegistrationNumber));
		XMLWriter.WriteAttribute("CompanyName"       , XMLString(ParametersStructure.CompanyName));
		XMLWriter.WriteAttribute("INN"               , XMLString(ParametersStructure.CompanyTIN));
		XMLWriter.WriteAttribute("SaleAddress"       , XMLString(ParametersStructure.AddressOfSettlementsConduction));
		XMLWriter.WriteAttribute("SaleLocation"      , XMLString(ParametersStructure.CalculationPlace));
		XMLWriter.WriteAttribute("TaxationSystems"   , XMLString(ParametersStructure.TaxationSystemCodes));
		XMLWriter.WriteAttribute("IsOffline"         , XMLString(ParametersStructure.IndicatesOfflineMode));
		XMLWriter.WriteAttribute("IsEncrypted"       , XMLString(ParametersStructure.IndicatesThatDataIsEncrypted));
		XMLWriter.WriteAttribute("IsService"         , XMLString(ParametersStructure.IndicatesSettlementsForServices));
		XMLWriter.WriteAttribute("IsExcisable"       , XMLString(ParametersStructure.SellExcisableGoods));
		XMLWriter.WriteAttribute("IsGambling"        , XMLString(ParametersStructure.GamblingConducting));
		XMLWriter.WriteAttribute("IsLottery"         , XMLString(ParametersStructure.LotteryConducting));
		XMLWriter.WriteAttribute("AgentTypes"        , XMLString(ParametersStructure.AgentCharacteristics));
		XMLWriter.WriteAttribute("BSOSing"           , XMLString(ParametersStructure.IndicatesThatAccountableFormsAreGenerated));
		XMLWriter.WriteAttribute("IsOnlineOnly"      , XMLString(ParametersStructure.IndicatesThatSettlementsAreMadeOnlyViaInternet));
		If InterfaceRevision >= 3004 Then  // Standard version 3.4 (OFD 1.2)
			XMLWriter.WriteAttribute("IsOnline"    , XMLString(ParametersStructure.CarryingOutCalculationOnInternet));
			XMLWriter.WriteAttribute("IsMarking"   , XMLString(ParametersStructure.SaleOfMarkedGoods));
			XMLWriter.WriteAttribute("IsPawnshop"  , XMLString(ParametersStructure.PawnshopUsageFlag));
			XMLWriter.WriteAttribute("IsAssurance" , XMLString(ParametersStructure.IndicationOfInsuranceActivity));
		EndIf;
		If InterfaceRevision >= 4000 Then  // Standard version 4.0 (OFD 1.2)
			XMLWriter.WriteAttribute("IsVendingMachine"  , XMLString(ParametersStructure.AutomaticVendingMachineSign));
			XMLWriter.WriteAttribute("IsCateringServices", XMLString(ParametersStructure.WhetherPublicCateringServicesAreProvided));
			XMLWriter.WriteAttribute("IsWholesaleTrade"  , XMLString(ParametersStructure.IndicatesWholesaleTradeWithOrganizations));
		EndIf;    
		XMLWriter.WriteAttribute("IsAutomaticPrinter", XMLString(ParametersStructure.InstallPrinterAutomatically));
		XMLWriter.WriteAttribute("IsAutomatic"       , XMLString(ParametersStructure.IndicatesAutomaticMode));
		XMLWriter.WriteAttribute("AutomaticNumber"   , XMLString(ParametersStructure.MachineNumberForAutomaticMode));
		XMLWriter.WriteAttribute("OFDCompany"        , XMLString(ParametersStructure.OrganizationOfdname));
		XMLWriter.WriteAttribute("OFDCompanyINN"     , XMLString(ParametersStructure.OFDINNOrganization));
		If Not IsBlankString(ParametersStructure.EmailSender) Then
			XMLWriter.WriteAttribute("SenderEmail", XMLString(ParametersStructure.EmailSender));
		EndIf;
		If Not IsBlankString(ParametersStructure.FTSWebsiteAddress) Then
			XMLWriter.WriteAttribute("FNSURL", XMLString(ParametersStructure.FTSWebsiteAddress));
		EndIf;
	
	Else
		
		XMLWriter.WriteStartElement("Parameters");
		XMLWriter.WriteAttribute("CashierName" , XMLString(?(ParametersStructure.Property("Cashier")   , XMLString(ParametersStructure.Cashier), NStr("vi = 'Người quản trị';
																																						|ru = 'Администратор';
																																						|en = 'Administrator'; fa = 'مدیر سیستم';
																																						|it = 'Администратор';
																																						|pl = 'Administrator';
																																						|tr = 'Yönetici'"))));
		XMLWriter.WriteAttribute("CashierVATIN", XMLString(?(ParametersStructure.Property("CashierTIN"), XMLString(ParametersStructure.CashierTIN), "")));
		// FFD 1.0.0
		XMLWriter.WriteAttribute("KKTNumber"          , XMLString(ParametersStructure.CRERegistrationNumber));
		XMLWriter.WriteAttribute("OFDVATIN"           , XMLString(ParametersStructure.OFDINNOrganization));
		XMLWriter.WriteAttribute("OFDOrganizationName", XMLString(ParametersStructure.OrganizationOfdname));
		XMLWriter.WriteAttribute("OrganizationName"   , XMLString(ParametersStructure.CompanyName));
		XMLWriter.WriteAttribute("VATIN"              , XMLString(ParametersStructure.CompanyTIN));
		XMLWriter.WriteAttribute("AddressSettle"      , XMLString(ParametersStructure.AddressOfSettlementsConduction));
		XMLWriter.WriteAttribute("TaxVariant"         , XMLString(ParametersStructure.TaxationSystemCodes));
		XMLWriter.WriteAttribute("OfflineMode"        , XMLString(ParametersStructure.IndicatesOfflineMode));
		XMLWriter.WriteAttribute("DataEncryption"     , XMLString(ParametersStructure.IndicatesThatDataIsEncrypted));
		XMLWriter.WriteAttribute("ServiceSign"        , XMLString(ParametersStructure.IndicatesSettlementsForServices));
		XMLWriter.WriteAttribute("BSOSing"            , XMLString(ParametersStructure.IndicatesThatAccountableFormsAreGenerated));
		XMLWriter.WriteAttribute("CalcOnlineSign"     , XMLString(ParametersStructure.IndicatesThatSettlementsAreMadeOnlyViaInternet));
		XMLWriter.WriteAttribute("AutomaticMode"      , XMLString(ParametersStructure.IndicatesAutomaticMode));
		XMLWriter.WriteAttribute("AutomaticNumber"    , XMLString(ParametersStructure.MachineNumberForAutomaticMode));
		// FFD 1.05 & 1.1
		XMLWriter.WriteAttribute("PlaceSettle"        , XMLString(ParametersStructure.CalculationPlace));
		XMLWriter.WriteAttribute("SaleExcisableGoods" , XMLString(ParametersStructure.SellExcisableGoods));
		XMLWriter.WriteAttribute("SignOfGambling"     , XMLString(ParametersStructure.GamblingConducting));
		XMLWriter.WriteAttribute("SignOfLottery"      , XMLString(ParametersStructure.LotteryConducting));
		XMLWriter.WriteAttribute("SignOfAgent"        , XMLString(ParametersStructure.AgentCharacteristics));
		XMLWriter.WriteAttribute("PrinterAutomatic"   , XMLString(ParametersStructure.InstallPrinterAutomatically));
		// Changing the registration parameters.
		XMLWriter.WriteAttribute("ReasonCode"         , XMLString(ParametersStructure.CodeOfReasonForReregistration));
		If Not IsBlankString(ParametersStructure.CodesOfReasonsForChangingInformation) Then
			XMLWriter.WriteAttribute("InfoChangesReasonsCodes", XMLString(ParametersStructure.CodesOfReasonsForChangingInformation));
		EndIf;
		If Not IsBlankString(ParametersStructure.EmailSender) Then
			XMLWriter.WriteAttribute("SenderEmail", XMLString(ParametersStructure.EmailSender));
		EndIf;
		If Not IsBlankString(ParametersStructure.FTSWebsiteAddress) Then
			XMLWriter.WriteAttribute("FNSWebSite", XMLString(ParametersStructure.FTSWebsiteAddress));
		EndIf;
		
	EndIf;
	
	XMLWriter.WriteEndElement();
	Return XMLWriter.Close();
	
EndFunction

// Get the parameter table from the CCT.
// 
// Parameters:
//  Data - Structure - data.
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  Structure - Parameters from the CCT xmlpackage:
//  * ShowsWhetherFiscalizationIsUsed - String
//  * FiscalizationDocumentNumber - Number
//  * DateAndTimeOfFiscalization - Date
Function ParametersFromXMLPackageCCT(Data, InterfaceRevision = 0) Export
	
	XMLReader = New XMLReader; 
	XMLReader.SetString(Data);
	XMLReader.MoveToContent();
	
	Parameters = PeripheralsReceiptPrintersClientServer.CRERegistrationParameters();
	Parameters.Insert("EquipmentType", Enums.PeripheralTypes.CREWithDataTransfer);
	
	If InterfaceRevision >= 3000 Then  // Standard version 3.0 (OFD 1.1)
		
		If (XMLReader.Name = "Parameters" Or XMLReader.Name = "TableParametersKKT") And XMLReader.NodeType = XMLNodeType.StartElement Then  
			
			Parameters.FFDFNVersion = "1.1";
			FFDFNVersion = XMLReader.AttributeValue("FFDVersionFN");
			If FFDFNVersion = "1.0" Then
				Parameters.FFDFNVersion = "1.0"
			ElsIf FFDFNVersion = "1.0.5" Or FFDFNVersion = "1.05" Then
				Parameters.FFDFNVersion = "1.05"
			ElsIf FFDFNVersion = "1.2" Then
				Parameters.FFDFNVersion = "1.2"
			EndIf;
			
			Parameters.VersionFDFCRE = "1.1"; 
			VersionFDFCRE = XMLReader.AttributeValue("FFDVersionKKT");
			If VersionFDFCRE = "1.0" Then
				Parameters.VersionFDFCRE = "1.0"
			ElsIf VersionFDFCRE = "1.0.5" Or VersionFDFCRE = "1.05" Then
				Parameters.VersionFDFCRE = "1.05"
			ElsIf VersionFDFCRE = "1.2" Then
				Parameters.VersionFDFCRE = "1.2"
			EndIf;
			
			// FFD 1.0
			Parameters.CRERegistrationNumber    = TrimAll(XMLReader.AttributeValue("KKTNumber"));
			Parameters.CREIdentificationNumber          = TrimAll(XMLReader.AttributeValue("KKTSerialNumber"));
			Parameters.ManufaturerNumberOfFiscalStorage           = TrimAll(XMLReader.AttributeValue("FNSerialNumber"));
			Parameters.CompanyName        = XMLReader.AttributeValue("CompanyName");
			Parameters.CompanyTIN             = TrimAll(XMLReader.AttributeValue("INN"));
			Parameters.AddressOfSettlementsConduction    = XMLReader.AttributeValue("SaleAddress");
			Parameters.CalculationPlace    = XMLReader.AttributeValue("SaleLocation");
			Parameters.TaxationSystemCodes = XMLReader.AttributeValue("TaxationSystems");
			Parameters.IndicatesOfflineMode   = Upper(XMLReader.AttributeValue("IsOffline")) = "TRUE";
			Parameters.IndicatesThatDataIsEncrypted    = Upper(XMLReader.AttributeValue("IsEncrypted")) = "TRUE";
			Parameters.IndicatesSettlementsForServices    = Upper(XMLReader.AttributeValue("IsService")) = "TRUE";
			Parameters.SellExcisableGoods  = Upper(XMLReader.AttributeValue("IsExcisable")) = "TRUE";
			Parameters.GamblingConducting      = Upper(XMLReader.AttributeValue("IsGambling")) = "TRUE";
			Parameters.LotteryConducting          = Upper(XMLReader.AttributeValue("IsLottery")) = "TRUE";
			Parameters.AgentCharacteristics             = XMLReader.AttributeValue("AgentTypes");
			Parameters.IndicatesThatAccountableFormsAreGenerated         = Upper(XMLReader.AttributeValue("BSOSing")) = "TRUE";
			Parameters.IndicatesThatSettlementsAreMadeOnlyViaInternet = Upper(XMLReader.AttributeValue("IsOnlineOnly")) = "TRUE";
			Parameters.InstallPrinterAutomatically     = Upper(XMLReader.AttributeValue("IsAutomaticPrinter")) = "TRUE";
			Parameters.IndicatesAutomaticMode   = Upper(XMLReader.AttributeValue("IsAutomatic")) = "TRUE";
			Parameters.MachineNumberForAutomaticMode = XMLReader.AttributeValue("AutomaticNumber");
			Parameters.OrganizationOfdname     = XMLReader.AttributeValue("OFDCompany");
			Parameters.OFDINNOrganization          = TrimAll(XMLReader.AttributeValue("OFDCompanyINN"));
			Parameters.ShowsWhetherFiscalizationIsUsed        = Upper(XMLReader.AttributeValue("Fiscal")) = "TRUE";
			Parameters.FiscalizationDocumentNumber = XMLReader.AttributeValue("DocumentNumber");
			Parameters.DateAndTimeOfFiscalization      = XMLReader.AttributeValue("DateTime");
			Parameters.EmailSender           = XMLReader.AttributeValue("SenderEmail");
			Parameters.FTSWebsiteAddress              = XMLReader.AttributeValue("FNSURL");
			If InterfaceRevision >= 3004 Then  // Standard version 3.4 (OFD 1.2)
				Parameters.CarryingOutCalculationOnInternet  = Upper(XMLReader.AttributeValue("IsOnline")) = "TRUE";
				Parameters.SaleOfMarkedGoods = Upper(XMLReader.AttributeValue("IsMarking")) = "TRUE"; 
				Parameters.PawnshopUsageFlag = Upper(XMLReader.AttributeValue("IsPawnshop")) = "TRUE"; 
				Parameters.IndicationOfInsuranceActivity = Upper(XMLReader.AttributeValue("IsAssurance")) = "TRUE"; 
			EndIf;
			If InterfaceRevision >= 4000 Then  // Standard version 4.0 (OFD 1.2)
				Parameters.AutomaticVendingMachineSign = Upper(XMLReader.AttributeValue("IsVendingMachine")) = "TRUE";   
				Parameters.WhetherPublicCateringServicesAreProvided = Upper(XMLReader.AttributeValue("IsCateringServices")) = "TRUE";  
				IndicatesWholesaleTradeWithOrganizations = XMLReader.AttributeValue("IsWholesaleTrade"); 
				If Not IsBlankString(IndicatesWholesaleTradeWithOrganizations) Then
					Parameters.IndicatesWholesaleTradeWithOrganizations = Upper(IndicatesWholesaleTradeWithOrganizations) = "TRUE"; 
				EndIf;
			EndIf;    
		EndIf;
		
	Else
		
		If XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			Parameters.FFDFNVersion   = XMLReader.AttributeValue("FFDVersionFN");
			If IsBlankString(Parameters.FFDFNVersion) Then
				Parameters.FFDFNVersion = "1.0";
			EndIf;
			Parameters.VersionFDFCRE  = XMLReader.AttributeValue("FFDVersionKKT");
			If IsBlankString(Parameters.VersionFDFCRE) Then
				Parameters.VersionFDFCRE = "1.0";
			EndIf;
			// FFD 1.0
			Parameters.CRERegistrationNumber        = TrimAll(XMLReader.AttributeValue("KKTNumber"));
			Parameters.CompanyName            = XMLReader.AttributeValue("OrganizationName");
			Parameters.CompanyTIN                 = TrimAll(XMLReader.AttributeValue("VATIN"));
			Parameters.AddressOfSettlementsConduction        = XMLReader.AttributeValue("AddressSettle");
			Parameters.CalculationPlace        = XMLReader.AttributeValue("PlaceSettle");
			Parameters.TaxationSystemCodes     = XMLReader.AttributeValue("TaxVariant");
			If IsBlankString(Parameters.TaxationSystemCodes) Then
				Parameters.TaxationSystemCodes = XMLReader.AttributeValue("TaxVarinat");
			EndIf;
			Parameters.IndicatesOfflineMode       = Upper(XMLReader.AttributeValue("OfflineMode")) = "TRUE";
			Parameters.IndicatesAutomaticMode   = Upper(XMLReader.AttributeValue("AutomaticMode")) = "TRUE";
			Parameters.MachineNumberForAutomaticMode = XMLReader.AttributeValue("AutomaticNumber");
			Parameters.IndicatesThatAccountableFormsAreGenerated         = Upper(XMLReader.AttributeValue("BSOSing")) = "TRUE";
			Parameters.IndicatesThatSettlementsAreMadeOnlyViaInternet = Upper(XMLReader.AttributeValue("CalcOnlineSign")) = "TRUE";
			Parameters.IndicatesThatDataIsEncrypted        = Upper(XMLReader.AttributeValue("DataEncryption")) = "TRUE";
			Parameters.OFDINNOrganization          = TrimAll(XMLReader.AttributeValue("OFDVATIN"));
			Parameters.OrganizationOfdname     = XMLReader.AttributeValue("OFDOrganizationName");
			Parameters.CREIdentificationNumber          = TrimAll(XMLReader.AttributeValue("KKTSerialNumber"));
			Parameters.ShowsWhetherFiscalizationIsUsed        = Upper(XMLReader.AttributeValue("Fiscal")) = "TRUE";
			Parameters.ManufaturerNumberOfFiscalStorage           = TrimAll(XMLReader.AttributeValue("FNSerialNumber"));
			Parameters.FiscalizationDocumentNumber = XMLReader.AttributeValue("DocumentNumber");
			Parameters.DateAndTimeOfFiscalization      = XMLReader.AttributeValue("DateTime");
			Parameters.IndicatesSettlementsForServices    = Upper(XMLReader.AttributeValue("ServiceSign")) = "TRUE";
			Parameters.SellExcisableGoods  = Upper(XMLReader.AttributeValue("SaleExcisableGoods")) = "TRUE";
			Parameters.GamblingConducting      = Upper(XMLReader.AttributeValue("SignOfGambling")) = "TRUE";
			Parameters.LotteryConducting          = Upper(XMLReader.AttributeValue("SignOfLottery")) = "TRUE";
			Parameters.AgentCharacteristics             = XMLReader.AttributeValue("SignOfAgent");
			Parameters.InstallPrinterAutomatically = Upper(XMLReader.AttributeValue("PrinterAutomatic")) = "TRUE";
			Parameters.EmailSender           = XMLReader.AttributeValue("SenderEmail");
			Parameters.FTSWebsiteAddress              = XMLReader.AttributeValue("FNSWebSite");
		EndIf;
		
	EndIf;
	
	TaxationSystems = New Array();
	If Not IsBlankString(Parameters.TaxationSystemCodes) Then
		TimeTaxSystems = StrSplit(Parameters.TaxationSystemCodes, ",");
		For Each VremyaSNO In TimeTaxSystems Do
			SNO = PeripheralsReceiptPrintersClientServer.KktTaxSystemByCode(Number(VremyaSNO));
			TaxationSystems.Add(SNO);
		EndDo;
		Parameters.Insert("TaxationSystems", TaxationSystems);
	EndIf;

	Return Parameters;
	
EndFunction

// The procedure generates an XML package for fiscal receipt.
// 
// Parameters:
//  CommonParameters - Structure - receipt parameters
//  FiscalizationParameters - Structure - parameters of the receipt fiscalization.
//  IncludePersonalData - Boolean - Include personal data.
//  PersonalDetails - See PeripheralsReceiptPrintersClientServer.ParametersPersonalDataOfBuyer.
//  PersonalDataType - EnumRef.TypesOfPersonalDataOfTheCCT - Type of personal data.
Procedure GenerateXMLPackageForFiscalizingReceipt(CommonParameters, FiscalizationParameters, IncludePersonalData = False, 
	PersonalDetails = Undefined, PersonalDataType = Undefined) Export
	
	
EndProcedure

// Get the xmlpackage for the operation.
// 
// Parameters:
//  CommonParameters - Structure, Boolean - General settings
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  String - Get the Xmlpackage for the operation
Function GetXMLPacketForOperation(CommonParameters, InterfaceRevision = 0) Export
	
	Return PeripheralsReceiptPrintersClientServer.GetXMLPacketForOperation(CommonParameters, InterfaceRevision);
	
EndFunction   

// Get an xmlpackage for text.
// 
// Parameters:
//  TextString - String, Structure - Line of text
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  Array of XMLWriter - Get an xmlpackage for text.
Function GetXMLPackageForText(TextString, InterfaceRevision = 0) Export
	
	Return PeripheralsReceiptPrintersClientServer.
		GetXMLPackageForText(TextString, InterfaceRevision);
	
EndFunction  

// Get state parameters from an XML package.
// 
// Parameters:
//  Data - Arbitrary
//  ShiftNumber - Undefined - shift number
// 
// Returns:
//  Structure - Get State parameters from an xmlpackage:
//  * CREShiftDate - Number -
//  * CREShiftNumber - Number -
//  * KKTReceiptNumber - Number -
//  * ShiftReceiptNumber - Number -
//  * ShiftStatus - Undefined -
//  * CountersForArrivalOperations - Structure -:
//    ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//    ** AmountOfChecks - Number
//    ** NumberOfCorrectionChecks - Number
//    ** AmountOfCorrectionChecks - Number
//  * CountersForRefundOperations - Structure -:
//    ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//    ** AmountOfChecks - Number
//    ** NumberOfCorrectionChecks - Number
//    ** AmountOfCorrectionChecks - Number
//  * OperationCountersExpense - Structure -:
//    ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//    ** AmountOfChecks - Number
//    ** NumberOfCorrectionChecks - Number
//    ** AmountOfCorrectionChecks - Number
//  * OperationCountersRefundOfExpenses - Structure -:
//    ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//    ** AmountOfChecks - Number
//    ** NumberOfCorrectionChecks - Number
//    ** AmountOfCorrectionChecks - Number
//  * NumberOfSalesSlipsAccountableFormsPerShift - Number
//  * CashBalance - Number
//  * FDOResponseTimeoutExceeded - Boolean -
//  * UnpostedFDCount - Undefined -
//  * NumberOfFirstUntransmittedFD - Undefined -
//  * DateAndTimeOfFirstOfUnsentFD - Undefined -
//  * UrgentReplacementOfFNIsNeeded - Boolean -
//  * ShowsThatFiscalStorageMemoryIsFull - Boolean -
//  * FiscalStorageResourceExceeded - Boolean -
Function GetStateParametersFromXMLPackage(Data, ShiftNumber = Undefined) Export
	
	Return PeripheralsReceiptPrintersClientServer.
		GetStateParametersFromXMLPackage(Data, ShiftNumber);

EndFunction

// Get a table of shift parameters from the KKT.
//
// Parameters:
//  XMLData1 - String - xml string
//  InterfaceRevision - Number - Interface revision
//  CREShiftNumber - Number - shift number
//  KKTReceiptNumber - Number - receipt number
//
// Returns:
//  Structure
//
Function GetShiftParametersFromXMLPackage(XMLData1, InterfaceRevision = 0, CREShiftNumber = 0, KKTReceiptNumber = 0) Export
	
	Return PeripheralsReceiptPrintersClientServer.
		GetShiftParametersFromXMLPackage(XMLData1, InterfaceRevision, CREShiftNumber, KKTReceiptNumber);
	
EndFunction

// Fill in the fiscal receipt results from the XML package.
//
// Parameters:
//  FiscalizationParameters - Structure 
Procedure FillInResultsOfReceiptFiscalizationFromXMLPackage(FiscalizationParameters) Export
	
	If Not IsBlankString(FiscalizationParameters.ResultOfXMLOperation) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(FiscalizationParameters.ResultOfXMLOperation);
		XMLReader.MoveToContent();
		If XMLReader.Name = "DocumentOutputParameters" And XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.Read() And XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
				FiscalizationParameters.CREShiftNumber = XMLReader.AttributeValue("ShiftNumber");
				FiscalizationParameters.KKTReceiptNumber  = XMLReader.AttributeValue("CheckNumber");
				FiscalizationParameters.ShiftReceiptNumber   = XMLReader.AttributeValue("ShiftClosingCheckNumber");
				FiscalizationParameters.FiscalFlag  = XMLReader.AttributeValue("FiscalSign");
				FiscalizationParameters.VerificationWebsiteAddress = XMLReader.AttributeValue("AddressSiteInspections");
				FiscalizationParameters.PrintError = Upper(XMLReader.AttributeValue("PrintError")) = "TRUE" ;
				ReceiptDateAndTime = XMLReader.AttributeValue("DateTime");
				If Not IsBlankString(ReceiptDateAndTime) Then
					FiscalizationParameters.ReceiptDateAndTime = XMLValue(Type("Date"), ReceiptDateAndTime);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure fills in an XML package for printing a text document
// 
// Parameters:
//  TestReceipts - Array of String - 
//  NonFiscalDocuments - Array of See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  ConnectionParameters - See EquipmentManagerClientServer.ConnectionParameters
//  LineWidth_ - Number - width of the printer line
//
Procedure FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_ = 32) Export
	
	PeripheralsReceiptPrintersClientServer.
		FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_);
	
EndProcedure  

// Get the receipt structure from XML.
// 
// Parameters:
//  XMLData1 - String - XML data    
//  Marking_Data - Boolean - The marking data will be uploaded
// 
// Returns:
//  Structure - Load fiscalization data from XML:
//  * CorrectionData - Structure -:
//    ** PrescriptionNumber - Number -
//    ** CorrectionDate_ - Date -
//    ** AdjustmentDescription - String -
//    ** AdjustmentType - Number -
//  * CRENonApplication - Boolean -
//  * DocumentToBeCorrected - Arbitrary -
//  * ThereIsPersonalData - Boolean -
//  * IndividualModeOfDataPreparationForVOFDTransmission - Boolean -
//  * AllowableDiscrepancyOfFormatLogicalControl - Number -
//  * MethodOfFormatLogicalControl - Undefined -
//  * ProcessCorrectionCheck - Boolean -
//  * AdditionalUserDetails - Structure -:
//    ** Value - Arbitrary -
//    ** Description - String -
//  * AdditionalAttribute - Undefined -
//  * NonFiscalDocuments - Array of DefinedType.BaseDocumentForFiscalPLTransaction -
//  * CashRegister - Arbitrary -
//  * ReceiptTemplate - Arbitrary -
//  * TableOfPayment - Array of Structure-
//  * ReceiptPositions - Array of Structure -
//  * CopiesOfReceipt - Number -
//  * FooterText - String -
//  * HeaderText - String -
//  * DateTime - Date -
//  * ShiftNumber - Number -
//  * ReceiptNumber - String -
//  * CheckoutNumber - String -
//  * StoreName_ - String -
//  * StoreAddress - String -
//  * CompanyCRTR - String -
//  * CompanyTIN - String -
//  * CompanyName - String -
//  * SerialNumber - String -
//  * BeneficiaryTIN - String -
//  * Recipient - String -
//  * VendorData - Structure -:
//    ** TIN - String -
//    ** Description - String -
//    ** Phone - String -
//  * AgentData - Structure -:
//    ** PaymentAcceptanceOperator - Structure -:
//       *** Phone - Undefined -
//    ** TransferOperator - Structure -:
//       *** Phone - String -
//       *** Description - String -
//       *** Address - String -
//       *** TIN - String -
//    ** PayingAgent - Structure -:
//       *** Operation - String -
//       *** Phone - String -
//  * AgentAttribute - Undefined -
//  * BuyerNumber - String -
//  * BuyerEmail - String -
//  * EmailSender - String -
//  * PlaceOfSettlement - String -
//  * SettlementAddress - String -
//  * TaxationSystem - EnumRef.CRETaxationSystemTypes -
//  * Sends1CEmail - Boolean -
//  * Sends1CSMS - Boolean -
//  * CalculationType - EnumRef.CashSettlementTypes -
//  * Electronically - Boolean -
//  * RetailFacility - Undefined -
//  * Organization - Undefined -
//  * IDOfFiscalRecord - Undefined -
//  * DocumentBasis - Undefined -
//  * CashierTIN - Undefined -
//  * Cashier - String -            
//
Function LoadFiscalizationDataFromXML(XMLData1, Marking_Data = True) Export
	
	CommonParameters = PeripheralsReceiptPrintersClientServer.ParametersOfCorrectionReceiptOperation();
	
	FiscalLine = Undefined;
	ReceiptAmount = 0;
	
	If Not IsBlankString(XMLData1) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLData1);
		XMLReader.MoveToContent();
		If XMLReader.Name = "CheckPackage" And XMLReader.NodeType = XMLNodeType.StartElement Then
			
			While XMLReader.Read() Do
				If XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					CalculationType = ?(XMLReader.AttributeValue("PaymentType") <> Undefined, XMLReader.AttributeValue("PaymentType"), XMLReader.AttributeValue("OperationType"));
					CommonParameters.CalculationType = PeripheralsReceiptPrintersClientServer.CashPaymentByCode(Number(CalculationType));
					
					TaxationSystem = ?(XMLReader.AttributeValue("TaxVariant") <> Undefined, XMLReader.AttributeValue("TaxVariant"), XMLReader.AttributeValue("TaxationSystem"));
					CommonParameters.TaxationSystem = PeripheralsReceiptPrintersClientServer.KktTaxSystemByCode(Number(TaxationSystem));
					
					CommonParameters.Cashier = XMLReader.AttributeValue("CashierName");
					CommonParameters.CashierTIN = XMLAttributeValue(XMLReader, "CashierVATIN", "CashierINN", Undefined);
					
					CommonParameters.EmailSender = XMLReader.AttributeValue("SenderEmail");
					CommonParameters.BuyerEmail = XMLReader.AttributeValue("CustomerEmail");
					CommonParameters.BuyerNumber = XMLReader.AttributeValue("CustomerPhone");
					CommonParameters.AgentAttribute = XMLReader.AttributeValue("AgentSign");
					CommonParameters.SettlementAddress = XMLAttributeValue(XMLReader, "SaleAddress", "AddressSettle");
					CommonParameters.PlaceOfSettlement = XMLAttributeValue(XMLReader, "SaleLocation", "PlaceSettle");
					If XMLReader.AttributeValue("OperationOnline") <> Undefined Then  
						InternetIndicator = XMLReader.AttributeValue("OperationOnline");        
						CommonParameters.Internet = Upper(InternetIndicator) = "TRUE";
					EndIf;
					CommonParameters.TimeArea   = XMLAttributeValue(XMLReader, "TimeZone");
					
					CommonParameters.AdditionalAttribute = XMLReader.AttributeValue("AdditionalAttribute");
					CommonParameters.Recipient    = XMLReader.AttributeValue("CustomerInfo");
					CommonParameters.BeneficiaryTIN = XMLReader.AttributeValue("CustomerINN");
				EndIf;
				
				If XMLReader.Name = "PurveyorData" And XMLReader.NodeType = XMLNodeType.StartElement Then   
					CommonParameters.VendorData.Description = XMLAttributeValue(XMLReader, "PurveyorName");
					CommonParameters.VendorData.Phone = XMLAttributeValue(XMLReader, "PurveyorPhone");
					CommonParameters.VendorData.TIN = XMLAttributeValue(XMLReader, "PurveyorVATIN");
				EndIf;
				
				If XMLReader.Name = "VendorData" And XMLReader.NodeType = XMLNodeType.StartElement Then   
					CommonParameters.VendorData.Description = XMLAttributeValue(XMLReader, "VendorName");
					CommonParameters.VendorData.Phone = XMLAttributeValue(XMLReader, "VendorPhone");
					CommonParameters.VendorData.TIN = XMLAttributeValue(XMLReader, "VendorINN");
				EndIf;
				
				If XMLReader.Name = "CustomerDetail" And XMLReader.NodeType = XMLNodeType.StartElement Then   
					CommonParameters.BuyerInformation.Customer = XMLAttributeValue(XMLReader, "Info");
					CommonParameters.BuyerInformation.BuyerTin = XMLAttributeValue(XMLReader, "INN");
					CommonParameters.BuyerInformation.BuyerAddress = XMLAttributeValue(XMLReader, "Address");
				EndIf;
				
				If XMLReader.Name = "AgentData" And XMLReader.NodeType = XMLNodeType.StartElement Then   
					AgentData = CommonParameters.AgentData;
					AgentData.PayingAgent.Operation = XMLAttributeValue(XMLReader, "AgentOperation", "PayingAgentOperation");
					AgentData.PayingAgent.Phone  = XMLAttributeValue(XMLReader, "AgentPhone", "PayingAgentPhone");
					AgentData.TransferOperator.Phone      = XMLAttributeValue(XMLReader, "AcquirerOperatorPhone", "MoneyTransferOperatorPhone");
					AgentData.TransferOperator.Description = XMLAttributeValue(XMLReader, "AcquirerOperatorName", "MoneyTransferOperatorName");
					AgentData.TransferOperator.Address        = XMLAttributeValue(XMLReader, "AcquirerOperatorAddress", "MoneyTransferOperatorAddress");
					AgentData.TransferOperator.TIN          = XMLAttributeValue(XMLReader, "AcquirerOperatorINN", "MoneyTransferOperatorVATIN");
					AgentData.PaymentAcceptanceOperator.Phone = XMLAttributeValue(XMLReader, "PaymentProcessorPhone", "ReceivePaymentsOperatorPhone");
				EndIf;
				
				If XMLReader.Name = "UserAttribute" And XMLReader.NodeType = XMLNodeType.StartElement Then   
					CommonParameters.AdditionalUserDetails.Description = XMLAttributeValue(XMLReader, "Name");
					CommonParameters.AdditionalUserDetails.Value = XMLAttributeValue(XMLReader, "Value");
				EndIf;
		
				If XMLReader.Name = "Positions" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					While XMLReader.Read() And Not (XMLReader.Name = "Positions" And XMLReader.NodeType = XMLNodeType.EndElement) Do
						
						If XMLReader.Name = "FiscalString" And XMLReader.NodeType = XMLNodeType.StartElement Then  
							FiscalLine = PeripheralsReceiptPrintersClientServer.ParametersOfReceiptSFiscalLine();
							
							FiscalLine.Description =  XMLAttributeValue(XMLReader, "Name");
							FiscalLine.Count   =  Number(XMLAttributeValue(XMLReader, "Quantity", , 0));
							
							FiscalLine.DiscountedPrice =  Number(XMLAttributeValue(XMLReader, "PriceWithDiscount", , 0));
							FiscalLine.Sum          =  Number(XMLAttributeValue(XMLReader, "AmountWithDiscount", "SumWithDiscount", 0));
							ReceiptAmount = ReceiptAmount + FiscalLine.Sum;
							Profit = XMLAttributeValue(XMLReader, "DiscountAmount", "DiscountSum", 0);
							If Not IsBlankString(Profit) Then
								FiscalLine.Profit  =  Number(Profit);
							EndIf;
							FiscalLine.SectionNumber_ = Number(XMLAttributeValue(XMLReader, "Department", , 0));
							FiscalLine.UnitOfMeasure = XMLAttributeValue(XMLReader, "MeasurementUnit");
							VATAmount = XMLAttributeValue(XMLReader, "VATAmount", "TaxSum", 0);
							If Not IsBlankString(VATAmount) Then
								FiscalLine.VATAmount = Number(VATAmount);
							EndIf;
							
							ShowsCalculationMethod = Number(XMLAttributeValue(XMLReader, "SignMethodCalculation", "PaymentMethod", 0));
							FiscalLine.ShowsCalculationMethod = PeripheralsReceiptPrintersClientServer.FlagForCodeCalculationMethod(ShowsCalculationMethod);
							
							SettlementSubjectFlag = Number(XMLAttributeValue(XMLReader, "SignCalculationObject", "CalculationSubject", 0));
							FiscalLine.SettlementSubjectFlag =  PeripheralsReceiptPrintersClientServer.AttributeOfSubjectOfCalculationByCode(SettlementSubjectFlag);
							
							
							FiscalLine.CountryCodeOfOrigin = XMLAttributeValue(XMLReader, "CountryOfOrigin");
							FiscalLine.CustomsDeclarationNumber = XMLAttributeValue(XMLReader, "CustomsDeclaration");
							FiscalLine.AdditionalAttribute = XMLAttributeValue(XMLReader, "AdditionalAttribute");
							
							ExciseTaxAmount = XMLAttributeValue(XMLReader, "ExciseAmount");
							If Not IsBlankString(ExciseTaxAmount) Then
								If Number(ExciseTaxAmount) > 0 Then 
									FiscalLine.ExciseTaxAmount = Number(ExciseTaxAmount);
								EndIf;
							EndIf;
							
							If Marking_Data And XMLReader.AttributeValue("MarkingCode") <> Undefined Then
								FiscalLine.ControlMark = XMLReader.AttributeValue("MarkingCode"); 
							EndIf;
							
							CommonParameters.ReceiptPositions.Add(FiscalLine);
						EndIf;
						
						If XMLReader.Name = "AgentData" And XMLReader.NodeType = XMLNodeType.StartElement Then   
							If FiscalLine <> Undefined Then
								AgentData = FiscalLine.AgentData;
								AgentData.PayingAgent.Operation = XMLAttributeValue(XMLReader, "AgentOperation", "PayingAgentOperation");
								AgentData.PayingAgent.Phone  = XMLAttributeValue(XMLReader, "AgentPhone", "PayingAgentPhone");
								AgentData.TransferOperator.Phone      = XMLAttributeValue(XMLReader, "AcquirerOperatorPhone", "MoneyTransferOperatorPhone");
								AgentData.TransferOperator.Description = XMLAttributeValue(XMLReader, "AcquirerOperatorName", "MoneyTransferOperatorName");
								AgentData.TransferOperator.Address        = XMLAttributeValue(XMLReader, "AcquirerOperatorAddress", "MoneyTransferOperatorAddress");
								AgentData.TransferOperator.TIN          = XMLAttributeValue(XMLReader, "AcquirerOperatorINN", "MoneyTransferOperatorVATIN");
								AgentData.PaymentAcceptanceOperator.Phone = XMLAttributeValue(XMLReader, "PaymentProcessorPhone", "ReceivePaymentsOperatorPhone");
							EndIf;
						EndIf;
						
						If XMLReader.Name = "PurveyorData" And XMLReader.NodeType = XMLNodeType.StartElement Then   
							If FiscalLine <> Undefined Then
								FiscalLine.VendorData.Description = XMLAttributeValue(XMLReader, "PurveyorName");
								FiscalLine.VendorData.Phone = XMLAttributeValue(XMLReader, "PurveyorPhone");
								FiscalLine.VendorData.TIN = XMLAttributeValue(XMLReader, "PurveyorVATIN");
							EndIf;
						EndIf;
						
						If XMLReader.Name = "VendorData" And XMLReader.NodeType = XMLNodeType.StartElement Then   
							If FiscalLine <> Undefined Then
								FiscalLine.VendorData.Description = XMLAttributeValue(XMLReader, "VendorName");
								FiscalLine.VendorData.Phone = XMLAttributeValue(XMLReader, "VendorPhone");
								FiscalLine.VendorData.TIN = XMLAttributeValue(XMLReader, "VendorINN");
							EndIf;
						EndIf;
							
						If XMLReader.Name = "IndustryAttribute" And XMLReader.NodeType = XMLNodeType.StartElement Then   
							If FiscalLine <> Undefined Then   
								IDOfFOIV = XMLAttributeValue(XMLReader, "IdentifierFOIV");
								FiscalLine.IndustryProps.IDOfFOIV = IDOfFOIV;
								BaseDocumentDate = XMLAttributeValue(XMLReader, "DocumentDate");                             
								If Not IsBlankString(BaseDocumentDate) Then
									FiscalLine.IndustryProps.BaseDocumentDate = CommonCEL.StringToDate(XMLValue(Type("String"), BaseDocumentDate));
								EndIf;
								FiscalLine.IndustryProps.ReferenceDocumentNumber = XMLAttributeValue(XMLReader, "DocumentNumber");
								FiscalLine.IndustryProps.AttributeValue = XMLAttributeValue(XMLReader, "AttributeValue");
							EndIf;
						EndIf;                  
						
						If CommonCEL.MarkingIsUsed() And Marking_Data Then
							If XMLReader.Name = "GoodCodeData" And XMLReader.NodeType = XMLNodeType.StartElement Then   
								If FiscalLine <> Undefined Then
									FiscalLine.ProductProductCodeData.GlobalTradeUnitIdentifier = XMLAttributeValue(XMLReader, "GTIN");
									FiscalLine.ProductProductCodeData.ControlIdentificationMark = XMLAttributeValue(XMLReader, "Stamp");
									FiscalLine.ProductProductCodeData.SerialNumber = XMLAttributeValue(XMLReader, "SerialNumber");
									TypeOfMarking = XMLAttributeValue(XMLReader, "StampType");
									ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
									FiscalLine.ProductProductCodeData.TypeOfMarking = ModuleEquipmentManagerMarking.KktMarkingTypeByCode(TypeOfMarking);
									FiscalLine.ProductProductCodeData.ProductCodeDetails = XMLAttributeValue(XMLReader, "MarkingCode");
								EndIf
							EndIf;
						EndIf;
						
						If XMLReader.Name = "TextString" And XMLReader.NodeType = XMLNodeType.StartElement Then  
							Text = XMLAttributeValue(XMLReader, "Text");
							TextString = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters(Text);
							CommonParameters.ReceiptPositions.Add(TextString);
						EndIf;
						
						If XMLReader.Name = "Barcode" And XMLReader.NodeType = XMLNodeType.StartElement Then  
							BarcodeTypeVal = XMLAttributeValue(XMLReader, "Type");
							BarCodeVal = XMLAttributeValue(XMLReader, "Value");
							BarcodeBASE64 = XMLAttributeValue(XMLReader, "ValueBase64");
							BarcodeString = PeripheralsReceiptPrintersClientServer.ParametersBarcodeInReceiptLine(BarcodeTypeVal, BarCodeVal, BarcodeBASE64); 
							CommonParameters.ReceiptPositions.Add(BarcodeString);
						EndIf;
						
					EndDo;  
					
				EndIf;
				
				If XMLReader.Name = "Payments" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					
					AmountCash   = Number(XMLAttributeValue(XMLReader, "Cash", , 0));
					AmountElectronically = Number(XMLAttributeValue(XMLReader, "ElectronicPayment", , 0));
					PostpaidAmount = Number(XMLAttributeValue(XMLReader, "Credit", "PostPayment", 0));
					PrepaymentAmount_ = Number(XMLAttributeValue(XMLReader, "AdvancePayment", "PrePayment", 0));
					AmountOfPayment = Number(XMLAttributeValue(XMLReader, "CashProvision", "Barter", 0));
					
					PaymentNotInCash = AmountElectronically + PostpaidAmount + PrepaymentAmount_ + AmountOfPayment;
					AmountCash = ?(AmountCash + PaymentNotInCash > ReceiptAmount, ReceiptAmount - PaymentNotInCash, AmountCash); 
					
					If AmountCash > 0 Then
						PaymentLine_ = New Structure();
						PaymentLine_.Insert("TypeOfPayment", PredefinedValue("Enum.CREPaymentTypes.CashPayment"));
						PaymentLine_.Insert("Sum", AmountCash);
						CommonParameters.TableOfPayment.Add(PaymentLine_);
					EndIf;
					
					If AmountElectronically > 0 Then
						PaymentLine_ = New Structure();
						PaymentLine_.Insert("TypeOfPayment", PredefinedValue("Enum.CREPaymentTypes.Electronically"));
						PaymentLine_.Insert("Sum", AmountElectronically);
						CommonParameters.TableOfPayment.Add(PaymentLine_);
					EndIf;
					
					If PostpaidAmount > 0 Then
						PaymentLine_ = New Structure();
						PaymentLine_.Insert("TypeOfPayment", PredefinedValue("Enum.CREPaymentTypes.Postpayment"));
						PaymentLine_.Insert("Sum", PostpaidAmount);
						CommonParameters.TableOfPayment.Add(PaymentLine_);
					EndIf;
					
					If PrepaymentAmount_ > 0 Then
						PaymentLine_ = New Structure();
						PaymentLine_.Insert("TypeOfPayment", PredefinedValue("Enum.CREPaymentTypes.Prepayment"));
						PaymentLine_.Insert("Sum", PrepaymentAmount_);
						CommonParameters.TableOfPayment.Add(PaymentLine_);
					EndIf;
					
					If AmountOfPayment > 0 Then
						PaymentLine_ = New Structure();
						PaymentLine_.Insert("TypeOfPayment", PredefinedValue("Enum.CREPaymentTypes.Consideration"));
						PaymentLine_.Insert("Sum", AmountOfPayment);
						CommonParameters.TableOfPayment.Add(PaymentLine_);
					EndIf;
					
				EndIf;
				
				If XMLReader.Name = "ElectronicPaymentInfo" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					While XMLReader.Read() And Not (XMLReader.Name = "ElectronicPaymentInfo" And XMLReader.NodeType = XMLNodeType.EndElement) Do
						If XMLReader.Name = "ElectronicPayment" And XMLReader.NodeType = XMLNodeType.StartElement Then      
							InformationAboutNonCashPayment = PeripheralsReceiptPrintersClientServer.ParametersInformationAboutNonCashPayment();   
							InformationAboutNonCashPayment.PaymentMethodAttribute = Number(XMLAttributeValue(XMLReader, "PaymentMethod", , 0));     
							InformationAboutNonCashPayment.IDs = XMLAttributeValue(XMLReader, "Identifiers");     
							InformationAboutNonCashPayment.AdditionalInfrmation = XMLAttributeValue(XMLReader, "AdditionalInformation");   
							CommonParameters.InformationAboutNonCashPayment.Add(InformationAboutNonCashPayment);
						EndIf; 
					EndDo
				EndIf;
				
			EndDo; 
			
		EndIf;
		
	EndIf;
		
	Return CommonParameters;
	
EndFunction

#EndRegion

// This function generates a receipt template.
//
// Parameters:
//  CommonParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  EquipmentType - String - types of equipment by line.
//  AdditionalText - String - additional text of the receipt template.
//  DeviceID - CatalogRef.Peripherals
//
// Returns:
//  Structure
Function ReceiptTemplate(CommonParameters, EquipmentType, AdditionalText = Undefined, DeviceID = Undefined) Export
	
	StandardProcessing = True;
	
	ReceiptTemplate = Undefined;
	EquipmentManagerServerCallOverridable.GenerateReceiptTemplate(ReceiptTemplate, CommonParameters, AdditionalText, StandardProcessing, EquipmentType); 
	If StandardProcessing Or ReceiptTemplate = Undefined Then
		Return CommonParameters;
	Else
		Return ReceiptTemplate;
	EndIf;
	
EndFunction

// The function generates a tabular document based on the fiscal receipt data.
//
// Parameters:
//  DocumentType - Number
//   CommonParameters - Structure - fiscal document parameters loaded from XML data
//                    See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   ReceiptDetails_ - Structure - parameters of a fiscal document from the information register fiscal documents
//                    See FiscalOperationData()
//   FFDFormat - String - the format of fiscal data affects the output of the payment table at "1.0" 
//                        only the types of payments "CASH", "ELECTRONIC" are used
//
// Returns:
//  SpreadsheetDocument - a tabular document with a generated fiscal document can be saved in any format.
//
Function GenerateFiscalDocument(DocumentType, CommonParameters, ReceiptDetails_ = Undefined, FFDFormat = "1.1", ReceiptWidth = 42) Export
	
	If DocumentType = 1 Then
		Template = FiscalDocumentTemplates.TemplateReportOnOpeningShift(ReceiptWidth, CommonParameters);
	ElsIf DocumentType = 2 Then
		Template = FiscalDocumentTemplates.CashDepositTemplate(ReceiptWidth, CommonParameters);
	ElsIf DocumentType = 3 Then
		Template = FiscalDocumentTemplates.CashDepositTemplate(ReceiptWidth, CommonParameters);  
	ElsIf DocumentType = 4 Then
		Template = FiscalDocumentTemplates.TemplateReportOnCurrentState(ReceiptWidth, CommonParameters);
	ElsIf DocumentType = 5 Then
		Template = FiscalDocumentTemplates.TemplateReportOnClosingShift(ReceiptWidth, CommonParameters);
	Else
		Template = FiscalDocumentTemplates.SalesSlipTemplate(ReceiptWidth, CommonParameters, ReceiptDetails_);    
	EndIf;
	
	FiscalDocumentTemplates.GenerateDocumentUsingTemplate(Template);
	SpreadsheetDocument = FiscalDocumentTemplates.OutputAsTabularDocument(Template); 
	
	Return SpreadsheetDocument;
	
EndFunction       

// The function generates a tabular document based on the fiscal receipt data.
//
// Parameters:
//  DocumentType - Number
//   CommonParameters - Structure - fiscal document parameters loaded from XML data
//                    See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   ReceiptDetails_ - Structure - parameters of a fiscal document from the information register fiscal documents
//                    See FiscalOperationData()
//   FFDFormat - String - the format of fiscal data affects the output of the payment table at "1.0" 
//                        only the types of payments "CASH", "ELECTRONIC" are used
//   ReceiptWidth - Number 
//
// Returns:
//  String
//
Function GenerateFiscalDocumentText(DocumentType, CommonParameters, ReceiptDetails_ = Undefined, FFDFormat = "1.1", ReceiptWidth = 42) Export
	
	If DocumentType = 1 Then
		Template = FiscalDocumentTemplates.TemplateReportOnOpeningShift(ReceiptWidth, CommonParameters);
	ElsIf DocumentType = 2 Then
		Template = FiscalDocumentTemplates.CashDepositTemplate(ReceiptWidth, CommonParameters);
	ElsIf DocumentType = 3 Then
		Template = FiscalDocumentTemplates.CashDepositTemplate(ReceiptWidth, CommonParameters);  
	ElsIf DocumentType = 4 Then
		Template = FiscalDocumentTemplates.TemplateReportOnCurrentState(ReceiptWidth, CommonParameters);
	ElsIf DocumentType = 5 Then
		Template = FiscalDocumentTemplates.TemplateReportOnClosingShift(ReceiptWidth, CommonParameters);
	Else
		Template = FiscalDocumentTemplates.SalesSlipTemplate(ReceiptWidth, CommonParameters, ReceiptDetails_);    
	EndIf;
	
	FiscalDocumentTemplates.GenerateDocumentUsingTemplate(Template);
	Text = FiscalDocumentTemplates.OutputAsText(Template); 
	
	Return Text;
	
EndFunction

// Returns the flag whether the POS shift is open
// 
// Parameters:
//  CashRegisterShiftStatus - EnumRef.CashRegisterShiftStatuses
//
// Returns:
//  Boolean
Function CashShiftIsOpen(CashRegisterShiftStatus) Export
	
	ShiftIsOpened = Undefined;
	If CashRegisterShiftStatus = Enums.CashRegisterShiftStatuses.IsOpen Then
		ShiftIsOpened = True;
	Else
		ShiftIsOpened = False;
	EndIf;
	
	Return ShiftIsOpened;
	
EndFunction

// Returns the Status that the POS shift is open
// 
// Returns:
//  EnumRef.CashRegisterShiftStatuses
Function StatusOfOpenShift() Export
	
	Return Enums.CashRegisterShiftStatuses.IsOpen;
	
EndFunction

// Returns the Status that the POS shift is closed
// 
// Returns:
//  EnumRef.CashRegisterShiftStatuses
Function ClosedShiftStatus() Export
	
	Return Enums.CashRegisterShiftStatuses.Closed_;
	
EndFunction

// Returns possible check Status options in the queue
// 
// Returns:
//  Map of KeyAndValue
Function ReceiptStatusesInQueue() Export
	
	Result = New Map();
	
	Result.Insert("Fiscalized" , PredefinedValue("Enum.CREReceiptStatusInQueue.Fiscalized"));
	Result.Insert("Error"         , PredefinedValue("Enum.CREReceiptStatusInQueue.Error"));
	Result.Insert("New"          , PredefinedValue("Enum.CREReceiptStatusInQueue.New"));
	Result.Insert("Fiscalizing", PredefinedValue("Enum.CREReceiptStatusInQueue.Fiscalizing"));
	Result.Insert("RolledBack_"        , PredefinedValue("Enum.CREReceiptStatusInQueue.RolledBack_"));
	
	Return Result;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Outdated: You should use Management equipmentmark.The Product code identifies the instance.
// Whether the product code (tag value 1162) identifies an instance of the product.
//
// Parameters:
//   ProductCodeDetails - String - The value of the product code details in BASE64.
//   ProductBarCode_ - String - Bar code of the item.
//
// Returns:
//  Boolean - True - If the product code identifies an instance of the product.
//
Function ProductCodeIdentifiesInstance(Val ProductCodeDetails = Undefined, Val ProductBarCode_ = Undefined) Export
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		Return ModuleEquipmentManagerMarking.ProductCodeIdentifiesInstance(ProductCodeDetails, ProductBarCode_);
	Else
		Return False;
	EndIf;
	
EndFunction

// Outdated: you should use a template check.
// The function generates a receipt template.
//
// Parameters:
//  CommonParameters - Structure - SeePeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation().
//  EquipmentType - String - types of equipment by line.
//  AdditionalText - String - additional text of the receipt template.
//  DeviceID - CatalogRef.Peripherals
//
// Returns:
//  - Structure
Function GenerateReceiptTemplate(CommonParameters, EquipmentType, AdditionalText = Undefined, DeviceID = Undefined) Export
	
	Return ReceiptTemplate(CommonParameters, EquipmentType, AdditionalText, DeviceID);
	
EndFunction

#EndRegion

// Returns the name of the organization based on a link of the Definable Types type.Organization
//
// Parameters:
//  Organization - DefinedType.CompanyCEL
//
// Returns:
//  Structure:
//   * Description - String - Name of the organization
Function CompanyInformation(Organization) Export
	
	InformationRecords = New Structure();
	InformationRecords.Insert("Description", "");
	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.CompanyInformation(Organization, InformationRecords, StandardProcessing);
	If StandardProcessing Then
		InformationRecords.Description = String(Organization);
	EndIf;
	Return InformationRecords;
	
EndFunction

#Region OFDCodes

///////////////////////////////////////////////////////////////////////////////
// Unit codes

// Returns the code for measuring the quantity of the item being calculated by the CCT.
// 
// Parameters:
//  QuantityMeasureOfCRCalculationSubject - EnumRef.QuantityMeasureOfCRCalculationSubject - A measure of the quantity of the subject of calculation of the CCT
// 
// Returns:
//  Arbitrary, Number - The code of the measure of the quantity of the object of calculation of the KKT     
Function CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT(QuantityMeasureOfCRCalculationSubject) Export
	
	QuantityMeasures = Enums.QuantityMeasureOfCRCalculationSubject.CodesOfMeasureOfQuantityOfSubjectOfCalculationOfCCT();
	Return QuantityMeasures.Get(QuantityMeasureOfCRCalculationSubject);
	
EndFunction

// Returns a measure of the number of items calculated by code.
// 
// Parameters:
//  CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT - EnumRef.QuantityMeasureOfCRCalculationSubject - The code of the measure of the quantity of the object of calculation of the KKT
// 
// Returns:                                                                                    
//  Arbitrary, EnumRef.QuantityMeasureOfCRCalculationSubject - A measure of the quantity of the subject of calculation of KKT by Code        
//
Function MeasureOfQuantityOfSubjectOfCalculationOfKKTByCode(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT) Export
	
	QuantityMeasures = Enums.QuantityMeasureOfCRCalculationSubject.MeasureOfQuantityOfSubjectOfCalculationOfKKTByCode();
	Return QuantityMeasures.Get(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT);
	
EndFunction

// Returns a measure of the quantity of the calculation item by the unit code.
// 
// Parameters:
//  UnitCode - Number - The unit code.
// 
// Returns:
//  EnumRef.QuantityMeasureOfCRCalculationSubject, Arbitrary - A measure of the quantity of the object of calculation according to the unit code
Function MeasureOfQuantityOfSubjectOfCalculationByUnitCode(UnitCode) Export
	
	MeasureOfQuantity = Enums.QuantityMeasureOfCRCalculationSubject.MeasureOfQuantityOfSubjectOfCalculationByUnitCode();
	Result = MeasureOfQuantity.Get(TrimAll(String(UnitCode)));
	If Result = Undefined Then
		Result = MeasureOfQuantity.Get("OtherUnitsOfMeasurement");
	EndIf;
	Return Result;
	
EndFunction

// Returns the unit code for the CCT code.
// 
// Parameters:
//  CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT - Number - The code of the measure of the quantity of the object of calculation of the KKT.
// 
// Returns:
//  String
//
Function CodeOfUnitOfMeasurementAccordingToKKTCode(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT) Export
	
	QuantityMeasures = Enums.QuantityMeasureOfCRCalculationSubject.CodesOfUnitsOfMeasurementByKKTCode();
	UnitCode = QuantityMeasures.Get(CodeOfMeasureOfQuantityOfSubjectOfCalculationOfKKT);
	Return UnitCode;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Adds the supplied drivers to the list as part of the configuration.
//
// Parameters:
//  DriversOfHardware - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//
Procedure UpdateSuppliedDrivers(DriversOfHardware) Export
	
	Driver = DriversOfHardware.Add();
	Driver.EquipmentType = Enums.PeripheralTypes.ReceiptPrinter;
	Driver.NameOfDriver  = "Driver1CReceiptPrinter";
	Driver.Description = NStr("vi = '1C:Máy in phiếu tính tiền';
								|ru = '1С:Принтер чеков';
								|en = '1C:Receipt printer'; fa = '1C:Receipt printer';
								|it = '1С:Stampante degli scontrini';
								|pl = '1C:Drukarka paragonów';
								|tr = '1C:Receipt printer'", CommonCEL.DefaultLanguageCode());
	Driver.ObjectID = "ReceiptPrinterNative"; 
	Driver.RecommendedUse = True;
	
	
EndProcedure

#Region PreparationOfOfOperationData

// Prepare the operation data before executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - See EquipmentManagerClientServer.ConnectionParameters()
//  Command - String - command to execute
//  OperationParametersList - Structure - 
// 
// Returns:
//  Structure - Prepare Operation Data:
//  * Cashier - DefinedType.PersonalDataSubjectCEL
//  * CashierTIN - Number
//  * DocumentBasis - DefinedType.BaseDocumentForFiscalPLTransaction
//  * IDOfFiscalRecord - UUID
//  * Organization - DefinedType.CompanyCEL
//  * RetailFacility - DefinedType.RetailFacilityCEL
//  * DocumentToBeCorrected - DefinedType.BaseDocumentForFiscalPLTransaction
//  * ThereIsPersonalData - Boolean -
//  * PersonalDataSubject - DefinedType.PersonalDataSubjectCEL
//  * PersonalDataType - EnumRef.TypesOfPersonalDataOfTheCCT
//  * CalculationType - EnumRef.CashSettlementTypes
//  * DocumentType - EnumRef.TypesOfCREFiscalDocuments
//  * InterfaceRevision - Number -
//  * LineWidth_ - Number - 
//  * CRERegistrationNumber - String -
//  * ManufaturerNumberOfFiscalStorage - String - 
//  * AdditionalAttribute - String - 
//  * CREShiftNumber - Number -
//  * KKTReceiptNumber - Number -
//  * ShiftReceiptNumber - Number -
//  * ReceiptDateAndTime - Date
//  * ReceiptAmount - Number -
//  * CashAccountPayment - Number -
//  * ElectronicalyPayment - Number -
//  * PaymentPrepayment - Number -
//  * PaymentPayment - Number -
//  * PaymentConsideration - Number -
//  * FiscalFlag - String -
//  * VerificationWebsiteAddress - String -
//  * PrintError - Boolean -
//  * Electronically - Boolean -
//  * Sends1CSMS - Boolean -
//  * Sends1CEmail - Boolean -
//  * Offline - Boolean -
//  * XMLReceiptData_ - String
//  * ReceiptDataAndPersonalData - String 
//  * ResultOfXMLOperation - Boolean
//  * MessageText - String
//  * CurrentStatus - Structure -:
//    ** CREShiftNumber - Number -
//    ** KKTReceiptNumber - Number -
//    ** ShiftStatus - Number -
//    ** DateTime - Date
//    ** XMLParameters - String -
//    ** XMLResult - String -
//    ** CashRegisterShift - DocumentRef.CashRegisterShift
//    ** TestReceipts - Boolean
//    ** Result - Boolean -
//    ** ErrorText - String
//  * ReverseCorrectionCheck - Boolean
//  * ProcessCorrectionCheck - Boolean -
//  * CRENonApplication - Boolean -
//  * VersionFDFCRE11 - Boolean -
//  * Result - Boolean -
//  * OperationRecorded - Boolean -
//  * ErrorText - String
//  * ShiftStatus - Number -
//  * TestReceipts - Boolean
//  * SingleReceipt - Boolean -
//  * PaymentSystemPaymentID - UUID
//  * PaymentSystemType - EnumRef.TypesOfCashRegisterPaymentSystem  
//
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList) Export
	
	LineWidth_ = ?(ConnectionParameters.Property("LineWidth_") And ConnectionParameters.LineWidth_ > 0, ConnectionParameters.LineWidth_, 32);
	
	OperationData = New Structure();
	OperationData.Insert("Result", True);
	OperationData.Insert("ErrorText");
	OperationData.Insert("TestReceipts");
	OperationData.Insert("ReceiptText");
	
	// For all operations, we check the correctness of the cashier's TIN.
	If OperationParametersList <> Undefined And OperationParametersList.Property("CashierTIN") And Not IsBlankString(OperationParametersList.CashierTIN) Then
		ErrorDescription = "";
		If Not PeripheralsReceiptPrintersClientServer.TINMeetsRequirements(OperationParametersList.CashierTIN, False, ErrorDescription) Then
			ErrorText = NStr("vi = 'MST của thu ngân không chính xác (%Error%)';
							|ru = 'ИНН кассира некорректен (%Error%)';
							|en = 'Cashier TIN is incorrect (%Error%)'; fa = 'Cashier TIN is incorrect (%Error%)';
							|it = 'Codice fiscale del cassiere errato (%Error%)';
							|pl = 'NIP kasjera jest niewłaściwy (%Error%)';
							|tr = 'Kasiyere ait VKN düzeltilmedi (%Error%)'");
			ErrorDescription = StrReplace(ErrorText, "%Error%", ErrorDescription);
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
	EndIf;
	
	// For all operations, we check the correctness of the TIN of the organization.
	If  OperationParametersList <> Undefined And OperationParametersList.Property("CompanyTIN") And Not IsBlankString(OperationParametersList.CompanyTIN) Then
		If StrLen(OperationParametersList.CompanyTIN) <> 10 And StrLen(OperationParametersList.CompanyTIN) <> 12 Then
			ErrorDescription = NStr("vi = 'Sai độ dài MST của doanh nghiệp.';
									|ru = 'Неверная длина ИНН организации.';
									|en = 'Incorrect length of the company TIN.'; fa = 'Incorrect length of the company TIN.';
									|it = 'Lunghezza codice fiscale azienda non valida';
									|pl = 'Nieprawidłowa długość NIP firmy.';
									|tr = 'İş yeri VKN yanlış uzunlukta.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
	EndIf;
	
	// For all operations, we check the correctness of the length of the Cashier field (FFD 1021) (max 64)
	If  OperationParametersList <> Undefined And OperationParametersList.Property("Cashier") And Not IsBlankString(OperationParametersList.Cashier) Then
		If StrLen(OperationParametersList.Cashier) > 64 Then
			OperationParametersList.Cashier = Left(TrimAll(OperationParametersList.Cashier),64);
		EndIf;
	EndIf;
	
	If Command = "CheckFiscalization" Then
		
		If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter 
				And OperationParametersList.Property("AutonomousCCT") And Not OperationParametersList.AutonomousCCT Then
			ErrorDescription = NStr("vi = 'Đã cấm tài chính hóa trên máy in phiếu tính tiền.';
									|ru = 'Фискализация на принтерах чеков запрещена.';
									|en = 'Fiscalization on receipt printers is not allowed.'; fa = 'Fiscalization on receipt printers is not allowed.';
									|it = 'Фискализация на принтерах чеков запрещена.';
									|pl = 'Fiscalization on receipt printers is not allowed.';
									|tr = 'Fiş yazıcılarında malileştirme yasaktır.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		LastShiftStatus = GetLastShiftStatus(ConnectionParameters.DeviceID);
		If OperationParametersList.Property("AutonomousCCT") And OperationParametersList.AutonomousCCT Then
			LastShiftStatus.Active = True;
		EndIf;
		If Not LastShiftStatus.Active = True Then
			ErrorDescription = NStr("vi = 'Phiên thu ngân chưa mở hoặc đã hết hạn.';
									|ru = 'Кассовая смена не открыта или истекла.';
									|en = 'POS shift is not opened or expired.'; fa = 'POS shift is not opened or expired.';
									|it = 'Il cambio di cassa non è aperto o è scaduto.';
									|pl = 'Zmiana kasowa nie jest otwarta lub wygasła.';
									|tr = 'Kasa vardiyası açık değil veya süresi dolmuş.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		ElsIf OperationParametersList.Property("AutonomousCCT") And OperationParametersList.AutonomousCCT Then
		Else
			// Format and logic control
			ErrorDescription = "";
			If CommonCEL.FormatLogicalControlIsUsed() Then
				FormatAndLogicControlModule = CommonCEL.CommonModule("FormatLogicalControl");
				If Not FormatAndLogicControlModule.MandatoryAndCorrectFillingOfTagsWasChecked(OperationParametersList, 
					ConnectionParameters.DeviceID, ErrorDescription) Then
					OperationData.Result = False;
					OperationData.ErrorText = ErrorDescription;
					Return OperationData;
				EndIf;
				FormatAndLogicControlModule.BringDataToRequiredFormat(OperationParametersList);
			EndIf;
		EndIf;
		
		If ValueIsFilled(OperationParametersList.DocumentBasis) And ControlOfFiscalizationOfNonCashPayments() Then    
			FillInDetailsOfPaymentOfOperations(OperationParametersList);
		EndIf;
		
		// Parameters of receipt fiscalization
		FiscalizationParameters = ReceiptFiscalizationParameters();
		FiscalizationParameters.CurShift = LastShiftStatus.CashRegisterShift;
		
		// Parameters for registering a KKT
		RegistrationParameters = DeviceRegistrationParameters(ConnectionParameters.DeviceID);
		VersionFDFCRE11 = ?(RegistrationParameters.Property("VersionFDFCRE"), RegistrationParameters.VersionFDFCRE, "1.05");
		VersionFDFCRE11 = VersionFDFCRE11 = "1.1" Or  VersionFDFCRE11 = "1.2"; // FFD 1.1 feature
		
		OperationParametersList = ReceiptTemplate(OperationParametersList, Enums.PeripheralTypes.CREWithDataTransfer, Undefined, ConnectionParameters.DeviceID);
		
		// add the text of a short slip receipt to the body of the fiscal receipt
		If Not IsBlankString(OperationParametersList.TextOfShortSlipReceipt) Then
			ReceiptRow = PeripheralsReceiptPrintersClientServer.ReceiptTextStringParameters(OperationParametersList.TextOfShortSlipReceipt);
			ReceiptRow.Align = "Center";
			OperationParametersList.ReceiptPositions.Add(ReceiptRow);
		EndIf;
		
		FiscalizationParameters.CRERegistrationNumber = ?(RegistrationParameters.Property("CRERegistrationNumber"), RegistrationParameters.CRERegistrationNumber, "");
		FiscalizationParameters.ManufaturerNumberOfFiscalStorage  = ?(RegistrationParameters.Property("ManufaturerNumberOfFiscalStorage"), RegistrationParameters.ManufaturerNumberOfFiscalStorage, "");
		FiscalizationParameters.LineWidth_      = LineWidth_;
		FiscalizationParameters.InterfaceRevision = ConnectionParameters.InterfaceRevision;
		FiscalizationParameters.DocumentBasis = OperationParametersList.DocumentBasis;
		FiscalizationParameters.IDOfFiscalRecord = OperationParametersList.IDOfFiscalRecord;
		FiscalizationParameters.Organization       = OperationParametersList.Organization;
		FiscalizationParameters.RetailFacility    = OperationParametersList.RetailFacility;
		FiscalizationParameters.AdditionalAttribute = OperationParametersList.AdditionalAttribute;  
		FiscalizationParameters.PersonalDataSubject = OperationParametersList.PersonalDataSubject;
		FiscalizationParameters.ThereIsPersonalData    = OperationParametersList.ThereIsPersonalData;
		If OperationParametersList.Property("PaymentSystemPaymentID") Then 
			FiscalizationParameters.PaymentSystemPaymentID = OperationParametersList.PaymentSystemPaymentID;
		EndIf;
		If OperationParametersList.Property("PaymentSystemType") Then 
			FiscalizationParameters.PaymentSystemType = OperationParametersList.PaymentSystemType;
		EndIf;
		If OperationParametersList.Property("DocumentToBeCorrected") Then 
			FiscalizationParameters.DocumentToBeCorrected = OperationParametersList.DocumentToBeCorrected;
		EndIf;
		FiscalizationParameters.Cashier       = OperationParametersList.Cashier;
		FiscalizationParameters.CashierTIN    = OperationParametersList.CashierTIN;
		FiscalizationParameters.Electronically   = OperationParametersList.Electronically;
		FiscalizationParameters.Sends1CSMS   = OperationParametersList.Sends1CSMS;
		If OperationParametersList.Sends1CSMS Then
			FiscalizationParameters.BuyerNumber = OperationParametersList.BuyerNumber;
		EndIf;
		FiscalizationParameters.Sends1CEmail = OperationParametersList.Sends1CEmail;
		If OperationParametersList.Sends1CEmail Then
			FiscalizationParameters.BuyerEmail = OperationParametersList.BuyerEmail;
		EndIf;
		FiscalizationParameters.VersionFDFCRE11    = VersionFDFCRE11;
		FiscalizationParameters.SingleReceipt         = OperationParametersList.SingleReceipt;
		FiscalizationParameters.DocumentType = Enums.TypesOfCREFiscalDocuments.SALESSLIP;      
		
		// Generating XML
		GenerateXMLPackageForFiscalizingReceipt(OperationParametersList, FiscalizationParameters);   
		
		If FiscalizationParameters.ThereIsPersonalData Then
			If IsBlankString(FiscalizationParameters.ReceiptDateAndTime) Then
				ReceiptDateAndTime = CommonCEL.SessionDate();
			Else
				ReceiptDateAndTime = FiscalizationParameters.ReceiptDateAndTime;
			EndIf;
			BuyerInformation = PeripheralsReceiptPrintersClientServer.ParametersPersonalDataOfBuyer();
			FiscalizationParameters.PersonalDataType = OperationParametersList.PersonalDataType;
			EquipmentManagerServerCallOverridable.ProcessingOfPersonalDataFilling(BuyerInformation, FiscalizationParameters.PersonalDataSubject, 
				FiscalizationParameters.PersonalDataType, ReceiptDateAndTime);
			GenerateXMLPackageForFiscalizingReceipt(OperationParametersList, FiscalizationParameters, True, BuyerInformation, FiscalizationParameters.PersonalDataType);
		EndIf;
		
		FiscalizationParameters.CurrentStatus.XMLParameters = GetXMLPacketForOperation(OperationParametersList, ConnectionParameters.InterfaceRevision);
			
		If ValueIsFilled(OperationParametersList.PrintDevice) 
			And (ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And Not ConnectionParameters.TypesOfEquipment.ReceiptPrinter) 
			Or (OperationParametersList.Property("AutonomousCCT") And OperationParametersList.AutonomousCCT) Then
			
			Template = FiscalDocumentTemplates.SalesSlipTemplate(LineWidth_, OperationParametersList);
			ReceiptText = FiscalDocumentTemplates.OutputAsText(Template);
			FiscalizationParameters.CopyOfReceipt = GetXMLPackageForText(ReceiptText, ConnectionParameters.InterfaceRevision);
			FiscalizationParameters.ReceiptText = ReceiptText;
			
		EndIf;
		
		If OperationParametersList.DocumentsPackage <> Undefined And OperationParametersList.DocumentsPackage.Count() > 0 Then
			
			If FiscalizationParameters.AdditionalDocuments_ = Undefined Then
				FiscalizationParameters.AdditionalDocuments_ = New Array();
			EndIf;
			
			For Each AdditionalDocument In OperationParametersList.DocumentsPackage Do
				PrintText_ = GetXMLPackageForText(AdditionalDocument.Key, ConnectionParameters.InterfaceRevision);
				FiscalizationParameters.AdditionalDocuments_.Add(New Structure("PrintText_, PrintDevice" , PrintText_, AdditionalDocument.Value));
			EndDo;
			
		EndIf;
		
		If OperationParametersList.NonFiscalDocuments <> Undefined And OperationParametersList.NonFiscalDocuments.Count() > 0 Then
			If FiscalizationParameters.TestReceipts = Undefined Then
				FiscalizationParameters.TestReceipts = New Array();
			EndIf;
				FillInXMLPackagesForTextDocument(
				FiscalizationParameters.TestReceipts, 
				OperationParametersList.NonFiscalDocuments, 
				ConnectionParameters, 
				LineWidth_);
		EndIf;
		
		For Each Position In OperationParametersList.ReceiptPositions Do
			If Position.Property("FiscalLine") Then
				BarcodeBASE64 = ?(ValueIsFilled(Position.BarcodeBASE64), 
					Position.BarcodeBASE64, 
					CommonCELClientServer.BarcodeInBase64(Position.Barcode));
				If ValueIsFilled(BarcodeBASE64) Then
					
					ProductionData = New Structure;
					ProductionData.Insert("Description", Position.Description);
					FiscalizationParameters.BarcodesOfManufacturedProducts.Insert(BarcodeBASE64, ProductionData);
					
				EndIf;
			EndIf;
		EndDo;
		
		If CommonCEL.MarkingIsUsed() Then   
			ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
			FiscalizationParameters.MTDisposalReport = ModuleEquipmentManagerMarking.GenerateDataForMTDisposalReport(OperationParametersList, FiscalizationParameters);
		EndIf;
		
		Return FiscalizationParameters;
			
	ElsIf Command = "PrintReceiptCorrection" Then
		
		If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter 
				And OperationParametersList.Property("AutonomousCCT") And Not OperationParametersList.AutonomousCCT Then
			ErrorDescription = NStr("vi = 'Đã cấm tài chính hóa trên máy in phiếu tính tiền.';
									|ru = 'Фискализация на принтерах чеков запрещена.';
									|en = 'Fiscalization on receipt printers is not allowed.'; fa = 'Fiscalization on receipt printers is not allowed.';
									|it = 'Фискализация на принтерах чеков запрещена.';
									|pl = 'Fiscalization on receipt printers is not allowed.';
									|tr = 'Fiş yazıcılarında malileştirme yasaktır.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		FiscalizationParameters = ReceiptFiscalizationParameters();              
		// Parameters for registering a KKT
		RegistrationParameters = DeviceRegistrationParameters(ConnectionParameters.DeviceID); 
		VersionFDFCRE11 = ?(RegistrationParameters.Property("VersionFDFCRE"), RegistrationParameters.VersionFDFCRE, "1.05");
		VersionFDFCRE11 = VersionFDFCRE11 = "1.1" Or VersionFDFCRE11 = "1.2"; // FFD 1.1 feature
		
		If (ConnectionParameters.InterfaceRevision < 3000 And OperationParametersList.CRENonApplication) 
			And (OperationParametersList.CalculationType = Enums.CashSettlementTypes.Refund 
			Or OperationParametersList.CalculationType = Enums.CashSettlementTypes.CashOutflowRefund) Then
			FiscalizationParameters.Result = False;
			FiscalizationParameters.ErrorText = NStr("vi = 'Đối với kiểu tính toán này, không thể tạo phiếu điều chỉnh cho MTT này.';
													|ru = 'Для данного типа расчета нельзя сформировать чек коррекции для данного ККТ.';
													|en = 'For this type of calculation, it is impossible to form an adjustment voucher for this cash register.'; fa = 'For this type of calculation, it is impossible to form an adjustment voucher for this cash register.';
													|it = 'Per questo tipo di calcolo, non è possibile generare un controllo di correzione per un determinato Registratore di cassa.';
													|pl = 'Dla tego typu obliczeń niemożliwe jest utworzenie kontroli korekty dla tego KK.';
													|tr = 'Bu yazar kasaya bu tür bir faturalama için düzeltme fişi oluşturulamaz.'");
			Return FiscalizationParameters;
		EndIf;    
		
		// Parameters of receipt fiscalization
		FiscalizationParameters.CRENonApplication   = OperationParametersList.CRENonApplication;
		FiscalizationParameters.Cashier            = OperationParametersList.Cashier;
		FiscalizationParameters.Electronically        = OperationParametersList.Electronically;
		FiscalizationParameters.Sends1CSMS   = OperationParametersList.Sends1CSMS;
		FiscalizationParameters.Sends1CEmail = OperationParametersList.Sends1CEmail;
		FiscalizationParameters.Organization       = OperationParametersList.Organization;
		FiscalizationParameters.RetailFacility    = OperationParametersList.RetailFacility;
		FiscalizationParameters.AdditionalAttribute = OperationParametersList.AdditionalAttribute;  
		FiscalizationParameters.VersionFDFCRE11    = VersionFDFCRE11; 
		FiscalizationParameters.SingleReceipt         = OperationParametersList.SingleReceipt;
		FiscalizationParameters.CRERegistrationNumber = ?(RegistrationParameters.Property("CRERegistrationNumber"), RegistrationParameters.CRERegistrationNumber, "");
		FiscalizationParameters.ManufaturerNumberOfFiscalStorage  = ?(RegistrationParameters.Property("ManufaturerNumberOfFiscalStorage"), RegistrationParameters.ManufaturerNumberOfFiscalStorage, "");
		FiscalizationParameters.LineWidth_      = LineWidth_;
		FiscalizationParameters.InterfaceRevision = ConnectionParameters.InterfaceRevision;
		FiscalizationParameters.DocumentBasis = OperationParametersList.DocumentBasis;
		FiscalizationParameters.IDOfFiscalRecord  = OperationParametersList.IDOfFiscalRecord;    
		FiscalizationParameters.GenerateCorrectionReceiptForReverse = OperationParametersList.GenerateCorrectionReceiptForReverse;
		If OperationParametersList.Property("DocumentToBeCorrected") Then 
			FiscalizationParameters.DocumentToBeCorrected = OperationParametersList.DocumentToBeCorrected;
		EndIf;
		
		If OperationParametersList.CRENonApplication Then    
			FiscalizationParameters.GenerateCorrectionReceiptForReverse = False;   
		EndIf; 
		
		If Not FiscalizationParameters.GenerateCorrectionReceiptForReverse Then 
			// Scenario 1 - non-use of CCT. 
			If OperationParametersList.CRENonApplication And ValueIsFilled(OperationParametersList.DocumentToBeCorrected) Then
				FiscalizationParameters.Result = False;
				FiscalizationParameters.ErrorText = NStr("vi = 'Không thể tạo phiếu điều chỉnh ""không sử dụng MTT"" đối với phiếu đã ghi nhận từ trước.';
														|ru = 'Чек коррекции «неприменение ККТ» нельзя сформировать для фискализированного ранее чека.';
														|en = 'An adjustment voucher “non-use of cash register” cannot be formed for a receipt that was previously fiscalized.'; fa = 'An adjustment voucher “non-use of cash register” cannot be formed for a receipt that was previously fiscalized.';
														|it = 'L''assegno di correzione ""Non applicabile Registratore di cassa"" non può essere generato per un assegno precedentemente fiscalizzato.';
														|pl = 'Nie można utworzyć testu korekty „nieużywanie KK” dla paragonu, który był wcześniej fiskalizowany.';
														|tr = 'Önceden malileştirilen bir fiş için ""yazar kasanın kullanılmaması"" düzeltme fişi oluşturulamaz.'");
				Return FiscalizationParameters;
			EndIf;                        
			
			FiscalizationParameters.CorrectionReceiptForCCT = True;   
			If Not FiscalizationParameters.CRENonApplication And Not FiscalizationParameters.GenerateCorrectionReceiptForReverse And Not VersionFDFCRE11 Then
				FiscalizationParameters.CorrectionReceiptForCCT = False;
				// Non-ApplicationeCKT is not used, the formationcheckcorrectionhistorically contains a lie
				// VERSIYAFFDKKT11 contains a lie, FFD is less than 1.1
				ReplacePaymentTypesDuringCorrection(OperationParametersList, Undefined);
			EndIf;                                                                                   
			FiscalizationParameters.DocumentType = ?(FiscalizationParameters.CorrectionReceiptForCCT, Enums.TypesOfCREFiscalDocuments.AdjustmentSalesSlip, Enums.TypesOfCREFiscalDocuments.SALESSLIP);
			GenerateXMLPackageForFiscalizingReceipt(OperationParametersList, FiscalizationParameters);
		Else
			// Scenario 2 - correction of violations of the use of CCT.
			If IsBlankString(OperationParametersList.DocumentToBeCorrected) Then
				FiscalizationParameters.Result = False; 
				FiscalizationParameters.ErrorText = NStr("vi = 'Chưa chỉ định chứng từ điều chỉnh để tạo phiếu điều chỉnh.';
														|ru = 'Корректируемый документ не указан для формирования чека коррекции.';
														|en = 'The adjusted document is not specified for the adjustment voucher.'; fa = 'The adjusted document is not specified for the adjustment voucher.';
														|it = 'Il documento da correggere non è specificato per generare un controllo di correzione.';
														|pl = 'Poprawiony dokument nie został określony w celu utworzenia korekty.';
														|tr = 'Düzeltme fişi oluşturmak için düzeltilecek belge belirtilmemiştir.'");
				Return FiscalizationParameters;
			EndIf;       
			
			DocumentTypes = New Array();
			DocumentTypes.Add(Enums.TypesOfCREFiscalDocuments.SALESSLIP); // For FFD 1.05
			DocumentTypes.Add(Enums.TypesOfCREFiscalDocuments.AdjustmentSalesSlip); // For FFD 1.1
			
			CorrectedDocumentOperation = FiscalOperationData(OperationParametersList.DocumentToBeCorrected, ,DocumentTypes); 
			If CorrectedDocumentOperation = Undefined Then
				FiscalizationParameters.Result = False; 
				FiscalizationParameters.ErrorText = NStr("vi = 'Không tìm thấy phiếu tính tiền đã ghi nhận từ trước để tạo phiếu điều chỉnh.';
														|ru = 'Не найден ранее фискализированный кассовый чек для формирования чека коррекции.';
														|en = 'Previously fiscalized sales slip to generate a cash register adjustment voucher is not found.'; fa = 'Previously fiscalized sales slip to generate a cash register adjustment voucher is not found.';
														|it = 'Non è stato trovato uno scontrino di cassa precedentemente fiscalizzato per la creazione dello scontrino di correzione.';
														|pl = 'Nie znaleziono wcześniej paragonu kasjera fiskalnego w celu sprawdzenia poprawności.';
														|tr = 'Önceden mali hale getirilen bir kasa fişi için düzeltme fişinin oluşturmadığı tespit edilmiştir.'");
				Return FiscalizationParameters;
			EndIf;            
			
			// Depending on the FFD version, we form a "Cash Receipt" or "Cash Correction Receipt".   
			FiscalizationParameters.CorrectionReceiptForCCT = VersionFDFCRE11;
			TypeOfFiscalDocuments = ?(FiscalizationParameters.CorrectionReceiptForCCT, Enums.TypesOfCREFiscalDocuments.AdjustmentSalesSlip, Enums.TypesOfCREFiscalDocuments.SALESSLIP);
			// Additional details of the receipt are a fiscal feature of the foundation document (according to which the correction is taking place).
			FiscalFlag = CorrectedDocumentOperation.FiscalFlag;
			
			// We form a cash receipt with the correct details.
			OperationParametersList.AdditionalAttribute = FiscalFlag;
			FiscalizationParameters.AdditionalAttribute = FiscalFlag;  
			FiscalizationParameters.DocumentType = TypeOfFiscalDocuments;
			
			// We form the fiscalization parameters for the reversal correction check.
			XMLReceiptData = CorrectedDocumentOperation.XMLData1.Get();    
			// The correction receipt does not contain data about the marking
			GeneralParametersOfStorno = LoadFiscalizationDataFromXML(XMLReceiptData, False);
			GeneralParametersOfStorno.AdditionalAttribute = FiscalFlag;
			
			FillPropertyValues(GeneralParametersOfStorno.CorrectionData, OperationParametersList.CorrectionData);
			PrepareCorrectionReceipt(OperationParametersList, GeneralParametersOfStorno, VersionFDFCRE11);
			// For 1.05 format
			If Not VersionFDFCRE11 Then            
				ReplacePaymentTypesDuringCorrection(OperationParametersList, GeneralParametersOfStorno);
			EndIf;  
			
			GenerateXMLPackageForFiscalizingReceipt(OperationParametersList, FiscalizationParameters);
			
			ParametersOfFiscalizationOfStorno = ReceiptFiscalizationParameters();
			FillPropertyValues(ParametersOfFiscalizationOfStorno, FiscalizationParameters);
			GenerateXMLPackageForFiscalizingReceipt(GeneralParametersOfStorno, ParametersOfFiscalizationOfStorno);
			
			FiscalizationParameters.ReverseCorrectionCheck = ParametersOfFiscalizationOfStorno;
			
		EndIf;
	
		Return FiscalizationParameters;
		
	ElsIf Command = "PrintCheckCopy" Then            
		
		Hardware = ?(OperationParametersList.Property("Hardware"), OperationParametersList.Hardware, True);
		
		If Not Hardware Then 
			DocumentRef = ?(OperationParametersList.Property("DocumentRef"), OperationParametersList.DocumentRef, Undefined); 
			FiscalFlag = ?(OperationParametersList.Property("FiscalFlag"), OperationParametersList.FiscalFlag, Undefined); 
			
			If Not ValueIsFilled(DocumentRef) And IsBlankString(FiscalFlag) Then
				ErrorText = NStr("vi = 'Chưa chỉ định tham số in bản sao chứng từ.';
								|ru = 'Не указаны параметры печати копии документа.';
								|en = 'Document copy print parameters are not specified.'; fa = 'Document copy print parameters are not specified.';
								|it = 'Non sono indicati i parametri di stampa della copia del documento.';
								|pl = 'Nie podano parametrów drukowania kopii dokumentu.';
								|tr = 'Belgenin kopyasını yazmak için parametre belirtilmemiş.'");
				OperationData.Result = False;
				OperationData.ErrorText = ErrorText;
				Return OperationData;
			EndIf;
				
			FiscalTransaction = FiscalOperationData(DocumentRef, Undefined, Undefined, Undefined, FiscalFlag);
			If FiscalTransaction = Undefined Then
				ErrorText = NStr("vi = 'Không tìm thấy chứng từ đã ghi nhận để in bản sao.';
								|ru = 'Фискальный документ для печати копии не найден.';
								|en = 'Fiscal document for printing the copy is not found.'; fa = 'Fiscal document for printing the copy is not found.';
								|it = 'Il documento fiscale per la stampa della copia non è stato trovato.';
								|pl = 'Dokument fisklany do drukowania kopii nie jest potrzebny.';
								|tr = 'Kopyasının okunması için mali belge bulunamadı.'");
				OperationData.Result = False;
				OperationData.ErrorText = ErrorText;
				Return OperationData;
			EndIf;


			XMLData1 = FiscalTransaction.XMLData1.Get();    
			ReceiptCopyParameters = LoadFiscalizationDataFromXML(XMLData1);           
			ReceiptCopyParameters.DateTime = FiscalTransaction.Date; 
			
			PrintParameters  = FiscalDocumentTemplates.ParametersOfFiscalDocumentTemplate();
			PrintParameters.Title = NStr("vi = 'BẢN SAO PHIẾU';
										|ru = 'КОПИЯ ЧЕКА';
										|en = 'RECEIPT COPY'; fa = 'RECEIPT COPY';
										|it = 'COPIA SCONTRINO';
										|pl = 'KOPIA PARAGONU';
										|tr = 'FİŞ KOPYASI'");;
			PrintParameters.DisplayFiscalInformation = False;
			Template    = FiscalDocumentTemplates.SalesSlipTemplate(ConnectionParameters.LineWidth_, ReceiptCopyParameters, FiscalTransaction, PrintParameters);
			ReceiptText = FiscalDocumentTemplates.OutputAsText(Template); 
			
			ReceiptText = PrintParameters.Title + Chars.LF + ReceiptText;
			OperationData.Insert("TestReceipts", GetXMLPackageForText(ReceiptText, ConnectionParameters.InterfaceRevision));     
			OperationData.ReceiptText = ReceiptText;

			OperationData.Insert("TestReceipts", GetXMLPackageForText(ReceiptText, ConnectionParameters.InterfaceRevision));   
		EndIf;
		
		OperationData.Insert("ReceiptNumber", OperationParametersList.ReceiptNumber);
		OperationData.Insert("Hardware", Hardware); 
		
		Return OperationData;
		
	ElsIf Command = "PrintText" Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "PrintQRCode" Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "OpenShift"  Then
		
		If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter 
				And OperationParametersList.Property("AutonomousCCT") And Not OperationParametersList.AutonomousCCT Then
			ErrorDescription = NStr("vi = 'Đã cấm tài chính hóa trên máy in phiếu tính tiền.';
									|ru = 'Фискализация на принтерах чеков запрещена.';
									|en = 'Fiscalization on receipt printers is not allowed.'; fa = 'Fiscalization on receipt printers is not allowed.';
									|it = 'Фискализация на принтерах чеков запрещена.';
									|pl = 'Fiscalization on receipt printers is not allowed.';
									|tr = 'Fiş yazıcılarında malileştirme yasaktır.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		OperationData = ParametersOfFiscalOperation();
		If OperationParametersList.Property("AdditionalParameters") Then
			OperationData.AdditionalParameters = OperationParametersList.AdditionalParameters;
		EndIf;
		 
		If Not BeforeOpeningCashShift(ConnectionParameters, OperationData) Then
			Return OperationData;
		EndIf;
			
		OperationData.XMLParameters = GetXMLPacketForOperation(OperationParametersList, ConnectionParameters.InterfaceRevision);
			
		Return OperationData;
		
	ElsIf Command = "CloseShift" Then
		
		If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter 
				And OperationParametersList.Property("AutonomousCCT") And Not OperationParametersList.AutonomousCCT Then
			ErrorDescription = NStr("vi = 'Đã cấm tài chính hóa trên máy in phiếu tính tiền.';
									|ru = 'Фискализация на принтерах чеков запрещена.';
									|en = 'Fiscalization on receipt printers is not allowed.'; fa = 'Fiscalization on receipt printers is not allowed.';
									|it = 'Фискализация на принтерах чеков запрещена.';
									|pl = 'Fiscalization on receipt printers is not allowed.';
									|tr = 'Fiş yazıcılarında malileştirme yasaktır.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		OperationData = ParametersOfFiscalOperation();
		If OperationParametersList.Property("AdditionalParameters") Then
			OperationData.AdditionalParameters = OperationParametersList.AdditionalParameters;
		EndIf;
		
		If Not BeforeClosingCashShift(ConnectionParameters, OperationData) Then
			Return OperationData;
		EndIf;
		
		OperationData.XMLParameters = GetXMLPacketForOperation(OperationParametersList, ConnectionParameters.InterfaceRevision);
		
		Return OperationData;
		
	ElsIf Command = "ReportCurrentStatusOfSettlements" Or Command = "GetCurrentStatus"  Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "PrintXReport"  Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "Encash" Then
		
		If ConnectionParameters.TypesOfEquipment.Property("ReceiptPrinter") And ConnectionParameters.TypesOfEquipment.ReceiptPrinter 
				And OperationParametersList.Property("AutonomousCCT") And Not OperationParametersList.AutonomousCCT Then
			ErrorDescription = NStr("vi = 'Đã cấm tài chính hóa trên máy in phiếu tính tiền.';
									|ru = 'Фискализация на принтерах чеков запрещена.';
									|en = 'Fiscalization on receipt printers is not allowed.'; fa = 'Fiscalization on receipt printers is not allowed.';
									|it = 'Фискализация на принтерах чеков запрещена.';
									|pl = 'Fiscalization on receipt printers is not allowed.';
									|tr = 'Fiş yazıcılarında malileştirme yasaktır.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		FiscalizationParameters = ReceiptFiscalizationParameters();
		If OperationParametersList.TypeOfCollection = 0 Then
			FiscalizationParameters.DocumentType = Enums.TypesOfCREFiscalDocuments.Withdrawal
		Else
			FiscalizationParameters.DocumentType = Enums.TypesOfCREFiscalDocuments.CashDeposit
		EndIf;
		FiscalizationParameters.TypeOfCollection = OperationParametersList.TypeOfCollection; 
		FiscalizationParameters.ReceiptDateAndTime = CommonCEL.SessionDate();
		
		If ConnectionParameters.TypesOfEquipment.CREWithDataTransfer Then
			
			RegistrationParameters = DeviceRegistrationParameters(ConnectionParameters.DeviceID);
			
			FiscalizationParameters.CRERegistrationNumber = ?(RegistrationParameters.Property("CRERegistrationNumber"), RegistrationParameters.CRERegistrationNumber, "");
			FiscalizationParameters.ManufaturerNumberOfFiscalStorage  = ?(RegistrationParameters.Property("ManufaturerNumberOfFiscalStorage"), RegistrationParameters.ManufaturerNumberOfFiscalStorage, "");
			FiscalizationParameters.LineWidth_      = ?(ConnectionParameters.Property("LineWidth_"), ConnectionParameters.LineWidth_, 32);
			FiscalizationParameters.InterfaceRevision = ConnectionParameters.InterfaceRevision;
			
			If OperationParametersList.Property("DocumentBasis") Then 
				FiscalizationParameters.DocumentBasis = OperationParametersList.DocumentBasis;
			EndIf;
			If OperationParametersList.Property("Cashier") Then
				FiscalizationParameters.Cashier = OperationParametersList.Cashier;
			EndIf;
			If OperationParametersList.Property("Organization") Then
				FiscalizationParameters.Organization = OperationParametersList.Organization;
			EndIf;
			If OperationParametersList.Property("RetailFacility") Then
				FiscalizationParameters.RetailFacility = OperationParametersList.RetailFacility;
			EndIf;
			FiscalizationParameters.ReceiptAmount      = OperationParametersList.Sum;
			FiscalizationParameters.CashAccountPayment = OperationParametersList.Sum;
			FiscalizationParameters.XMLReceiptData_  = GetXMLPacketForOperation(OperationParametersList, ConnectionParameters.InterfaceRevision);
			
		EndIf;
		
		Return FiscalizationParameters;
		
	ElsIf Command = "OperationFN" Then
		
		OperationData = ParametersOfFiscalOperation();
		OperationData.Insert("OperationType", OperationParametersList.OperationType);
		InterfaceRevision  = ConnectionParameters.InterfaceRevision;
		OperationData.XMLParameters = CreateTableOfParametersForFNOperation(OperationParametersList, InterfaceRevision);
		Return OperationData;
		
	ElsIf Command = "PiotStart" Or Command = "PiotCheckKM" Then  
		
		Return OperationData;
					 
	ElsIf Command = "RequestKM" Or Command = "RequestKMKMNoWait" Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "CheckKM" Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "CheckFiscalizationPacket" Then
		
		LastShiftStatus = GetLastShiftStatus(ConnectionParameters.DeviceID);
		If Not LastShiftStatus.Active = True Then
			ErrorDescription = NStr("vi = 'Phiên thu ngân chưa mở hoặc đã hết hạn.';
									|ru = 'Кассовая смена не открыта или истекла.';
									|en = 'POS shift is not opened or expired.'; fa = 'POS shift is not opened or expired.';
									|it = 'Il cambio di cassa non è aperto o è scaduto.';
									|pl = 'Zmiana kasowa nie jest otwarta lub wygasła.';
									|tr = 'Kasa vardiyası açık değil veya süresi dolmuş.'");
			OperationData.Result = False;
			OperationData.ErrorText = ErrorDescription;
			Return OperationData;
		EndIf;
		
		OperationData = ReceiptFiscalizationParameters();       
		
		If OperationParametersList <> Undefined And OperationParametersList.Property("XMLReceiptData_") Then
			OperationData.XMLReceiptData_ = OperationParametersList.XMLReceiptData_;
		EndIf;
		
		Return OperationData;
		
	EndIf
	
EndFunction

#EndRegion

#Region DataProcessingOfOperation

// Process the operation data after executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - See EquipmentManagerClientServer.ConnectionParameters()
//  Command - String - command to execute
//  ExecutionResult - Structure - 
//  OperationData - Structure - 
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
	InterfaceRevision = ConnectionParameters.InterfaceRevision;
	
	If Command = "CheckFiscalization" Or Command = "CheckFiscalizationPacket" Then
		
		ProcessReceiptFiscalization(InterfaceRevision, OperationData, ExecutionResult);
		
	ElsIf Command = "PrintReceiptCorrection" Then
		
		ProcessPrintingOfCorrectionReceipt(OperationData, ExecutionResult);
		
	ElsIf Command = "CloseShift" Then
		
		ProcessClosingOfCashShift(InterfaceRevision, OperationData, ConnectionParameters, ExecutionResult);
	
	ElsIf Command = "OpenShift" Then
		
		ProcessOpeningOfCashShift(InterfaceRevision, OperationData, ConnectionParameters, ExecutionResult);
		
	ElsIf Command = "Encash" Then
		
		ProcessCollection(OperationData);
		
	ElsIf Command = "GetDataKKT" Then
		
		ProcessCCTParameters(InterfaceRevision, ConnectionParameters, ExecutionResult);
		
	ElsIf Command = "GetCurrentStatus" Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "PiotStart" Or Command = "PiotCheckKM" Or Command = "PiotStatus"  Then  
		
	
	ElsIf Command = "RequestKM" Then
		
		// Transferred to the client in the equipment module of the printing device Client
		
	ElsIf Command = "GetProcessingKMResult"  Or Command = "RequestKMKMNoWait"  Then
		
		
	ElsIf Command = "CheckKM" Then
		
		
	ElsIf Command = "OperationFN" Then
		
		If OperationData.Property("CREParameters") And Not IsBlankString(OperationData.CREParameters)  Then 
			CREParameters = ParametersFromXMLPackageCCT(OperationData.CREParameters, InterfaceRevision);
			ExecutionResult.Insert("CREParameters" , CREParameters);     
			SaveDeviceRegistrationSettings(ConnectionParameters.DeviceID, CREParameters);
		EndIf;
		
	EndIf
	
EndProcedure

Procedure ProcessReceiptFiscalization(InterfaceRevision, OperationData, ExecutionResult)
	
	If InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
		// Fill in the results of the fiscal receipt from the XML package.
		FillInResultsOfReceiptFiscalizationFromXMLPackage(OperationData);
	EndIf;
	
	ExecutionResult.Insert("CREShiftNumber" , OperationData.CREShiftNumber);
	ExecutionResult.Insert("KKTReceiptNumber"  , OperationData.KKTReceiptNumber);
	ExecutionResult.Insert("ShiftStatus", 2);
	ExecutionResult.Insert("ReceiptDateAndTime"          , OperationData.ReceiptDateAndTime);
	ExecutionResult.Insert("FiscalFlag"      , OperationData.FiscalFlag);
	ExecutionResult.Insert("VerificationWebsiteAddress"     , OperationData.VerificationWebsiteAddress);
	ExecutionResult.Insert("PrintError"           , OperationData.PrintError); 
	ExecutionResult.Insert("CRERegistrationNumber", OperationData.CRERegistrationNumber);
	ExecutionResult.Insert("XMLReceiptData_"          , OperationData.XMLReceiptData_);
	ExecutionResult.Insert("OperationRecorded"       , True);
	ExecutionResult.Insert("FiscalizationParameters"  , OperationData);
	ExecutionResult.Insert("MTDisposalReport"         , OperationData.MTDisposalReport);
	

	Try
		// Record a fiscal transaction.
		RecordFiscalTransaction(OperationData);
	Except
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Ghi lại giao dịch tài chính';
				|ru = 'Запись фискальной операции';
				|en = 'Record fiscal transaction'; fa = 'Record fiscal transaction';
				|it = 'Запись фискальной операции';
				|pl = 'Record fiscal transaction';
				|tr = 'Запись фискальной операции'"), 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	MethodParameters = New Array(1);
	MethodParameters[0] = OperationData;
	BackgroundJobs.Execute(
		"PeripheralsReceiptPrinters.ProcessReceiptFiscalizationInBackground",
		MethodParameters);
	
EndProcedure

Procedure ProcessReceiptFiscalizationInBackground(OperationData) Export
	
	// Send an electronic receipt via the mailing list
	If (OperationData.Sends1CSMS Or OperationData.Sends1CEmail) Then
		ElectronicReceiptMailingModule = CommonCEL.CommonModule("ElectronicCashReceiptMailout");
		If ElectronicReceiptMailingModule <> Undefined Then
			MessageText = ElectronicReceiptMailingModule.TemplateForReceiptAttributesToSend(OperationData);
			ElectronicReceiptMailingModule.SendElectronicReceipt(
			OperationData,
			MessageText, 
			OperationData.BuyerEmail, 
			OperationData.BuyerNumber);
		EndIf;
	EndIf;

EndProcedure

Procedure ProcessPrintingOfCorrectionReceipt(OperationData, Val ExecutionResult)
	
	// Fill in the fiscal receipt results from the XML package.
	FillInResultsOfReceiptFiscalizationFromXMLPackage(OperationData); 
	
	ExecutionResult.Insert("CREShiftNumber" , OperationData.CREShiftNumber);
	ExecutionResult.Insert("KKTReceiptNumber"  , OperationData.KKTReceiptNumber);
	ExecutionResult.Insert("ShiftStatus", 2);
	ExecutionResult.Insert("ReceiptDateAndTime"          , OperationData.ReceiptDateAndTime);
	ExecutionResult.Insert("FiscalFlag"      , OperationData.FiscalFlag);
	ExecutionResult.Insert("VerificationWebsiteAddress"     , OperationData.VerificationWebsiteAddress);
	ExecutionResult.Insert("PrintError"           , OperationData.PrintError); 
	ExecutionResult.Insert("CRERegistrationNumber", OperationData.CRERegistrationNumber);
	ExecutionResult.Insert("XMLReceiptData_"          , OperationData.XMLReceiptData_);
	ExecutionResult.Insert("OperationRecorded"       , True);
	ExecutionResult.Insert("FiscalizationParameters"  , OperationData);
	
	If Not OperationData.CRENonApplication And OperationData.GenerateCorrectionReceiptForReverse Then
		// Fill in the fiscal receipt results from the XML package.
		FillInResultsOfReceiptFiscalizationFromXMLPackage(OperationData.ReverseCorrectionCheck); 
		Try
			// Write down a fiscal operation - reverse.
			RecordFiscalTransaction(OperationData.ReverseCorrectionCheck);
		Except
			CommonCEL.WriteErrorToEventLog(
				NStr("vi = 'Ghi lại giao dịch tài chính phiếu điều chỉnh đảo ngược';
					|ru = 'Запись фискальной операции чека коррекции сторно';
					|en = 'Record fiscal transaction of cash register adjustment voucher storno'; fa = 'Record fiscal transaction of cash register adjustment voucher storno';
					|it = 'Record fiscal transaction of cash register adjustment voucher storno';
					|pl = 'Record fiscal transaction of cash register adjustment voucher storno';
					|tr = 'Düzeltme çeki mali işlemi kaydının iptali'"), 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	Try
		// Record a fiscal transaction.
		RecordFiscalTransaction(OperationData);
	Except
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Ghi lại giao dịch tài chính phiếu điều chỉnh';
				|ru = 'Запись фискальной операции чека коррекции';
				|en = 'Record fiscal transaction of cash register adjustment voucher'; fa = 'Record fiscal transaction of cash register adjustment voucher';
				|it = 'Record fiscal transaction of cash register adjustment voucher';
				|pl = 'Record fiscal transaction of cash register adjustment voucher';
				|tr = 'Düzeltme çeki mali işlemi kaydı'"), 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure ProcessClosingOfCashShift(InterfaceRevision, OperationData, ConnectionParameters, ExecutionResult)
	
	ExecutionResult.Insert("CREShiftNumber", OperationData.CREShiftNumber);
	ExecutionResult.Insert("KKTReceiptNumber" , OperationData.KKTReceiptNumber);
	ExecutionResult.Insert("ShiftStatus"  , OperationData.ShiftStatus);
	ExecutionResult.Insert("CashRegisterShift" , OperationData.CashRegisterShift);
	
	If InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
		FiscalDataStructure = GetShiftParametersFromXMLPackage(OperationData.XMLResult, InterfaceRevision);
		ExecutionResult.CREShiftNumber = FiscalDataStructure.CREShiftNumber;
		ExecutionResult.KKTReceiptNumber = FiscalDataStructure.KKTReceiptNumber;
		ExecutionResult.ShiftStatus = FiscalDataStructure.ShiftStatus;
	Else
		FiscalDataStructure = GetShiftParametersFromXMLPackage(OperationData.XMLResult);
		FiscalDataStructure.CREShiftNumber = OperationData.CREShiftNumber;
		FiscalDataStructure.ShiftStatus   = 1; // Closed_
	EndIf;
	
	ExecutionResult.Insert("FiscalDataStructure", FiscalDataStructure);
	ExecutionResult.Insert("FiscalDataXMLString", OperationData.XMLResult);
	If OperationData.Property("AdditionalParameters") Then
		ExecutionResult.Insert("AdditionalParameters", OperationData.AdditionalParameters);
	EndIf;
	
	AfterCashShiftCloses(ConnectionParameters, ExecutionResult);

EndProcedure

Procedure ProcessOpeningOfCashShift(InterfaceRevision, OperationData, ConnectionParameters, ExecutionResult)
	
	ExecutionResult.Insert("CREShiftNumber" , OperationData.CREShiftNumber);
	ExecutionResult.Insert("KKTReceiptNumber"  , OperationData.KKTReceiptNumber);
	ExecutionResult.Insert("ShiftStatus"   , OperationData.ShiftStatus);
	ExecutionResult.Insert("CashRegisterShift" , OperationData.CashRegisterShift);
	
	If InterfaceRevision >= 3000 Then // Standard version 3.0 (OFD 1.1)
		FiscalDataStructure = GetShiftParametersFromXMLPackage(OperationData.XMLResult, InterfaceRevision);
		ExecutionResult.CREShiftNumber = FiscalDataStructure.CREShiftNumber;
		ExecutionResult.KKTReceiptNumber = FiscalDataStructure.KKTReceiptNumber;
		ExecutionResult.ShiftStatus = FiscalDataStructure.ShiftStatus;
	Else  // Standard version 2.2 and higher (OFD 1.05)
		FiscalDataStructure = GetShiftParametersFromXMLPackage(OperationData.XMLResult, InterfaceRevision);
		FiscalDataStructure.CREShiftNumber = OperationData.CREShiftNumber;
		FiscalDataStructure.ShiftStatus   = 2; // IsOpen
	EndIf;
	ExecutionResult.Insert("FiscalDataStructure", FiscalDataStructure);
	ExecutionResult.Insert("FiscalDataXMLString", OperationData.XMLResult);
	If OperationData.Property("AdditionalParameters") Then
		ExecutionResult.Insert("AdditionalParameters", OperationData.AdditionalParameters);
	EndIf;
	
	If OperationData.Property("CREParameters") And Not IsBlankString(OperationData.CREParameters)  Then 
		CREParameters = ParametersFromXMLPackageCCT(OperationData.CREParameters, InterfaceRevision);
		SaveDeviceRegistrationSettings(ConnectionParameters.DeviceID, CREParameters);
		
		ISMPProductsAreRecorded = EquipmentManager.ISMPProductsAreRecorded();
		If CREParameters.Property("VersionFDFCRE") And CREParameters.VersionFDFCRE <> "1.2" Then
			// Letter of the Federal Tax Service dated October 28, 2021 No. PA-4-20/15207@ On the transition of the CCT to FFD 1.2
			If ISMPProductsAreRecorded Then
				MessageText = NStr("vi = 'Khi hạch toán hàng hóa có dán nhãn, cần chuyển đến MTT có FFD phiên bản 1.2 trước ngày 01.02.2022.';
									|ru = 'При осуществлении расчетов за маркированные товары необходимо перейти на ККТ с ФФД версии 1.2 в срок до 01.02.2022.';
									|en = 'When making payments for marked goods, switch to the cash register with FDF of version 1.2 before 02/01/2022.'; fa = 'When making payments for marked goods, switch to the cash register with FDF of version 1.2 before 02/01/2022.';
									|it = 'Al pagamento di articoli contrassegnati, è necessario passare al registratore di cassa con versione FFD 1.2 fino al 01.02.2022.';
									|pl = 'Przy dokonywaniu rozliczeń za oznakowane towary należy przejść na kasy fiskalne z FFD wersji 1.2 w terminie do 01.02.2022.';
									|tr = 'Etiketli malların ödemesi yapılırken, 01.02.2022 tarihine kadar FFD sürüm 1.2''nin bulunduğu bir yazar kasaya geçilmesi gerekmektedir.'") + Chars.LF 
				+ NStr("vi = 'Công văn của tổng cục thuế ngày 28 tháng 10 năm 2021 số PA-4-20/15207@ ""Về việc chuyển đổi máy tính tiền sang FFD 1.2""';
						|ru = 'Письмо ФНС от 28 октября 2021 г. № ПА-4-20/15207@ «О переходе ККТ на ФФД 1.2»';
						|en = 'Letter of the Federal Tax Service dated October 28, 2021 No. PA-4-20/15207@ ""On migrating the cash register to FDF 1.2""'; fa = 'Letter of the Federal Tax Service dated October 28, 2021 No. PA-4-20/15207@ ""On migrating the cash register to FDF 1.2""';
						|it = 'Lettera del servizio fiscale federale del 28 ottobre 2021 № PA-4-20/15207@ ""Passaggio al registratore di cassa su FFD 1.2""';
						|pl = 'List FNS z dnia 28 października 2021 r. nr ПА-4-20/15207@ ""O przejściu kas fiskalnych na FFD 1.2»';
						|tr = '28 Ekim 2021 tarihli PA-4-20/15207@ numaralı ""Yazar kasaların FFD 1.2''ye geçişi hakkındaki"" FNS mektubu'"); 
				CommonCEL.MessageToUser(MessageText);
			EndIf;
		ElsIf CREParameters.Property("VersionFDFCRE") And CREParameters.VersionFDFCRE = "1.2" And ISMPProductsAreRecorded Then
			If Not CREParameters.SaleOfMarkedGoods Then
				MessageText = NStr("vi = 'KKT chưa được ghi nhận để làm việc với sản phẩm được dán nhãn.';
									|ru = 'ККТ не зарегистрирована для работы с маркированной продукцией.';
									|en = 'The cash register is not registered for marked product operations.'; fa = 'The cash register is not registered for marked product operations.';
									|it = 'ККТ не зарегистрирована для работы с маркированной продукцией.';
									|pl = 'The cash register is not registered for marked product operations.';
									|tr = 'Yazar kasa ekipmanları, etiketli ürünlerle çalışacak şekilde kaydedilmemiştir.'") + Chars.LF 
				+ NStr("vi = 'Cần đăng ký lại KKT.';
						|ru = 'Необходимо провести перерегистрацию ККТ.';
						|en = 'Re-register the cash register.'; fa = 'Re-register the cash register.';
						|it = 'Необходимо провести перерегистрацию ККТ.';
						|pl = 'Re-register the cash register.';
						|tr = 'Yazar kasa ekipmanları yeniden kaydedilmelidir.'"); 
				CommonCEL.MessageToUser(MessageText);
			EndIf;
		EndIf;
	Else
		CREParameters = PeripheralsReceiptPrintersClientServer.CRERegistrationParameters();
	EndIf;
	ExecutionResult.Insert("CREParameters" , CREParameters);     
	
	AfterOpeningCashShift(ConnectionParameters, ExecutionResult);

EndProcedure

Procedure ProcessCollection(OperationData)
	
	MethodParameters = New Array(1);
	MethodParameters[0] = OperationData;
	BackgroundJobs.Execute(
		"PeripheralsReceiptPrinters.ProcessCollectionInBackground",
		MethodParameters);

EndProcedure

Procedure ProcessCollectionInBackground(OperationData) Export
	
	Try
		// Record a fiscal transaction.
		RecordFiscalTransaction(OperationData);
	Except
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Ghi lại giao dịch tài chính chuyển tiền nội bộ';
				|ru = 'Запись фискальной операции инкассация';
				|en = 'Record fiscal transaction cash deposit/withdrawal'; fa = 'Record fiscal transaction cash deposit/withdrawal';
				|it = 'Record fiscal transaction cash deposit/withdrawal';
				|pl = 'Record fiscal transaction cash deposit/withdrawal';
				|tr = 'Nakit yatırma/çekme mali işlemi kaydı'"), 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;

EndProcedure

Procedure ProcessCCTParameters(InterfaceRevision, ConnectionParameters, ExecutionResult)
	
	CREParameters = ParametersFromXMLPackageCCT(ExecutionResult.CCTXMLParameters, InterfaceRevision);
	ExecutionResult.Insert("CREParameters" , CREParameters);
	
	SaveDeviceRegistrationSettings(ConnectionParameters.DeviceID, CREParameters);
	
EndProcedure


#EndRegion

Function BeforeOpeningCashShift(ConnectionParameters, OperationData) Export
	
	Result = True;                    
	
	If CashShiftsAreUsed() Then
		DescriptionOfCashShift = DescriptionOfLastCashShift(ConnectionParameters.DeviceID);
		If DescriptionOfCashShift <> Undefined And DescriptionOfCashShift.Status = Enums.CashRegisterShiftStatuses.IsOpen Then
			OperationData.Result = False;
			OperationData.ErrorText = NStr("vi = 'Đã mở phiên thu ngân.';
											|ru = 'Кассовая смена уже открыта.';
											|en = 'POS shift is already opened.'; fa = 'POS shift is already opened.';
											|it = 'Turno di cassa già aperto.';
											|pl = 'Zmiana kasy jest już otwarta.';
											|tr = 'Kasa vardiyası açık.'");
		EndIf;
	EndIf;
	
	Return Result;  
	
EndFunction

Function BeforeClosingCashShift(ConnectionParameters, OperationData) Export
	
	Result = True;
	
	If CashShiftsAreUsed() Then
		DescriptionOfCashShift = DescriptionOfLastCashShift(ConnectionParameters.DeviceID);
		If DescriptionOfCashShift = Undefined Then
			OperationData.CashRegisterShift = NewCashRegisterShift(ConnectionParameters.DeviceID, OperationData);
			DescriptionOfCashShift = DescriptionOfLastCashShift(ConnectionParameters.DeviceID);
		ElsIf DescriptionOfCashShift.Status = Enums.CashRegisterShiftStatuses.IsOpen Then
			OperationData.CashRegisterShift = DescriptionOfCashShift.CashRegisterShift;
		Else
			OperationData.Result = False;
			OperationData.ErrorText = NStr("vi = 'Đã đóng phiên thu ngân.';
											|ru = 'Кассовая смена уже закрыта.';
											|en = 'POS shift is already closed.'; fa = 'POS shift is already closed.';
											|it = 'Turno di cassa già chiuso.';
											|pl = 'Zmiana kasowa jest już zamknięta.';
											|tr = 'Kasa vardiyası kapalı.'");
		EndIf;
	EndIf;
	
	Return Result;  
	
EndFunction

Function AfterOpeningCashShift(ConnectionParameters, ExecutionResult) Export
	
	Result = True;
	
	CashRegisterShift = NewCashRegisterShift(ConnectionParameters.DeviceID, ExecutionResult);
	If Not ValueIsFilled(ExecutionResult.CashRegisterShift) Then
		ExecutionResult.CashRegisterShift = CashRegisterShift;
	EndIf;
	
	EquipmentManagerServerCallOverridable.AfterOpeningCashShift(ConnectionParameters.DeviceID, ExecutionResult);
	
	If CashShiftsAreUsed() Then
		CashShiftModule = CommonCEL.CommonModule("RegisterShifts");
		LastShiftStatus = CashShiftModule.LastShiftStatus(ConnectionParameters.DeviceID);
		ExecutionResult.Insert("LastShiftStatus", LastShiftStatus);
	EndIf;
	
	Return Result;
	
EndFunction

Function AfterCashShiftCloses(ConnectionParameters, ExecutionResult) Export
	
	Result = True;
	
	CloseRegisterShift(ExecutionResult); 
	
	EquipmentManagerServerCallOverridable.AfterCashShiftCloses(ConnectionParameters.DeviceID, ExecutionResult);
	
	If CashShiftsAreUsed() Then
		CashShiftModule = CommonCEL.CommonModule("RegisterShifts");
		LastShiftStatus = CashShiftModule.LastShiftStatus(ConnectionParameters.DeviceID);
		ExecutionResult.Insert("LastShiftStatus", LastShiftStatus);
	EndIf;
	
	Return Result;
	
EndFunction

Function XMLInfoReceiptPackage(Data, LineWidth_, InterfaceRevision) Export
	
	Template = FiscalDocumentTemplates.InfoReceiptTemplate(LineWidth_, Data);
	Text  = FiscalDocumentTemplates.OutputAsText(Template);
	
	Return PeripheralsReceiptPrinters.GetXMLPackageForText(Text, InterfaceRevision);
EndFunction

// ++ Non-mobile application

// Returns the period for storing payment transactions in the information register
//
// Returns:
//   EnumRef.RetentionPeriodOfTransactionHistory
Function PeriodOfStorageOfHistoryOfFiscalTransactions() Export
	
	StoragePeriod = Constants.RetentionPeriodOfFiscalTransactions.Get();
	Return StoragePeriod;
	
EndFunction

// Set the value of constants for the retention periods of operations in the information registers
//
Procedure SetRetentionPeriodForFiscalTransactions() Export 
	
	If Not ValueIsFilled(Constants.RetentionPeriodOfFiscalTransactions.Get()) Then
		Constants.RetentionPeriodOfFiscalTransactions.Set(Enums.RetentionPeriodOfTransactionHistory.AllTime);
	EndIf;
	
EndProcedure

#Region ScheduledJobs

// It is called from the routine taskdetermined procedure.When
// defining the settings of the scheduled tasks to set the availability of the scheduled task, determines the dependence on the functional options.
// 
// Parameters:
//  Settings - ValueTable
//  FunctionalOption - MetadataObjectFunctionalOption
Procedure OnDefineScheduledJobSettings(Settings, FunctionalOption = Undefined) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ClearHistoryOfFiscalTransactions;
	Setting.FunctionalOption = FunctionalOption;
	
EndProcedure

// Will clear the history of fiscal transactions
//
Procedure ClearHistoryOfFiscalTransactions(ClearDate) Export
	
	If ClearDate = Undefined Then
		Return;
	EndIf;
	
	InformationRegisters.FiscalTransactions.ClearRegisterBeforeDate(ClearDate);
	
EndProcedure

#EndRegion

// -- Non-mobile application

#EndRegion

#Region Private

#Region GeneratingCCTData

Procedure FillInDetailsOfPaymentOfOperations(CommonParameters)
	
	If CommonCEL.UsedPaymentSystems() Then  
		
		AdditionalUserDetails = CommonParameters.AdditionalUserDetails;
		
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");   
		PaymentTransactions = ModuleEquipmentPaymentSystems.PaymentOfOperationsData(Undefined, CommonParameters.DocumentBasis);
		
		If PaymentTransactions.Count() > 0 Then   
			
			Operation = PaymentTransactions[0]; // The first Operation, as part of a pilot project.
			// The prefix "epay" as a sign that the tag 1086 contains information specific for Transferring via a non-cash payment method;
			If Not IsBlankString(AdditionalUserDetails.Description) Then     
				AdditionalUserDetails.Description = String(AdditionalUserDetails.Description) + ";";
			EndIf;         
			AdditionalUserDetails.Description = String(AdditionalUserDetails.Description) + "epay";
			
			// In the 1086 tag, blocks of information are separated by the ";" symbol
			TransactionDateTime = Format(Operation.TransactionDateTime - Date(1970,1,1,1,0,0), "NG=0"); // Date and time in UnixTime format)  
			AttributeValue = StrTemplate("date=%1&rrn=%2&tid=%3&ps=%4&acq=%5&auth=%6&uuid=%7",
				TransactionDateTime, // Date and time of transaction initialization, contains the local date and time of transaction initialization UnixTime
				Operation.ReferenceNumber, // RNN is the ID of the bank transaction.
				Operation.TerminalId, // TID is the unique identification number of the POS terminal.
				Operation.PaymentSystemId, // PS is the unique identifier of the payment system through which the Operation was performed.
				Operation.AcquirerBankID, // ACQ is a unique identifier of the acquiring bank used on the POS terminal.
				Operation.AuthorizationCode, // AUTH is the authorization code assigned by the issuing bank.
				Operation.FiscalTransactionID); // UUID - A unique identifier of a banking transaction generated on the side of the issuing bank.
			If Not IsBlankString(AdditionalUserDetails.Value) Then   
				AdditionalUserDetails.Value = String(AdditionalUserDetails.Value) + ";";
			EndIf; 
			AdditionalUserDetails.Value = String(AdditionalUserDetails.Value) + AttributeValue;
			
		EndIf;   
		
	EndIf;
	
EndProcedure

// Replaces payment types during correction, used only for FFD 1.05
Procedure ReplacePaymentTypesDuringCorrection(CommonParameters, GeneralParametersOfStorno = Undefined)
	
	// It is necessary to change the type of payments to "Counter-delivery"	
	For Each ArrayElement In CommonParameters.TableOfPayment Do 
		ArrayElement.TypeOfPayment = Enums.CREPaymentTypes.Consideration;
	EndDo; 

	If GeneralParametersOfStorno = Undefined Then
		Return;
	EndIf;
	// It is necessary to change the type of payments to "Counter-delivery"	
	For Each ArrayElement In GeneralParametersOfStorno.TableOfPayment Do 
		ArrayElement.TypeOfPayment = Enums.CREPaymentTypes.Consideration;
	EndDo; 
	
EndProcedure

Procedure PrepareCorrectionReceipt(CommonParameters, GeneralParametersOfStorno, VersionFDFCRE11)
	
	// We change the sign of the calculation type to the opposite.
	If GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.CashReceipt Then
		GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.Refund;
	ElsIf GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.Refund Then
		GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.CashReceipt;
	ElsIf GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.CashOutflow Then
		GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.CashOutflowRefund;
	ElsIf GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.CashOutflowRefund Then
		GeneralParametersOfStorno.CalculationType = Enums.CashSettlementTypes.CashOutflow;
	EndIf;
	
EndProcedure


Function XMLAttributeValue(XMLReader, AttributeName, AddAttributeName = Undefined, DefaultValue = Undefined)
	
	Result = DefaultValue;
	If XMLReader.AttributeValue(AttributeName) <> Undefined Then  
		Result = XMLReader.AttributeValue(AttributeName);
	ElsIf Not IsBlankString(AddAttributeName) And XMLReader.AttributeValue(AddAttributeName) <> Undefined Then
		Result = XMLReader.AttributeValue(AddAttributeName);
	EndIf;
	
	Return Result; 
	
EndFunction

#EndRegion

#Region CashRegisterShift

// Returns True if the "Cash Changes" subsystem is used.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// At least one "functional" subsystem has the "Include in command interface" checkbox enabled.
//
// Returns:
//  Boolean
//
Function CashShiftsAreUsed()
	
	Return CommonCEL.CashShiftIsUsed();
	
EndFunction        

// For internal use
//
Function GetLastShiftStatus(DeviceID) 
	
	If CashShiftsAreUsed() Then
		CashShiftModule = CommonCEL.CommonModule("RegisterShifts");
		Return CashShiftModule.LastShiftStatus(DeviceID);
	Else
		OperationResult = New Structure();
		OperationResult.Insert("Active", True);
		OperationResult.Insert("IsOpen", True);
		OperationResult.Insert("CurReceiptNumber", 1); 
		OperationResult.Insert("CashRegisterShift", Undefined);
		Return OperationResult; 
	EndIf;
	
EndFunction

// For internal use
//
Function NewCashRegisterShift(FiscalDevice, OperationData) 
	
	If CashShiftsAreUsed() Then
		CashShiftModule = CommonCEL.CommonModule("RegisterShifts");
		Return CashShiftModule.NewCashRegisterShift(FiscalDevice, OperationData);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// For internal use
//
Procedure CloseRegisterShift(OperationData) 
	
	If CashShiftsAreUsed() Then
		CashShiftModule = CommonCEL.CommonModule("RegisterShifts");
		CashShiftModule.CloseRegisterShift(OperationData);
	EndIf;
	
EndProcedure

// For internal use
//
Function DescriptionOfLastCashShift(FiscalDevice) 
	
	If CashShiftsAreUsed() Then
		CashShiftModule = CommonCEL.CommonModule("RegisterShifts");
		Return CashShiftModule.DescriptionOfLastCashShift(FiscalDevice);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion