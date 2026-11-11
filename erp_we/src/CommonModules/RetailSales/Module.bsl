
#Region Public

#Region FiscalTransactions

// Initiate the data structure of the electronic check
// 
// Returns:
// 	Structure - Description: Electronic Receipt Data Structure
Function StructureOfFiscalTransactionData() Export
	
	FiscalOperationData = New Structure;
	FiscalOperationData.Insert("SendEmailViaOFD",          Constants.SendElectronicReceiptsByEmailViaFiscalDataOperator.Get());
	FiscalOperationData.Insert("SendSMSViaOFD",            Constants.SendElectronicReceiptsBySMSMessageViaFiscalDataOperator.Get());
	FiscalOperationData.Insert("DoNotPrintFiscalCheck",          GetFunctionalOption("DoNotPrintAFiscalSlipWhileSendingAnElectronicReceiptToACustomer"));
	FiscalOperationData.Insert("EmailSender");
	FiscalOperationData.Insert("OptionOfSendingElectronicReceipt");
	FiscalOperationData.Insert("ContactDetailsOfElectronicReceipt");
	
	ClearFiscalTransactionData(FiscalOperationData);
	
	Return FiscalOperationData;
	
EndFunction

Procedure ClearFiscalTransactionData(FiscalOperationData) Export
	
	FiscalOperationData.OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.EmptyRef();
	FiscalOperationData.ContactDetailsOfElectronicReceipt = "";
	
EndProcedure

// Returns the FFD CCT version
// 
// Parameters:
//  DeviceID - String - Device ID
// 
// Returns:
//  String -- FFDKKT version
Function VersionFDFCRE(DeviceID) Export
	
	DeviceRegistrationParameters = DeviceRegistrationParameters(DeviceID);
	
	FFDFNVersion = "";
	If TypeOf(DeviceRegistrationParameters) = Type("Structure")
		And DeviceRegistrationParameters.Property("FFDFNVersion") Then
		
		FFDFNVersion = DeviceRegistrationParameters.FFDFNVersion;
	EndIf;
	
	Return FFDFNVersion;
	
EndFunction

// Returns the status of whether it is possible to specify marked goods in the document without marking codes
// 
// Parameters:
//  DocumentRef - DocumentRef - Document link
// 
// Returns:
//  Boolean - True, marinated goods without stamps are allowed in the document
Function ProductsWithoutStampsInDocumentAreAllowed(DocumentRef) Export
	
	ProductsWithoutStampsAreAllowedForDocument = False;
	
	If TypeOf(DocumentRef) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
		Or TypeOf(DocumentRef) = Type("DocumentRef.CashRegisterReceiptReturn") Then
		
		ProductsWithoutStampsAreAllowedForDocument = True;
	EndIf;
	
	Return ProductsWithoutStampsAreAllowedForDocument;
	
EndFunction

// Returns the name of the trade object. If the Trade Object parameter is filled in, the name of the trade
// object is returned, otherwise the abbreviated name of the organization is returned.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  RetailFacility - CatalogRef.Warehouses, Undefined - Shopping facility
// 
// Returns:
//  Arbitrary - KKT Shopping Center
Function KktShoppingFacility(Organization, RetailFacility = Undefined) Export
	
	TradeObjectName = "";
	If ValueIsFilled(RetailFacility) Then
		TradeObjectName = Common.ObjectAttributeValue(RetailFacility, "Description");
	Else
		InformationAboutLegalEntity = PrintFormGeneration.InformationAboutLegalEntity(Organization, CurrentSessionDate());
		TradeObjectName = InformationAboutLegalEntity.NameAbbreviated;
	EndIf;
	
	Return TradeObjectName;
	
EndFunction

// Returns the place of KKT calculations.
// 
// Parameters:
//  CREEquipment - CatalogRef.Peripherals - KKT Equipment
// 
// Returns:
//  String - Place of KKT calculations
Function PlaceOfKKTCalculations(CREEquipment) Export
	
	TradeObjectPlaceOfSettlement = "";
	
	CRERegistrationParameters = PeripheralsReceiptPrinters.DeviceRegistrationParameters(CREEquipment);
	If TypeOf(CRERegistrationParameters) = Type("Structure") Then
		If CRERegistrationParameters.Property("CalculationPlace") Then
			TradeObjectPlaceOfSettlement = CRERegistrationParameters.CalculationPlace;
		EndIf;
	EndIf;
	
	Return TradeObjectPlaceOfSettlement;
	
EndFunction

// Returns the address of the KKT calculations. If the registration parameters of the cash register contain 
// the settlement address, then the settlement address is returned, otherwise the actual address of the organization is returned. 
// 
// Parameters:
//  CREEquipment - CatalogRef.Peripherals - KKT Equipment
//  Organization - CatalogRef.Companies - Organization
// 
// Returns:
//  String - Address of KKT calculations
Function AddressOfKKTCalculations(CREEquipment, Organization) Export
	
	ShoppingFacilitySettlementAddress = "";
	
	CRERegistrationParameters = PeripheralsReceiptPrinters.DeviceRegistrationParameters(CREEquipment);
	If TypeOf(CRERegistrationParameters) = Type("Structure") Then
		If CRERegistrationParameters.Property("AddressOfSettlementsConduction") Then
			ShoppingFacilitySettlementAddress = CRERegistrationParameters.AddressOfSettlementsConduction;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(ShoppingFacilitySettlementAddress) Then
		InformationAboutLegalEntity = PrintFormGeneration.InformationAboutLegalEntity(Organization, CurrentSessionDate());
		ShoppingFacilitySettlementAddress = InformationAboutLegalEntity.ActualAddress;
	EndIf;
	
	Return ShoppingFacilitySettlementAddress;
	
EndFunction

// Returns the unit code
// 
// Parameters:
//  UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure, String, Undefined - Unit
// 
// Returns:
//  String - Code of the unit of measurement of the receipt parameter
Function UnitCodeForReceiptParameter(UnitOfMeasure) Export
	
	UnitCode = "";
	
	If TypeOf(UnitOfMeasure) = Type("String")
		And UnitOfMeasure = "pcs." Then
		
		UnitCode = "796";
		
	ElsIf TypeOf(UnitOfMeasure) = Type("CatalogRef.PackagesAndUnitsOfMeasure")
		And Not UnitOfMeasure.IsEmpty() Then
		
		ClassifierUnitOfMeasurement = Common.ObjectAttributeValue(UnitOfMeasure, "UnitOfMeasure");
		If ClassifierUnitOfMeasurement.IsEmpty() Then
			ClassifierUnitOfMeasurement = UnitOfMeasure;
		EndIf;
		UnitCode = Common.ObjectAttributeValue(ClassifierUnitOfMeasurement, "Code");
		
	EndIf;
	
	If Not ValueIsFilled(UnitCode) Then
		UnitCode = "796";
	EndIf;
	
	Return TrimAll(UnitCode);
	
EndFunction

// Returns the citizenship of the buyer according to the passport.
// 
// Parameters:
//  Individual - CatalogRef.Persons - A natural person
//  OnDate - Date, Undefined - On the date
// 
// Returns:
//  CatalogRef.WorldCountries - buyer's nationality
Function BuyerCitizenship(Individual, OnDate = Undefined) Export
	
	BuyerCitizenship = Catalogs.WorldCountries.EmptyRef();
	OnDate = ?(OnDate = Undefined, CurrentSessionDate(), OnDate);
	
	InteriorMinistryCodes = New Array;
	InteriorMinistryCodes.Add("10");
	InteriorMinistryCodes.Add("21");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentKindsOfPersons.Ref AS Ref
	|INTO DocumentKindsOfPersons
	|FROM
	|	Catalog.DocumentKindsOfPersons AS DocumentKindsOfPersons
	|WHERE
	|	DocumentKindsOfPersons.FTSCode IN(&InteriorMinistryCodes)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DocumentsPersonsSliceLast.CountryOfIssue AS Country
	|FROM
	|	InformationRegister.DocumentsPersons.SliceLast(&SliceDate, Person = &Person) AS DocumentsPersonsSliceLast
	|		INNER JOIN DocumentKindsOfPersons AS DocumentKindsOfPersons
	|		ON DocumentsPersonsSliceLast.DocumentKind = DocumentKindsOfPersons.Ref";
	Query.SetParameter("SliceDate", EndOfDay(OnDate));
	Query.SetParameter("Person", Individual);
	Query.SetParameter("InteriorMinistryCodes", InteriorMinistryCodes);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		BuyerCitizenship = Selection.Country;
	EndIf;
	
	Return BuyerCitizenship;
	
EndFunction

// Returns the date of birth of an individual
// 
// Parameters:
//  Individual - CatalogRef.Persons - A natural person
// 
// Returns:
//  String - buyer's date of birth
Function BuyerDateOfBirth(Individual) Export
	
	Return TrimAll(Common.ObjectAttributeValue(Individual, "BirthDate"));
	
EndFunction

// Returns the TIN of an individual
// 
// Parameters:
//  Individual - CatalogRef.Persons - A natural person
// 
// Returns:
//  String - Buyer's INN
Function BuyerTin(Individual) Export
	
	Return TrimAll(Common.ObjectAttributeValue(Individual, "TIN"));
	
EndFunction

// Returns the passport data of the buyer in one line.
// 
// Parameters:
//  Individual - CatalogRef.Persons - A natural person
//  OnDate - Date, Undefined - On the date
// 
// Returns:
//  String - passport details of the buyer
Function BuyerPassportData(Individual, OnDate = Undefined) Export
	
	CustomerPersonalData = "";
	OnDate = ?(OnDate = Undefined, CurrentSessionDate(), OnDate);
	
	InteriorMinistryCodes = New Array;
	InteriorMinistryCodes.Add("10");
	InteriorMinistryCodes.Add("21");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentKindsOfPersons.Ref AS Ref
	|INTO DocumentKindsOfPersons
	|FROM
	|	Catalog.DocumentKindsOfPersons AS DocumentKindsOfPersons
	|WHERE
	|	DocumentKindsOfPersons.FTSCode IN(&InteriorMinistryCodes)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DocumentsPersonsSliceLast.Period AS Period,
	|	DocumentsPersonsSliceLast.Person AS Person,
	|	DocumentsPersonsSliceLast.DocumentKind AS DocumentKind,
	|	DocumentsPersonsSliceLast.Series AS Series,
	|	DocumentsPersonsSliceLast.Number AS Number,
	|	DocumentsPersonsSliceLast.DateOfIssue1 AS DateOfIssue1,
	|	DocumentsPersonsSliceLast.ValidityPeriod AS ValidityPeriod,
	|	DocumentsPersonsSliceLast.IssuedBy AS IssuedBy,
	|	DocumentsPersonsSliceLast.BusinessUnitCode AS BusinessUnitCode,
	|	DocumentsPersonsSliceLast.ThisIsAnIdentityDocument AS ThisIsAnIdentityDocument,
	|	DocumentsPersonsSliceLast.Presentation AS Presentation,
	|	DocumentsPersonsSliceLast.DeleteDocumentKind AS DeleteDocumentKind,
	|	DocumentsPersonsSliceLast.LastNameInLatin AS LastNameInLatin,
	|	DocumentsPersonsSliceLast.NameInLatin AS NameInLatin,
	|	DocumentsPersonsSliceLast.CountryOfIssue AS CountryOfIssue
	|FROM
	|	InformationRegister.DocumentsPersons.SliceLast(&SliceDate, Person = &Person) AS DocumentsPersonsSliceLast
	|		INNER JOIN DocumentKindsOfPersons AS DocumentKindsOfPersons
	|		ON DocumentsPersonsSliceLast.DocumentKind = DocumentKindsOfPersons.Ref";
	Query.SetParameter("SliceDate", EndOfDay(OnDate));
	Query.SetParameter("Person", Individual);
	Query.SetParameter("InteriorMinistryCodes", InteriorMinistryCodes);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		CustomerPersonalData = TrimAll(Selection.Series) + " " + TrimAll(Selection.Number) + " " + TrimAll(Selection.IssuedBy)
			+ " " + Format(Selection.DateOfIssue1, NStr("vi = 'ДФ=дд.ММ.гггг';
														|ru = 'ДФ=dd.MM.yyyy';
														|en = 'DF=MM/dd/yyyy'; fa = 'DF=MM/dd/yyyy';
														|it = 'ДФ=дд.ММ.гггг';
														|pl = 'DF=dd.MM.yyyy';
														|tr = 'DF=dd.MM.yyyy'")) + " " + Format(Selection.ValidityPeriod, NStr("vi = 'ДФ=дд.ММ.гггг';
																																|ru = 'ДФ=dd.MM.yyyy';
																																|en = 'DF=MM/dd/yyyy'; fa = 'DF=MM/dd/yyyy';
																																|it = 'ДФ=дд.ММ.гггг';
																																|pl = 'DF=dd.MM.yyyy';
																																|tr = 'DF=dd.MM.yyyy'"));
	EndIf;
	
	Return CustomerPersonalData;
	
EndFunction

// Returns the status of whether the buyer is an individual.
// 
// Parameters:
//  Counterparty - CatalogRef.Counterparties - Counterparty
// 
// Returns:
//  Boolean - True if the buyer is an individual
Function BuyerIndividual(Counterparty) Export
	
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Counterparty, "LegalEntityIndividual");
	Return CounterpartyLegEntInd = Enums.LegalEntityIndividual.Person;
	
EndFunction

// Returns Cash register warehouses with a hierarchy
// 
// Parameters:
//  CashRegisters - Array of CatalogRef.CashRegisters - Cash registers
// 
// Returns:
//  Array of CatalogRef.Warehouses
Function WarehousesOfCashAccountsOfKKMVHierarchy(CashRegisters) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Warehouses.Ref AS Warehouse
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|
	|	INNER JOIN Catalog.CashRegisters AS CashRegisters
	|	ON CashRegisters.Warehouse = Warehouses.Ref
	|		AND CashRegisters.Ref IN (&CashRegisters)
	|		AND CashRegisters.CashRegisterType = &CashAccountTypeFiscalCashRegister";
	Query.SetParameter("CashRegisters", CashRegisters);
	Query.SetParameter("CashAccountTypeFiscalCashRegister", Enums.CashRegisterTypes.FiscalCashRegisters);
	
	Return CashAccountWarehousesWithParentsInHierarchy(Query.Execute().Unload().UnloadColumn("Warehouse"));
	
EndFunction

// Returns Cash register warehouses with a hierarchy
// 
// Parameters:
//  Warehouses - Array of CatalogRef.Warehouses - Warehouses
// 
// Returns:
//  Array of CatalogRef.Warehouses
Function CashAccountWarehousesWithParentsInHierarchy(Warehouses) Export
	
	CashRegisterCashAccountDepots = Warehouses;
	
	Parents = Common.ObjectsAttributesValues(CashRegisterCashAccountDepots, "Parent");
	
	ArrayOfParentsToProcess = New Array;
	For Each ParentValue In Parents Do
		If ValueIsFilled(ParentValue.Value.Parent) Then
			ArrayOfParentsToProcess.Add(ParentValue.Value.Parent);
			CashRegisterCashAccountDepots.Add(ParentValue.Value.Parent);
		EndIf;
	EndDo;
	
	While ArrayOfParentsToProcess.Count() > 0 Do
		
		Parents = Common.ObjectsAttributesValues(ArrayOfParentsToProcess, "Parent");
		ArrayOfParentsToProcess.Clear();
		
		For Each ParentValue In Parents Do
			If ValueIsFilled(ParentValue.Value.Parent) Then
				ArrayOfParentsToProcess.Add(ParentValue.Value.Parent);
				CashRegisterCashAccountDepots.Add(ParentValue.Value.Parent);
			EndIf;
		EndDo;
		
	EndDo;
	
	Return CashRegisterCashAccountDepots;
	
EndFunction

// Returns the warehouse hierarchy
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses - Warehouses
// 
// Returns:
//  Array of CatalogRef.Warehouses
Function WarehouseInHierarchy(Warehouse) Export
	
	Warehouses = New Array;
	Warehouses.Add(Warehouse);
	
	If Not ValueIsFilled(Warehouse) Then
		Return Warehouses;
	EndIf;
	
	Warehouses = CashAccountWarehousesWithParentsInHierarchy(Warehouses);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Warehouses.Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY (&Warehouse)";
	Query.SetParameter("Warehouse", Warehouse);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Warehouses.Find(Selection.Ref) = Undefined Then
			Warehouses.Add(Selection.Ref);
		EndIf;
	EndDo;
	
	Return Warehouses;
	
EndFunction

// Records the form object, 
// 
// Parameters:
//  Form - ManagedFormExtensionForObjects -
//  FiscalizationParameters - Structure -
//  WriteParameters - Structure -
//  
// Returns:
//  Boolean - 
//
Function RecordFiscalTransactionOnServer(Form, FiscalizationParameters, WriteParameters) Export
	
	DocumentWrittenSuccessfully = True;
	Result = True;
	SetPrivilegedMode(True);
	
	Object = Form.Object; // DocumentObject
	Object.Date = CurrentSessionDate();
	
	ObjectMetadata = Object.Ref.Metadata();
	ThisIsCashRegisterCorrectionReceipt = (TypeOf(Object.Ref) = Type("DocumentRef.ReceiptOfCashRegisterAdjustment"));
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add();
		LockItem.Region = ObjectMetadata.FullName();
		LockItem.Mode = DataLockMode.Exclusive;
		If TypeOf(Object.Ref) = Type("DocumentRef.ReturnOfGiftCards")
			Or TypeOf(Object.Ref) = Type("DocumentRef.GiftCertificateSale") Then
				LockItem.Mode = DataLockMode.Shared;
		EndIf;
		LockItem.SetValue("Ref", Object.Ref);
		
		NeedToRecordFiscalOperation = False;
		NeedToRecordFiscalCorrectionOperation = False;
		If FiscalizationParameters <> Undefined Then
			If Not FiscalizationParameters.OperationRecorded Then
				NeedToRecordFiscalOperation = True;
				If ValueIsFilled(FiscalizationParameters.DocumentBasis) Then
					LockItem = Block.Add();
					LockItem.Region = "InformationRegister.FiscalTransactions";
					
					LockItem.Mode = DataLockMode.Exclusive;
					If TypeOf(Object.Ref) = Type("DocumentRef.ReturnOfGiftCards")
						Or TypeOf(Object.Ref) = Type("DocumentRef.GiftCertificateSale") Then
							LockItem.Mode = DataLockMode.Shared;
					EndIf;
					
					LockItem.SetValue("DocumentBasis", FiscalizationParameters.DocumentBasis);
				EndIf;
			EndIf;
			If ThisIsCashRegisterCorrectionReceipt = True
				And FiscalizationParameters.Property("ReverseCorrectionCheck") 
				And ValueIsFilled(FiscalizationParameters.ReverseCorrectionCheck)
				And Not FiscalizationParameters.ReverseCorrectionCheck.OperationRecorded Then
					NeedToRecordFiscalCorrectionOperation = True;
					If ValueIsFilled(FiscalizationParameters.ReverseCorrectionCheck.DocumentBasis) Then
						LockItem = Block.Add();
						LockItem.Region = "InformationRegister.FiscalTransactions";
						LockItem.Mode = DataLockMode.Exclusive;
						LockItem.SetValue("DocumentBasis", FiscalizationParameters.ReverseCorrectionCheck.DocumentBasis);
					EndIf;
			EndIf;

		EndIf;
		
		Block.Lock();
		
		If NeedToRecordFiscalOperation Then
			EquipmentReceiptPrintersServerCall.RecordFiscalTransaction(FiscalizationParameters);
		EndIf;
		
		If NeedToRecordFiscalCorrectionOperation Then
			EquipmentReceiptPrintersServerCall.RecordFiscalTransaction(FiscalizationParameters.ReverseCorrectionCheck);
		EndIf;
		
		If TypeOf(WriteParameters) <> Type("Structure") 
			Or WriteParameters.Count() = 0 Then
			WriteParameters = New Structure;
			WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
			WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
			WriteParameters.Insert("TransactionMode", True);
		EndIf;
		
		DocumentWrittenSuccessfully = Form.Write(WriteParameters);
		
		RetailSalesLocalization.RecordFiscalTransaction(Form, FiscalizationParameters, WriteParameters, DocumentWrittenSuccessfully);
		
		If Not DocumentWrittenSuccessfully Then
			If ThisIsCashRegisterCorrectionReceipt Then
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể ghi lại chứng từ: %1';
																								|ru = 'Не удалось записать документ: %1';
																								|en = 'Cannot save the document: %1'; fa = 'Cannot save the document: %1';
																								|it = 'Non è stato possibile salvare il documento: %1';
																								|pl = 'Nie udało się zapisać dokument: %1';
																								|tr = 'Belge kaydedilemedi: %1'"), Object.Ref);
				Raise ErrorDescription;
			Else
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã ghi lại dữ liệu của giao dịch tài chính, không thể ghi lại chứng từ: %1';
																								|ru = 'Данные фискальной операции записаны, не удалось записать документ: %1';
																								|en = 'Fiscal transaction data is not saved. Cannot save the document: %1'; fa = 'Fiscal transaction data is not saved. Cannot save the document: %1';
																								|it = 'Dati dell''operazione fiscale bloccati, non è stato possibile bloccare il documento: %1';
																								|pl = 'Dane operacji fiskalnej są zapisane, nie udało się zapisać dokumentu: %1';
																								|tr = 'Mali işlem verileri kaydedildi, belge kaydedilemedi: %1'"), Object.Ref);
				WriteLogEvent(NStr("vi = 'Bán lẻ';
									|ru = 'Розничные продажи';
									|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
									|it = 'Vendite al dettaglio';
									|pl = 'Sprzedaże detaliczne';
									|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
			EndIf;
		EndIf;
		
		CommitTransaction();
		
	Except
		ErrorInfo = ErrorInfo();
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		ArrayOfErrorDescriptionLines = New Array();
		If Not DocumentWrittenSuccessfully And ThisIsCashRegisterCorrectionReceipt Then
			ArrayOfErrorDescriptionLines.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Else
			ArrayOfErrorDescriptionLines.Add(NStr("vi = 'Khi ghi lại chứng từ %1, đã xảy ra lỗi.';
													|ru = 'При записи документа %1 произошла ошибка.';
													|en = 'An error occurred when saving the %1 document.'; fa = 'An error occurred when saving the %1 document.';
													|it = 'Durante il blocco del documento %1 si è verificato un errore.';
													|pl = 'Podczas zapisu dokumentu %1 wystąpił błąd.';
													|tr = '%1belgesi kaydedilirken bir hata oluştu.'"));
		EndIf;
		If NeedToRecordFiscalOperation Then
			ArrayOfErrorDescriptionLines.Add(NStr("vi = 'Chưa ghi lại dữ liệu của giao dịch tài chính.';
													|ru = 'Данные фискальной операции не записаны.';
													|en = 'Fiscal transaction data is not saved.'; fa = 'Fiscal transaction data is not saved.';
													|it = 'I dati dell''operazione fiscale non sono bloccati.';
													|pl = 'Dane operacji fiskalnej nie zostały zapisane.';
													|tr = 'Mali işlem verileri kaydedilemedi.'"));
		EndIf;
		If NeedToRecordFiscalCorrectionOperation Then
			ArrayOfErrorDescriptionLines.Add(NStr("vi = 'Chưa ghi lại dữ liệu đảo ngược giao dịch tài chính.';
													|ru = 'Данные сторно фискальной операции не записаны.';
													|en = 'Fiscal transaction storno data is not saved.'; fa = 'Fiscal transaction storno data is not saved.';
													|it = 'I dati di storno dell''operazione fiscale non sono bloccati.';
													|pl = 'Dane storno operacji fiskalnej nie zostały zapisane.';
													|tr = 'Mali işlemle ilgili herhangi bir iptal kaydı yapılamadı.'"));
		EndIf;
		If DocumentWrittenSuccessfully Or Not ThisIsCashRegisterCorrectionReceipt Then
			ArrayOfErrorDescriptionLines.Add(NStr("vi = 'Mô tả bổ sung:
							|%2';
							|ru = 'Дополнительное описание:
							|%2';
							|en = 'Additional details:
							|%2'; fa = 'Additional details:
							|%2';
							|it = 'Descrizione aggiuntiva:
							|%2';
							|pl = 'Opis dodatkowy:
							|%2';
							|tr = 'Ek ayrıntılar:
							|%2'"));
		EndIf;
		ErrorDescription = StrConcat(ArrayOfErrorDescriptionLines, Chars.LF);
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorDescription, Object.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
		
		Result = False;
	EndTry;
	
	Return Result;
EndFunction

#EndRegion

#Region ProceduresForMakingAndWithdrawingCash

// Creates a document for depositing monetary funds in a cash register.
//
// Parameters:
//  InputData - Structure - Data structure with the details of the document being created.
//
// Returns:
//  DocumentRef.DepositCashIntoCashRegister - The created document.
//
Function CreateDocumentDepositingFundsToCashRegister(InputData) Export
	
	NewDocument = Documents.DepositCashIntoCashRegister.CreateDocument();
	
	NewDocument.Date              = CurrentSessionDate();
	NewDocument.Organization       = InputData.Organization;
	NewDocument.CashAccount             = InputData.CashAccount;
	NewDocument.CashRegister          = InputData.CashRegister;
	NewDocument.DocumentAmount    = InputData.DocumentAmount;
	NewDocument.Currency            = InputData.Currency;
	NewDocument.DocumentBasis = InputData.DocumentBasis;
	NewDocument.Cashier            = Users.CurrentUser();
	
	NewDocument.Organization = SettingsValueCached.GetDefaultOrganization(NewDocument.Organization);
	NewDocument.Write(DocumentWriteMode.Posting);
	
	Return NewDocument.Ref;
	
EndFunction

// Creates the document dredging the cash funds from the cash register.
//
// Parameters:
//  InputData - Structure - Data structure with the details of the document being created.
//
// Returns:
//  DocumentRef.CashWithdrawalFromCashRegister - The created document.
//
Function CreateDocumentWithdrawalOfFundsFromCashRegisterCashRegister(InputData) Export
	
	NewDocument = Documents.CashWithdrawalFromCashRegister.CreateDocument();
	
	NewDocument.Date           = CurrentSessionDate();
	NewDocument.Organization    = InputData.Organization;
	NewDocument.Currency         = InputData.Currency;
	NewDocument.CashRegister       = InputData.CashRegister;
	NewDocument.DocumentAmount = InputData.DocumentAmount;
	NewDocument.Cashier         = Users.CurrentUser();
	
	NewDocument.Organization = SettingsValueCached.GetDefaultOrganization(NewDocument.Organization);
	NewDocument.Write(DocumentWriteMode.Posting);
	
	Return NewDocument.Ref;
	
EndFunction

#EndRegion

#Region Other

// To rearrange the buttons of the form
//
// Parameters:
//  Form - ClientApplicationForm - Form
//  ElementsToRegroup - Array of FormButton - Array of form elements to regroup.
//
Procedure RearrangeFormButtons(Form, ElementsToRegroup) Export
	
	Map = New Map;
	Map.Insert("GroupBottomCommandMenuBarReceiptOperations",   New Array);
	Map.Insert("GroupBottomCommandBarContextCommands", New Array);
	Map.Insert("GroupBottomCommandBarPayment",             New Array);
	
	DeletedItems = New Array;
	For Each Item In ElementsToRegroup Do
		If DeletedItems.Find(ElementsToRegroup.Find(Item)) <> Undefined Then
			Continue;
		EndIf;
		// Deleting previously added form elements
		Decoration = Form.Items.Find(Item.Name + "Decoration" + "Duplicate1");
		If Decoration <> Undefined Then
			IndexOf = ElementsToRegroup.Find(Decoration);
			If IndexOf <> Undefined Then
				DeletedItems.Add(IndexOf);
			EndIf;
			Form.Items.Delete(Decoration);
		EndIf;
		If StrEndsWith(Item.Name, "SceneryDouble") Then
			Form.Items.Delete(Item);
			Continue;
		EndIf;
		For Each KeyAndValue In Map Do
			If Find(Item.Parent.Name, KeyAndValue.Key) Then
				KeyAndValue.Value.Add(Item);
			EndIf;
		EndDo;
	EndDo;
	
	For Each KeyAndValue In Map Do
	
		IndexOf = 0;
		NumberOfGroup = 1;
		ChangedElements = False;
		For Each Item In KeyAndValue.Value Do
			
			Form.Items.Move(Item, Form.Items[KeyAndValue.Key + NumberOfGroup]);
			
			If Not Item.Visible Then
				Continue;
			EndIf;
			
			ChangedElements = True;
			IndexOf = 1 - IndexOf;
			If IndexOf = 0 Then
				NumberOfGroup = NumberOfGroup + 1;
			EndIf;
			
		EndDo;
		
		If ChangedElements And IndexOf = 1 Then
			CreatedElement = AddItem(Form, Item.Name + "SceneryDouble", KeyAndValue.Key, NumberOfGroup);
			CreatedElement.CommandName = Item.CommandName;
			CreatedElement.Width = Item.Width;
			CreatedElement.Height = Item.Height;
			CreatedElement.BackColor = Item.BackColor;
			CreatedElement.Visible = True;
			CreatedElement.Enabled = False;
			CreatedElement.Title = " ";
		EndIf;
		
		If Not ChangedElements Then
			Delta = 0;
		Else
			Delta = 1;
		EndIf;
		
		If NumberOfGroup < 4 Then
			For IndexOf = NumberOfGroup + Delta To 4 Do
				TagName = KeyAndValue.Key + IndexOf;
				If TMCommonUseClientServer.HasObjectAttribute(Form.Items, TagName) Then
					Form.Items[TagName].Visible = False;
				EndIf;
			EndDo;
		EndIf;
		
		If NumberOfGroup + Delta = 1 Then
			If KeyAndValue.Key = "GroupBottomCommandMenuBarReceiptOperations" Then
				TagName = "SeparatorGroupLowerCommandPanelOperationsOnCheck";
			ElsIf KeyAndValue.Key = "GroupBottomCommandBarContextCommands" Then
				TagName = "SeparatorGroupBottomCommandPanelContextCommands";
			ElsIf KeyAndValue.Key = "GroupBottomCommandBarPayment" Then
				TagName = "SeparatorGroupBottomCommandPanelPayment";
			EndIf;
			If TMCommonUseClientServer.HasObjectAttribute(Form.Items, TagName) Then
				Form.Items[TagName].Visible = False;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PutPrintCommandsInAllActions(FormGroup, PrintButtons)
	
	For Each PrintButton In FormGroup.ChildItems Do
		If TypeOf(PrintButton) = Type("FormGroup") Then
			PutPrintCommandsInAllActions(PrintButton, PrintButtons);
		Else
			PrintButtons.Add(PrintButton);
			PrintButton.Visible = False;
		EndIf;
	EndDo;
	
EndProcedure

// To configure the print command
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  CommandGroup - CommandGroup
//
Procedure ConfigurePrintCommands(Form, CommandGroup) Export
	
	PrintButtons = New Array;
	PutPrintCommandsInAllActions(CommandGroup, PrintButtons);
	
	PrintCommands = New Array;
	For Each PrintButton In PrintButtons Do
		FormCommand = Form.Commands[PrintButton.CommandName]; // FormCommand
		PrintCommands.Add(
			New Structure("Title, CommandName", FormCommand.Title, PrintButton.CommandName));
	EndDo;
	Form.PrintCommandAddressInTheTemporaryStorage = PutToTempStorage(PrintCommands, Form.UUID);
	
EndProcedure

// Set up quick products and keyboard shortcuts
//
// Parameters:
//  Form - ClientApplicationForm
//  Selection - QueryResultSelection
//
Procedure ConfigureQuickItemsAndHotkeys(Form, Selection) Export
	
	If Form.HotkeysAreConfigured Then
		Return;
	EndIf;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "QuickGoods")
		And Form.QuickGoods.Count() = 0 Then
		
		SamplingQuickProducts = Selection.QuickGoods; // ValueStorage
		QuickGoods = SamplingQuickProducts.Get(); // ValueTable - See Catalogs.KeyboardShortcuts.NewCommand.Table
		
		If QuickGoods.Count() > 0 Then
			
			For Each TSRow In QuickGoods Do
				
				If ValueIsFilled(TSRow.Products) Then
					
					ButtonName = "QuickProduct_" + QuickGoods.IndexOf(TSRow);
					
					NewCommand = Form.ThisObject.Commands.Add(ButtonName);
					NewCommand.Action = "QuickProductSelected";
					If ValueIsFilled(TSRow.Title) Then
						NewCommand.Title = TSRow.Title;
					Else
						NewCommand.Title = String(TSRow.Products);
					EndIf;
					NewCommand.Representation               = ButtonRepresentation.Text;
					NewCommand.ModifiesStoredData = True;
					NewCommand.Shortcut           = New Shortcut(Key[TSRow.Key], TSRow.Alt, TSRow.Ctrl, TSRow.Shift);
					
					NewButton = Form.Items.Add(ButtonName, Type("FormButton"), Form.Items.FormKeyboardShortcutsQuickGoods);
					NewButton.OnlyInAllActions = True;
					NewButton.CommandName = NewCommand.Name;
					
					NewProduct_ = Form.QuickGoods.Add();
					FillPropertyValues(NewProduct_, TSRow);
					NewProduct_.CommandName = NewCommand.Name;
					
				EndIf;
				
			EndDo;
			
			RequestMoreInformationAboutFastProducts = New Query(
			"SELECT
			|	Goods.Products AS Products
			|INTO Goods
			|FROM
			|	&Goods AS Goods
			|;
			|SELECT
			|	Goods.Products AS Products,
			|	CatalogProducts.ItemsType AS ItemsType
			|FROM
			|	Goods AS Goods
			|		LEFT JOIN Catalog.Products AS CatalogProducts
			|		ON Goods.Products = CatalogProducts.Ref");
			
			RequestMoreInformationAboutFastProducts.SetParameter("Goods", Form.QuickGoods.Unload(,"Products"));
			
			SampleAdditionalDataAboutFastProducts = RequestMoreInformationAboutFastProducts.Execute().Select();
			
			While SampleAdditionalDataAboutFastProducts.Next() Do
				
				Filter = New Structure("Products", SampleAdditionalDataAboutFastProducts.Products);
				FoundAndFastProducts = Form.QuickGoods.FindRows(Filter);
				For Each QuickProductLine In FoundAndFastProducts Do
					QuickProductLine.ItemsType = SampleAdditionalDataAboutFastProducts.ItemsType;
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	FormElementsWithCommands = New ValueTable;
	FormElementsWithCommands.Columns.Add("Item");
	FormElementsWithCommands.Columns.Add("CommandName");
	For Each FormItem In Form.Items Do
		If TMCommonUseClientServer.HasObjectAttribute(FormItem, "CommandName") And ValueIsFilled(FormItem.CommandName) Then
			NewRow = FormElementsWithCommands.Add();
			NewRow.Item = FormItem;
			NewRow.CommandName = FormItem.CommandName;
		EndIf;
	EndDo;
	
	FormCommandSelection = Selection.FormCommands; // ValueStorage
	FormCommands = FormCommandSelection.Get(); // ValueTable - See Catalogs.KeyboardShortcuts.NewCommand.Table
	For Each TSRow In FormCommands Do
		
		Command = Form.Commands.Find(TSRow.Command);
		If Command = Undefined Then
			Continue;
		EndIf;
		
		NewKeyboardShortcut = New Shortcut(Key[TSRow.Key], TSRow.Alt, TSRow.Ctrl, TSRow.Shift);
		OldKeyboardShortcutPresentation = TMCommonUse.KeyboardShortcutPresentation(Command.Shortcut);
		NewKeyboardShortcutPresentation  = TMCommonUse.KeyboardShortcutPresentation(NewKeyboardShortcut);
		
		NewCommand = Command;
		If NewKeyboardShortcutPresentation <> OldKeyboardShortcutPresentation Then
			
			NewCommand = Form.ThisObject.Commands.Add(TSRow.Command + StrReplace(New UUID, "-", "_"));
			NewCommand.Action                  = Command.Action;
			NewCommand.ModifiesStoredData = Command.ModifiesStoredData;
			NewCommand.Picture                  = Command.Picture;
			NewCommand.Representation               = Command.Representation;
			NewCommand.ToolTip                 = Command.ToolTip;
			NewCommand.Title                 = StrReplace(Command.Title, OldKeyboardShortcutPresentation, NewKeyboardShortcutPresentation);
			NewCommand.Shortcut           = NewKeyboardShortcut;
			
			FoundFormElements = FormElementsWithCommands.FindRows(New Structure("CommandName", Command.Name));
			For Each FormItem In FoundFormElements Do
				FormItem.CommandName = NewCommand.Name;
				FormItem.Item.CommandName = NewCommand.Name;
			EndDo;
			
		EndIf;
		
		If TSRow.Hide_2 Then
			
			FoundFormElements = FormElementsWithCommands.FindRows(New Structure("CommandName", Command.Name));
			For Each FormItem In FoundFormElements Do
				FormItem.Item.Visible = False;
			EndDo;
			
			ButtonName = "Hotkey_" + FormCommands.IndexOf(TSRow);
			
			NewButton = Form.Items.Add(ButtonName, Type("FormButton"), Form.Items.FormKeyboardShortcuts);
			NewButton.OnlyInAllActions = True;
			NewButton.CommandName = NewCommand.Name;
			NewCommand.Title = StrReplace(Command.Title, OldKeyboardShortcutPresentation, "");
			NewCommand.Title = TrimAll(NewCommand.Title);
			
		EndIf;
		
	EndDo;
	
	Form.HotkeysAreConfigured = True;
	
EndProcedure

// The procedure to Sign the hotkeys on the buttons
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//
Procedure SignHotkeysOnButtons(Form) Export
	
	For Each Command In Form.Commands Do
		SignHotkeyOnButton(Command);
	EndDo;
	
EndProcedure

// The procedure is to sign a combination of hotkeys on the button
//
// Parameters:
//  Command - MetadataObjectCommand - form command.
//
Procedure SignHotkeyOnButton(Command) Export
	
	KeyboardShortcutPresentation = TMCommonUse.KeyboardShortcutPresentation(Command.Shortcut);
	If StrFind(Command.Title, KeyboardShortcutPresentation) = 0 Then
		Command.Title = Command.Title + Chars.LF + KeyboardShortcutPresentation;
	EndIf;
	
EndProcedure

// Returns a link to the document Report on Retail Sales by receipt
//
// Parameters:
//  CashRegisterReceipt  - DocumentRef.CashRegisterReceipt - The CMC receipt for which you want to get a report on retail sales.
//
// Returns:
//   DocumentRef.RetailSalesReport - A found document or an empty link to a retail sales report.
//
Function GetReportOnRetailSalesByCashRegisterReceipt(CashRegisterReceipt) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	RetailSalesReport.Ref AS DocumentSalesOfGoodsAndServices
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|		LEFT JOIN Document.RetailSalesReport AS RetailSalesReport
	|		ON CashRegisterReceipt.CashRegisterShift = RetailSalesReport.CashRegisterShift
	|WHERE
	|	CashRegisterReceipt.Ref = &Ref
	|	AND CashRegisterReceipt.VATTaxation =  RetailSalesReport.VATTaxation";
	
	Query.SetParameter("Ref", CashRegisterReceipt);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.DocumentSalesOfGoodsAndServices;
	Else
		Return Documents.RetailSalesReport.EmptyRef();
	EndIf;
	
EndFunction

// The procedure checks that the tabular part of the "Paymentpayable Cards" is filled in.
//
// Parameters:
//  Object - DocumentObject - Current document.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure CheckPaymentCompletionWithPaymentCards(Object, Cancel) Export
	
	DataKey = Object;
	If Object.AdditionalProperties.Property("SoftwareFilling") And Object.AdditionalProperties.SoftwareFilling = True Then
		DataKey = Undefined;
	EndIf;
	
	NameOfTabularPartPaymentByPaymentCards = Object.Metadata().TabularSections.PaymentWithPaymentCards.Synonym;
	
	For Each TSRow In Object.PaymentWithPaymentCards Do
		
		If (TypeOf(Object) = Type("DocumentObject.RetailReturnsReport")
			Or TypeOf(Object) = Type("DocumentObject.RetailSalesReport"))
			And Not ValueIsFilled(TSRow.PaymentKind_) Then
			
			Text = NStr("vi = 'Trong dòng %LineNumber% phần bảng ""%TabularSectionName%"", cần chỉ ra dạng thanh toán.';
						|ru = 'В строке %LineNumber% табличной части ""%TabularSectionName%"" необходимо указать вид оплаты.';
						|en = 'In line %LineNumber% of the %TabularSectionName% table, enter the payment kind.'; fa = 'In line %LineNumber% of the %TabularSectionName% table, enter the payment kind.';
						|it = 'В строке %LineNumber% табличной части ""%TabularSectionName%"" необходимо указать вид оплаты.';
						|pl = 'In line %LineNumber% of the %TabularSectionName% table, enter the payment kind.';
						|tr = '""%TabularSectionName%"" tablosunun %LineNumber% satırında ödeme türünü belirtmeniz gerekmektedir.'");
			Text = StrReplace(Text, "%LineNumber%",       TSRow.LineNumber);
			Text = StrReplace(Text, "%TabularSectionName%", NameOfTabularPartPaymentByPaymentCards);
			
			Common.MessageToUser(
				Text,
				DataKey,
				?(DataKey=Undefined, "", CommonClientServer.PathToTabularSection("PaymentWithPaymentCards", TSRow.LineNumber, "PaymentKind_")),
				,
				Cancel);
		
		EndIf;
	
		If Not ValueIsFilled(TSRow.POSTerminal)
			And (TSRow.PaymentKind_ = Enums.TypesOfCashRegisterPaymentSystem.PaymentCard
			Or TSRow.PaymentKind_ = Enums.TypesOfCashRegisterPaymentSystem.NSPKCertificate) Then
			
			Text = NStr("vi = 'Trong dòng %LineNumber% của phần bảng ""%TabularSectionName%"", cần chỉ ra thiết bị thanh toán thẻ.';
						|ru = 'В строке %LineNumber% табличной части ""%TabularSectionName%"" необходимо указать эквайринговый терминал.';
						|en = 'In line %LineNumber% of the %TabularSectionName% table, enter the POS terminal.'; fa = 'In line %LineNumber% of the %TabularSectionName% table, enter the POS terminal.';
						|it = 'В строке %LineNumber% табличной части ""%TabularSectionName%"" необходимо указать эквайринговый терминал.';
						|pl = 'In line %LineNumber% of the %TabularSectionName% table, enter the POS terminal.';
						|tr = '""%TabularSectionName%"" tablosunun %LineNumber% satırında PoS terminalini belirtmeniz gerekmektedir.'");
			Text = StrReplace(Text, "%LineNumber%",       TSRow.LineNumber);
			Text = StrReplace(Text, "%TabularSectionName%", NameOfTabularPartPaymentByPaymentCards);
			
			Common.MessageToUser(
				Text,
				DataKey,
				?(DataKey=Undefined, "", CommonClientServer.PathToTabularSection("PaymentWithPaymentCards", TSRow.LineNumber, "POSTerminal")),
				,
				Cancel);
			
		EndIf;

		If TypeOf(Object) = Type("DocumentObject.CashRegisterReceipt") 
			Or TypeOf(Object) = Type("DocumentObject.CashRegisterReceiptReturn")
			Or TypeOf(Object) = Type("DocumentObject.ReceiptOfCashRegisterAdjustment")
			Or TypeOf(Object) = Type("DocumentObject.GiftCertificateSale")
			Or TypeOf(Object) = Type("DocumentObject.RetailReturnsReport")
			Or TypeOf(Object) = Type("DocumentObject.RetailSalesReport") Then
			If Not ValueIsFilled(TSRow.ConnectionContract)
				And TSRow.PaymentKind_ = Enums.TypesOfCashRegisterPaymentSystem.InstantPayments Then
				
				Text = NStr("vi = 'Trong dòng %LineNumber% của phần bảng ""%TabularSectionName%"", cần chỉ ra hợp đồng kết nối.';
							|ru = 'В строке %LineNumber% табличной части ""%TabularSectionName%"" необходимо указать договор подключения.';
							|en = 'In line %LineNumber% of the %TabularSectionName% table, enter the payment system contract.'; fa = 'In line %LineNumber% of the %TabularSectionName% table, enter the payment system contract.';
							|it = 'В строке %LineNumber% табличной части ""%TabularSectionName%"" необходимо указать договор подключения.';
							|pl = 'In line %LineNumber% of the %TabularSectionName% table, enter the payment system contract.';
							|tr = '""%TabularSectionName%"" tablosunun %LineNumber% satırında bağlantı sözleşmesini belirtmeniz gerekmektedir.'");
				Text = StrReplace(Text, "%LineNumber%",       TSRow.LineNumber);
				Text = StrReplace(Text, "%TabularSectionName%", NameOfTabularPartPaymentByPaymentCards);
			
				Common.MessageToUser(
					Text,
					DataKey,
					?(DataKey=Undefined, "", CommonClientServer.PathToTabularSection("PaymentWithPaymentCards", TSRow.LineNumber, "ConnectionContract")),
					,
					Cancel);
				
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// The procedure complements the processing of the fill check.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Cancel - Boolean - A sign of refusal to carry out the document
//  CheckedAttributes - Array of String - 
//
Procedure FillCheckProcessingAtServer(Form, Cancel, CheckedAttributes) Export

	Object = Form.Object;
	If TypeOf(Object.Ref) = Type("CatalogRef.Partners") 
		And CommonClientServer.HasAttributeOrObjectProperty(Form, "ContactInformationAdditionalAttributesDetails")
		And Form.ContactInformationAdditionalAttributesDetails <> Undefined Then
		
		If Object.LegalEntityIndividual = PredefinedValue("Enum.IndividualCompany.Person_")
			 And ValueIsFilled(Object.OptionOfSendingElectronicReceipt)
			 And Not Object.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend") Then
			 
			ContactDetailsForVerification = New Map;
			For Each ContactInformationRow In Form.ContactInformationAdditionalAttributesDetails Do
				If ContactInformationRow.Type = PredefinedValue("Enum.ContactInformationTypes.Email")
					And Not IsBlankString(ContactInformationRow.Presentation) Then
					ContactDetailsForVerification.Insert(PredefinedValue("Enum.ContactInformationTypes.Email"),ContactInformationRow.Presentation);
				ElsIf ContactInformationRow.Type = PredefinedValue("Enum.ContactInformationTypes.Phone") 
					And Not IsBlankString(ContactInformationRow.Presentation) Then
					ContactDetailsForVerification.Insert(PredefinedValue("Enum.ContactInformationTypes.Phone"),ContactInformationRow.Presentation);
		    	EndIf;
			EndDo;

			RetailSalesClientServer.CheckIndicationOfPartnerSContactDetails(Object.OptionOfSendingElectronicReceipt, ContactDetailsForVerification, Cancel);
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ScheduledJobs

// Performs archiving of KKM receipts with registration of the event in the registration log.
// Called by a routine task.
//
Procedure ArchiveCashRegisterReceipts() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ArchiveCashRegisterReceipts);
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	CashRegisterShift.Ref AS CashRegisterShift
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Posted
	|	AND CashRegisterShift.PeriodEndTransactionsStatus IN (VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreated))
	|");
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		WriteLogEvent(NStr("vi = 'Lưu trữ phiếu tính tiền';
							|ru = 'Архивирование чеков ККМ';
							|en = 'Archive receipts'; fa = 'بایگانی رسیدها';
							|it = 'Archiviazione degli scontrini dei KKM (Macchinari di Registrazione e Controllo)';
							|pl = 'Archiwizacja paragonów kasy fiskalnej';
							|tr = 'Yazar kasa fişlerinin arşivlenmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Information, , ,
			NStr("vi = 'Bắt đầu lưu trữ phiếu tính tiền.';
				|ru = 'Начато регламентное архивирование чеков ККМ.';
				|en = 'Scheduled archiving of receipts has started.'; fa = 'Scheduled archiving of receipts has started.';
				|it = 'Iniziata l''archiviazione di routine degli scontrini dei KKM (Macchinari di Registrazione e Controllo).';
				|pl = 'Rozpoczęto planową archiwizację paragonów KF.';
				|tr = 'Kasa makbuzlarının düzenli olarak arşivlenmesine başlandı.'"));
			
		JobParameters = NewParametersForCashierShiftClosingTask();
		JobParameters.CashRegisterShift = Result.Unload().UnloadColumn("CashRegisterShift");
		JobParameters.ShowErrorToUser = False;
		
		ExecuteArchiveCashRegisterReceipts(JobParameters);
		
		WriteLogEvent(NStr("vi = 'Lưu trữ phiếu tính tiền';
							|ru = 'Архивирование чеков ККМ';
							|en = 'Archive receipts'; fa = 'بایگانی رسیدها';
							|it = 'Archiviazione degli scontrini dei KKM (Macchinari di Registrazione e Controllo)';
							|pl = 'Archiwizacja paragonów kasy fiskalnej';
							|tr = 'Yazar kasa fişlerinin arşivlenmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Information, , ,
			NStr("vi = 'Kết thúc việc lưu trữ phiếu tính tiền';
				|ru = 'Закончено регламентное архивирование чеков ККМ.';
				|en = 'Scheduled archiving of receipts is finished.'; fa = 'Scheduled archiving of receipts is finished.';
				|it = 'Terminata l''archiviazione di routine degli scontrini dei KKM (Macchinari di Registrazione e Controllo).';
				|pl = 'Zakończono planową archiwizację paragonów KF.';
				|tr = 'Kasa fişlerinin rutin arşivlenmesi tamamlandı.'"));
	EndIf;
	
EndProcedure

// Deletes KKM receipts and registers the event in the registration log.
// Called by a routine task.
//
Procedure DeleteCashRegisterReceipts() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeleteCashRegisterReceipts);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	CashRegisterShift.Ref AS CashRegisterShift
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Posted
	|	AND CashRegisterShift.Date < &ReceiptRetentionDate
	|	AND CashRegisterShift.PeriodEndTransactionsStatus IN (VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreated),
	|                                                 VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived))
	|";
	
	NumberOfDaysOfReceiptStorage = Constants.NumberOfArchivedReceiptStorageDays.Get() * 86400;
	ReceiptRetentionDate = CurrentSessionDate() - NumberOfDaysOfReceiptStorage;
	
	Query.SetParameter("ReceiptRetentionDate", ReceiptRetentionDate);
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		WriteLogEvent(NStr("vi = 'Đã xóa phiếu tính tiền';
							|ru = 'Удаление чеков ККМ';
							|en = 'Delete receipts'; fa = 'حذف رسیدها';
							|it = 'Eliminazione di scontrini dei KKM (Macchinari di Registrazione e Controllo)';
							|pl = 'Usunięcie paragonów kasy fiskalnej';
							|tr = 'Yazar kasa fişlerinin silinmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Information, , ,
			NStr("vi = 'Bắt đầu xóa bỏ thường kỳ phiếu tính tiền.';
				|ru = 'Начато регламентное удаление чеков ККМ.';
				|en = 'Scheduled removal of receipts has started.'; fa = 'Scheduled removal of receipts has started.';
				|it = 'Iniziata la cancellazione di routine degli scontrini dei KKM (Macchinari di Registrazione e Controllo).';
				|pl = 'Rozpoczęto planowe usuwanie paragonów KF.';
				|tr = 'Kasa fişlerinin rutin olarak silinmesine başlandı.'"));
		
		JobParameters = NewParametersForCashierShiftClosingTask();
		JobParameters.CashRegisterShift = Result.Unload().UnloadColumn("CashRegisterShift");
		JobParameters.ShowErrorToUser = False;
		
		ExecuteDeleteCashRegisterReceipts(JobParameters);
		
		WriteLogEvent(NStr("vi = 'Đã xóa phiếu tính tiền';
							|ru = 'Удаление чеков ККМ';
							|en = 'Delete receipts'; fa = 'حذف رسیدها';
							|it = 'Eliminazione di scontrini dei KKM (Macchinari di Registrazione e Controllo)';
							|pl = 'Usunięcie paragonów kasy fiskalnej';
							|tr = 'Yazar kasa fişlerinin silinmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Information, , ,
			NStr("vi = 'Đã kết thúc nhiệm vụ thường kỳ xóa phiếu tính tiền.';
				|ru = 'Закончено регламентное удаление чеков ККМ.';
				|en = 'Scheduled deletion of receipts is finished.'; fa = 'Scheduled deletion of receipts is finished.';
				|it = 'Terminata la cancellazione di routine degli scontrini dei KKM (Macchinari di Registrazione e Controllo).';
				|pl = 'Zakończono planowe usuwanie paragonów KF.';
				|tr = 'Kasa fişlerinin rutin olarak silinmesi işlemi tamamlandı.'"));
		
	EndIf;
	
EndProcedure

// Performs archiving of KKM receipts with registration of the event in the registration log.
// Called by a routine task.
//
Procedure DeleteDeferredCashRegisterReceipts() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeleteDeferredCashRegisterReceipts);
	
	SetPrivilegedMode(True);
	
	WriteLogEvent(NStr("vi = 'Xóa phiếu tính tiền đang hoãn';
						|ru = 'Удаление отложенных чеков ККМ';
						|en = 'Deletion of held receipts'; fa = 'حذف رسیدهای نگه‌داشته‌شده';
						|it = 'Eliminazione degli scontrini posticipati dei KKM (Macchinari di Registrazione e Controllo)';
						|pl = 'Usunięcie odłożonych paragonów kasy';
						|tr = 'Ertelenmiş kasa fişlerinin silinmesi'", CommonClientServer.DefaultLanguageCode()),
	                         EventLogLevel.Information, , ,
	                         NStr("vi = 'Bắt đầu xóa bỏ thường kỳ phiếu tính tiền đang hoãn';
									|ru = 'Начато регламентное удаление отложенных чеков ККМ.';
									|en = 'Scheduled removal of held receipts has started.'; fa = 'Scheduled removal of held receipts has started.';
									|it = 'Iniziata la cancellazione di routine degli scontrini posticipati dei KKM (Macchinari di Registrazione e Controllo).';
									|pl = 'Rozpoczęto planowe usuwanie odroczonych paragonów KF.';
									|tr = 'Ertelenmiş kasa fişlerinin rutin olarak silinmesine başlandı.'"));
	
	BeginTransaction();
	Try
		
		Selection = SelectDeferredCashRegisterReceiptsToDelete();
		While Selection.Next() Do
			
			CashRegisterReceiptObject = Selection.Ref.GetObject(); // DocumentObject
			CashRegisterReceiptObject.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(NStr("vi = 'Xóa phiếu tính tiền đang hoãn';
							|ru = 'Удаление отложенных чеков ККМ';
							|en = 'Deletion of held receipts'; fa = 'حذف رسیدهای نگه‌داشته‌شده';
							|it = 'Eliminazione degli scontrini posticipati dei KKM (Macchinari di Registrazione e Controllo)';
							|pl = 'Usunięcie odłożonych paragonów kasy';
							|tr = 'Ertelenmiş kasa fişlerinin silinmesi'", CommonClientServer.DefaultLanguageCode()),
		                         EventLogLevel.Error, , ,
		                         NStr("vi = 'Khi xóa bỏ phiếu tính tiền đang hoãn, đã xảy ra lỗi';
										|ru = 'Во время регламентного удаления отложенных чеков ККМ произошла ошибка.';
										|en = 'An error occurred during scheduled removal of held receipts.'; fa = 'An error occurred during scheduled removal of held receipts.';
										|it = 'Durante la cancellazione di routine degli scontrini posticipati dei KKM (Macchinari di Registrazione e Controllo) si è verificato un errore.';
										|pl = 'Podczas planowego usuwania odroczonych paragonów KF wyniknął błąd.';
										|tr = 'Ertelenmiş makbuzların kasadan rutin olarak silinmesi sırasında bir hata oluştu.'")
		                         + Chars.LF + DetailErrorDescription);
		Return;
		
	EndTry;
	
	WriteLogEvent(NStr("vi = 'Xóa phiếu tính tiền đang hoãn';
						|ru = 'Удаление отложенных чеков ККМ';
						|en = 'Deletion of held receipts'; fa = 'حذف رسیدهای نگه‌داشته‌شده';
						|it = 'Eliminazione degli scontrini posticipati dei KKM (Macchinari di Registrazione e Controllo)';
						|pl = 'Usunięcie odłożonych paragonów kasy';
						|tr = 'Ertelenmiş kasa fişlerinin silinmesi'", CommonClientServer.DefaultLanguageCode()),
	                         EventLogLevel.Information, , ,
	                         NStr("vi = 'Kết thúc việc định kỳ xóa bỏ phiếu tính tiền đang hoãn';
									|ru = 'Закончено регламентное удаление отложенных чеков ККМ.';
									|en = 'Scheduled removal of held receipts is completed.'; fa = 'Scheduled removal of held receipts is completed.';
									|it = 'Terminata la cancellazione di routine degli scontrini posticipati dei KKM (Macchinari di Registrazione e Controllo).';
									|pl = 'Zakończono planowe usuwanie odroczonych paragonów KF.';
									|tr = 'Ertelenmiş kasa fişlerinin rutin olarak silinmesi işlemi tamamlandı.'"));
	
EndProcedure

// Performs archiving of KKM receipts for a cash shift.
//
// Parameters:
//  JobParameters  - See NewParametersForCashierShiftClosingTask
//  StorageAddress - String - the address in the temporary storage.
//  IncludeUnverifiedReceipts - Boolean - The default is false. Completed and unverified receipts that have not been marked for deletion will be processed
//
Procedure ExecuteArchiveCashRegisterReceipts(JobParameters, StorageAddress="", IncludeUnverifiedReceipts = False) Export
	
	SetPrivilegedMode(True);
	
	Result = True;
	
	Query = New Query(
	"SELECT
	|	CashRegisterReceipt.Ref AS Ref,
	|	CashRegisterReceipt.CashRegisterShift AS CashRegisterShift
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	NOT CashRegisterReceipt.Archived
	|	AND (CashRegisterReceipt.Posted
	|		OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceipt.DeletionMark)
	|	AND CashRegisterReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND CashRegisterReceipt.CashRegisterShift IN(&CashRegisterShift)
	|
	|UNION ALL
	|
	|SELECT
	|	CashRegisterReceiptReturn.Ref,
	|	CashRegisterReceiptReturn.CashRegisterShift
	|FROM
	|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	|WHERE
	|	NOT CashRegisterReceiptReturn.Archived
	|	AND (CashRegisterReceiptReturn.Posted
	|		OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceiptReturn.DeletionMark)
	|	AND CashRegisterReceiptReturn.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND CashRegisterReceiptReturn.CashRegisterShift IN(&CashRegisterShift)
	|
	|UNION ALL
	|
	|SELECT
	|	ReceiptOfCashRegisterAdjustment.Ref AS Ref,
	|	ReceiptOfCashRegisterAdjustment.CashRegisterShift AS CashRegisterShift
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
	|WHERE
	|	NOT ReceiptOfCashRegisterAdjustment.Archived
	|	AND (ReceiptOfCashRegisterAdjustment.Posted
	|		OR &IncludeUnverifiedReceipts AND NOT ReceiptOfCashRegisterAdjustment.DeletionMark)
	|	AND ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND ReceiptOfCashRegisterAdjustment.CashRegisterShift IN(&CashRegisterShift)
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(RetailReturnsReport.Ref, VALUE(Document.RetailReturnsReport.EmptyRef)) AS Ref,
	|	DocumentCashRegisterShift.Ref AS CashRegisterShift
	|FROM
	|	Document.CashRegisterShift AS DocumentCashRegisterShift
	|		LEFT JOIN Document.RetailReturnsReport AS RetailReturnsReport
	|		ON DocumentCashRegisterShift.Ref = RetailReturnsReport.CashRegisterShift
	|WHERE
	|	DocumentCashRegisterShift.Ref IN (&CashRegisterShift)
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(RetailSalesReport.Ref, VALUE(Document.RetailSalesReport.EmptyRef)) AS Ref,
	|	DocumentCashRegisterShift.Ref AS CashRegisterShift
	|FROM
	|	Document.CashRegisterShift AS DocumentCashRegisterShift
	|		LEFT JOIN Document.RetailSalesReport AS RetailSalesReport
	|		ON DocumentCashRegisterShift.Ref = RetailSalesReport.CashRegisterShift
	|WHERE
	|	DocumentCashRegisterShift.Ref IN (&CashRegisterShift)
	|
	|TOTALS BY
	|	CashRegisterShift");
	
	Query.SetParameter("CashRegisterShift", JobParameters.CashRegisterShift);
	Query.SetParameter("IncludeUnverifiedReceipts", IncludeUnverifiedReceipts);
	SelectionOfCashShifts = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SelectionOfCashShifts.Next() Do
		
		BeginTransaction();
		Try
			
			Cancel = False;
			
			// The first stage. Shift status - Closed, receipts archived.
			CashShiftObject = SelectionOfCashShifts.CashRegisterShift.GetObject(); // DocumentObject.CashRegisterShift
			CashShiftObject.PeriodEndTransactionsStatus = Enums.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived;
			CashShiftObject.Write(DocumentWriteMode.Posting);
			
			// The second stage. Archiving of receipts and full implementation of the retail sales report and the retail returns report.
			SelectionOfDocuments = SelectionOfCashShifts.Select();
			While SelectionOfDocuments.Next() Do
				
				DataLock = New DataLock;
				LockItem = DataLock.Add("AccumulationRegister.CashInCashRegistersCR.RecordSet");
				LockItem.SetValue("Recorder", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem = DataLock.Add("AccumulationRegister.CashInTransit.RecordSet");
				LockItem.SetValue("Recorder", SelectionOfDocuments.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				DataLock.Lock();
				
			EndDo;
			
			SelectionOfDocuments.Reset();
			While SelectionOfDocuments.Next() Do
				If Not SelectionOfDocuments.Ref.IsEmpty() Then
					DocumentObject = SelectionOfDocuments.Ref.GetObject();
					If TypeOf(DocumentObject) = Type("DocumentObject.CashRegisterReceipt")
						Or TypeOf(DocumentObject) = Type("DocumentObject.CashRegisterReceiptReturn")
						Or TypeOf(DocumentObject) = Type("DocumentObject.ReceiptOfCashRegisterAdjustment") Then
						
						DocumentObject.Archived = True;
						DocumentObject.Write(DocumentWriteMode.Posting);
						
					ElsIf TypeOf(DocumentObject) = Type("DocumentObject.RetailSalesReport") 
							Or TypeOf(DocumentObject) = Type("DocumentObject.RetailReturnsReport") Then

						// When performing the operation of automatic archiving of receipts, it is not necessary to monitor the security. 
                        If TypeOf(DocumentObject) = Type("DocumentObject.RetailSalesReport") Then
							DocumentObject.AdditionalProperties.Insert("ControlSupply", False);
						EndIf;

						DocumentObject.DeletionMark = False;
						DocumentObject.Write(DocumentWriteMode.Posting);
					EndIf;
				ElsIf Not TypeOf(SelectionOfDocuments.Ref) = Type("DocumentRef.RetailReturnsReport") Then
					Cancel = True;
					ErrorDescription = NStr("vi = 'Theo chứng từ %CashRegisterShift% chưa tạo chứng từ %Synonym%';
											|ru = 'По документу %CashRegisterShift% не создано документов %Synonym%';
											|en = 'Documents %Synonym% failed to be created by document %CashRegisterShift%'; fa = 'Documents %Synonym% failed to be created by document %CashRegisterShift%';
											|it = 'In base al documento %CashRegisterShift% non sono stati creati i documenti %Synonym%';
											|pl = 'Wg dokumentu %CashRegisterShift% nie utworzono dokumentów %Synonym%';
											|tr = '%CashRegisterShift% belgesi için hiçbir %Synonym% belgesi oluşturulmadı'",  Common.DefaultLanguageCode());
					ErrorDescription = StrReplace(ErrorDescription, "%CashRegisterShift%", SelectionOfDocuments.CashRegisterShift);
					ErrorDescription = StrReplace(ErrorDescription, "%Synonym%", SelectionOfDocuments.Ref.Metadata().Synonym);
					WriteLogEvent(NStr("vi = 'Lưu trữ phiếu tính tiền';
										|ru = 'Архивирование чеков ККМ';
										|en = 'Archive receipts'; fa = 'بایگانی رسیدها';
										|it = 'Archiviazione degli scontrini dei KKM (Macchinari di Registrazione e Controllo)';
										|pl = 'Archiwizacja paragonów kasy fiskalnej';
										|tr = 'Yazar kasa fişlerinin arşivlenmesi'", Common.DefaultLanguageCode()),
							EventLogLevel.Error, , ,
							NStr("vi = 'Khi lưu trữ định kỳ phiếu tính tiền, đã xảy ra lỗi.';
								|ru = 'Во время регламентного архивирования чеков ККМ произошла ошибка.';
								|en = 'An error occurred during scheduled archiving of the receipts.'; fa = 'An error occurred during scheduled archiving of the receipts.';
								|it = 'Durante l''archiviazione di routine degli scontrini dei KKM (Macchinari di Registrazione e Controllo) si è verificato un errore.';
								|pl = 'Podczas planowej archiwizacji paragonów KF wyniknął błąd.';
								|tr = 'Kasa fişlerinin rutin arşivlenmesi sırasında bir hata oluştu.'", Common.DefaultLanguageCode())
							+ Chars.LF + ErrorDescription);
					If JobParameters.ShowErrorToUser Then
						Common.MessageToUser(ErrorDescription);
					EndIf;
				EndIf
			EndDo;
			
			If Cancel Then
				RollbackTransaction();
				Result = False;
				
				If TransactionActive() Then
					Raise ErrorDescription;
				EndIf; 
			Else
				CommitTransaction();
			EndIf;
			
		Except
			
			RollbackTransaction();
			
			ErrorInfo = ErrorInfo();
			DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			WriteLogEvent(NStr("vi = 'Lưu trữ phiếu tính tiền';
								|ru = 'Архивирование чеков ККМ';
								|en = 'Archive receipts'; fa = 'بایگانی رسیدها';
								|it = 'Archiviazione degli scontrini dei KKM (Macchinari di Registrazione e Controllo)';
								|pl = 'Archiwizacja paragonów kasy fiskalnej';
								|tr = 'Yazar kasa fişlerinin arşivlenmesi'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, , ,
					DetailErrorDescription);
			If TransactionActive() Then
				Raise DetailErrorDescription;
			EndIf; 
			
			Result = False;
			
			If JobParameters.ShowErrorToUser Then
				ErrorDescription = NStr("vi = 'Khi lưu lại phiếu tính tiền, đã xảy ra lỗi.
			                      |Chưa thực hiện lưu trữ phiếu tính tiền.
			                      |Mô tả bổ sung:
			                      |%AdditionalDetails%';
			                      |ru = 'При архивации чеков ККМ произошла ошибка.
			                      |Архивация чеков ККМ не выполнена.
			                      |Дополнительное описание:
			                      |%AdditionalDetails%';
			                      |en = 'An error occurred when archiving the receipt.
			                      |Receipt archiving is not completed.
			                      |Additional details:
			                      |%AdditionalDetails%'; fa = 'An error occurred when archiving the receipt.
			                      |Receipt archiving is not completed.
			                      |Additional details:
			                      |%AdditionalDetails%';
			                      |it = 'Durante l''archiviazione degli scontrini dei KKM (Macchinari di Registrazione e Controllo) si è verificato un errore.
			                      |L''archiviazione degli scontrini dei KKM (Macchinari di Registrazione e Controllo) non è stata effettuata.
			                      |Descrizione aggiuntiva:
			                      |%AdditionalDetails%';
			                      |pl = 'Wystąpił błąd podczas archiwizowania paragonów w kasie.
			                      |Archiwizacja paragonów w kasie nie została zakończona.
			                      | Dokładniej:
			                      |%AdditionalDetails%';
			                      |tr = 'Kasa fişini arşivlerken bir hata oluştu. 
			                      |Kasa fişi arşivlenmedi.
			                      |Ek açıklama: 
			                      |%AdditionalDetails%'");
				ErrorDescription = StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorProcessing.BriefErrorDescription(ErrorInfo));
			
				Common.MessageToUser(ErrorDescription);
			EndIf;
			
		EndTry;
	EndDo;
	JobParameters.ProcessSucceeded = Result;
	
	If Not IsBlankString(StorageAddress) Then
		PutToTempStorage(JobParameters, StorageAddress);
	EndIf;
	
EndProcedure

// The constructor of the parameter of the methods to perform the deletion of the check of the CM() and perform the archiving of the check of the CM()
// Returns:
// Structure:
//	*ProcessSucceeded - Boolean - a sign of a successful End
//	*CashRegisterShift - DocumentRef.CashRegisterShift,Array of DocumentRef.CashRegisterShift
//	*ShowErrorToUser - Boolean
Function NewParametersForCashierShiftClosingTask() Export
	
	JobParameters = New Structure;
	JobParameters.Insert("ProcessSucceeded", False);
	JobParameters.Insert("CashRegisterShift", New Array);
	JobParameters.Insert("ShowErrorToUser", True);
	
	Return JobParameters;
	
EndFunction

// Deletes KKM receipts for a cash shift.
//
// Parameters:
//  JobParameters  - See NewParametersForCashierShiftClosingTask
//  StorageAddress - String - the address in the temporary storage.
//  IncludeUnverifiedReceipts - Boolean - The default is false. When performing of operation, unverified receipts will be deleted, including those marked for deletion.
//
Procedure ExecuteDeleteCashRegisterReceipts(JobParameters, StorageAddress = "", IncludeUnverifiedReceipts = False) Export
	
	ExecuteArchiveCashRegisterReceipts(JobParameters, StorageAddress, IncludeUnverifiedReceipts);
	
	SetPrivilegedMode(True);
	
	DeletionCompleted_ = JobParameters.ProcessSucceeded;
	
	Query = New Query(
		"SELECT
		|	ReturnOfGoodsFromCustomer.Ref AS Ref,
		|	ReturnOfGoodsFromCustomer.CashRegisterReceipt.CashRegisterShift AS CashRegisterShift
		|FROM
		|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
		|WHERE
		|	ReturnOfGoodsFromCustomer.CashRegisterReceipt.CashRegisterShift IN(&CashRegisterShift)
		|	AND ReturnOfGoodsFromCustomer.CashRegisterReceipt.CashRegisterShift.PeriodEndTransactionsStatus = 
		|		VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)
		|
		|UNION ALL
		|
		|SELECT
		|	RequestForReturnOfGoodsFromCustomer.Ref,
		|	RequestForReturnOfGoodsFromCustomer.CashRegisterReceipt.CashRegisterShift AS CashRegisterShift
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
		|WHERE
		|	RequestForReturnOfGoodsFromCustomer.CashRegisterReceipt.CashRegisterShift IN(&CashRegisterShift)
		|	AND RequestForReturnOfGoodsFromCustomer.CashRegisterReceipt.CashRegisterShift.PeriodEndTransactionsStatus = 
		|		VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)
		|
		|UNION ALL
		|
		|SELECT
		|	CashRegisterReceipt.Ref AS Ref,
		|	CashRegisterReceipt.CashRegisterShift AS CashRegisterShift
		|FROM
		|	Document.CashRegisterReceipt AS CashRegisterReceipt
		|WHERE
		|	(CashRegisterReceipt.Posted
		|		OR &IncludeUnverifiedReceipts)
		|	AND CashRegisterReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND CashRegisterReceipt.CashRegisterShift IN(&CashRegisterShift)
		|	AND CashRegisterReceipt.CashRegisterShift.PeriodEndTransactionsStatus = 
		|		VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)
		|
		|UNION ALL
		|
		|SELECT
		|	CashRegisterReceiptReturn.Ref,
		|	CashRegisterReceiptReturn.CashRegisterShift
		|FROM
		|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
		|WHERE
		|	(CashRegisterReceiptReturn.Posted
		|		OR &IncludeUnverifiedReceipts)
		|	AND CashRegisterReceiptReturn.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND CashRegisterReceiptReturn.CashRegisterShift IN(&CashRegisterShift)
		|	AND CashRegisterReceiptReturn.CashRegisterShift.PeriodEndTransactionsStatus = 
		|		VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)
		|
		|UNION ALL
		|
		|SELECT
		|	ReceiptOfCashRegisterAdjustment.Ref AS Ref,
		|	ReceiptOfCashRegisterAdjustment.CashRegisterShift AS CashRegisterShift
		|FROM
		|	Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
		|WHERE
		|	(ReceiptOfCashRegisterAdjustment.Posted
		|		OR &IncludeUnverifiedReceipts)
		|	AND ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND ReceiptOfCashRegisterAdjustment.CashRegisterShift IN(&CashRegisterShift)
		|	AND ReceiptOfCashRegisterAdjustment.CashRegisterShift.PeriodEndTransactionsStatus = 
		|		VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)
		|TOTALS BY
		|	CashRegisterShift");

	Query.SetParameter("CashRegisterShift", JobParameters.CashRegisterShift);
	Query.SetParameter("IncludeUnverifiedReceipts", IncludeUnverifiedReceipts);
	Result = Query.Execute();
	
	SelectionOfCashShifts = Result.Select(QueryResultIteration.ByGroups);
	
	While SelectionOfCashShifts.Next() Do
		
		BeginTransaction();
		Try
			
			// The first stage. Deleting receipts, retail sales reports, and receipts from refunds.
			SelectionOfDocuments = SelectionOfCashShifts.Select();
			While SelectionOfDocuments.Next() Do
				DocumentObject = SelectionOfDocuments.Ref.GetObject(); // DocumentObject
				If TypeOf(DocumentObject) = Type("DocumentObject.ReturnOfGoodsFromCustomer")
					Or TypeOf(DocumentObject) = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer") Then
					
					DocumentObject.DataExchange.Load = True;
					DocumentObject.CashRegisterReceipt = Undefined;
					DocumentObject.Write();
										
				ElsIf TypeOf(DocumentObject) = Type("DocumentObject.CashRegisterReceipt") 
					Or TypeOf(DocumentObject) = Type("DocumentObject.CashRegisterReceiptReturn")
					Or TypeOf(DocumentObject) = Type("DocumentObject.ReceiptOfCashRegisterAdjustment") Then
					
					DocumentObject.Delete();
					
				EndIf;
			EndDo;
			
			// We do not delete the Cash Shift document. Required to calculate the relationship between the Retail Sales Report and the Retail Returns Report
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();

			ErrorInfo = ErrorInfo();
			DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
			WriteLogEvent(
				NStr("vi = 'Đã xóa phiếu tính tiền';
					|ru = 'Удаление чеков ККМ';
					|en = 'Delete receipts'; fa = 'حذف رسیدها';
					|it = 'Eliminazione di scontrini dei KKM (Macchinari di Registrazione e Controllo)';
					|pl = 'Usunięcie paragonów kasy fiskalnej';
					|tr = 'Yazar kasa fişlerinin silinmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , ,
				DetailErrorDescription);
			If TransactionActive() Then
				Raise DetailErrorDescription;
			EndIf; 
			
			If JobParameters.ShowErrorToUser Then
				ErrorTemplate = NStr("vi = 'Khi xóa phiếu tính tiền, đã xảy ra lỗi.
			                      |Chưa xóa phiếu tính tiền.
			                      |Mô tả bổ sung:
			                      |%AdditionalDetails%';
			                      |ru = 'При удалении чеков ККМ произошла ошибка.
			                      |Удаление чеков ККМ не выполнено.
			                      |Дополнительное описание:
			                      |%AdditionalDetails%';
			                      |en = 'An error occurred while removing receipts. 
			                      |Receipts were not removed.
			                      |Additional description:
			                      |%AdditionalDetails%'; fa = 'An error occurred while removing receipts. 
			                      |Receipts were not removed.
			                      |Additional description:
			                      |%AdditionalDetails%';
			                      |it = 'Durante la cancellazione degli scontrini dei KKM (Macchinari di Registrazione e Controllo) si è verificato un errore.
			                      |La cancellazione degli scontrini dei registratori di cassa non è stata effettuata.
			                      |Descrizione aggiuntiva:
			                      |%AdditionalDetails%';
			                      |pl = 'Po usunięciu paragonów KF wystąpił błąd.
			                      |Usuwanie paragonów KF nie powiodła się.
			                      |Dodatkowy opis:
			                      |%AdditionalDetails%';
			                      |tr = 'Kasa fişini arşivlerken bir hata oluştu. 
			                      |Kasa fişi arşivlenmedi.
			                      |Ek açıklama: 
			                      |%AdditionalDetails%'");
				ErrorDescription = StrReplace(
					ErrorTemplate, 
					"%AdditionalDetails%", 
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
				Common.MessageToUser(ErrorDescription);
			EndIf;
			
			DeletionCompleted_ = False;
			
		EndTry;
	EndDo;
	
	JobParameters.ProcessSucceeded = DeletionCompleted_;
	
	If Not IsBlankString(StorageAddress) Then
		PutToTempStorage(JobParameters, StorageAddress);
	EndIf;
	
EndProcedure

// Routine task handler Metadata.Routine tasks.Removal of useddannyh accessories from store and trade cards
//
Procedure DeleteUnusedDataOnInventoryOwnershipOfRetailOutlets() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeleteUnusedInventoryAffiliationDataOfRetailOutlets);
	
	WriteLogEvent(NStr("vi = 'Xóa dữ liệu không sử dụng về thuộc tính sở hữu hàng tồn kho của điểm bán hàng';
						|ru = 'Удаление неиспользуемых данных о принадлежности запасов торговых точек';
						|en = 'Delete unused inventory affiliation data of retail outlets'; fa = 'حذف داده‌های استفاده‌نشده تعلق موجودی فروشگاه‌های خرده‌فروشی';
						|it = 'Delete unused inventory affiliation data of retail outlets';
						|pl = 'Delete unused inventory affiliation data of retail outlets';
						|tr = 'Satış noktası stoklarına ait kullanılmayan verileri sil'", Common.DefaultLanguageCode()),
	                         EventLogLevel.Information, , ,
	                         NStr("vi = 'Bắt đầu xóa thường kỳ dữ liệu không sử dụng về thuộc tính sở hữu hàng tồn kho của điểm bán hàng.';
									|ru = 'Начато регламентное удаление неиспользуемых данных о принадлежности запасов торговых точек.';
									|en = 'Scheduled deletion of unused inventory affiliation data of retail outlets is started.'; fa = 'Scheduled deletion of unused inventory affiliation data of retail outlets is started.';
									|it = 'Scheduled deletion of unused inventory affiliation data of retail outlets is started.';
									|pl = 'Scheduled deletion of unused inventory affiliation data of retail outlets is started.';
									|tr = 'Satış noktası stoklarına ait kullanılmayan verilerin rutin olarak silinmesine başlandı.'"));

	InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation.DeleteUnusedDataOnInventoryOwnershipOfRetailOutlets();
	
	WriteLogEvent(NStr("vi = 'Xóa dữ liệu không sử dụng về thuộc tính sở hữu hàng tồn kho của điểm bán hàng';
						|ru = 'Удаление неиспользуемых данных о принадлежности запасов торговых точек';
						|en = 'Delete unused inventory affiliation data of retail outlets'; fa = 'حذف داده‌های استفاده‌نشده تعلق موجودی فروشگاه‌های خرده‌فروشی';
						|it = 'Delete unused inventory affiliation data of retail outlets';
						|pl = 'Delete unused inventory affiliation data of retail outlets';
						|tr = 'Satış noktası stoklarına ait kullanılmayan verileri sil'", Common.DefaultLanguageCode()),
	                         EventLogLevel.Information, , ,
	                         NStr("vi = 'Đã kết thúc xóa thường kỳ dữ liệu không sử dụng về thuộc tính sở hữu hàng tồn kho của điểm bán hàng.';
									|ru = 'Закончено регламентное удаление неиспользуемых данных о принадлежности запасов торговых точек.';
									|en = 'Scheduled deletion of unused inventory affiliation data of retail outlets is completed.'; fa = 'Scheduled deletion of unused inventory affiliation data of retail outlets is completed.';
									|it = 'Scheduled deletion of unused inventory affiliation data of retail outlets is completed.';
									|pl = 'Scheduled deletion of unused inventory affiliation data of retail outlets is completed.';
									|tr = 'Satış noktası stoklarına ait kullanılmayan verilerin rutin olarak silinmesi tamamlandı.'"));
	
EndProcedure

#EndRegion

#Region ProceduresForOpeningAndClosingCashShift

// Opens a cash shift.
//
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - Parameters of a routine task
//  AdditionalParameters - Structure - 
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  Boolean - True if the operation was completed successfully.
//
Function OpenRegisterShift(CashRegister, AdditionalParameters, ErrorDescription = "") Export
	
	SetPrivilegedMode(True);
	
	Result = True;
	
	StructureRegisterShiftState = GetCashShiftState(CashRegister);
	
	OpeningDateOfCashShift = CurrentSessionDate();
	
	If StructureRegisterShiftState.CashRegisterShiftStatus = Enums.CashRegisterShiftStatuses.IsOpen Then
		
		// If the shift is open, then no more than 24 hours should pass from the moment of opening.
		If StructureRegisterShiftState.Error24Hours Then
			
			Result = False;
			// It is likely that the shift was not closed.
			ErrorDescription = ErrorDescription24Hours();
			LogEntry(ErrorDescription, "OpenRegisterShift", CashRegister);
			
		EndIf;
		
	Else
		
		// The shift is closed. We will open a new cash shift.
		
		NewCashRegisterShift = Documents.CashRegisterShift.CreateDocument();
		NewCashRegisterShift.Fill(New Structure("CashRegister", CashRegister));
		
		NewCashRegisterShift.Organization            = StructureRegisterShiftState.Organization;
		NewCashRegisterShift.CashRegister               = CashRegister;
		NewCashRegisterShift.Date                   = OpeningDateOfCashShift;
		NewCashRegisterShift.Status                 = Enums.CashRegisterShiftStatuses.IsOpen;
		NewCashRegisterShift.CashRegisterShiftStart    = OpeningDateOfCashShift;
		NewCashRegisterShift.CashRegisterShiftEnd = '00010101';
		
		If ValueIsFilled(AdditionalParameters) Then
			If AdditionalParameters.Property("SettlementAddress")
				And ValueIsFilled(AdditionalParameters.SettlementAddress) Then
        		NewCashRegisterShift.SettlementAddress = AdditionalParameters.SettlementAddress;
			EndIf;
			If AdditionalParameters.Property("PlaceOfSettlement")
				And ValueIsFilled(AdditionalParameters.PlaceOfSettlement) Then
        		NewCashRegisterShift.PlaceOfSettlement = AdditionalParameters.PlaceOfSettlement;
			EndIf;
		EndIf;
		
		If NewCashRegisterShift.CheckFilling() Then
			NewCashRegisterShift.Write(DocumentWriteMode.Posting);
		Else
			Result = False;
			ErrorDescription = GetErrorTextForFillingInReport();
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Performs the closing of cash register shift.
//
// Parameters:
//  Object - CatalogRef.CashRegisters, CatalogRef.Peripherals - Cash registers.
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  DocumentRef.CashRegisterShift, Undefined - Closed cash shift.
//
Function CloseRegisterShift(Object, ErrorDescription = "") Export
	
	Result = Undefined;

	SetPrivilegedMode(True);
	
	StructureRegisterShiftState = GetCashShiftState(Object);
	
	If StructureRegisterShiftState.CashRegisterShiftStatus = Enums.CashRegisterShiftStatuses.IsOpen
		Or (StructureRegisterShiftState.CashRegisterShiftStatus = Enums.CashRegisterShiftStatuses.Closed_
		  And  StructureRegisterShiftState.PeriodEndTransactionsStatus = Enums.StatusesOfPeriodEndTransactionsOfCashRegisterShift.EmptyRef()) Then
		
		If StructureRegisterShiftState.StatusChangeDate <= CurrentSessionDate() Then
		
			CashShiftObject = StructureRegisterShiftState.CashRegisterShift.GetObject();
			CashShiftObject.Status                     = Enums.CashRegisterShiftStatuses.Closed_;
			CashShiftObject.PeriodEndTransactionsStatus = Enums.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreated;
			CashShiftObject.CashRegisterShiftEnd     = CurrentSessionDate();

			CashShiftObject.Write(DocumentWriteMode.Posting);
			
			Result = StructureRegisterShiftState.CashRegisterShift;
			
		Else

			ErrorDescription = NStr("vi = 'Khi đóng phiên thu ngân đã xảy ra lỗi.
			                            |Mô tả bổ sung:
			                            |Ngày đóng phiên thu ngân nhỏ hơn ngày thay đổi trạng thái phiên thu ngân gần nhất.';
			                            |ru = 'При закрытии кассовой смены произошла ошибка.
			                            |Подробное описание:
			                            |Дата закрытия кассовой смены меньше даты последнего изменения статуса кассовой смены.';
			                            |en = 'An error occurred when closing the POS shift.
			                            |Detailed description:
			                            |Date of the POS shift closing is less than the date of the last POS shift status change.'; fa = 'An error occurred when closing the POS shift.
			                            |Detailed description:
			                            |Date of the POS shift closing is less than the date of the last POS shift status change.';
			                            |it = 'Durante la chiusura del cambio di cassa si è verificato un errore.
			                            |Descrizione dettagliata:
			                            |La data di chiusura dello spostamento del registratore di cassa è inferiore alla data dell''ultima modifica dello stato del cambio di cassa.';
			                            |pl = 'Po zamknięciu kasowej zmiany wystąpił błąd.
			                            |Detaliczny opis:
			                            |Data zamknięcia kasowej zmiany mniejsza od daty ostatniej zmiany statusu kasowym zmiany.';
			                            |tr = 'Kasa vardiyası kapatılırken bir hata oluştu.
			                            | Detaylı açıklama:
			                            | Kasa vardiyasının kapatılma tarihi, kasa vardiyası durumunun son değiştirilme tarihinden önce.'");

		EndIf;
		
	ElsIf Not ValueIsFilled(StructureRegisterShiftState.CashRegisterShift) Then

        // There is not a single cash shift
		ErrorDescription = NStr("vi = 'Khi đóng phiên thu ngân, đã xảy ra lỗi.
		|Mô tả chi tiết:
		|Không tìm thấy phiên thu ngân nào.';
		|ru = 'При закрытии кассовой смены произошла ошибка.
		|Подробное описание:
		|Не найдено ни одной кассовой смены.';
		|en = 'An error occurred upon the POS shift-end closing.
		|More information:
		|No POS shift is found.'; fa = 'An error occurred upon the POS shift-end closing.
		|More information:
		|No POS shift is found.';
		|it = 'Si è verificato un errore durante la chiusura del turno di cassa. 
		|Descrizione dettagliata:
		| Non è stato trovato alcun turno di cassa.';
		|pl = 'Podczas zamknięcia zmiany kasowej wystąpił błąd.
		|Opis szczegółowy:
		|Nie znaleziono ani jednej zmiany kasowej.';
		|tr = 'Kasa vardiyası kapatılırken bir hata oluştu.
		| Detaylı açıklama:
		| Herhangi bir kasa vardiyası bulunamadı.'");

	Else
		
		// The shift is not open.
		Result = StructureRegisterShiftState.CashRegisterShift;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Fills in the retail sales Report for the cash shift.
//
// Parameters:
//  RegisterShiftState - See DescriptionOfCashShift.
//	VATTaxation - EnumRef - The type of VAT taxation according to which it is necessary to fill out Reports on retail sales /refunds.
//	TempTablesManager - TempTablesManager -
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  DocumentRef.RetailSalesReport - A link to the report if the operation was completed successfully. Otherwise, It Is Uncertain.
//
Function FillOutReportOnRetailSalesByCashShift(RegisterShiftState, VATTaxation, TempTablesManager, ErrorDescription = "") Export
	
	SetPrivilegedMode(True);
	
	// Search for a retail sales report by tax type
	RetailSalesReport = FindRetailSalesReport(RegisterShiftState.CashRegisterShift, VATTaxation);
	UpdateReports = RegisterShiftState.UpdateReports;
	If RetailSalesReport = Undefined Then
		RetailSalesReportObject = Documents.RetailSalesReport.CreateDocument();
		UpdateReports = True;
	Else
		RetailSalesReportObject = RetailSalesReport.GetObject();
	EndIf;
	
	If UpdateReports Then
		RetailSalesReportObject.AdditionalProperties.Insert("SoftwareFilling", True);
		Return FillOutRetailSalesReport(RetailSalesReportObject, RegisterShiftState, VATTaxation, TempTablesManager, , ErrorDescription);
	Else
		Return RetailSalesReport;
	EndIf;
	
EndFunction

// Fills in the retail sales Report for the cash shift.
//
// Parameters:
//  RetailSalesReportObject - DocumentObject.RetailSalesReport - The document to be filled in.
//  RegisterShiftState - See DescriptionOfCashShift.
//	VATTaxation - EnumRef - The type of VAT taxation according to which it is necessary to fill out Reports on retail sales /refunds.
//	TempTablesManager - TempTablesManager -
//	OnlyFillIn - Boolean - A flag that determines whether an attempt will be made to conduct/record after filling in.
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  DocumentRef.RetailSalesReport - A link to the report if the operation was completed successfully. Otherwise, It Is Uncertain.
//
Function FillOutRetailSalesReport(RetailSalesReportObject, RegisterShiftState, VATTaxation, TempTablesManager, OnlyFillIn = False, ErrorDescription = "") Export
	
	SetPrivilegedMode(True);
	
	// Filling out a retail sales report
	Try
		
		ThisIsAttemptToHoldDocument = False;
		
		// Data preparation.
		QueryText = "
		|SELECT
		|	CashRegisterReceiptGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
		|	CashRegisterReceiptGoods.Ref AS Ref,
		|	CashRegisterReceiptGoods.CashRegisterReceipt AS CashRegisterReceipt,
		|	CashRegisterReceiptGoods.Date AS Date,
		|	CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products AS Products,
		|	CashRegisterReceiptGoods.Characteristic AS Characteristic,
		|	CashRegisterReceiptGoods.Series AS Series,
		|	CashRegisterReceiptGoods.Package AS Package,
		|	CashRegisterReceiptGoods.Price AS Price,
		|	CashRegisterReceiptGoods.VATRate AS VATRate,
		|	CashRegisterReceiptGoods.NumberOfPackages AS NumberOfPackages,
		|	CashRegisterReceiptGoods.Count AS Count,
		|	CashRegisterReceiptGoods.Sum AS Sum,
		|	CashRegisterReceiptGoods.VATAmount AS VATAmount,
		|	CashRegisterReceiptGoods.Warehouse AS Warehouse,
		|	CashRegisterReceiptGoods.Partner AS Partner,
		|	CashRegisterReceiptGoods.Premise AS Premise,
		|	CashRegisterReceiptGoods.Seller AS Seller,
		|	CashRegisterReceiptGoods.Currency AS Currency,
		|	CashRegisterReceiptGoods.PriceKind AS PriceKind,
		|	CashRegisterReceiptGoods.CashRegister AS CashRegister,
		|	CashRegisterReceiptGoods.Organization AS Organization,
		|	CashRegisterReceiptGoods.VATTaxation AS VATTaxation,
		|	CashRegisterReceiptGoods.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|	CashRegisterReceiptGoods.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift,
		|	CashRegisterReceiptGoods.CashRegisterReceiptForWhichProblematicReturnWasIssued AS CashRegisterReceiptForWhichProblematicReturnWasIssued
		|INTO GoodsList
		|FROM
		|	RetailSalesProducts_ AS CashRegisterReceiptGoods
		|WHERE
		|	CashRegisterReceiptGoods.VATTaxation = &VATTaxation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsList.ByCorrectionReceipt AS ByCorrectionReceipt,
		|	GoodsList.Ref AS Ref,
		|	GoodsList.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|	GoodsList.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift,
		|	GoodsList.CashRegister AS CashRegister,
		|	GoodsList.Organization AS Organization,
		|	GoodsList.Warehouse AS Warehouse,
		|	GoodsList.Currency AS Currency,
		|	GoodsList.PriceKind AS PriceKind,
		|	GoodsList.VATTaxation AS VATTaxation,
		|	GoodsList.Partner AS Partner,
		|	GoodsList.Date AS Date,
		|	GoodsList.CashRegisterReceipt AS CashRegisterReceipt,
		|	CASE WHEN ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt IS NULL
		|		THEN FALSE 
		|		ELSE TRUE 
		|	END AS ReturnToSalesShift
		|INTO CashRegisterReceipts
		|FROM
		|	GoodsList AS GoodsList
		|	LEFT JOIN ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift AS ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift
		|	ON ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt = GoodsList.CashRegisterReceipt
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CashRegisterReceiptsSalesDocuments.CashRegisterShift AS CashRegisterShift,
		|	CashRegisterReceiptsSalesDocuments.VATTaxation AS VATTaxation,
		|	CashRegisterReceiptsSalesDocuments.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
		|FROM
		|	CashRegisterReceiptsSalesDocuments AS CashRegisterReceiptsSalesDocuments
		|WHERE
		|	NOT CashRegisterReceiptsSalesDocuments.DocumentSalesOfGoodsAndServices = UNDEFINED
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsList.Currency AS Currency,
		|	GoodsList.PriceKind AS PriceKind,
		|	GoodsList.CashRegister AS CashRegister,
		|	GoodsList.Organization AS Organization,
		|	GoodsList.VATTaxation AS VATTaxation,
		|	GoodsList.Warehouse AS Warehouse
		|FROM
		|	CashRegisterReceipts AS GoodsList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsList.ProductsInSet AS ProductsInSet,
		|	GoodsList.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsList.Products AS Products,
		|	GoodsList.Characteristic AS Characteristic,
		|	GoodsList.Series AS Series,
		|	GoodsList.Package AS Package,
		|	GoodsList.Price AS Price,
		|	GoodsList.VATRate AS VATRate
		|FROM
		|	GoodsList AS GoodsList";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("CashRegisterShift", RegisterShiftState.CashRegisterShift);
		Query.SetParameter("VATTaxation", VATTaxation);
		
		Query.TempTablesManager = TempTablesManager;
		ResultsArray = Query.ExecuteBatch();
		
		TableOfImplementationDocuments = ResultsArray[2].Unload();
		TableOfImplementationDocuments.Indexes.Add("CashRegisterShift,VATTaxation");
		
		// Formation of index tables by analytics and nomenclature
		TableOfIndexesForAnalytics = ResultsArray[3].Unload();
		TMCommonUse.NumberValueTable(TableOfIndexesForAnalytics,"IndexOf");
		
		IndexTableByProduct = ResultsArray[4].Unload();
		TMCommonUse.NumberValueTable(IndexTableByProduct,"IndexOf");

		QueryText = 
		"SELECT
		|	IndexTable.IndexOf AS AnalyticsIndex,
		|	IndexTable.Currency AS Currency,
		|	IndexTable.PriceKind AS PriceKind,
		|	IndexTable.CashRegister AS CashRegister,
		|	IndexTable.Organization AS Organization,
		|	IndexTable.VATTaxation AS VATTaxation,
		|	IndexTable.Warehouse AS Warehouse
		|INTO AnalyticsIndexes
		|FROM
		|	&TableOfIndexesForAnalytics AS IndexTable
		|
		|INDEX BY
		|	Currency,
		|	PriceKind,
		|	CashRegister,
		|	Organization,
		|	VATTaxation,
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IndexTable.IndexOf AS ProductItemIndex,
		|	IndexTable.ProductsInSet AS ProductsInSet,
		|	IndexTable.ItemVariantOfSet AS ItemVariantOfSet,
		|	IndexTable.Products AS Products,
		|	IndexTable.Characteristic AS Characteristic,
		|	IndexTable.Series AS Series,
		|	IndexTable.Package AS Package,
		|	IndexTable.Price AS Price,
		|	IndexTable.VATRate AS VATRate
		|INTO ProductIndexes
		|FROM
		|	&IndexTableByProduct AS IndexTable
		|
		|INDEX BY
		|	ProductsInSet,
		|	ItemVariantOfSet,
		|	Products,
		|	Characteristic,
		|	Series,
		|	Package,
		|	Price,
		|	VATRate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsList.ByCorrectionReceipt AS ByCorrectionReceipt,
		|	GoodsList.ProductsInSet AS ProductsInSet,
		|	GoodsList.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsList.Products AS Products,
		|	GoodsList.Characteristic AS Characteristic,
		|	GoodsList.Series AS Series,
		|	GoodsList.Package AS Package,
		|	GoodsList.Price AS Price,
		|	GoodsList.Partner AS Partner,
		|	GoodsList.Premise AS Premise,
		|	GoodsList.Seller AS Seller,
		|	GoodsList.VATRate AS VATRate,
		|	SUM(GoodsList.NumberOfPackages) AS NumberOfPackages,
		|	SUM(GoodsList.Count) AS Count,
		|	SUM(GoodsList.Sum) AS Sum,
		|	SUM(GoodsList.VATAmount) AS VATAmount,
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex,
		|	ProductIndexes.ProductItemIndex AS ProductItemIndex,
		|	GoodsList.Warehouse AS Warehouse,
		|	GoodsList.Currency AS Currency,
		|	GoodsList.PriceKind AS PriceKind,
		|	GoodsList.CashRegister AS CashRegister,
		|	GoodsList.Organization AS Organization,
		|	GoodsList.VATTaxation AS VATTaxation,
		|	GoodsList.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|	GoodsList.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|FROM
		|	(SELECT
		|		GoodsList.CashRegisterReceipt AS CashRegisterReceipt,
		|		GoodsList.ByCorrectionReceipt AS ByCorrectionReceipt,
		|		GoodsList.ProductsInSet AS ProductsInSet,
		|		GoodsList.ItemVariantOfSet AS ItemVariantOfSet,
		|		GoodsList.Products AS Products,
		|		GoodsList.Characteristic AS Characteristic,
		|		GoodsList.Series AS Series,
		|		GoodsList.VATRate AS VATRate,
		|		GoodsList.Package AS Package,
		|		CAST(CASE
		|				WHEN GoodsList.NumberOfPackages = 0
		|					THEN GoodsList.Sum
		|				ELSE GoodsList.Sum / GoodsList.NumberOfPackages
		|			END AS NUMBER(31, 2)) AS Price,
		|		GoodsList.Partner AS Partner,
		|		MAX(GoodsList.Premise) AS Premise,
		|		GoodsList.Seller AS Seller,
		|		SUM(GoodsList.NumberOfPackages) AS NumberOfPackages,
		|		SUM(GoodsList.Count) AS Count,
		|		SUM(GoodsList.Sum) AS Sum,
		|		SUM(GoodsList.VATAmount) AS VATAmount,
		|		GoodsList.Warehouse AS Warehouse,
		|		GoodsList.Currency AS Currency,
		|		GoodsList.PriceKind AS PriceKind,
		|		GoodsList.CashRegister AS CashRegister,
		|		GoodsList.Organization AS Organization,
		|		GoodsList.VATTaxation AS VATTaxation,
		|		GoodsList.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|		GoodsList.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|	FROM
		|		GoodsList AS GoodsList
		|	WHERE
		|		GoodsList.CashRegisterReceiptForWhichProblematicReturnWasIssued = FALSE
		|	
		|	GROUP BY
		|		GoodsList.CashRegisterReceipt,
		|		GoodsList.ByCorrectionReceipt,
		|		GoodsList.ProductsInSet,
		|		GoodsList.ItemVariantOfSet,
		|		GoodsList.Products,
		|		GoodsList.Characteristic,
		|		GoodsList.Series,
		|		GoodsList.VATRate,
		|		GoodsList.Package,
		|		CAST(CASE
		|				WHEN GoodsList.NumberOfPackages = 0
		|					THEN GoodsList.Sum
		|				ELSE GoodsList.Sum / GoodsList.NumberOfPackages
		|			END AS NUMBER(31, 2)),
		|		GoodsList.Partner,
		|		GoodsList.Seller,
		|		GoodsList.Warehouse,
		|		GoodsList.Currency,
		|		GoodsList.PriceKind,
		|		GoodsList.CashRegister,
		|		GoodsList.Organization,
		|		GoodsList.VATTaxation,
		|		GoodsList.CashRegisterReceiptVATTaxation,
		|		GoodsList.CashRegisterReceiptCashRegisterShift
		|
		|	UNION ALL
		|
		|	SELECT
		|		GoodsList.CashRegisterReceipt AS CashRegisterReceipt,
		|		GoodsList.ByCorrectionReceipt AS ByCorrectionReceipt,
		|		GoodsList.ProductsInSet AS ProductsInSet,
		|		GoodsList.ItemVariantOfSet AS ItemVariantOfSet,
		|		GoodsList.Products AS Products,
		|		GoodsList.Characteristic AS Characteristic,
		|		GoodsList.Series AS Series,
		|		GoodsList.VATRate AS VATRate,
		|		GoodsList.Package AS Package,
		|		CAST(CASE
		|				WHEN GoodsList.NumberOfPackages = 0
		|					THEN GoodsList.Sum
		|				ELSE GoodsList.Sum / GoodsList.NumberOfPackages
		|			END AS NUMBER(31, 2)) AS Price,
		|		GoodsList.Partner AS Partner,
		|		MAX(GoodsList.Premise) AS Premise,
		|		MAX(GoodsList.Seller) AS Seller,
		|		SUM(GoodsList.NumberOfPackages) AS NumberOfPackages,
		|		SUM(GoodsList.Count) AS Count,
		|		SUM(GoodsList.Sum) AS Sum,
		|		SUM(GoodsList.VATAmount) AS VATAmount,
		|		GoodsList.Warehouse AS Warehouse,
		|		GoodsList.Currency AS Currency,
		|		GoodsList.PriceKind AS PriceKind,
		|		GoodsList.CashRegister AS CashRegister,
		|		GoodsList.Organization AS Organization,
		|		GoodsList.VATTaxation AS VATTaxation,
		|		GoodsList.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|		GoodsList.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|	FROM
		|		GoodsList AS GoodsList
		|	WHERE
		|		GoodsList.CashRegisterReceiptForWhichProblematicReturnWasIssued = TRUE
		|	
		|	GROUP BY
		|		GoodsList.CashRegisterReceipt,
		|		GoodsList.ByCorrectionReceipt,
		|		GoodsList.ProductsInSet,
		|		GoodsList.ItemVariantOfSet,
		|		GoodsList.Products,
		|		GoodsList.Characteristic,
		|		GoodsList.Series,
		|		GoodsList.VATRate,
		|		GoodsList.Package,
		|		CAST(CASE
		|				WHEN GoodsList.NumberOfPackages = 0
		|					THEN GoodsList.Sum
		|				ELSE GoodsList.Sum / GoodsList.NumberOfPackages
		|			END AS NUMBER(31, 2)),
		|		GoodsList.Partner,
		|		GoodsList.Warehouse,
		|		GoodsList.Currency,
		|		GoodsList.PriceKind,
		|		GoodsList.CashRegister,
		|		GoodsList.Organization,
		|		GoodsList.VATTaxation,
		|		GoodsList.CashRegisterReceiptVATTaxation,
		|		GoodsList.CashRegisterReceiptCashRegisterShift
		|	) AS GoodsList
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON GoodsList.Warehouse = AnalyticsIndexes.Warehouse
		|			AND GoodsList.Currency = AnalyticsIndexes.Currency
		|			AND GoodsList.PriceKind = AnalyticsIndexes.PriceKind
		|			AND GoodsList.CashRegister = AnalyticsIndexes.CashRegister
		|			AND GoodsList.Organization = AnalyticsIndexes.Organization
		|			AND GoodsList.VATTaxation = AnalyticsIndexes.VATTaxation
		|		LEFT JOIN ProductIndexes AS ProductIndexes
		|		ON GoodsList.Products = ProductIndexes.Products
		|			AND GoodsList.ProductsInSet = ProductIndexes.ProductsInSet
		|			AND GoodsList.ItemVariantOfSet = ProductIndexes.ItemVariantOfSet
		|			AND GoodsList.Characteristic = ProductIndexes.Characteristic
		|			AND GoodsList.Series = ProductIndexes.Series
		|			AND GoodsList.Package = ProductIndexes.Package
		|			AND GoodsList.Price = ProductIndexes.Price
		|			AND GoodsList.VATRate = ProductIndexes.VATRate
		|
		|GROUP BY
		|	GoodsList.ByCorrectionReceipt,
		|	GoodsList.ProductsInSet,
		|	GoodsList.ItemVariantOfSet,
		|	GoodsList.Products,
		|	GoodsList.Characteristic,
		|	GoodsList.Series,
		|	GoodsList.VATRate,
		|	GoodsList.Package,
		|	GoodsList.Price,
		|	GoodsList.Partner,
		|	GoodsList.Premise,
		|	GoodsList.Seller,
		|	ProductIndexes.VATRate,
		|	AnalyticsIndexes.AnalyticsIndex,
		|	ProductIndexes.ProductItemIndex,
		|	GoodsList.Warehouse,
		|	GoodsList.Currency,
		|	GoodsList.PriceKind,
		|	GoodsList.CashRegister,
		|	GoodsList.Organization,
		|	GoodsList.VATTaxation,
		|	GoodsList.CashRegisterReceiptVATTaxation,
		|	GoodsList.CashRegisterReceiptCashRegisterShift
		|
		|HAVING
		|	SUM(GoodsList.Count) <> 0
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Series,
		|	Package,
		|	PriceKind,
		|	Price,
		|	Partner,
		|	Seller,
		|	AnalyticsIndex,
		|	ByCorrectionReceipt
		|TOTALS
		|	MAX(ProductsInSet),
		|	MAX(ItemVariantOfSet),
		|	MAX(Products),
		|	MAX(Characteristic),
		|	MAX(Series),
		|	MAX(Package),
		|	MAX(Price),
		|	MAX(Partner),
		|	MAX(Premise),
		|	MAX(Seller),
		|	MAX(VATRate),
		|	MAX(NumberOfPackages),
		|	MAX(Count),
		|	MAX(Sum),
		|	MAX(VATAmount),
		|	MAX(Warehouse),
		|	MAX(Currency),
		|	MAX(PriceKind),
		|	MAX(CashRegister),
		|	MAX(Organization),
		|	MAX(VATTaxation)
		|BY
		|	AnalyticsIndex,
		|	ProductItemIndex
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PaymentWithPaymentCards.PaymentKind_ AS PaymentKind_,
		|	PaymentWithPaymentCards.POSTerminal AS POSTerminal,
		|	PaymentWithPaymentCards.PaymentCardNumber AS PaymentCardNumber,
		|	PaymentWithPaymentCards.AuthorizationCode AS AuthorizationCode,
		|	PaymentWithPaymentCards.ConnectionContract AS ConnectionContract,
		|	SUM(PaymentWithPaymentCards.Sum) AS Sum,
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex
		|FROM
		// All payments for sales receipts per shift, except for fully refunded ones, which were paid in a mixed way
		|	(SELECT
		|		1 AS DimensionNumber_,
		|		CashRegisterReceiptPaymentWithPaymentCards.PaymentKind_ AS PaymentKind_,
		|		CashRegisterReceiptPaymentWithPaymentCards.POSTerminal AS POSTerminal,
		|		CASE WHEN ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt IS NULL
		|			THEN CashRegisterReceiptPaymentWithPaymentCards.PaymentCardNumber
		|			ELSE """" END AS PaymentCardNumber,
		|		CASE WHEN ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt IS NULL
		|			THEN CashRegisterReceiptPaymentWithPaymentCards.AuthorizationCode
		|			ELSE """" END AS AuthorizationCode,
		|		CashRegisterReceiptPaymentWithPaymentCards.ConnectionContract AS ConnectionContract,
		|		CashRegisterReceiptPaymentWithPaymentCards.Sum AS Sum,
		|		CashRegisterReceipts.CashRegister AS CashRegister,
		|		CashRegisterReceipts.Organization AS Organization,
		|		CashRegisterReceipts.Warehouse AS Warehouse,
		|		CashRegisterReceipts.Currency AS Currency,
		|		CashRegisterReceipts.PriceKind AS PriceKind
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceipt.PaymentWithPaymentCards AS CashRegisterReceiptPaymentWithPaymentCards
		|			ON CashRegisterReceiptPaymentWithPaymentCards.Ref = CashRegisterReceipts.Ref
		|			LEFT JOIN ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift AS ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift
		|			ON ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt = CashRegisterReceiptPaymentWithPaymentCards.Ref
		|			LEFT JOIN CashRegisterReceiptsForReturnsThatAreReflectedInRRR AS CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|			ON CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt = CashRegisterReceiptPaymentWithPaymentCards.Ref
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = FALSE
		|		AND CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt IS NULL
		|	
		|	UNION ALL
		|	
		// All refunds on sales receipts per shift, except for fully refunded ones that were paid in a mixed way
		|	SELECT
		|		1 AS DimensionNumber_,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.PaymentKind_,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.POSTerminal,
		|		"""",
		|		"""",
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.ConnectionContract,
		|		-CashRegisterReceiptReturnPaymentWithPaymentCards.Sum,
		|		CashRegisterReceipts.CashRegister,
		|		CashRegisterReceipts.Organization,
		|		CashRegisterReceipts.Warehouse,
		|		CashRegisterReceipts.Currency,
		|		CashRegisterReceipts.PriceKind
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS CashRegisterReceiptReturnPaymentWithPaymentCards
		|			ON CashRegisterReceiptReturnPaymentWithPaymentCards.Ref = CashRegisterReceipts.Ref
		|			LEFT JOIN CashRegisterReceiptsForReturnsThatAreReflectedInRRR AS CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|			ON CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt = CashRegisterReceipts.CashRegisterReceipt 
		|	WHERE
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.PaymentIsCanceled
		|		AND CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt IS NULL
		|
		|	UNION ALL
		|	
		// Payments for fully refunded sales receipts per shift that were paid in a mixed way
		|	SELECT
		|		2 AS DimensionNumber_,
		|		CashRegisterReceiptPaymentWithPaymentCards.PaymentKind_ AS PaymentKind_,
		|		CashRegisterReceiptPaymentWithPaymentCards.POSTerminal AS POSTerminal,
		|		CashRegisterReceiptPaymentWithPaymentCards.PaymentCardNumber AS PaymentCardNumber,
		|		CashRegisterReceiptPaymentWithPaymentCards.AuthorizationCode AS AuthorizationCode,
		|		CashRegisterReceiptPaymentWithPaymentCards.ConnectionContract AS ConnectionContract,
		|		CashRegisterReceiptPaymentWithPaymentCards.Sum AS Sum,
		|		CashRegisterReceipts.CashRegister AS CashRegister,
		|		CashRegisterReceipts.Organization AS Organization,
		|		CashRegisterReceipts.Warehouse AS Warehouse,
		|		CashRegisterReceipts.Currency AS Currency,
		|		CashRegisterReceipts.PriceKind AS PriceKind
		|	FROM
		|		CashRegisterReceiptsForReturnsThatAreReflectedInRRR AS CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|			LEFT JOIN CashRegisterReceipts AS CashRegisterReceipts
		|			ON CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt = CashRegisterReceipts.Ref
		|			INNER JOIN Document.CashRegisterReceipt.PaymentWithPaymentCards AS CashRegisterReceiptPaymentWithPaymentCards
		|			ON CashRegisterReceiptPaymentWithPaymentCards.Ref = CashRegisterReceipts.Ref) AS PaymentWithPaymentCards
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON PaymentWithPaymentCards.CashRegister = AnalyticsIndexes.CashRegister
		|			AND PaymentWithPaymentCards.Organization = AnalyticsIndexes.Organization
		|			AND PaymentWithPaymentCards.Warehouse = AnalyticsIndexes.Warehouse
		|			AND PaymentWithPaymentCards.Currency = AnalyticsIndexes.Currency
		|			AND PaymentWithPaymentCards.PriceKind = AnalyticsIndexes.PriceKind
		|
		|GROUP BY
		|	PaymentWithPaymentCards.DimensionNumber_,
		|	PaymentWithPaymentCards.PaymentKind_,
		|	PaymentWithPaymentCards.POSTerminal,
		|	PaymentWithPaymentCards.PaymentCardNumber,
		|	PaymentWithPaymentCards.AuthorizationCode,
		|	PaymentWithPaymentCards.ConnectionContract,
		|	AnalyticsIndexes.AnalyticsIndex
		|
		|ORDER BY
		|	DimensionNumber_,
		|	PaymentKind_,
		|	POSTerminal,
		|	AnalyticsIndex,
		|	PaymentCardNumber,
		|	AuthorizationCode,
		|	ConnectionContract
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Premise AS Premise,
		|	SetOfSeries.Series AS Series,
		|	SetOfSeries.Products AS Products,
		|	SetOfSeries.Characteristic AS Characteristic,
		|	SUM(SetOfSeries.Count) AS Count,
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex
		|FROM
		|	(SELECT
		|		CashRegisterReceiptSetOfSeries.Premise AS Premise,
		|		CashRegisterReceiptSetOfSeries.Series AS Series,
		|		CashRegisterReceiptSetOfSeries.Products AS Products,
		|		CashRegisterReceiptSetOfSeries.Characteristic AS Characteristic,
		|		CashRegisterReceiptSetOfSeries.Count AS Count,
		|		CashRegisterReceipts.CashRegister AS CashRegister,
		|		CashRegisterReceipts.Organization AS Organization,
		|		CashRegisterReceipts.Warehouse AS Warehouse,
		|		CashRegisterReceipts.Currency AS Currency,
		|		CashRegisterReceipts.PriceKind AS PriceKind
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceipt.SetOfSeries AS CashRegisterReceiptSetOfSeries
		|			ON (CashRegisterReceiptSetOfSeries.Ref = CashRegisterReceipts.Ref)
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = FALSE
		|		AND CashRegisterReceipts.ReturnToSalesShift = FALSE
		|	
		|	UNION ALL
		|	
		|	SELECT 
		|		MAX(CashRegisterReceiptSetOfSeries.Premise) AS Premise,
		|		CashRegisterReceiptSetOfSeries.Series AS Series,
		|		CashRegisterReceiptSetOfSeries.Products AS Products,
		|		CashRegisterReceiptSetOfSeries.Characteristic AS Characteristic,
		|		SUM(CashRegisterReceiptSetOfSeries.Count) AS Count,
		|		CashRegisterReceiptSetOfSeries.CashRegister AS CashRegister,
		|		CashRegisterReceiptSetOfSeries.Organization AS Organization,
		|		CashRegisterReceiptSetOfSeries.Warehouse AS Warehouse,
		|		CashRegisterReceiptSetOfSeries.Currency AS Currency,
		|		CashRegisterReceiptSetOfSeries.PriceKind AS PriceKind
		|    FROM
		|		(SELECT
		|			CashRegisterReceiptSetOfSeries.Premise AS Premise,
		|			CashRegisterReceiptSetOfSeries.Series AS Series,
		|			CashRegisterReceiptSetOfSeries.Products AS Products,
		|			CashRegisterReceiptSetOfSeries.Characteristic AS Characteristic,
		|			CashRegisterReceiptSetOfSeries.Count AS Count,
		|			CashRegisterReceipts.CashRegister AS CashRegister,
		|			CashRegisterReceipts.Organization AS Organization,
		|			CashRegisterReceipts.Warehouse AS Warehouse,
		|			CashRegisterReceipts.Currency AS Currency,
		|			CashRegisterReceipts.PriceKind AS PriceKind
		|		FROM
		|			CashRegisterReceipts AS CashRegisterReceipts
		|				INNER JOIN Document.CashRegisterReceipt.SetOfSeries AS CashRegisterReceiptSetOfSeries
		|				ON (CashRegisterReceiptSetOfSeries.Ref = CashRegisterReceipts.Ref)
		|		WHERE
		|			CashRegisterReceipts.ByCorrectionReceipt = FALSE
		|			AND CashRegisterReceipts.ReturnToSalesShift = TRUE
		|
		|		UNION ALL
		|
		|		SELECT
		|			VALUE(Catalog.Warerooms.EmptyRef),
		|			CashRegisterReceiptReturnSetOfSeries.Series,
		|			CashRegisterReceiptReturnSetOfSeries.Products,
		|			CashRegisterReceiptReturnSetOfSeries.Characteristic,
		|			-CashRegisterReceiptReturnSetOfSeries.Count,
		|			CashRegisterReceipts.CashRegister,
		|			CashRegisterReceipts.Organization,
		|			CashRegisterReceipts.Warehouse,
		|			CashRegisterReceipts.Currency,
		|			CashRegisterReceipts.PriceKind
		|		FROM
		|			CashRegisterReceipts AS CashRegisterReceipts
		|				INNER JOIN Document.CashRegisterReceiptReturn.SetOfSeries AS CashRegisterReceiptReturnSetOfSeries
		|				ON (CashRegisterReceiptReturnSetOfSeries.Ref = CashRegisterReceipts.Ref)
		|		WHERE
		|			CashRegisterReceipts.ByCorrectionReceipt = FALSE) AS CashRegisterReceiptSetOfSeries
		|
		|	GROUP BY
		|		CashRegisterReceiptSetOfSeries.Series,
		|		CashRegisterReceiptSetOfSeries.Products,
		|		CashRegisterReceiptSetOfSeries.Characteristic,
		|		CashRegisterReceiptSetOfSeries.CashRegister,
		|		CashRegisterReceiptSetOfSeries.Organization,
		|		CashRegisterReceiptSetOfSeries.Warehouse,
		|		CashRegisterReceiptSetOfSeries.Currency,
		|		CashRegisterReceiptSetOfSeries.PriceKind
		|	HAVING 
		|		SUM(CashRegisterReceiptSetOfSeries.Count) > 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceiptSetOfSeries.Premise,
		|		CashRegisterReceiptSetOfSeries.Series,
		|		CashRegisterReceiptSetOfSeries.Products,
		|		CashRegisterReceiptSetOfSeries.Characteristic,
		|		-CashRegisterReceiptSetOfSeries.Count,
		|		CashRegisterReceipts.CashRegister,
		|		CashRegisterReceipts.Organization,
		|		CashRegisterReceipts.Warehouse,
		|		CashRegisterReceipts.Currency,
		|		CashRegisterReceipts.PriceKind
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceipt.SetOfSeries AS CashRegisterReceiptSetOfSeries
		|			ON (CashRegisterReceiptSetOfSeries.Ref = CashRegisterReceipts.Ref)
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = TRUE
		|
		|	UNION ALL
		|	
		|	SELECT
		|		ReceiptOfCashRegisterAdjustmentSetOfSeries.Premise,
		|		ReceiptOfCashRegisterAdjustmentSetOfSeries.Series,
		|		ReceiptOfCashRegisterAdjustmentSetOfSeries.Products,
		|		ReceiptOfCashRegisterAdjustmentSetOfSeries.Characteristic,
		|		ReceiptOfCashRegisterAdjustmentSetOfSeries.Count,
		|		CashRegisterReceipts.CashRegister,
		|		CashRegisterReceipts.Organization,
		|		CashRegisterReceipts.Warehouse,
		|		CashRegisterReceipts.Currency,
		|		CashRegisterReceipts.PriceKind
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.ReceiptOfCashRegisterAdjustment.SetOfSeries AS ReceiptOfCashRegisterAdjustmentSetOfSeries
		|			ON (ReceiptOfCashRegisterAdjustmentSetOfSeries.Ref = CashRegisterReceipts.Ref)
		|				AND ReceiptOfCashRegisterAdjustmentSetOfSeries.Ref.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = TRUE) AS SetOfSeries
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON SetOfSeries.CashRegister = AnalyticsIndexes.CashRegister
		|			AND SetOfSeries.Organization = AnalyticsIndexes.Organization
		|			AND SetOfSeries.Warehouse = AnalyticsIndexes.Warehouse
		|			AND SetOfSeries.Currency = AnalyticsIndexes.Currency
		|			AND SetOfSeries.PriceKind = AnalyticsIndexes.PriceKind
		|
		|GROUP BY
		|	SetOfSeries.Premise,
		|	SetOfSeries.Series,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	AnalyticsIndexes.AnalyticsIndex
		|
		|ORDER BY
		|	AnalyticsIndex,
		|	Premise,
		|	Products,
		|	Characteristic,
		|	Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GiftCertificates.GiftCertificate AS GiftCertificate,
		|	SUM(GiftCertificates.Count) AS Count,
		|	SUM(GiftCertificates.Sum) AS Sum,
		|	SUM(GiftCertificates.AmountInCertificateCurrency) AS AmountInCertificateCurrency,
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex
		|FROM
		|	(SELECT
		|		CashRegisterReceiptGiftCertificates.GiftCertificate AS GiftCertificate,
		|		1 AS Count,
		|		CashRegisterReceiptGiftCertificates.Sum AS Sum,
		|		CashRegisterReceiptGiftCertificates.AmountInCertificateCurrency AS AmountInCertificateCurrency,
		|		CashRegisterReceipts.CashRegister AS CashRegister,
		|		CashRegisterReceipts.Organization AS Organization,
		|		CashRegisterReceipts.Warehouse AS Warehouse,
		|		CashRegisterReceipts.Currency AS Currency,
		|		CashRegisterReceipts.PriceKind AS PriceKind
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceipt.GiftCertificates AS CashRegisterReceiptGiftCertificates
		|			ON (CashRegisterReceiptGiftCertificates.Ref = CashRegisterReceipts.Ref)
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = FALSE
		|	) AS GiftCertificates
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON GiftCertificates.CashRegister = AnalyticsIndexes.CashRegister
		|			AND GiftCertificates.Organization = AnalyticsIndexes.Organization
		|			AND GiftCertificates.Warehouse = AnalyticsIndexes.Warehouse
		|			AND GiftCertificates.Currency = AnalyticsIndexes.Currency
		|			AND GiftCertificates.PriceKind = AnalyticsIndexes.PriceKind
		|
		|GROUP BY
		|	GiftCertificates.GiftCertificate,
		|	AnalyticsIndexes.AnalyticsIndex
		|
		|HAVING
		|	SUM(GiftCertificates.Count) <> 0
		|
		|ORDER BY
		|	GiftCertificate,
		|	AnalyticsIndex
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex,
		|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
		|	BonusPoints.AccrualDate AS AccrualDate,
		|	BonusPoints.DateOfDeduction AS DateOfDeduction,
		|	BonusPoints.Partner AS Partner,
		|	SUM(BonusPoints.AmountOfBonusPoints) AS AmountOfBonusPoints
		|FROM
		|	(SELECT
		|		CashRegisterReceipts.CashRegister AS CashRegister,
		|		CashRegisterReceipts.Organization AS Organization,
		|		CashRegisterReceipts.Warehouse AS Warehouse,
		|		CashRegisterReceipts.Currency AS Currency,
		|		CashRegisterReceipts.PriceKind AS PriceKind,
		|		CashRegisterReceipts.Partner AS Partner,
		|		BonusPoints.LoyaltyProgram AS LoyaltyProgram,
		|		BonusPoints.AccrualDate AS AccrualDate,
		|		BonusPoints.DateOfDeduction AS DateOfDeduction,
		|		BonusPoints.AmountOfBonusPoints AS AmountOfBonusPoints
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceipt.BonusPoints AS BonusPoints
		|			ON (BonusPoints.Ref = CashRegisterReceipts.Ref)
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = FALSE
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceipts.CashRegister,
		|		CashRegisterReceipts.Organization,
		|		CashRegisterReceipts.Warehouse,
		|		CashRegisterReceipts.Currency,
		|		CashRegisterReceipts.PriceKind,
		|		CashRegisterReceipts.Partner,
		|		BonusPoints.LoyaltyProgram,
		|		BonusPoints.AccrualDate,
		|		BonusPoints.DateOfDeduction,
		|		-BonusPoints.AmountOfBonusPoints
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceiptReturn.BonusPoints AS BonusPoints
		|			ON (BonusPoints.Ref = CashRegisterReceipts.Ref)) AS BonusPoints
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON BonusPoints.CashRegister = AnalyticsIndexes.CashRegister
		|			AND BonusPoints.Organization = AnalyticsIndexes.Organization
		|			AND BonusPoints.Warehouse = AnalyticsIndexes.Warehouse
		|			AND BonusPoints.Currency = AnalyticsIndexes.Currency
		|			AND BonusPoints.PriceKind = AnalyticsIndexes.PriceKind
		|
		|GROUP BY
		|	AnalyticsIndexes.AnalyticsIndex,
		|	BonusPoints.AccrualDate,
		|	BonusPoints.DateOfDeduction,
		|	BonusPoints.LoyaltyProgram,
		|	BonusPoints.Partner
		|
		|HAVING
		|	SUM(BonusPoints.AmountOfBonusPoints) <> 0
		|
		|ORDER BY
		|	Partner,
		|	LoyaltyProgram,
		|	AnalyticsIndex,
		|	AccrualDate,
		|	DateOfDeduction
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex,
		|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
		|	BonusPoints.PayDate AS PayDate,
		|	BonusPoints.Partner AS Partner,
		|	SUM(BonusPoints.AmountOfBonusPoints) AS AmountOfBonusPoints
		|FROM
		|	(SELECT
		|		CashRegisterReceipts.CashRegister AS CashRegister,
		|		CashRegisterReceipts.Organization AS Organization,
		|		CashRegisterReceipts.Warehouse AS Warehouse,
		|		CashRegisterReceipts.Currency AS Currency,
		|		CashRegisterReceipts.PriceKind AS PriceKind,
		|		CashRegisterReceipts.Partner AS Partner,
		|		Table.Ref.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
		|		BEGINOFPERIOD(CashRegisterReceipts.Date, DAY) AS PayDate,
		|		Table.AmountOfBonusPointsToDeduction AS AmountOfBonusPoints
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceipt.Goods AS Table
		|			ON (Table.Ref = CashRegisterReceipts.Ref)
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = FALSE
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceiptReturn.CashRegister,
		|		CashRegisterReceiptReturn.Organization,
		|		CashRegisterReceiptReturn.Warehouse,
		|		CashRegisterReceiptReturn.Currency,
		|		CashRegisterReceiptReturn.PriceKind,
		|		CashRegisterReceiptReturn.Partner,
		|		CashRegisterReceiptReturn.LoyaltyCard.Owner.LoyaltyProgram,
		|		BEGINOFPERIOD(CashRegisterReceiptReturn.Date, DAY),
		|		-CashRegisterReceiptReturn.AmountOfBonusPointsToReturn
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
		|			ON (CashRegisterReceiptReturn.Ref = CashRegisterReceipts.Ref)) AS BonusPoints
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON BonusPoints.CashRegister = AnalyticsIndexes.CashRegister
		|			AND BonusPoints.Organization = AnalyticsIndexes.Organization
		|			AND BonusPoints.Warehouse = AnalyticsIndexes.Warehouse
		|			AND BonusPoints.Currency = AnalyticsIndexes.Currency
		|			AND BonusPoints.PriceKind = AnalyticsIndexes.PriceKind
		|
		|GROUP BY
		|	AnalyticsIndexes.AnalyticsIndex,
		|	BonusPoints.PayDate,
		|	BonusPoints.LoyaltyProgram,
		|	BonusPoints.Partner
		|
		|HAVING
		|	SUM(BonusPoints.AmountOfBonusPoints) <> 0
		|
		|ORDER BY
		|	Partner,
		|	LoyaltyProgram,
		|	AnalyticsIndex,
		|	PayDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex,
		|	ExciseStamps.Help2 AS Help2,
		|	ExciseStamps.ExciseStamp AS ExciseStamp
		|FROM
		|	(SELECT
		|		CashRegisterReceipts.CashRegister AS CashRegister,
		|		CashRegisterReceipts.Organization AS Organization,
		|		CashRegisterReceipts.Warehouse AS Warehouse,
		|		CashRegisterReceipts.Currency AS Currency,
		|		CashRegisterReceipts.PriceKind AS PriceKind,
		|		Table.Help2 AS Help2,
		|		Table.ExciseStamp AS ExciseStamp,
		|		1 AS NumberOfExciseTaxes
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceipt.ExciseStamps AS Table
		|			ON (Table.Ref = CashRegisterReceipts.Ref)
		|
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceipts.CashRegister,
		|		CashRegisterReceipts.Organization,
		|		CashRegisterReceipts.Warehouse,
		|		CashRegisterReceipts.Currency,
		|		CashRegisterReceipts.PriceKind,
		|		Table.Help2,
		|		Table.ExciseStamp,
		|		-1
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|			INNER JOIN Document.CashRegisterReceiptReturn.ExciseStamps AS Table
		|			ON (Table.Ref = CashRegisterReceipts.Ref)) AS ExciseStamps
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON ExciseStamps.CashRegister = AnalyticsIndexes.CashRegister
		|			AND ExciseStamps.Organization = AnalyticsIndexes.Organization
		|			AND ExciseStamps.Warehouse = AnalyticsIndexes.Warehouse
		|			AND ExciseStamps.Currency = AnalyticsIndexes.Currency
		|			AND ExciseStamps.PriceKind = AnalyticsIndexes.PriceKind
		|
		|GROUP BY
		|	AnalyticsIndexes.AnalyticsIndex,
		|	ExciseStamps.Help2,
		|	ExciseStamps.ExciseStamp
		|
		|HAVING
		|	SUM(ExciseStamps.NumberOfExciseTaxes) > 0
		|
		|ORDER BY
		|	AnalyticsIndex,
		|	ExciseStamp
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP GoodsList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CashRegisterReceipts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP AnalyticsIndexes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductIndexes";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("TableOfIndexesForAnalytics", TableOfIndexesForAnalytics);
		Query.SetParameter("IndexTableByProduct", IndexTableByProduct);
		
		Result = Query.ExecuteBatch();
		
		PaymentWithPaymentCards = Result[3].Unload(); // ValueTable
		SetOfSeries                   = Result[4].Unload(); // ValueTable
		GiftCertificates   = Result[5].Unload(); // ValueTable
		BonusPoints           = Result[6].Unload(); // ValueTable
		PaymentWithBonusPoints  = Result[7].Unload(); // ValueTable
		ExciseStamps           = Result[8].Unload(); // ValueTable
	
		PaymentWithPaymentCards.Indexes.Add("AnalyticsIndex");
		SetOfSeries.Indexes.Add("AnalyticsIndex");
		GiftCertificates.Indexes.Add("AnalyticsIndex");
		BonusPoints.Indexes.Add("AnalyticsIndex");
		PaymentWithBonusPoints.Indexes.Add("AnalyticsIndex");
		ExciseStamps.Indexes.Add("AnalyticsIndex");
		
		SampleByAnalytics = Result[2].Select(QueryResultIteration.ByGroups);
				
		// Let's clear the tabular parts of the document.
		RetailSalesReportObject.Goods.Clear();
		RetailSalesReportObject.SetOfSeries.Clear();
		RetailSalesReportObject.PaymentWithPaymentCards.Clear();
		RetailSalesReportObject.InventoryKinds.Clear();
		RetailSalesReportObject.GiftCertificates.Clear();
		RetailSalesReportObject.BonusPointAccrual.Clear();
		RetailSalesReportObject.PaymentWithBonusPoints.Clear();
		RetailSalesReportObject.ExciseStamps.Clear();
	
		If SampleByAnalytics.Next() Then
			
			FillPropertyValues(RetailSalesReportObject, SampleByAnalytics);
			
			SelectionBasedOnProductAnalysis = SampleByAnalytics.Select(QueryResultIteration.ByGroups);
			While SelectionBasedOnProductAnalysis.Next() Do
				
				SelectionDetailRecords = SelectionBasedOnProductAnalysis.Select();
				While SelectionDetailRecords.Next() Do
					
					RowOfTablePartProducts = RetailSalesReportObject.Goods.Add();
					FillPropertyValues(RowOfTablePartProducts, SelectionDetailRecords);
					RowOfTablePartProductsNumberOfPackages = ?(RowOfTablePartProducts.NumberOfPackages = 0, SelectionDetailRecords.Count, RowOfTablePartProducts.NumberOfPackages);
					RowOfTablePartProducts.Price = Round(RowOfTablePartProducts.Sum / RowOfTablePartProductsNumberOfPackages, 15, 2);
					SelectFillInImplementationDocumentInLine(RowOfTablePartProducts, TableOfImplementationDocuments, RegisterShiftState, SelectionDetailRecords, True);
					
				EndDo;
				
			EndDo;
			
			// Filling in the tabular part "Payment by payment cards".
			RowsArray = PaymentWithPaymentCards.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				If TSRow.Sum <> 0 Then
					LineOfATabularSection = RetailSalesReportObject.PaymentWithPaymentCards.Add();
					FillPropertyValues(LineOfATabularSection, TSRow);
				EndIf;
				
			EndDo;
			
			// Filling in the tabular part of the "Series".
			RowsArray = SetOfSeries.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				If TSRow.Count <> 0 Then
					LineOfATabularSection = RetailSalesReportObject.SetOfSeries.Add();
					FillPropertyValues(LineOfATabularSection, TSRow);
				EndIf;
				
			EndDo;
			
			// Filling in the tabular part "Gift certificates".
			RowsArray = GiftCertificates.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				If TSRow.Sum <> 0 Then
					LineOfATabularSection = RetailSalesReportObject.GiftCertificates.Add();
					FillPropertyValues(LineOfATabularSection, TSRow);
				EndIf;
				
			EndDo;
			
			// Filling in the tabular part of the "Bonus Points".
			RowsArray = BonusPoints.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				LineOfATabularSection = RetailSalesReportObject.BonusPointAccrual.Add();
				FillPropertyValues(LineOfATabularSection, TSRow);
				
			EndDo;
			
			// Filling in the tabular part of the "Pay with bonus points".
			RowsArray = PaymentWithBonusPoints.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				LineOfATabularSection = RetailSalesReportObject.PaymentWithBonusPoints.Add();
				FillPropertyValues(LineOfATabularSection, TSRow);
				
			EndDo;
			
			// Filling in the tabular part of the "Excise stamps".
			RowsArray = ExciseStamps.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				LineOfATabularSection = RetailSalesReportObject.ExciseStamps.Add();
				FillPropertyValues(LineOfATabularSection, TSRow);
				
			EndDo;
			
			RetailSalesReportObject.Date            = RegisterShiftState.StatusChangeDate;
			RetailSalesReportObject.PriceIncludesVAT = RegisterShiftState.PriceIncludesVAT;
			RetailSalesReportObject.CashRegisterShift   = RegisterShiftState.CashRegisterShift;
			RetailSalesReportObject.Department   = RegisterShiftState.Department;
			
			RetailSalesReportObject.DocumentAmount  = PriceManagementSystemClientServer.GetDocumentAmount(RetailSalesReportObject.Goods, RetailSalesReportObject.PriceIncludesVAT);
			
			ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(RetailSalesReportObject);
			
			If Not ValueIsFilled(RetailSalesReportObject.EmployeeResponsible) Then
				RetailSalesReportObject.EmployeeResponsible = Users.CurrentUser();
			EndIf;
			If Not ValueIsFilled(RetailSalesReportObject.Department) Then
				RetailSalesReportObject.Department = SettingsValueCached.UserDivision(RetailSalesReportObject.EmployeeResponsible, RetailSalesReportObject.Department);
			EndIf;
			
			SeriesSpecificationParameters = New FixedStructure(Documents.RetailSalesReport.SeriesSpecificationParameters(RetailSalesReportObject));
			ProductsServer.FillInStatusesForSpecifyingSeries(RetailSalesReportObject, SeriesSpecificationParameters);
						
		Else
			// No goods were sold on the cash shift		
			// Fills in the retail sales report with data on the current cash shift.
			FillPropertyValues(RetailSalesReportObject, RegisterShiftState, , "VATTaxation");
			
			RetailSalesReportObject.Date           		= RegisterShiftState.StatusChangeDate;
			RetailSalesReportObject.VATTaxation  	= VATTaxation;
			
			ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(RetailSalesReportObject);
					
			If Not ValueIsFilled(RetailSalesReportObject.EmployeeResponsible) Then
				RetailSalesReportObject.EmployeeResponsible = Users.CurrentUser();
			EndIf;
			If Not ValueIsFilled(RetailSalesReportObject.Department) Then
				RetailSalesReportObject.Department = SettingsValueCached.UserDivision(RetailSalesReportObject.EmployeeResponsible, RetailSalesReportObject.Department);
			EndIf;
			
			// Filling in the tabular part "Payment by payment cards".
			For Each TSRow In PaymentWithPaymentCards Do
				
				If TSRow.Sum <> 0 Then
					LineOfATabularSection = RetailSalesReportObject.PaymentWithPaymentCards.Add();
					FillPropertyValues(LineOfATabularSection, TSRow);
				EndIf;
				
			EndDo;
			
			// Filling in the tabular part "Gift certificates".
			For Each TSRow In GiftCertificates Do
				
				If TSRow.Sum <> 0 Then
					LineOfATabularSection = RetailSalesReportObject.GiftCertificates.Add();
					FillPropertyValues(LineOfATabularSection, TSRow);
				EndIf;
				
			EndDo;
			
			RetailSalesReportObject.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(RetailSalesReportObject.Goods, RetailSalesReportObject.PriceIncludesVAT);
			
			SeriesSpecificationParameters = New FixedStructure(Documents.RetailSalesReport.SeriesSpecificationParameters(RetailSalesReportObject));
			ProductsServer.FillInStatusesForSpecifyingSeries(RetailSalesReportObject, SeriesSpecificationParameters);
						
		EndIf;
		
		RetailSalesReportLocalization.Filling(RetailSalesReportObject, Undefined, True);
		
		If Not OnlyFillIn Then
			
			RetailSalesReportObject.Write(DocumentWriteMode.Write);
			If RetailSalesReportObject.CheckFilling() Then
				ThisIsAttemptToHoldDocument = True;
				RetailSalesReportObject.Write(DocumentWriteMode.Posting);
			Else
				ErrorDescription = NStr("vi = 'Khi kiểm tra điền trước khi kết chuyển chứng từ %Document% theo phiên %CashRegisterShift%đã xảy ra lỗi. Đã ghi lại chứng từ, nhưng chưa kết chuyển.';
										|ru = 'При проверке заполнения перед проведением документа %Document% по кассовой смене %CashRegisterShift% произошла ошибка. Документ записан, но не проведен.';
										|en = 'An error occurred when posting the %Document% document for the %CashRegisterShift% POS shift. The document is saved but not posted.'; fa = 'An error occurred when posting the %Document% document for the %CashRegisterShift% POS shift. The document is saved but not posted.';
										|it = 'При проверке заполнения перед проведением документа %Document% по кассовой смене %CashRegisterShift% произошла ошибка. Документ записан, но не проведен.';
										|pl = 'An error occurred when posting the %Document% document for the %CashRegisterShift% POS shift. The document is saved but not posted.';
										|tr = 'Kasa vardiyasının satış raporu %Document% belgesini kaydetmeden önce doldurma kontrol edilirken hata oluştu %CashRegisterShift%. Belge saklandı, ancak kaydedilmedi.'");
				ErrorDescription = StrReplace(ErrorDescription, "%CashRegisterShift%", RegisterShiftState.CashRegisterShift);
				ErrorDescription = StrReplace(ErrorDescription, "%Document%", RetailSalesReportObject.Ref);
				WriteLogEvent(NStr("vi = 'Bán lẻ';
									|ru = 'Розничные продажи';
									|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
									|it = 'Vendite al dettaglio';
									|pl = 'Sprzedaże detaliczne';
									|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
			EndIf;
			
		EndIf;
		
		Return RetailSalesReportObject.Ref;
		
	Except
		
		ErrorDescription = NStr("vi = 'Khi tạo bảng kê bán lẻ hàng hóa theo phiên thu ngân %CashRegisterShift% đã xảy ra lỗi.
		                            |Mô tả bổ sung:
		                            |%AdditionalDetails%';
		                            |ru = 'При создании отчета о розничных продажах по кассовой смене %CashRegisterShift% произошла ошибка.
		                            |Дополнительное описание:
		                            |%AdditionalDetails%';
		                            |en = 'An error occurred when generating the retail sales report for the %CashRegisterShift% POS shift.
		                            |Additional details:
		                            |%AdditionalDetails%'; fa = 'An error occurred when generating the retail sales report for the %CashRegisterShift% POS shift.
		                            |Additional details:
		                            |%AdditionalDetails%';
		                            |it = 'При создании отчета о розничных продажах по кассовой смене %CashRegisterShift% произошла ошибка.
		                            |Дополнительное описание:
		                            |%AdditionalDetails%';
		                            |pl = 'An error occurred when generating the retail sales report for the %CashRegisterShift% POS shift.
		                            |Additional details:
		                            |%AdditionalDetails%';
		                            |tr = 'Kasa vardiyasının%CashRegisterShift% perakende satış raporu oluşturulurken bir hata oluştu.
		                            | Ek açıklama:
		                            |%AdditionalDetails%'");
		ErrorDescription = StrReplace(ErrorDescription, "%CashRegisterShift%", RegisterShiftState.CashRegisterShift);
		ErrorDescription = StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
		
		Return ?(Not OnlyFillIn And ThisIsAttemptToHoldDocument And ValueIsFilled(RetailSalesReportObject.Ref), RetailSalesReportObject.Ref, Undefined);
		
	EndTry;
	
EndFunction 

// Performs filling out a Report on retail refunds for a cash shift.
//
// Parameters:
//  RegisterShiftState - See DescriptionOfCashShift.
//	VATTaxation - EnumRef - The type of VAT taxation according to which it is necessary to fill out Reports on retail sales /refunds.
//	TempTablesManager - TempTablesManager -  
//	GoodsReturnLinesPerShift - Array of LineOfATabularSection - 
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  DocumentRef.RetailReturnsReport - A link to the report if the operation was completed successfully. Otherwise, It Is Uncertain.
//
Function FillOutReportOnRetailReturnsForCashShift(RegisterShiftState, VATTaxation, TempTablesManager, GoodsReturnLinesPerShift, ErrorDescription = "") Export
	
	SetPrivilegedMode(True);
	
	// Search for a report on retail refunds by type of taxation
	RetailReturnsReport = FindRetailReturnsReport(RegisterShiftState.CashRegisterShift, VATTaxation);
	UpdateReports = RegisterShiftState.UpdateReports;
	If RetailReturnsReport = Undefined Then
		RetailReturnsReportObject = Documents.RetailReturnsReport.CreateDocument();
		UpdateReports = True;
	Else
		RetailReturnsReportObject = RetailReturnsReport.GetObject();
	EndIf;
	
	If UpdateReports Then
		RetailReturnsReportObject.AdditionalProperties.Insert("SoftwareFilling", True);
		Return CompleteRetailReturnsReport(
			RetailReturnsReportObject,
			RegisterShiftState,
			VATTaxation,
			TempTablesManager,
			GoodsReturnLinesPerShift,
			,
			ErrorDescription);
	Else
		Return RetailReturnsReport;
	EndIf;
	
EndFunction

// Performs filling out a Report on retail refunds for a cash shift.
//
// Parameters:
//  RetailReturnsReportObject - DocumentObject.RetailReturnsReport - The document to be filled in.
//  RegisterShiftState - See DescriptionOfCashShift.
//	VATTaxation - EnumRef - The type of VAT taxation according to which it is necessary to fill out Reports on retail sales /refunds.
//	TempTablesManager - TempTablesManager -
//	GoodsReturnLinesPerShift - Undefined, Array of LineOfATabularSection - Product return lines in the sales shift
//	OnlyFillIn - Boolean - A flag that determines whether an attempt will be made to conduct/record after filling in.
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  DocumentRef.RetailReturnsReport - A link to the report if the operation was completed successfully. Otherwise, It Is Uncertain.
//
Function CompleteRetailReturnsReport(
	RetailReturnsReportObject,
	RegisterShiftState,
	VATTaxation,
	TempTablesManager,
	GoodsReturnLinesPerShift = Undefined,
	OnlyFillIn = False,
	ErrorDescription = "") Export
	
	SetPrivilegedMode(True);
	
	// Filling out a report on retail returns, 
	// receipts of the CMC return outside the sales shift or without a sales receipt, 
	// receipts of the CMC correction with the basis outside the sales shift.
	Try
		
		ThisIsAttemptToHoldDocument = False;
		
		// Data preparation.
		QueryText = "SELECT
		|	CashRegisterReceiptGoods.ByCorrectionReceipt    AS ByCorrectionReceipt,
		|	CashRegisterReceiptGoods.Ref             AS Ref,
		|	CashRegisterReceiptGoods.CashRegisterReceiptRef       AS CashRegisterReceiptRef,
		|	CashRegisterReceiptGoods.ProductsInSet   AS ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products       AS Products,
		|	CashRegisterReceiptGoods.Characteristic     AS Characteristic,
		|	CashRegisterReceiptGoods.Series              AS Series,
		|	CashRegisterReceiptGoods.Package           AS Package,
		|	CashRegisterReceiptGoods.Price               AS Price,
		|	CashRegisterReceiptGoods.VATRate          AS VATRate,
		|	CashRegisterReceiptGoods.NumberOfPackages AS NumberOfPackages,
		|	CashRegisterReceiptGoods.Count         AS Count,
		|	CashRegisterReceiptGoods.Sum              AS Sum,
		|	CashRegisterReceiptGoods.VATAmount           AS VATAmount,
		|	CashRegisterReceiptGoods.Warehouse              AS Warehouse,
		|	CashRegisterReceiptGoods.Partner            AS Partner,
		|	CashRegisterReceiptGoods.Premise          AS Premise,
		|	CashRegisterReceiptGoods.Seller           AS Seller,
		|	CashRegisterReceiptGoods.Currency             AS Currency,
		|	CashRegisterReceiptGoods.PriceKind            AS PriceKind,
		|	CashRegisterReceiptGoods.CashRegister           AS CashRegister,
		|	CashRegisterReceiptGoods.Organization        AS Organization,
		|	CashRegisterReceiptGoods.VATTaxation AS VATTaxation,
		|	CashRegisterReceiptGoods.CostDefiningMethod AS CostDefiningMethod,
		|	CashRegisterReceiptGoods.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|	CashRegisterReceiptGoods.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|	
		|INTO GoodsList
		|FROM
		|	RetailReturnsProducts AS CashRegisterReceiptGoods
		|WHERE 
		|	CashRegisterReceiptGoods.VATTaxation = &VATTaxation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsList.ByCorrectionReceipt AS ByCorrectionReceipt,
		|	GoodsList.Ref AS Ref,
		|	GoodsList.CostDefiningMethod AS CostDefiningMethod,
		|	GoodsList.CashRegisterReceiptRef AS CashRegisterReceiptRef,
		|	GoodsList.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|	GoodsList.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|INTO CashRegisterReceipts
		|FROM
		|	GoodsList AS GoodsList
		|
		|INDEX BY
		|	Ref
		|;
		|
		|SELECT 
		|   CashRegisterReceiptsSalesDocuments.CashRegisterShift AS CashRegisterShift,
		|   CashRegisterReceiptsSalesDocuments.VATTaxation AS VATTaxation,
		|	CashRegisterReceiptsSalesDocuments.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
		|FROM CashRegisterReceiptsSalesDocuments AS CashRegisterReceiptsSalesDocuments
		|WHERE 
		|	NOT CashRegisterReceiptsSalesDocuments.DocumentSalesOfGoodsAndServices = UNDEFINED
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsList.Currency AS Currency,
		|	GoodsList.PriceKind AS PriceKind,
		|	GoodsList.CashRegister AS CashRegister,
		|	GoodsList.Organization AS Organization,
		|	GoodsList.VATTaxation AS VATTaxation,
		|	GoodsList.Warehouse AS Warehouse
		|FROM
		|	GoodsList AS GoodsList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsList.ProductsInSet AS ProductsInSet,
		|	GoodsList.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsList.Products AS Products,
		|	GoodsList.Characteristic AS Characteristic,
		|	GoodsList.Series AS Series,
		|	GoodsList.Package AS Package,
		|	GoodsList.Price AS Price,
		|	GoodsList.VATRate AS VATRate
		|FROM
		|	GoodsList AS GoodsList
		|";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("CashRegisterShift", RegisterShiftState.CashRegisterShift);
		Query.SetParameter("VATTaxation", VATTaxation);
		
		Query.TempTablesManager = TempTablesManager;
		ResultsArray = Query.ExecuteBatch();
		
		TableOfImplementationDocuments = ResultsArray[2].Unload();
		TableOfImplementationDocuments.Indexes.Add("CashRegisterShift,VATTaxation");
		
		// Formation of index tables by analytics and nomenclature
		TableOfIndexesForAnalytics = ResultsArray[3].Unload();
		TMCommonUse.NumberValueTable(TableOfIndexesForAnalytics,"IndexOf");
		
		IndexTableByProduct = ResultsArray[4].Unload();
		TMCommonUse.NumberValueTable(IndexTableByProduct,"IndexOf");
		
		QueryText = 
		"SELECT
		|	IndexTable.IndexOf AS AnalyticsIndex,
		|	IndexTable.Currency AS Currency,
		|	IndexTable.PriceKind AS PriceKind,
		|	IndexTable.CashRegister AS CashRegister,
		|	IndexTable.Organization AS Organization,
		|	IndexTable.VATTaxation AS VATTaxation,
		|	IndexTable.Warehouse AS Warehouse
		|INTO AnalyticsIndexes
		|FROM
		|	&TableOfIndexesForAnalytics AS IndexTable
		|
		|INDEX BY
		|	Currency,
		|	PriceKind,
		|	CashRegister,
		|	Organization,
		|	VATTaxation,
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IndexTable.IndexOf AS ProductItemIndex,
		|	IndexTable.ProductsInSet   AS ProductsInSet,
		|	IndexTable.ItemVariantOfSet AS ItemVariantOfSet,
		|	IndexTable.Products AS Products,
		|	IndexTable.Characteristic AS Characteristic,
		|	IndexTable.Series AS Series,
		|	IndexTable.Package AS Package,
		|	IndexTable.Price AS Price,
		|	IndexTable.VATRate AS VATRate
		|INTO ProductIndexes
		|FROM
		|	&IndexTableByProduct AS IndexTable
		|
		|INDEX BY
		|	ProductsInSet,
		|	ItemVariantOfSet,
		|	Products,
		|	Characteristic,
		|	Series,
		|	Package,
		|	Price,
		|	VATRate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsList.ByCorrectionReceipt AS ByCorrectionReceipt,
		|	GoodsList.ProductsInSet AS ProductsInSet,
		|	GoodsList.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsList.Products AS Products,
		|	GoodsList.Characteristic AS Characteristic,
		|	GoodsList.Series AS Series,
		|	GoodsList.Package AS Package,
		|	GoodsList.Price AS Price,
		|	GoodsList.Partner AS Partner,
		|	GoodsList.Premise AS Premise,
		|	GoodsList.Seller AS Seller,
		|	GoodsList.VATRate AS VATRate,
		|	SUM(GoodsList.NumberOfPackages) AS NumberOfPackages,
		|	SUM(GoodsList.Count) AS Count,
		|	SUM(GoodsList.Sum) AS Sum,
		|	SUM(GoodsList.VATAmount) AS VATAmount,
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex,
		|	ProductIndexes.ProductItemIndex AS ProductItemIndex,
		|	GoodsList.Warehouse AS Warehouse,
		|	GoodsList.Currency AS Currency,
		|	GoodsList.PriceKind AS PriceKind,
		|	GoodsList.CashRegister AS CashRegister,
		|	GoodsList.Organization AS Organization,
		|	GoodsList.VATTaxation AS VATTaxation,
		|	GoodsList.CostDefiningMethod AS CostDefiningMethod,
		|	GoodsList.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|	GoodsList.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift,
		|	GoodsList.ReturnToShift AS ReturnToShift
		|FROM
		|	(SELECT
		|		GoodsList.ByCorrectionReceipt AS ByCorrectionReceipt,
		|		GoodsList.ProductsInSet AS ProductsInSet,
		|		GoodsList.ItemVariantOfSet AS ItemVariantOfSet,
		|		GoodsList.Products AS Products,
		|		GoodsList.Characteristic AS Characteristic,
		|		GoodsList.Series AS Series,
		|		GoodsList.Package AS Package,
		|		GoodsList.Price AS Price,
		|		GoodsList.Partner AS Partner,
		|		GoodsList.Premise AS Premise,
		|		GoodsList.Seller AS Seller,
		|		GoodsList.VATRate AS VATRate,
		|		GoodsList.NumberOfPackages AS NumberOfPackages,
		|		GoodsList.Count AS Count,
		|		GoodsList.Sum AS Sum,
		|		GoodsList.VATAmount AS VATAmount,
		|		GoodsList.Warehouse AS Warehouse,
		|		GoodsList.Currency AS Currency,
		|		GoodsList.PriceKind AS PriceKind,
		|		GoodsList.CashRegister AS CashRegister,
		|		GoodsList.Organization AS Organization,
		|		GoodsList.VATTaxation AS VATTaxation,
		|		GoodsList.CostDefiningMethod AS CostDefiningMethod,
		|		GoodsList.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|		GoodsList.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift,
		|		NOT (CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt IS NULL) AS ReturnToShift
		|	FROM
		|		GoodsList AS GoodsList
		|			LEFT JOIN CashRegisterReceiptsForReturnsThatAreReflectedInRRR AS CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|			ON CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt = GoodsList.CashRegisterReceiptRef
		|	) AS GoodsList
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON GoodsList.Warehouse = AnalyticsIndexes.Warehouse
		|			AND GoodsList.Currency = AnalyticsIndexes.Currency
		|			AND GoodsList.PriceKind = AnalyticsIndexes.PriceKind
		|			AND GoodsList.CashRegister = AnalyticsIndexes.CashRegister
		|			AND GoodsList.Organization = AnalyticsIndexes.Organization
		|			AND GoodsList.VATTaxation = AnalyticsIndexes.VATTaxation
		|		LEFT JOIN ProductIndexes AS ProductIndexes
		|		ON GoodsList.Products = ProductIndexes.Products
		|			AND GoodsList.ProductsInSet = ProductIndexes.ProductsInSet
		|			AND GoodsList.ItemVariantOfSet = ProductIndexes.ItemVariantOfSet
		|			AND GoodsList.Characteristic = ProductIndexes.Characteristic
		|			AND GoodsList.Series = ProductIndexes.Series
		|			AND GoodsList.Package = ProductIndexes.Package
		|			AND GoodsList.Price = ProductIndexes.Price
		|			AND GoodsList.VATRate = ProductIndexes.VATRate
		|
		|GROUP BY
		|	GoodsList.ByCorrectionReceipt,
		|	GoodsList.ProductsInSet,
		|	GoodsList.ItemVariantOfSet,
		|	GoodsList.Products,
		|	GoodsList.Characteristic,
		|	GoodsList.Series,
		|	GoodsList.VATRate,
		|	GoodsList.Package,
		|	GoodsList.Price,
		|	GoodsList.Partner,
		|	GoodsList.Premise,
		|	GoodsList.Seller,
		|	ProductIndexes.VATRate,
		|	AnalyticsIndexes.AnalyticsIndex,
		|	ProductIndexes.ProductItemIndex,
		|	GoodsList.Warehouse,
		|	GoodsList.Currency,
		|	GoodsList.PriceKind,
		|	GoodsList.CashRegister,
		|	GoodsList.Organization,
		|	GoodsList.VATTaxation,
		|	GoodsList.CostDefiningMethod,
		|	GoodsList.CashRegisterReceiptVATTaxation,
		|	GoodsList.CashRegisterReceiptCashRegisterShift,
		|	GoodsList.ReturnToShift
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Series,
		|	Package,
		|	PriceKind,
		|	Price,
		|	Partner,
		|	Seller,
		|	AnalyticsIndex,
		|	ByCorrectionReceipt
		|
		|TOTALS
		|	MAX(ByCorrectionReceipt),
		|	MAX(ProductsInSet),
		|	MAX(ItemVariantOfSet),
		|	MAX(Products),
		|	MAX(Characteristic),
		|	MAX(Series),
		|	MAX(Package),
		|	MAX(Price),
		|	MAX(Partner),
		|	MAX(Premise),
		|	MAX(Seller),
		|	MAX(VATRate),
		|	MAX(NumberOfPackages),
		|	MAX(Count),
		|	MAX(Sum),
		|	MAX(VATAmount),
		|	MAX(Warehouse),
		|	MAX(Currency),
		|	MAX(PriceKind),
		|	MAX(CashRegister),
		|	MAX(Organization),
		|	MAX(VATTaxation)
		|BY
		|	AnalyticsIndex,
		|	ProductItemIndex
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PaymentWithPaymentCards.PaymentKind_ AS PaymentKind_,
		|	PaymentWithPaymentCards.POSTerminal AS POSTerminal,
		|	PaymentWithPaymentCards.PaymentCardNumber AS PaymentCardNumber,
		|	PaymentWithPaymentCards.AuthorizationCode AS AuthorizationCode,
		|	PaymentWithPaymentCards.ConnectionContract AS ConnectionContract,
		|	SUM(PaymentWithPaymentCards.Sum) AS Sum,
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex
		|FROM
		|	(SELECT
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.Ref AS Ref,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.PaymentKind_ AS PaymentKind_,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.POSTerminal,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.PaymentCardNumber,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.AuthorizationCode,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.ConnectionContract,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.Sum,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.Ref.CashRegister,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.Ref.Organization,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.Ref.Warehouse,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.Ref.Currency,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.Ref.PriceKind
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|		INNER JOIN Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS CashRegisterReceiptReturnPaymentWithPaymentCards
		|		ON CashRegisterReceiptReturnPaymentWithPaymentCards.Ref = CashRegisterReceipts.Ref
		|	WHERE
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.PaymentIsCanceled
		|	) AS PaymentWithPaymentCards
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON PaymentWithPaymentCards.CashRegister = AnalyticsIndexes.CashRegister
		|			AND PaymentWithPaymentCards.Organization = AnalyticsIndexes.Organization
		|			AND PaymentWithPaymentCards.Warehouse = AnalyticsIndexes.Warehouse
		|			AND PaymentWithPaymentCards.Currency = AnalyticsIndexes.Currency
		|			AND PaymentWithPaymentCards.PriceKind = AnalyticsIndexes.PriceKind
		|GROUP BY
		|	PaymentWithPaymentCards.PaymentKind_,
		|	PaymentWithPaymentCards.POSTerminal,
		|	PaymentWithPaymentCards.PaymentCardNumber,
		|	PaymentWithPaymentCards.AuthorizationCode,
		|	PaymentWithPaymentCards.ConnectionContract,
		|	AnalyticsIndexes.AnalyticsIndex
		|
		|ORDER BY
		|	PaymentKind_,
		|	POSTerminal,
		|	AnalyticsIndex,
		|	PaymentCardNumber,
		|	AuthorizationCode,
		|	ConnectionContract
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Premise                      AS Premise,
		|	SetOfSeries.Series                          AS Series,
		|	SetOfSeries.Products                   AS Products,
		|	SetOfSeries.Characteristic                 AS Characteristic,
		|	SUM(SetOfSeries.Count)              AS Count,
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex,
		|	SetOfSeries.ByCorrectionReceipt 				 AS ByCorrectionReceipt,
		|	SetOfSeries.CostDefiningMethod AS CostDefiningMethod,
		|	SetOfSeries.CashRegisterReceiptVATTaxation       AS CashRegisterReceiptVATTaxation,
		|	SetOfSeries.CashRegisterReceiptCashRegisterShift            AS CashRegisterReceiptCashRegisterShift
		|FROM
		|	(SELECT
		|		CashRegisterReceiptReturnSetOfSeries.Premise,
		|		CashRegisterReceiptReturnSetOfSeries.Series,
		|		CashRegisterReceiptReturnSetOfSeries.Products,
		|		CashRegisterReceiptReturnSetOfSeries.Characteristic,
		|		CashRegisterReceiptReturnSetOfSeries.Count,
		|		CashRegisterReceiptReturnSetOfSeries.Ref.CashRegister,
		|		CashRegisterReceiptReturnSetOfSeries.Ref.Organization,
		|		CashRegisterReceiptReturnSetOfSeries.Ref.Warehouse,
		|		CashRegisterReceiptReturnSetOfSeries.Ref.Currency,
		|		CashRegisterReceiptReturnSetOfSeries.Ref.PriceKind,
		|		CashRegisterReceipts.ByCorrectionReceipt AS ByCorrectionReceipt,
		|		CashRegisterReceipts.CostDefiningMethod AS CostDefiningMethod,
		|		CashRegisterReceipts.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|		CashRegisterReceipts.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|		INNER JOIN Document.CashRegisterReceiptReturn.SetOfSeries AS CashRegisterReceiptReturnSetOfSeries
		|		ON CashRegisterReceiptReturnSetOfSeries.Ref = CashRegisterReceipts.Ref
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = FALSE
		|
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceiptSetOfSeries.Premise AS Premise,
		|		CashRegisterReceiptSetOfSeries.Series AS Series,
		|		CashRegisterReceiptSetOfSeries.Products AS Products,
		|		CashRegisterReceiptSetOfSeries.Characteristic AS Characteristic,
		|		CashRegisterReceiptSetOfSeries.Count AS Count,
		|		CashRegisterReceiptSetOfSeries.Ref.CashRegister AS CashRegister,
		|		CashRegisterReceiptSetOfSeries.Ref.Organization AS Organization,
		|		CashRegisterReceiptSetOfSeries.Ref.Warehouse AS Warehouse,
		|		CashRegisterReceiptSetOfSeries.Ref.Currency AS Currency,
		|		CashRegisterReceiptSetOfSeries.Ref.PriceKind AS PriceKind,
		|		CashRegisterReceipts.ByCorrectionReceipt AS ByCorrectionReceipt,
		|		CashRegisterReceipts.CostDefiningMethod AS CostDefiningMethod,
		|		CashRegisterReceipts.CashRegisterReceiptVATTaxation AS CashRegisterReceiptVATTaxation,
		|		CashRegisterReceipts.CashRegisterReceiptCashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|		INNER JOIN Document.CashRegisterReceipt.SetOfSeries AS CashRegisterReceiptSetOfSeries
		|		ON CashRegisterReceiptSetOfSeries.Ref = CashRegisterReceipts.Ref
		|	WHERE
		|		CashRegisterReceipts.ByCorrectionReceipt = TRUE
		|) AS SetOfSeries
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON SetOfSeries.CashRegister = AnalyticsIndexes.CashRegister
		|			AND SetOfSeries.Organization = AnalyticsIndexes.Organization
		|			AND SetOfSeries.Warehouse = AnalyticsIndexes.Warehouse
		|			AND SetOfSeries.Currency = AnalyticsIndexes.Currency
		|			AND SetOfSeries.PriceKind = AnalyticsIndexes.PriceKind
		|GROUP BY
		|	SetOfSeries.Premise,
		|	SetOfSeries.Series,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	AnalyticsIndexes.AnalyticsIndex,
		|	SetOfSeries.ByCorrectionReceipt,
		|	SetOfSeries.CostDefiningMethod,
		|	SetOfSeries.CashRegisterReceiptVATTaxation,
		|	SetOfSeries.CashRegisterReceiptCashRegisterShift
		|
		|ORDER BY
		|	AnalyticsIndex,
		|	Premise,
		|	Products,
		|	Characteristic,
		|	Series,
		|	CostDefiningMethod,
		|	CashRegisterReceiptCashRegisterShift,
		|	CashRegisterReceiptVATTaxation,
		|	ByCorrectionReceipt
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalyticsIndexes.AnalyticsIndex          AS AnalyticsIndex,
		|	BonusPoints.LoyaltyProgram     AS LoyaltyProgram,
		|	BonusPoints.AccrualDate                  AS AccrualDate,
		|	BonusPoints.DateOfDeduction                    AS DateOfDeduction,
		|	BonusPoints.Partner                         AS Partner,
		|	SUM(BonusPoints.AmountOfBonusPoints)      AS AmountOfBonusPoints
		|FROM
		|(SELECT
		|	BonusPoints.Ref.CashRegister    AS CashRegister,
		|	BonusPoints.Ref.Organization AS Organization,
		|	BonusPoints.Ref.Warehouse       AS Warehouse,
		|	BonusPoints.Ref.Currency      AS Currency,
		|	BonusPoints.Ref.PriceKind     AS PriceKind,
		|	BonusPoints.Ref.Partner     AS Partner,		
		|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
		|	BonusPoints.AccrualDate              AS AccrualDate,
		|	BonusPoints.DateOfDeduction                AS DateOfDeduction,
		|	BonusPoints.AmountOfBonusPoints        AS AmountOfBonusPoints
		|FROM
		|	CashRegisterReceipts AS CashRegisterReceipts
		|	INNER JOIN Document.CashRegisterReceiptReturn.BonusPoints AS BonusPoints
		|	ON BonusPoints.Ref = CashRegisterReceipts.Ref
		|) AS BonusPoints
		|
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON BonusPoints.CashRegister = AnalyticsIndexes.CashRegister
		|			AND BonusPoints.Organization = AnalyticsIndexes.Organization
		|			AND BonusPoints.Warehouse = AnalyticsIndexes.Warehouse
		|			AND BonusPoints.Currency = AnalyticsIndexes.Currency
		|			AND BonusPoints.PriceKind = AnalyticsIndexes.PriceKind
		|GROUP BY
		|	AnalyticsIndexes.AnalyticsIndex,
		|	BonusPoints.AccrualDate,
		|	BonusPoints.DateOfDeduction,
		|	BonusPoints.LoyaltyProgram,
		|	BonusPoints.Partner
		|HAVING
		|	SUM(BonusPoints.AmountOfBonusPoints) <> 0
		|
		|ORDER BY
		|	Partner,
		|	LoyaltyProgram,
		|	AnalyticsIndex,
		|	AccrualDate,
		|	DateOfDeduction
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalyticsIndexes.AnalyticsIndex          AS AnalyticsIndex,
		|	BonusPoints.LoyaltyProgram     AS LoyaltyProgram,
		|	BonusPoints.PayDate                  AS PayDate,
		|	BonusPoints.Partner                         AS Partner,
		|	SUM(BonusPoints.AmountOfBonusPoints)      AS AmountOfBonusPoints
		|FROM
		|(
		|SELECT
		|	CashRegisterReceiptReturn.CashRegister    AS CashRegister,
		|	CashRegisterReceiptReturn.Organization AS Organization,
		|	CashRegisterReceiptReturn.Warehouse       AS Warehouse,
		|	CashRegisterReceiptReturn.Currency      AS Currency,
		|	CashRegisterReceiptReturn.PriceKind     AS PriceKind,
		|	CashRegisterReceiptReturn.Partner     AS Partner,
		
		|	CashRegisterReceiptReturn.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
		|	CashRegisterReceiptReturn.Date                                                 AS PayDate,
		|	CashRegisterReceiptReturn.AmountOfBonusPointsToReturn                        AS AmountOfBonusPoints
		|FROM
		|	CashRegisterReceipts AS CashRegisterReceipts
		|	INNER JOIN Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
		|	ON CashRegisterReceiptReturn.Ref = CashRegisterReceipts.Ref
		|) AS BonusPoints
		|
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON BonusPoints.CashRegister = AnalyticsIndexes.CashRegister
		|			AND BonusPoints.Organization = AnalyticsIndexes.Organization
		|			AND BonusPoints.Warehouse = AnalyticsIndexes.Warehouse
		|			AND BonusPoints.Currency = AnalyticsIndexes.Currency
		|			AND BonusPoints.PriceKind = AnalyticsIndexes.PriceKind
		|GROUP BY
		|	AnalyticsIndexes.AnalyticsIndex,
		|	BonusPoints.PayDate,
		|	BonusPoints.LoyaltyProgram,
		|	BonusPoints.Partner
		|HAVING
		|	SUM(BonusPoints.AmountOfBonusPoints) <> 0
		|
		|ORDER BY
		|	Partner,
		|	LoyaltyProgram,
		|	AnalyticsIndex,
		|	PayDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalyticsIndexes.AnalyticsIndex AS AnalyticsIndex,
		|	ExciseStamps.Help2               AS Help2,
		|	ExciseStamps.ExciseStamp          AS ExciseStamp
		|FROM
		|(
		|	SELECT
		|		Table.Ref.CashRegister    AS CashRegister,
		|		Table.Ref.Organization AS Organization,
		|		Table.Ref.Warehouse       AS Warehouse,
		|		Table.Ref.Currency      AS Currency,
		|		Table.Ref.PriceKind     AS PriceKind,
		|		Table.Help2           AS Help2,
		|		Table.ExciseStamp      AS ExciseStamp,
		|		1                          AS NumberOfExciseTaxes
		|	FROM
		|		CashRegisterReceipts AS CashRegisterReceipts
		|		INNER JOIN Document.CashRegisterReceiptReturn.ExciseStamps AS Table
		|		ON Table.Ref = CashRegisterReceipts.Ref
		|	) AS ExciseStamps
		|		LEFT JOIN AnalyticsIndexes AS AnalyticsIndexes
		|		ON ExciseStamps.CashRegister = AnalyticsIndexes.CashRegister
		|			AND ExciseStamps.Organization = AnalyticsIndexes.Organization
		|			AND ExciseStamps.Warehouse = AnalyticsIndexes.Warehouse
		|			AND ExciseStamps.Currency = AnalyticsIndexes.Currency
		|			AND ExciseStamps.PriceKind = AnalyticsIndexes.PriceKind
		|GROUP BY
		|	AnalyticsIndexes.AnalyticsIndex,
		|	ExciseStamps.Help2,
		|	ExciseStamps.ExciseStamp
		|HAVING
		|	SUM(ExciseStamps.NumberOfExciseTaxes) > 0
		|
		|ORDER BY
		|	AnalyticsIndex,
		|	ExciseStamp
		|;
		|DROP GoodsList
		|;
		|DROP CashRegisterReceipts
		|;
		|DROP AnalyticsIndexes
		|;
		|DROP ProductIndexes
		|";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("TableOfIndexesForAnalytics", TableOfIndexesForAnalytics);
		Query.SetParameter("IndexTableByProduct", IndexTableByProduct);
		
		Result = Query.ExecuteBatch();
		
		PaymentWithPaymentCards = Result[3].Unload(); // ValueTable
		SetOfSeries                   = Result[4].Unload(); // ValueTable
		BonusPoints           = Result[5].Unload(); // ValueTable
		PaymentWithBonusPoints  = Result[6].Unload(); // ValueTable
		ExciseStamps           = Result[7].Unload(); // ValueTable
		
		PaymentWithPaymentCards.Indexes.Add("AnalyticsIndex");
		SetOfSeries.Indexes.Add("AnalyticsIndex");
		BonusPoints.Indexes.Add("AnalyticsIndex");
		PaymentWithBonusPoints.Indexes.Add("AnalyticsIndex");
		ExciseStamps.Indexes.Add("AnalyticsIndex");
		
		SampleByAnalytics = Result[2].Select(QueryResultIteration.ByGroups);
				
		// Let's clear the tabular parts of the document.
		RetailReturnsReportObject.Goods.Clear();
		RetailReturnsReportObject.SetOfSeries.Clear();
		RetailReturnsReportObject.PaymentWithPaymentCards.Clear();
		RetailReturnsReportObject.InventoryKinds.Clear();
		RetailReturnsReportObject.BonusPointAccrual.Clear();
		RetailReturnsReportObject.PaymentWithBonusPoints.Clear();
		RetailReturnsReportObject.ExciseStamps.Clear();
		
		GoodsReturnLinesPerShift = New Array;
		
		If SampleByAnalytics.Next() Then
			
			FillPropertyValues(RetailReturnsReportObject, SampleByAnalytics);
			
			SelectionBasedOnProductAnalysis = SampleByAnalytics.Select(QueryResultIteration.ByGroups);
			While SelectionBasedOnProductAnalysis.Next() Do
				
				SelectionDetailRecords = SelectionBasedOnProductAnalysis.Select();
				While SelectionDetailRecords.Next() Do
					
					If SelectionDetailRecords.Count <> 0 Then
						
						RowOfTablePartProducts = RetailReturnsReportObject.Goods.Add();
						FillPropertyValues(RowOfTablePartProducts, SelectionDetailRecords);
						RowOfTablePartProductsNumberOfPackages = ?(
							RowOfTablePartProducts.NumberOfPackages = 0,
							SelectionDetailRecords.Count,
							RowOfTablePartProducts.NumberOfPackages);
						RowOfTablePartProducts.Price = Round(
							RowOfTablePartProducts.Sum / RowOfTablePartProductsNumberOfPackages, 15, 2);
						
						SelectFillInImplementationDocumentInLine(
							RowOfTablePartProducts,
							TableOfImplementationDocuments,
							RegisterShiftState,
							SelectionDetailRecords,
							True);
						
						If SelectionDetailRecords.ReturnToShift
							And Not OnlyFillIn Then
							RowOfTablePartProducts.CostDefiningMethod
								 = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
							GoodsReturnLinesPerShift.Add(RowOfTablePartProducts);
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
			// Filling in the tabular part "Payment by payment cards".
			RowsArray = PaymentWithPaymentCards.FindRows(
				New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			
			For Each TSRow In RowsArray Do
				
				If TSRow.Sum <> 0 Then
					LineOfATabularSection = RetailReturnsReportObject.PaymentWithPaymentCards.Add();
					FillPropertyValues(LineOfATabularSection, TSRow);
				EndIf;
				
			EndDo;
			
			// Filling in the tabular part of the "Series".
			RowsArray = SetOfSeries.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				If TSRow.Count <> 0 Then
					LineOfATabularSection = RetailReturnsReportObject.SetOfSeries.Add();
					FillPropertyValues(LineOfATabularSection, TSRow);
					SelectFillInImplementationDocumentInLine(LineOfATabularSection, TableOfImplementationDocuments, RegisterShiftState, TSRow, False);
				EndIf;
				
			EndDo;
						
			// Filling in the tabular part of the "Bonus Points".
			RowsArray = BonusPoints.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				LineOfATabularSection = RetailReturnsReportObject.BonusPointAccrual.Add();
				FillPropertyValues(LineOfATabularSection, TSRow);
				
			EndDo;
			
			// Filling in the tabular part of the "Pay with bonus points".
			RowsArray = PaymentWithBonusPoints.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				LineOfATabularSection = RetailReturnsReportObject.PaymentWithBonusPoints.Add();
				FillPropertyValues(LineOfATabularSection, TSRow);
				
			EndDo;
			
			// Filling in the tabular part of the "Excise stamps".
			RowsArray = ExciseStamps.FindRows(New Structure("AnalyticsIndex", SampleByAnalytics.AnalyticsIndex));
			For Each TSRow In RowsArray Do
				
				LineOfATabularSection = RetailReturnsReportObject.ExciseStamps.Add();
				FillPropertyValues(LineOfATabularSection, TSRow);
				
			EndDo;
			
			RetailReturnsReportObject.Date            = RegisterShiftState.StatusChangeDate;
			RetailReturnsReportObject.PriceIncludesVAT = RegisterShiftState.PriceIncludesVAT;
			RetailReturnsReportObject.CashRegisterShift   = RegisterShiftState.CashRegisterShift;
			RetailReturnsReportObject.Department   = RegisterShiftState.Department;
			
		Else	
			// No goods were sold on the cash shift			
			// Fills in the retail sales report with data on the current cash shift.
			FillPropertyValues(RetailReturnsReportObject, RegisterShiftState, , "VATTaxation");
			
			RetailReturnsReportObject.Date           = RegisterShiftState.StatusChangeDate;
			RetailReturnsReportObject.VATTaxation  = VATTaxation;
			
		EndIf;

		ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(RetailReturnsReportObject);
					
		If Not ValueIsFilled(RetailReturnsReportObject.EmployeeResponsible) Then
			RetailReturnsReportObject.EmployeeResponsible = Users.CurrentUser();
		EndIf;
		If Not ValueIsFilled(RetailReturnsReportObject.Department) Then
			RetailReturnsReportObject.Department = SettingsValueCached.UserDivision(RetailReturnsReportObject.EmployeeResponsible, RetailReturnsReportObject.Department);
		EndIf;
		
		RetailReturnsReportObject.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(RetailReturnsReportObject.Goods, RetailReturnsReportObject.PriceIncludesVAT);
		
		If GetFunctionalOption("UseItemsBatch") And RetailReturnsReportObject.Goods.Count() Then
			
			SeriesSpecificationParameters = New FixedStructure(Documents.RetailReturnsReport.SeriesSpecificationParameters(RetailReturnsReportObject));
			ProductsServer.FillInStatusesForSpecifyingSeries(RetailReturnsReportObject, SeriesSpecificationParameters);
			
			// It is necessary to specify the series with the accounting policy "When planning shipment" in a separate tabular part.
			ItIsNecessaryToCollapseTabularParts = False;
			For Each LineProducts_ In RetailReturnsReportObject.Goods Do
				If ValueIsFilled(LineProducts_.Series) 
					And ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(LineProducts_.BatchesIndicationStatus, SeriesSpecificationParameters) Then
					NewRowSeries = RetailReturnsReportObject.SetOfSeries.Add();
					FillPropertyValues(NewRowSeries, LineProducts_);
					LineProducts_.Series = Catalogs.ItemsBatches.EmptyRef();
					ItIsNecessaryToCollapseTabularParts = True;
				EndIf;
			EndDo;
			If ItIsNecessaryToCollapseTabularParts Then
				TMCommonUse.CollapseTablePart(RetailReturnsReportObject, "SetOfSeries");
				NumericColumnsForGrouping = New Array;
				NumericColumnsForGrouping.Add("Price");
				NumericColumnsForGrouping.Add("BatchesIndicationStatus");
				TMCommonUse.CollapseTablePart(RetailReturnsReportObject, "Goods", NumericColumnsForGrouping);
				ProductsServer.FillInStatusesForSpecifyingSeries(RetailReturnsReportObject, SeriesSpecificationParameters);
			EndIf;
			
		EndIf;
		
		RetailReturnsReportLocalization.Filling(RetailReturnsReportObject, Undefined, True);
		
		If Not OnlyFillIn Then
			
			RetailReturnsReportObject.Write(DocumentWriteMode.Write);
			If RetailReturnsReportObject.CheckFilling() Then
				ThisIsAttemptToHoldDocument = True;
				RetailReturnsReportObject.Write(DocumentWriteMode.Posting);
			Else
				ErrorDescription = NStr("vi = 'Khi kiểm tra điền trước khi kết chuyển chứng từ %Document% theo phiên %CashRegisterShift%đã xảy ra lỗi. Đã ghi lại chứng từ, nhưng chưa kết chuyển.';
										|ru = 'При проверке заполнения перед проведением документа %Document% по кассовой смене %CashRegisterShift% произошла ошибка. Документ записан, но не проведен.';
										|en = 'An error occurred when posting the %Document% document for the %CashRegisterShift% POS shift. The document is saved but not posted.'; fa = 'An error occurred when posting the %Document% document for the %CashRegisterShift% POS shift. The document is saved but not posted.';
										|it = 'При проверке заполнения перед проведением документа %Document% по кассовой смене %CashRegisterShift% произошла ошибка. Документ записан, но не проведен.';
										|pl = 'An error occurred when posting the %Document% document for the %CashRegisterShift% POS shift. The document is saved but not posted.';
										|tr = '%Document% belgesini kaydetmeden önce doldurma kontrol edilirken hata oluştu %CashRegisterShift%. Belge saklandı, ancak kaydedilmedi.'");
				ErrorDescription = StrReplace(ErrorDescription, "%CashRegisterShift%", RegisterShiftState.CashRegisterShift);
				ErrorDescription = StrReplace(ErrorDescription, "%Document%", RetailReturnsReportObject.Ref);
				WriteLogEvent(NStr("vi = 'Bán lẻ';
									|ru = 'Розничные продажи';
									|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
									|it = 'Vendite al dettaglio';
									|pl = 'Sprzedaże detaliczne';
									|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
			EndIf;

		EndIf;
		
		Return RetailReturnsReportObject.Ref;
		
	Except
		
		ErrorDescription = NStr("vi = 'Khi tạo bảng kê bán lẻ hàng hóa trả lại theo phiên thu ngân %CashRegisterShift% đã xảy ra lỗi.
		                            |Mô tả bổ sung:
		                            |%AdditionalDetails%';
		                            |ru = 'При создании отчета о розничных возвратах по кассовой смене %CashRegisterShift% произошла ошибка.
		                            |Дополнительное описание:
		                            |%AdditionalDetails%';
		                            |en = 'An error occurred when generating the retail return report for the %CashRegisterShift% POS shift.
		                            |Additional details:
		                            |%AdditionalDetails%'; fa = 'An error occurred when generating the retail return report for the %CashRegisterShift% POS shift.
		                            |Additional details:
		                            |%AdditionalDetails%';
		                            |it = 'При создании отчета о розничных возвратах по кассовой смене %CashRegisterShift% произошла ошибка.
		                            |Дополнительное описание:
		                            |%AdditionalDetails%';
		                            |pl = 'An error occurred when generating the retail return report for the %CashRegisterShift% POS shift.
		                            |Additional details:
		                            |%AdditionalDetails%';
		                            |tr = 'Kasa vardiyasının perakende satış raporu %CashRegisterShift%oluşturulurken bir hata oluştu.
		                            | Ek açıklama:
		                            |%AdditionalDetails%'");
		ErrorDescription = StrReplace(ErrorDescription, "%CashRegisterShift%", RegisterShiftState.CashRegisterShift);
		ErrorDescription = StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorDescription);
		
		Return ?(Not OnlyFillIn And ThisIsAttemptToHoldDocument And ValueIsFilled(RetailReturnsReportObject.Ref), RetailReturnsReportObject.Ref, Undefined);
		
	EndTry;
	
EndFunction 

// Performs the preparation of data on cash shift receipts.
//
// Parameters:
//  RegisterShiftState - See DescriptionOfCashShift
//	TempTablesManager - TempTablesManager -
//  IncludeUnverifiedReceipts - Boolean - The default is false. Conducted and unverified checks will be selected and marked for deletion.
//
// Returns:
//  ValueTable - The table of values is filled with the types of VAT taxation that are used as part of the cash shift:
//  * VATTaxation - EnumRef.VATTaxationTypes
//
Function PrepareDataOnCashShiftReceipts(RegisterShiftState, TempTablesManager, IncludeUnverifiedReceipts = False) Export
	
	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager;	
	EndIf;
	
	// Let's find out how many tax options were used in the cash shift.
	// We will prepare temporary tables of retail sales, retail returns, 
	// which will be used to fill out documents for each type of taxation.
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
		|SELECT
		|	CashRegisterReceiptGoods.Ref AS Ref,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt AS CashRegisterReceipt,
		|	CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products AS Products,
		|	CashRegisterReceiptGoods.Characteristic AS Characteristic,
		|	CashRegisterReceiptGoods.Series AS Series,
		|	CashRegisterReceiptGoods.Package AS Package,
		|	CashRegisterReceiptGoods.Price AS Price,
		|	CashRegisterReceiptGoods.VATRate AS VATRate,
		|	CashRegisterReceiptGoods.NumberOfPackages AS NumberOfPackages,
		|	CashRegisterReceiptGoods.Count AS Count,
		|	CashRegisterReceiptGoods.Sum AS Sum,
		|	CashRegisterReceiptGoods.VATAmount AS VATAmount,
		|	CashRegisterReceiptGoods.Ref.Warehouse AS Warehouse,
		|	CashRegisterReceiptGoods.Ref.Partner AS Partner,
		|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
		|	CashRegisterReceiptGoods.Seller AS Seller,
		|	CashRegisterReceiptGoods.Ref.Date AS Date,
		|	CashRegisterReceiptGoods.Ref.Currency AS Currency,
		|	CashRegisterReceiptGoods.Ref.PriceKind AS PriceKind,
		|	CashRegisterReceiptGoods.Ref.CashRegister AS CashRegister,
		|	CashRegisterReceiptGoods.Ref.Organization AS Organization,
		|	CashRegisterReceiptGoods.Ref.VATTaxation AS VATTaxation
		|INTO GoodsOfRetailReturnsInSalesShift
		|FROM
		|	Document.CashRegisterReceiptReturn.Goods AS CashRegisterReceiptGoods
		|WHERE
		|	CashRegisterReceiptGoods.Ref.CashRegisterShift = &CashRegisterShift
		|	AND (CashRegisterReceiptGoods.Ref.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceiptGoods.Ref.DeletionMark)
		|	AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND NOT CashRegisterReceiptGoods.Ref.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|	AND CashRegisterReceiptGoods.Ref.CashRegisterReceipt.CashRegisterShift = &CashRegisterShift
		|	AND CashRegisterReceiptGoods.NumberOfPackages <> 0
		|
		|INDEX BY
		|	CashRegisterReceipt
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	RetailSalesProducts_.CashRegisterReceipt AS CashRegisterReceipt,
		|	CashRegisterReceipts.Warehouse AS Warehouse,
		|	CashRegisterReceipts.Partner AS Partner,
		|	CashRegisterReceipts.Date AS Date,
		|	CashRegisterReceipts.Currency AS Currency,
		|	CashRegisterReceipts.PriceKind AS PriceKind,
		|	CashRegisterReceipts.CashRegister AS CashRegister,
		|	CashRegisterReceipts.Organization AS Organization,
		|	CashRegisterReceipts.VATTaxation AS VATTaxation,
		|	CashRegisterReceipts.CashRegisterShift AS CashRegisterShift,
		|	CashRegisterReceipts.DocumentAmount AS DocumentAmount,
		|	CashRegisterReceipts.ReceivedInCash AS ReceivedInCash
		|INTO ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift
		|FROM
		|	GoodsOfRetailReturnsInSalesShift AS RetailSalesProducts_
		|		LEFT JOIN Document.CashRegisterReceipt AS CashRegisterReceipts
		|		ON (CashRegisterReceipts.Ref = RetailSalesProducts_.CashRegisterReceipt)
		|WHERE
		|	RetailSalesProducts_.Ref REFS Document.CashRegisterReceiptReturn
		|
		|INDEX BY
		|	CashRegisterReceipt
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	RetailSalesProducts_.Ref AS CashRegisterReceiptReturn,
		|	RetailSalesProducts_.CashRegisterReceipt AS CashRegisterReceipt,
		|	RetailSalesProducts_.Ref.IssueInCash AS IssueInCash
		|INTO CashRegisterAndReturnReceiptsIssuedDuringShift
		|FROM
		|	GoodsOfRetailReturnsInSalesShift AS RetailSalesProducts_
		|
		|INDEX BY
		|	CashRegisterReceiptReturn
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ListOfProblematicReturnsPerShift.CashRegisterReceipt AS CashRegisterReceipt
		|INTO CashRegisterReceiptsForProblematicReturnsPerShift
		|FROM
		|	(SELECT
		|		ListOfSalesPerShift.CashRegisterReceipt AS CashRegisterReceipt,
		|		ListOfSalesPerShift.ProductsInSet AS ProductsInSet,
		|		ListOfSalesPerShift.ItemVariantOfSet AS ItemVariantOfSet,
		|		ListOfSalesPerShift.Products AS Products,
		|		ListOfSalesPerShift.Characteristic AS Characteristic,
		|		ListOfSalesPerShift.Series AS Series,
		|		ListOfSalesPerShift.Package AS Package,
		|		ListOfSalesPerShift.Price AS Price,
		|		ListOfSalesPerShift.VATRate AS VATRate,
		|		SUM(ListOfSalesPerShift.NumberOfPackages) AS NumberOfPackages,
		|		SUM(ListOfSalesPerShift.Count) AS Count,
		|		SUM(ListOfSalesPerShift.Sum) AS Sum,
		|		SUM(ListOfSalesPerShift.VATAmount) AS VATAmount,
		|		ListOfSalesPerShift.Warehouse AS Warehouse,
		|		ListOfSalesPerShift.Partner AS Partner,
		|		MAX(ListOfSalesPerShift.Premise) AS Premise,
		|		ListOfSalesPerShift.Seller AS Seller,
		|		ListOfSalesPerShift.Currency AS Currency,
		|		ListOfSalesPerShift.PriceKind AS PriceKind,
		|		ListOfSalesPerShift.CashRegister AS CashRegister,
		|		ListOfSalesPerShift.Organization AS Organization,
		|		ListOfSalesPerShift.VATTaxation AS VATTaxation
		|	FROM
		|		(SELECT
		|			CashRegisterReceiptGoods.Ref AS CashRegisterReceipt,
		|			CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
		|			CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|			CashRegisterReceiptGoods.Products AS Products,
		|			CashRegisterReceiptGoods.Characteristic AS Characteristic,
		|			CashRegisterReceiptGoods.Series AS Series,
		|			CashRegisterReceiptGoods.Package AS Package,
		|			CAST(CASE
		|					WHEN CashRegisterReceiptGoods.ManualDiscount + CashRegisterReceiptGoods.DiscountMarkupAmount = 0
		|							OR CashRegisterReceiptGoods.NumberOfPackages = 0
		|						THEN CashRegisterReceiptGoods.Price
		|					ELSE CashRegisterReceiptGoods.Sum / CashRegisterReceiptGoods.NumberOfPackages
		|				END AS NUMBER(31, 2)) AS Price,
		|			CashRegisterReceiptGoods.VATRate AS VATRate,
		|			CashRegisterReceiptGoods.NumberOfPackages AS NumberOfPackages,
		|			CashRegisterReceiptGoods.Count AS Count,
		|			CashRegisterReceiptGoods.Sum AS Sum,
		|			CashRegisterReceiptGoods.VATAmount AS VATAmount,
		|			CashRegisterReceipts.Warehouse AS Warehouse,
		|			CashRegisterReceipts.Partner AS Partner,
		|			CashRegisterReceiptGoods.Premise AS Premise,
		|			CashRegisterReceiptGoods.Seller AS Seller,
		|			CashRegisterReceipts.Currency AS Currency,
		|			CashRegisterReceipts.PriceKind AS PriceKind,
		|			CashRegisterReceipts.CashRegister AS CashRegister,
		|			CashRegisterReceipts.Organization AS Organization,
		|			CashRegisterReceipts.VATTaxation AS VATTaxation
		|		FROM
		|			ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift AS CashRegisterReceipts
		|				INNER JOIN Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
		|				ON CashRegisterReceipts.CashRegisterReceipt = CashRegisterReceiptGoods.Ref
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			CashRegisterReceiptGoods.CashRegisterReceipt,
		|			CashRegisterReceiptGoods.ProductsInSet,
		|			CashRegisterReceiptGoods.ItemVariantOfSet,
		|			CashRegisterReceiptGoods.Products,
		|			CashRegisterReceiptGoods.Characteristic,
		|			CashRegisterReceiptGoods.Series,
		|			CashRegisterReceiptGoods.Package,
		|			CashRegisterReceiptGoods.Price,
		|			CashRegisterReceiptGoods.VATRate,
		|			-CashRegisterReceiptGoods.NumberOfPackages,
		|			-CashRegisterReceiptGoods.Count,
		|			-CashRegisterReceiptGoods.Sum,
		|			-CashRegisterReceiptGoods.VATAmount,
		|			CashRegisterReceiptGoods.Warehouse,
		|			CashRegisterReceiptGoods.Partner,
		|			CashRegisterReceiptGoods.Premise,
		|			CashRegisterReceiptGoods.Seller,
		|			CashRegisterReceiptGoods.Currency,
		|			CashRegisterReceiptGoods.PriceKind,
		|			CashRegisterReceiptGoods.CashRegister,
		|			CashRegisterReceiptGoods.Organization,
		|			CashRegisterReceiptGoods.VATTaxation
		|		FROM
		|			GoodsOfRetailReturnsInSalesShift AS CashRegisterReceiptGoods) AS ListOfSalesPerShift
		|	
		|	GROUP BY
		|		ListOfSalesPerShift.CashRegisterReceipt,
		|		ListOfSalesPerShift.ProductsInSet,
		|		ListOfSalesPerShift.ItemVariantOfSet,
		|		ListOfSalesPerShift.Products,
		|		ListOfSalesPerShift.Characteristic,
		|		ListOfSalesPerShift.Series,
		|		ListOfSalesPerShift.Package,
		|		ListOfSalesPerShift.Price,
		|		ListOfSalesPerShift.VATRate,
		|		ListOfSalesPerShift.Warehouse,
		|		ListOfSalesPerShift.Partner,
		|		ListOfSalesPerShift.Seller,
		|		ListOfSalesPerShift.Currency,
		|		ListOfSalesPerShift.PriceKind,
		|		ListOfSalesPerShift.CashRegister,
		|		ListOfSalesPerShift.Organization,
		|		ListOfSalesPerShift.VATTaxation
		|	
		|	HAVING
		|		SUM(ListOfSalesPerShift.Count) < 0) AS ListOfProblematicReturnsPerShift
		|
		|INDEX BY
		|	CashRegisterReceipt
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	PaymentsLessReturnsPerShift.CashRegisterReceipt AS CashRegisterReceipt
		|INTO CashRegisterReceiptsForReturnsThatReflectMixedPayment
		|FROM
		|	(SELECT
		|		ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt AS CashRegisterReceipt,
		|		CashRegisterReceiptPaymentWithPaymentCards.PaymentKind_ AS PaymentKind_,
		|		CashRegisterReceiptPaymentWithPaymentCards.ConnectionContract AS ConnectionContract,
		|		CashRegisterReceiptPaymentWithPaymentCards.POSTerminal AS POSTerminal,
		|		CashRegisterReceiptPaymentWithPaymentCards.Sum AS Sum
		|	FROM
		|		ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift AS ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift
		|			INNER JOIN Document.CashRegisterReceipt.PaymentWithPaymentCards AS CashRegisterReceiptPaymentWithPaymentCards
		|			ON CashRegisterReceiptPaymentWithPaymentCards.Ref = ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.CashRegisterReceipt AS CashRegisterReceipt,
		|		UNDEFINED,
		|		UNDEFINED,
		|		UNDEFINED,
		|		ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift.ReceivedInCash
		|	FROM
		|		ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift AS ReceiptsOfCashRegisterForWhichRefundWasIssuedInShift
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterAndReturnReceiptsIssuedDuringShift.CashRegisterReceipt,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.PaymentKind_,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.ConnectionContract,
		|		CashRegisterReceiptReturnPaymentWithPaymentCards.POSTerminal,
		|		-CashRegisterReceiptReturnPaymentWithPaymentCards.Sum
		|	FROM
		|		CashRegisterAndReturnReceiptsIssuedDuringShift AS CashRegisterAndReturnReceiptsIssuedDuringShift
		|			INNER JOIN Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS CashRegisterReceiptReturnPaymentWithPaymentCards
		|			ON CashRegisterReceiptReturnPaymentWithPaymentCards.Ref = CashRegisterAndReturnReceiptsIssuedDuringShift.CashRegisterReceiptReturn
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterAndReturnReceiptsIssuedDuringShift.CashRegisterReceipt,
		|		UNDEFINED,
		|		UNDEFINED,
		|		UNDEFINED,
		|		-CashRegisterAndReturnReceiptsIssuedDuringShift.IssueInCash
		|	FROM
		|		CashRegisterAndReturnReceiptsIssuedDuringShift AS CashRegisterAndReturnReceiptsIssuedDuringShift
		|	) AS PaymentsLessReturnsPerShift
		|	
		|	GROUP BY
		|		PaymentsLessReturnsPerShift.CashRegisterReceipt,
		|		PaymentsLessReturnsPerShift.PaymentKind_,
		|		PaymentsLessReturnsPerShift.ConnectionContract,
		|		PaymentsLessReturnsPerShift.POSTerminal
		|
		|HAVING 
		|	SUM(PaymentsLessReturnsPerShift.Sum) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt AS CashRegisterReceipt
		|INTO CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|FROM
		|	(SELECT
		|		CashRegisterReceiptsForReturnsThatReflectMixedPayment.CashRegisterReceipt AS CashRegisterReceipt
		|	FROM CashRegisterReceiptsForReturnsThatReflectMixedPayment AS CashRegisterReceiptsForReturnsThatReflectMixedPayment
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt AS CashRegisterReceipt
		|	FROM CashRegisterReceiptsForProblematicReturnsPerShift AS CashRegisterReceiptsForProblematicReturnsPerShift
		|	) AS CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FALSE AS ByCorrectionReceipt,
		|	CashRegisterReceiptGoods.Ref AS Ref,
		|	CashRegisterReceiptGoods.Ref AS CashRegisterReceipt,
		|	CashRegisterReceiptGoods.ConnectionKey AS ConnectionKey,
		|	CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products AS Products,
		|	CashRegisterReceiptGoods.Characteristic AS Characteristic,
		|	CashRegisterReceiptGoods.Series AS Series,
		|	CASE
		|		WHEN CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt IS NULL
		|			THEN CashRegisterReceiptGoods.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END AS Package,
		|	CAST(CASE
		|			WHEN CashRegisterReceiptGoods.ManualDiscount + CashRegisterReceiptGoods.DiscountMarkupAmount = 0
		|					OR CashRegisterReceiptGoods.NumberOfPackages = 0
		|				THEN CashRegisterReceiptGoods.Price
		|			ELSE CashRegisterReceiptGoods.Sum / CashRegisterReceiptGoods.NumberOfPackages
		|		END AS NUMBER(31, 2)) AS Price,
		|	CashRegisterReceiptGoods.VATRate AS VATRate,
		|	CASE
		|		WHEN CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt IS NULL
		|			THEN CashRegisterReceiptGoods.NumberOfPackages
		|		ELSE CashRegisterReceiptGoods.Count
		|	END AS NumberOfPackages,
		|	CashRegisterReceiptGoods.Count AS Count,
		|	CashRegisterReceiptGoods.Sum AS Sum,
		|	CashRegisterReceiptGoods.VATAmount AS VATAmount,
		|	CashRegisterReceiptGoods.Ref.Warehouse AS Warehouse,
		|	CashRegisterReceiptGoods.Ref.Partner AS Partner,
		|	CashRegisterReceiptGoods.Premise AS Premise,
		|	CashRegisterReceiptGoods.Seller AS Seller,
		|	CashRegisterReceiptGoods.Ref.Date AS Date,
		|	CashRegisterReceiptGoods.Ref.Currency AS Currency,
		|	CashRegisterReceiptGoods.Ref.PriceKind AS PriceKind,
		|	CashRegisterReceiptGoods.Ref.CashRegister AS CashRegister,
		|	CashRegisterReceiptGoods.Ref.Organization AS Organization,
		|	CashRegisterReceiptGoods.Ref.VATTaxation AS VATTaxation,
		|	UNDEFINED AS CashRegisterReceiptVATTaxation,
		|	UNDEFINED AS CashRegisterReceiptCashRegisterShift,
		|	NOT (CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt IS NULL) AS CashRegisterReceiptForWhichProblematicReturnWasIssued
		|INTO RetailSalesProducts_
		|FROM
		|	Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
		|		LEFT JOIN CashRegisterReceiptsForProblematicReturnsPerShift AS CashRegisterReceiptsForProblematicReturnsPerShift
		|		ON CashRegisterReceiptGoods.Ref = CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt
		|WHERE
		|	CashRegisterReceiptGoods.Ref.CashRegisterShift = &CashRegisterShift
		|	AND (CashRegisterReceiptGoods.Ref.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceiptGoods.Ref.DeletionMark)
		|	AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE,
		|	CashRegisterReceiptGoods.Ref,
		|	CashRegisterReceiptGoods.CashRegisterReceipt,
		|	0,
		|	CashRegisterReceiptGoods.ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products,
		|	CashRegisterReceiptGoods.Characteristic,
		|	CashRegisterReceiptGoods.Series,
		|	CASE
		|		WHEN CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt IS NULL
		|			THEN CashRegisterReceiptGoods.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END,
		|	CashRegisterReceiptGoods.Price,
		|	CashRegisterReceiptGoods.VATRate,
		|	CASE
		|		WHEN CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt IS NULL
		|			THEN -CashRegisterReceiptGoods.NumberOfPackages
		|		ELSE -CashRegisterReceiptGoods.Count
		|	END,
		|	-CashRegisterReceiptGoods.Count,
		|	-CashRegisterReceiptGoods.Sum,
		|	-CashRegisterReceiptGoods.VATAmount,
		|	CashRegisterReceiptGoods.Warehouse,
		|	CashRegisterReceiptGoods.Partner,
		|	CashRegisterReceiptGoods.Premise,
		|	CASE
		|		WHEN CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt IS NULL
		|			THEN CashRegisterReceiptGoods.Seller
		|		ELSE VALUE(Catalog.Users.EmptyRef)
		|	END,
		|	CashRegisterReceiptGoods.Date,
		|	CashRegisterReceiptGoods.Currency,
		|	CashRegisterReceiptGoods.PriceKind,
		|	CashRegisterReceiptGoods.CashRegister,
		|	CashRegisterReceiptGoods.Organization,
		|	CashRegisterReceiptGoods.VATTaxation,
		|	UNDEFINED,
		|	UNDEFINED,
		|	NOT (CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt IS NULL) AS CashRegisterReceiptForWhichProblematicReturnWasIssued
		|FROM
		|	GoodsOfRetailReturnsInSalesShift AS CashRegisterReceiptGoods
		|		LEFT JOIN CashRegisterReceiptsForProblematicReturnsPerShift AS CashRegisterReceiptsForProblematicReturnsPerShift
		|		ON CashRegisterReceiptGoods.CashRegisterReceipt = CashRegisterReceiptsForProblematicReturnsPerShift.CashRegisterReceipt
		|		LEFT JOIN CashRegisterReceiptsForReturnsThatAreReflectedInRRR AS CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|		ON CashRegisterReceiptGoods.Ref.CashRegisterReceipt = CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt
		|WHERE
		|	CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE,
		|	CashRegisterReceiptGoods.Ref,
		|	CashRegisterReceiptGoods.Ref,
		|	CashRegisterReceiptGoods.ConnectionKey,
		|	CashRegisterReceiptGoods.ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products,
		|	CashRegisterReceiptGoods.Characteristic,
		|	CashRegisterReceiptGoods.Series,
		|	CashRegisterReceiptGoods.Package,
		|	CAST(CASE
		|			WHEN CashRegisterReceiptGoods.ManualDiscount + CashRegisterReceiptGoods.DiscountMarkupAmount = 0
		|					OR CashRegisterReceiptGoods.NumberOfPackages = 0
		|				THEN CashRegisterReceiptGoods.Price
		|			ELSE CashRegisterReceiptGoods.Sum / CashRegisterReceiptGoods.NumberOfPackages
		|		END AS NUMBER(31, 2)),
		|	CashRegisterReceiptGoods.VATRate,
		|	-CashRegisterReceiptGoods.NumberOfPackages,
		|	-CashRegisterReceiptGoods.Count,
		|	-CashRegisterReceiptGoods.Sum,
		|	-CashRegisterReceiptGoods.VATAmount,
		|	CashRegisterReceiptGoods.Ref.Warehouse,
		|	CashRegisterReceiptGoods.Ref.Partner,
		|	CashRegisterReceiptGoods.Premise,
		|	CashRegisterReceiptGoods.Seller,
		|	CashRegisterReceiptGoods.Ref.Date,
		|	CashRegisterReceiptGoods.Ref.Currency,
		|	CashRegisterReceiptGoods.Ref.PriceKind,
		|	CashRegisterReceiptGoods.Ref.CashRegister,
		|	CashRegisterReceiptGoods.Ref.Organization,
		|	CashRegisterReceiptGoods.Ref.VATTaxation,
		|	UNDEFINED,
		|	UNDEFINED,
		|	FALSE
		|FROM
		|	Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
		|		INNER JOIN Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
		|		ON ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = CashRegisterReceiptGoods.Ref
		|WHERE
		|	CashRegisterReceiptGoods.Ref.CashRegisterShift = &CashRegisterShift
		|	AND ReceiptOfCashRegisterAdjustment.CashRegisterShift = &CashRegisterShift
		|	AND (ReceiptOfCashRegisterAdjustment.Posted
		|		OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceiptGoods.Ref.DeletionMark)
		|	AND ReceiptOfCashRegisterAdjustment.Ref.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
		|	AND ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN CashRegisterReceiptGoods.Ref.CashRegisterReceipt.CashRegisterShift = &CashRegisterShift
		|			THEN FALSE
		|		ELSE TRUE
		|	END,
		|	CashRegisterReceiptGoods.Ref,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt,
		|	0,
		|	CashRegisterReceiptGoods.ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products,
		|	CashRegisterReceiptGoods.Characteristic,
		|	CashRegisterReceiptGoods.Series,
		|	CashRegisterReceiptGoods.Package,
		|	CashRegisterReceiptGoods.Price,
		|	CashRegisterReceiptGoods.VATRate,
		|	CashRegisterReceiptGoods.NumberOfPackages,
		|	CashRegisterReceiptGoods.Count,
		|	CashRegisterReceiptGoods.Sum,
		|	CashRegisterReceiptGoods.VATAmount,
		|	CashRegisterReceiptGoods.Ref.Warehouse,
		|	CashRegisterReceiptGoods.Ref.Partner,
		|	CashRegisterReceiptGoods.Premise,
		|	CashRegisterReceiptGoods.Seller,
		|	CashRegisterReceiptGoods.Ref.Date,
		|	CashRegisterReceiptGoods.Ref.Currency,
		|	CashRegisterReceiptGoods.Ref.PriceKind,
		|	CashRegisterReceiptGoods.Ref.CashRegister,
		|	CashRegisterReceiptGoods.Ref.Organization,
		|	CashRegisterReceiptGoods.Ref.VATTaxation,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt.VATTaxation,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt.CashRegisterShift,
		|	FALSE
		|FROM
		|	Document.ReceiptOfCashRegisterAdjustment.Goods AS CashRegisterReceiptGoods
		|WHERE
		|	CashRegisterReceiptGoods.Ref.CashRegisterShift = &CashRegisterShift
		|	AND (CashRegisterReceiptGoods.Ref.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceiptGoods.Ref.DeletionMark)
		|	AND CashRegisterReceiptGoods.Ref.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
		|	AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FALSE AS ByCorrectionReceipt,
		|	CashRegisterReceiptGoods.Ref AS Ref,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt AS CashRegisterReceiptRef,
		|	CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products AS Products,
		|	CashRegisterReceiptGoods.Characteristic AS Characteristic,
		|	CashRegisterReceiptGoods.Series AS Series,
		|	CashRegisterReceiptGoods.Package AS Package,
		|	CashRegisterReceiptGoods.Price AS Price,
		|	CashRegisterReceiptGoods.VATRate AS VATRate,
		|	CashRegisterReceiptGoods.NumberOfPackages AS NumberOfPackages,
		|	CashRegisterReceiptGoods.Count AS Count,
		|	CashRegisterReceiptGoods.Sum AS Sum,
		|	CashRegisterReceiptGoods.VATAmount AS VATAmount,
		|	CashRegisterReceiptGoods.Ref.Warehouse AS Warehouse,
		|	CashRegisterReceiptGoods.Ref.Partner AS Partner,
		|	CashRegisterReceiptGoods.Premise AS Premise,
		|	CashRegisterReceiptGoods.Seller AS Seller,
		|	CashRegisterReceiptGoods.Ref.Currency AS Currency,
		|	CashRegisterReceiptGoods.Ref.PriceKind AS PriceKind,
		|	CashRegisterReceiptGoods.Ref.CashRegister AS CashRegister,
		|	CashRegisterReceiptGoods.Ref.Organization AS Organization,
		|	CashRegisterReceiptGoods.Ref.VATTaxation AS VATTaxation,
		|	CASE
		|		WHEN CashRegisterReceiptGoods.Ref.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			THEN VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
		|		ELSE VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
		|	END AS CostDefiningMethod,
		|	CASE
		|		WHEN CashRegisterReceiptGoods.Ref.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE CashRegisterReceiptGoods.Ref.CashRegisterReceipt.VATTaxation
		|	END AS CashRegisterReceiptVATTaxation,
		|	CASE
		|		WHEN CashRegisterReceiptGoods.Ref.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE CashRegisterReceiptGoods.Ref.CashRegisterReceipt.CashRegisterShift
		|	END AS CashRegisterReceiptCashRegisterShift
		|INTO RetailReturnsProducts
		|FROM
		|	Document.CashRegisterReceiptReturn.Goods AS CashRegisterReceiptGoods
		|WHERE
		|	CashRegisterReceiptGoods.Ref.CashRegisterShift = &CashRegisterShift
		|	AND (CashRegisterReceiptGoods.Ref.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceiptGoods.Ref.DeletionMark)
		|	AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND (CashRegisterReceiptGoods.Ref.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			OR NOT CashRegisterReceiptGoods.Ref.CashRegisterReceipt.CashRegisterShift = &CashRegisterShift)
		|	AND CashRegisterReceiptGoods.NumberOfPackages <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE AS ByCorrectionReceipt,
		|	CashRegisterReceiptGoods.Ref AS Ref,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt AS CashRegisterReceiptRef,
		|	CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products AS Products,
		|	CashRegisterReceiptGoods.Characteristic AS Characteristic,
		|	CashRegisterReceiptGoods.Series AS Series,
		|	CashRegisterReceiptGoods.Package AS Package,
		|	CashRegisterReceiptGoods.Price AS Price,
		|	CashRegisterReceiptGoods.VATRate AS VATRate,
		|	CashRegisterReceiptGoods.NumberOfPackages AS NumberOfPackages,
		|	CashRegisterReceiptGoods.Count AS Count,
		|	CashRegisterReceiptGoods.Sum AS Sum,
		|	CashRegisterReceiptGoods.VATAmount AS VATAmount,
		|	CashRegisterReceiptGoods.Ref.Warehouse AS Warehouse,
		|	CashRegisterReceiptGoods.Ref.Partner AS Partner,
		|	CashRegisterReceiptGoods.Premise AS Premise,
		|	CashRegisterReceiptGoods.Seller AS Seller,
		|	CashRegisterReceiptGoods.Ref.Currency AS Currency,
		|	CashRegisterReceiptGoods.Ref.PriceKind AS PriceKind,
		|	CashRegisterReceiptGoods.Ref.CashRegister AS CashRegister,
		|	CashRegisterReceiptGoods.Ref.Organization AS Organization,
		|	CashRegisterReceiptGoods.Ref.VATTaxation AS VATTaxation,
		|	VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument) AS CostDefiningMethod,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt.VATTaxation AS CashRegisterReceiptVATTaxation,
		|	CashRegisterReceiptGoods.Ref.CashRegisterReceipt.CashRegisterShift AS CashRegisterReceiptCashRegisterShift
		|FROM
		|	Document.CashRegisterReceiptReturn.Goods AS CashRegisterReceiptGoods
		|		INNER JOIN CashRegisterReceiptsForReturnsThatAreReflectedInRRR AS CashRegisterReceiptsForReturnsThatAreReflectedInRRR
		|		ON CashRegisterReceiptGoods.Ref.CashRegisterReceipt = CashRegisterReceiptsForReturnsThatAreReflectedInRRR.CashRegisterReceipt
		|
		|UNION ALL
		|
		|SELECT
		|	TRUE,
		|	ReceiptOfCashRegisterAdjustment.Ref,
		|	CashRegisterReceiptGoods.Ref,
		|	CashRegisterReceiptGoods.ProductsInSet,
		|	CashRegisterReceiptGoods.ItemVariantOfSet,
		|	CashRegisterReceiptGoods.Products,
		|	CashRegisterReceiptGoods.Characteristic,
		|	CashRegisterReceiptGoods.Series,
		|	CashRegisterReceiptGoods.Package,
		|	CAST(CASE
		|			WHEN CashRegisterReceiptGoods.ManualDiscount + CashRegisterReceiptGoods.DiscountMarkupAmount = 0
		|					OR CashRegisterReceiptGoods.NumberOfPackages = 0
		|				THEN CashRegisterReceiptGoods.Price
		|			ELSE CashRegisterReceiptGoods.Sum / CashRegisterReceiptGoods.NumberOfPackages
		|		END AS NUMBER(31, 2)),
		|	CashRegisterReceiptGoods.VATRate,
		|	CashRegisterReceiptGoods.NumberOfPackages,
		|	CashRegisterReceiptGoods.Count,
		|	CashRegisterReceiptGoods.Sum,
		|	CashRegisterReceiptGoods.VATAmount,
		|	CashRegisterReceiptGoods.Ref.Warehouse,
		|	CashRegisterReceiptGoods.Ref.Partner,
		|	CashRegisterReceiptGoods.Premise,
		|	CashRegisterReceiptGoods.Seller,
		|	CashRegisterReceiptGoods.Ref.Currency,
		|	CashRegisterReceiptGoods.Ref.PriceKind,
		|	CashRegisterReceiptGoods.Ref.CashRegister,
		|	CashRegisterReceiptGoods.Ref.Organization,
		|	CashRegisterReceiptGoods.Ref.VATTaxation,
		|	VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument),
		|	CashRegisterReceiptGoods.Ref.VATTaxation,
		|	CashRegisterReceiptGoods.Ref.CashRegisterShift
		|FROM
		|	Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
		|		INNER JOIN Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
		|		ON ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = CashRegisterReceiptGoods.Ref
		|WHERE
		|	CashRegisterReceiptGoods.Ref.CashRegisterShift <> &CashRegisterShift
		|	AND ReceiptOfCashRegisterAdjustment.CashRegisterShift = &CashRegisterShift
		|	AND (ReceiptOfCashRegisterAdjustment.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT ReceiptOfCashRegisterAdjustment.Ref.DeletionMark)
		|	AND ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND ReceiptOfCashRegisterAdjustment.Ref.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CashRegisterReceipt.VATTaxation AS VATTaxation,
		|	CashRegisterReceipt.VATTaxation AS CashRegisterReceiptVATTaxation,
		|	UNDEFINED AS CashRegisterReceiptCashRegisterShift,
		|	3 AS Priority
		|INTO CashRegisterReceiptsVATTaxation
		|FROM
		|	Document.CashRegisterReceipt AS CashRegisterReceipt
		|WHERE
		|	(CashRegisterReceipt.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceipt.DeletionMark)
		|	AND CashRegisterReceipt.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND CashRegisterReceipt.CashRegisterShift = &CashRegisterShift
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ReceiptOfCashRegisterAdjustment.VATTaxation,
		|	CASE
		|		WHEN ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			OR ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CRENonApplication)
		|			THEN ReceiptOfCashRegisterAdjustment.VATTaxation
		|		ELSE ReceiptOfCashRegisterAdjustment.CashRegisterReceipt.VATTaxation
		|	END,
		|	CASE
		|		WHEN ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			OR ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CRENonApplication)
		|			THEN UNDEFINED
		|		ELSE ReceiptOfCashRegisterAdjustment.CashRegisterReceipt.CashRegisterShift
		|	END,
		|	CASE
		|		WHEN ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CRENonApplication)
		|			THEN 2
		|		ELSE 1
		|	END
		|FROM
		|	Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
		|WHERE
		|	(ReceiptOfCashRegisterAdjustment.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT ReceiptOfCashRegisterAdjustment.DeletionMark)
		|	AND ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND ReceiptOfCashRegisterAdjustment.CashRegisterShift = &CashRegisterShift
		|	AND ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	CashRegisterReceiptReturn.VATTaxation,
		|	CASE
		|		WHEN CashRegisterReceiptReturn.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			THEN CashRegisterReceiptReturn.VATTaxation
		|		ELSE CashRegisterReceiptReturn.CashRegisterReceipt.VATTaxation
		|	END,
		|	CASE
		|		WHEN CashRegisterReceiptReturn.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE CashRegisterReceiptReturn.CashRegisterReceipt.CashRegisterShift
		|	END,
		|	CASE
		|		WHEN CashRegisterReceiptReturn.CashRegisterReceipt = VALUE(Document.CashRegisterReceipt.EmptyRef)
		|			THEN 3
		|		ELSE 2
		|	END
		|FROM
		|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
		|WHERE
		|	(CashRegisterReceiptReturn.Posted
		|			OR &IncludeUnverifiedReceipts AND NOT CashRegisterReceiptReturn.DeletionMark)
		|	AND CashRegisterReceiptReturn.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND CashRegisterReceiptReturn.CashRegisterShift = &CashRegisterShift
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CashRegisterReceiptsVATTaxation.CashRegisterReceiptCashRegisterShift AS CashRegisterShift,
		|	CashRegisterReceiptsVATTaxation.CashRegisterReceiptVATTaxation AS VATTaxation,
		|	ISNULL(RetailSalesReport.Ref, UNDEFINED) AS DocumentSalesOfGoodsAndServices
		|INTO CashRegisterReceiptsSalesDocuments
		|FROM
		|	CashRegisterReceiptsVATTaxation AS CashRegisterReceiptsVATTaxation
		|		LEFT JOIN Document.RetailSalesReport AS RetailSalesReport
		|		ON CashRegisterReceiptsVATTaxation.CashRegisterReceiptCashRegisterShift = RetailSalesReport.CashRegisterShift
		|			AND CashRegisterReceiptsVATTaxation.CashRegisterReceiptVATTaxation = RetailSalesReport.VATTaxation
		|			AND (NOT RetailSalesReport.DeletionMark)
		|WHERE
		|	NOT CashRegisterReceiptsVATTaxation.CashRegisterReceiptCashRegisterShift = UNDEFINED
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CashRegisterReceiptsVATTaxation.VATTaxation AS VATTaxation
		|FROM
		|	(SELECT
		|		CAST(CASE
		|				WHEN &VATTaxation = UNDEFINED
		|					THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|				ELSE &VATTaxation
		|			END AS Enum.VATTaxationTypes) AS VATTaxation,
		|		4 AS Priority
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceipts.VATTaxation,
		|		3
		|	FROM
		|		CashRegisterReceiptsVATTaxation AS CashRegisterReceipts
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CashRegisterReceipts.CashRegisterReceiptVATTaxation,
		|		CashRegisterReceipts.Priority
		|	FROM
		|		CashRegisterReceiptsVATTaxation AS CashRegisterReceipts) AS CashRegisterReceiptsVATTaxation
		|
		|GROUP BY
		|	CashRegisterReceiptsVATTaxation.VATTaxation
		|
		|ORDER BY
		|	MIN(CashRegisterReceiptsVATTaxation.Priority)";
	
	Query.SetParameter("CashRegisterShift", RegisterShiftState.CashRegisterShift);
	Query.SetParameter("VATTaxation", RegisterShiftState.VATTaxation);
	Query.SetParameter("IncludeUnverifiedReceipts", IncludeUnverifiedReceipts);
	
	SetPrivilegedMode(True);
	Return Query.Execute().Unload();
	
EndFunction

// Performs filling out Reports on retail returns/sales on a cash shift for all types of taxation within this cash shift.
//
// Parameters:
//  RegisterShiftState - See DescriptionOfCashShift
//  ErrorDescription - String - Returned error description
//  IncludeUnverifiedReceipts - Boolean - By default, false
//
// Returns:
//  Boolean - If there were no errors when filling out the documents, the value True will be returned.
//
Function CompleteReportsOnRetailSalesAndReturns(RegisterShiftState, ErrorDescription, IncludeUnverifiedReceipts = False) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"CommonModule.RetailSales.CompleteReportsOnRetailSalesAndReturns");
	
	NumberOfProcessedData = 0;
	
	// We will fill out a couple of documents for each type of taxation: a report on retail sales, a report on retail returns
	DocumentPairsFormed = True;
	
	ErrorsDescription = New Array;
	
	TempTablesManager = New TempTablesManager;
	TypesOfVATTaxationByCashShift = PrepareDataOnCashShiftReceipts(
		RegisterShiftState,
		TempTablesManager,
		IncludeUnverifiedReceipts);
	
	For Each VATTaxationType In TypesOfVATTaxationByCashShift Do
		
		GoodsReturnLinesPerShift = Undefined;
		
		FillErrorDescription = "";
		// Filling out a report on retail returns
		RetailReturnsReport = FillOutReportOnRetailReturnsForCashShift(
			RegisterShiftState,
			VATTaxationType.VATTaxation,
			TempTablesManager,
			GoodsReturnLinesPerShift,
			FillErrorDescription);
		If Not IsBlankString(FillErrorDescription) Then
			ErrorsDescription.Add(FillErrorDescription);
		EndIf;
	
		FillErrorDescription = "";
		// Filling out a retail sales report
		RetailSalesReport = FillOutReportOnRetailSalesByCashShift(
			RegisterShiftState,
			VATTaxationType.VATTaxation,
			TempTablesManager,
			FillErrorDescription);
		If Not IsBlankString(FillErrorDescription) Then
			ErrorsDescription.Add(FillErrorDescription);
		EndIf;
		
		If RetailSalesReport <> Undefined
			And RetailReturnsReport <> Undefined
			And GoodsReturnLinesPerShift <> Undefined
			And GoodsReturnLinesPerShift.Count() > 0 Then
			
			RetailReturnsReportObject = RetailReturnsReport.GetObject();
			For Each GoodsReturnLine In GoodsReturnLinesPerShift Do
				LineTSGoodsRSR = RetailReturnsReportObject.Goods[GoodsReturnLine.LineNumber - 1];
				
				LineTSGoodsRSR.CostDefiningMethod
					= Enums.WaysToCalculateReturnCost.FromSalesDocument;
				LineTSGoodsRSR.DocumentSalesOfGoodsAndServices = RetailSalesReport;
			EndDo;
			
			Try
				
				RetailReturnsReportObject.Write(DocumentWriteMode.Write);
				If RetailReturnsReportObject.Posted Then
					RetailReturnsReportObject.Write(
						DocumentWriteMode.Posting,
						DocumentPostingMode.Regular);
				EndIf;
				
				RetailSalesReportConducted = Common.ObjectAttributeValue(
					RetailSalesReport,
					"Posted");
				If RetailReturnsReportObject.Posted And RetailSalesReportConducted Then
					RetailSalesReportObject = RetailSalesReport.GetObject();
					RetailSalesReportObject.Write(
						DocumentWriteMode.Posting,
						DocumentPostingMode.Regular);
				EndIf;
				
			Except
				
				ErrorDescription = NStr("vi = 'Khi bổ sung dữ liệu hoàn trả vào Bảng kê hàng hóa bán lẻ trả lại và Bảng kê bán lẻ hàng hóa trong ca làm việc với dạng thanh toán bị thay đổi theo phiên thu ngân %CashRegisterShift% đã xảy ra lỗi.
		                                     |Mô tả bổ sung:
		                                     |%AdditionalDetails%';
		                                     |ru = 'При дозаполнении в ОРВ и ОРП данными возврата в смену с измененным видом оплаты по кассовой смене %CashRegisterShift% произошла ошибка.
		                                     |Дополнительное описание:
		                                     |%AdditionalDetails%';
		                                     |en = 'An error occurred when completing the retail return report and retail sales report with return data for a shift with a changed payment kind for the %CashRegisterShift% POS shift.
		                                     |Additional description:
		                                     |%AdditionalDetails%'; fa = 'An error occurred when completing the retail return report and retail sales report with return data for a shift with a changed payment kind for the %CashRegisterShift% POS shift.
		                                     |Additional description:
		                                     |%AdditionalDetails%';
		                                     |it = 'An error occurred when completing the retail return report and retail sales report with return data for a shift with a changed payment kind for the %CashRegisterShift% POS shift.
		                                     |Additional description:
		                                     |%AdditionalDetails%';
		                                     |pl = 'An error occurred when completing the retail return report and retail sales report with return data for a shift with a changed payment kind for the %CashRegisterShift% POS shift.
		                                     |Additional description:
		                                     |%AdditionalDetails%';
		                                     |tr = 'Değiştirilmiş ödeme türü olan vardiyasında %CashRegisterShift% kasa vardiayası ile ilgili iade verileri girilirken Perakende satış raporunda ve Perakende iade raporunda bir hata oluştu.
		                                     |Ayrıntılar:
		                                     |%AdditionalDetails%'");
				ErrorDescription = StrReplace(ErrorDescription, "%CashRegisterShift%", RegisterShiftState.CashRegisterShift);
				ErrorDescription = StrReplace(
					ErrorDescription,
					"%AdditionalDetails%",
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(
					NStr(
						"vi = 'Bán lẻ';
						|ru = 'Розничные продажи';
						|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
						|it = 'Vendite al dettaglio';
						|pl = 'Sprzedaże detaliczne';
						|tr = 'Perakende satışlar'",
						Common.DefaultLanguageCode()),
					EventLogLevel.Error, , ,
					ErrorDescription);
				
			EndTry;
			
		EndIf;
		
		If RetailReturnsReport = Undefined
			Or RetailSalesReport = Undefined
			Or ErrorsDescription.Count() > 0 Then
			DocumentPairsFormed = False;
		EndIf;
		
		NumberOfProcessedData = 	NumberOfProcessedData + 1;
		
	EndDo;
	If ErrorsDescription.Count() > 0 Then
		ErrorDescription = StrConcat(ErrorsDescription, Chars.LF);
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData);
	
	Return DocumentPairsFormed;
	
EndFunction	

// Performs the closing of cash register shift.
//
// Parameters:
//  Object - CatalogRef.CashRegisters, CatalogRef.Peripherals - Cash registers.
//  ErrorWhenDeletingZReport - Boolean - Flag, an error occurred when closing the shift.
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  Array of DocumentRef.CashRegisterShift - An array of created retail sales reports.
//
Function PerformCashShiftClosingOperation(Object, ErrorWhenDeletingZReport, ErrorDescription = "") Export
	
	DocumentsArray = New Array;
	
	CashRegisterCashRegisterFiscalDevice = RetailSales.CashRegisterCashRegisterFiscalDevice(Object);
	CashRegister             = CashRegisterCashRegisterFiscalDevice.CashRegister;
	
	// Closing the cash shift
	BeginTransaction();
	Try
		
		CashRegisterShift = CloseRegisterShift(Object, ErrorDescription);
		If Not ValueIsFilled(CashRegisterShift) Then
			Raise ErrorDescription;
		EndIf;
		
		If ValueIsFilled(CashRegister) Then
			CollectionCompleted = PerformAutomaticCashCollection(CashRegister, ErrorWhenDeletingZReport);
		Else
			CheckOfOperationWhenClosingCashierShiftShowRecommendation();
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(NStr("vi = 'Đóng quầy thu ngân';
							|ru = 'Закрытие кассовой смены';
							|en = 'POS shift-end closing'; fa = 'بستن پایان شیفت صندوق';
							|it = 'Chiusura del turno di cassa';
							|pl = 'Zamykanie zmiany kasowej';
							|tr = 'Kasa vardiyası kapanışı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription);
		
		If TransactionActive() Then
			Raise DetailErrorDescription;
		EndIf;

		BriefErrorDescription = NStr("vi = 'Khi đóng phiên thu ngân, đã xảy ra lỗi. Xem mô tả chi tiết trong nhật ký sự kiện.';
									|ru = 'При закрытии кассовой смены произошла ошибка. Подробное описание находится в журнале регистрации.';
									|en = 'An error occurred upon the POS shift-end closing. For more information, see the event log.'; fa = 'An error occurred upon the POS shift-end closing. For more information, see the event log.';
									|it = 'Si è verificato un errore durante la chiusura del turno di casa. Una descrizione dettagliata è disponibile nel registro eventi.';
									|pl = 'Podczas zamknięcia zmiany kasowej wystąpił błąd. Opis szczegółowy znajduje się w dzienniku rejestracji.';
									|tr = 'Kasa vardiyası kapatılırken bir hata oluştu. Kayıt defterinde ayrıntılı bir açıklama bulunabilir.'");
		ErrorDescription = BriefErrorDescription;
		Common.MessageToUser(BriefErrorDescription);

		Return DocumentsArray;
		
	EndTry;
	
	If ValueIsFilled(CashRegister) Then
		
		// We will get the status of the cash shift
		RegisterShiftState = GetCashShiftState(CashRegister);
		
		// Removal of deferred and receipts for which the goods were reserved.
		DeleteDeferredReceipts(CashRegisterShift, ErrorDescription);
		
		DocumentsArray.Add(RegisterShiftState.CashRegisterShift);
		
		GenerateDocumentsForCashShiftClosingOperation(RegisterShiftState, ErrorDescription);
		
	EndIf;
	
	Return DocumentsArray;
	
EndFunction

// Generates documents at the closing of the cash shift.
//
// Parameters:
//  RegisterShiftState - See GetCashShiftState
//  ErrorDescription - String - Returned error description
//  IncludeUnverifiedReceipts - Boolean - By default, false
//
Procedure GenerateDocumentsForCashShiftClosingOperation(RegisterShiftState, ErrorDescription, IncludeUnverifiedReceipts = False) Export
	
	// We will fill out a couple of documents for each type of taxation: a report on retail sales, a report on retail returns
	DescriptionOfErrorWhenGeneratingDocuments = "";
	DocumentPairsFormed = CompleteReportsOnRetailSalesAndReturns(RegisterShiftState, DescriptionOfErrorWhenGeneratingDocuments, IncludeUnverifiedReceipts);
	
	If Not DocumentPairsFormed Then
		
		ArrayOfErrorDescriptionLines = New Array;
		If Not IsBlankString(ErrorDescription) Then
			ArrayOfErrorDescriptionLines.Add(ErrorDescription);
		EndIf;
		ArrayOfErrorDescriptionLines.Add(StrTemplate(NStr("vi = 'Khi tạo chứng từ, đối với thao tác đóng phiên thu ngân %1 đã xảy ra lỗi.';
															|ru = 'При формировании документов для операции закрытия кассовой смены %1 возникла ошибка.';
															|en = 'An error occurred when generating documents for the %1 POS shift-end closing operation.'; fa = 'An error occurred when generating documents for the %1 POS shift-end closing operation.';
															|it = 'При формировании документов для операции закрытия кассовой смены %1 возникла ошибка.';
															|pl = 'An error occurred when generating documents for the %1 POS shift-end closing operation.';
															|tr = '%1 vardiya sonu kapanışı işlemi için belgeler oluştururken hata oluştu.'"), RegisterShiftState.CashRegisterShift));
		If Not IsBlankString(DescriptionOfErrorWhenGeneratingDocuments) Then
			ArrayOfErrorDescriptionLines.Add(NStr("vi = 'Mô tả bổ sung:';
													|ru = 'Дополнительное описание:';
													|en = 'Additional description:'; fa = 'Additional description:';
													|it = 'Descrizione aggiuntiva:';
													|pl = 'Opis dodatkowy:';
													|tr = 'Ek açıklama:'"));
			ArrayOfErrorDescriptionLines.Add(DescriptionOfErrorWhenGeneratingDocuments);
		EndIf;
		
		ErrorDescription = StrConcat(ArrayOfErrorDescriptionLines, Chars.LF);
		
	Else
		
		CheckOfOperationWhenClosingCashierShiftShowRecommendation();
		
		// Archiving KKM receipts
		If Constants.TransactionOnRegisterShiftEndClosing.Get() = Enums.TransactionsOnRegisterShiftEndClosing.CashRegisterReceiptArchiving Then
			
			JobParameters = NewParametersForCashierShiftClosingTask();
			JobParameters.CashRegisterShift = RegisterShiftState.CashRegisterShift;
			
			ExecuteArchiveCashRegisterReceipts(JobParameters, , IncludeUnverifiedReceipts);
			
		EndIf;
		
		// Deleting KKM receipts
		If Constants.TransactionOnRegisterShiftEndClosing.Get() = Enums.TransactionsOnRegisterShiftEndClosing.DeleteCashRegisterReceipts Then
			
			JobParameters = NewParametersForCashierShiftClosingTask();
			JobParameters.CashRegisterShift= RegisterShiftState.CashRegisterShift;
			
			ExecuteDeleteCashRegisterReceipts(JobParameters, , IncludeUnverifiedReceipts);
			
		EndIf;
	
	EndIf;
	
EndProcedure

// The constructor function of a structure the state of the cash changer.
//
// Returns:
// 	Structure - Contains:
// * TaxationSystem - EnumRef.CRETaxationSystemTypes -
// * CashRegisterSerialNumber - String -
// * InformationAboutCompany - String - 
// * VATTaxation - EnumRef.VATTaxationTypes - 
// * PriceIncludesVAT - Boolean - 
// * WarehouseAddress - String -
// * Warehouse - CatalogRef.Warehouses - 
// * Cashier - CatalogRef.Users - 
// * PriceKind - CatalogRef.TypesOfPrices - 
// * CurrencyPresentation - String - 
// * Currency - CatalogRef.Currencies - 
// * FiscalDevice - CatalogRef.Peripherals - 
// * CashRegister - DefinedType.CashAccountCEL - 
// * Organization - DefinedType.CompanyCEL - 
// * UpdateReports - Boolean - 
// * ErrorDescription - String -
// * Error24Hours - Boolean -
// * ShiftIsOpened - Boolean -
// * CashShiftNumber - String - 
// * CashOnHand - Undefined -
// * CashRegisterShift - DocumentRef.CashRegisterShift - 
// * PeriodEndTransactionsStatus - EnumRef.StatusesOfPeriodEndTransactionsOfCashRegisterShift - 
// * CashRegisterShiftStatus - EnumRef.CashRegisterShiftStatuses - 
// * StatusChangeDate - Date - 
// * ItinerantTrade - Boolean -
// * StoreAddress - String -
// 
Function DescriptionOfCashShift() Export
	
	RegisterShiftState = New Structure;
	RegisterShiftState.Insert("StatusChangeDate");
	RegisterShiftState.Insert("CashRegisterShiftStatus");
	RegisterShiftState.Insert("PeriodEndTransactionsStatus");
	RegisterShiftState.Insert("CashRegisterShift");
	RegisterShiftState.Insert("CashOnHand");
	RegisterShiftState.Insert("CashShiftNumber");
	RegisterShiftState.Insert("ShiftIsOpened", False);
	RegisterShiftState.Insert("Error24Hours", False);
	RegisterShiftState.Insert("ErrorDescription", "");
	RegisterShiftState.Insert("UpdateReports", True);
	
	// Description of the details of the cash shift
	RegisterShiftState.Insert("Organization");
	RegisterShiftState.Insert("CashRegister");
	RegisterShiftState.Insert("FiscalDevice");
	
	RegisterShiftState.Insert("Currency");
	RegisterShiftState.Insert("CurrencyPresentation");
	RegisterShiftState.Insert("PriceKind");
	RegisterShiftState.Insert("Cashier");
	RegisterShiftState.Insert("Warehouse");
	RegisterShiftState.Insert("Department");
	RegisterShiftState.Insert("WarehouseAddress", "");
	RegisterShiftState.Insert("PriceIncludesVAT");
	RegisterShiftState.Insert("VATTaxation", Enums.VATTaxationTypes.EmptyRef());
	RegisterShiftState.Insert("ItinerantTrade", False);
	RegisterShiftState.Insert("SettlementAddress", "");
	RegisterShiftState.Insert("PlaceOfSettlement", "");
	
	// Other
	RegisterShiftState.Insert("InformationAboutCompany");
	RegisterShiftState.Insert("CashRegisterSerialNumber",       "");
	RegisterShiftState.Insert("TaxationSystem", Enums.CRETaxationSystemTypes.EmptyRef());
	
	Return RegisterShiftState;
	
EndFunction

#EndRegion

#Region GettingSalesData

// Gets data on retail sales for the period.
//
// Parameters:
//  CalculationParameters - Structure - parameters for getting sales: Organization, Beginning Of Period, End Of Period
//
// Returns:
//  ValueTable - with columns:
//		Organization, Period, Nomenclature type, StavkaNDS, SummaBezNDS, SummaNDS
//
Function GetSalesDataForPeriod(CalculationParameters) Export
	
	QueryText = 
	"SELECT DISTINCT
	|	RetailSalesReport.CashRegisterShift AS CashRegisterShift
	|INTO CashShiftsWithReports
	|FROM
	|	Document.RetailSalesReport AS RetailSalesReport
	|WHERE
	|	RetailSalesReport.Organization IN(&CompanyArray)
	|	AND RetailSalesReport.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RetailSalesReport.Posted
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RetailReturnsReport.CashRegisterShift AS CashRegisterShift
	|FROM
	|	Document.RetailReturnsReport AS RetailReturnsReport
	|WHERE
	|	RetailReturnsReport.Organization IN(&CompanyArray)
	|	AND RetailReturnsReport.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RetailReturnsReport.Posted
	|
	|INDEX BY
	|	CashRegisterShift
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RetailSalesReport.CashRegisterShift AS CashRegisterShift
	|INTO CashShiftsWithReportsForSelectingReceipts
	|FROM
	|	Document.RetailSalesReport AS RetailSalesReport
	|WHERE
	|	RetailSalesReport.Organization IN(&CompanyArray)
	|	AND RetailSalesReport.Date >= &BeginOfPeriod
	|	AND RetailSalesReport.Posted
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RetailReturnsReport.CashRegisterShift AS CashRegisterShift
	|FROM
	|	Document.RetailReturnsReport AS RetailReturnsReport
	|WHERE
	|	RetailReturnsReport.Organization IN(&CompanyArray)
	|	AND RetailReturnsReport.Date >= &BeginOfPeriod
	|	AND RetailReturnsReport.Posted
	|
	|INDEX BY
	|	CashRegisterShift
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RetailSales.Organization     AS Organization,
	|	RetailSales.Period          AS Period,
	|	RetailSales.ItemsType AS ItemsType,
	|	RetailSales.VATRate       AS VATRate,
	|	SUM(RetailSales.Sum)    AS Sum,
	|	SUM(RetailSales.VATAmount) AS VATAmount
	|FROM
	|	(SELECT
	|		CashRegisterReceiptGoods.Ref.Organization AS Organization,
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.Date, MONTH) AS Period,
	|		CashRegisterReceiptGoods.Products.ItemsType AS ItemsType,
	|		CashRegisterReceiptGoods.VATRate AS VATRate,
	|		CASE
	|			WHEN CashRegisterReceiptGoods.Ref.PriceIncludesVAT
	|				THEN CashRegisterReceiptGoods.Sum - CashRegisterReceiptGoods.VATAmount
	|			ELSE CashRegisterReceiptGoods.Sum
	|		END AS Sum,
	|		CashRegisterReceiptGoods.VATAmount AS VATAmount
	|	FROM
	|		Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
	|	WHERE
	|		CashRegisterReceiptGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.Posted
	|		AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		AND CashRegisterReceiptGoods.Ref.Organization IN (&CompanyArray)
	|		AND NOT CashRegisterReceiptGoods.Ref.CashRegisterShift IN (SELECT T.CashRegisterShift FROM CashShiftsWithReportsForSelectingReceipts AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashRegisterReceiptGoods.Ref.Organization,
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.Date, MONTH),
	|		CashRegisterReceiptGoods.Products.ItemsType,
	|		CashRegisterReceiptGoods.VATRate,
	|		CASE
	|			WHEN CashRegisterReceiptGoods.Ref.PriceIncludesVAT
	|				THEN - CashRegisterReceiptGoods.Sum + CashRegisterReceiptGoods.VATAmount
	|			ELSE - CashRegisterReceiptGoods.Sum
	|		END AS Sum,
	|		-CashRegisterReceiptGoods.VATAmount
	|	FROM
	|		Document.CashRegisterReceiptReturn.Goods AS CashRegisterReceiptGoods
	|	WHERE
	|		CashRegisterReceiptGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.Posted
	|		AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		AND CashRegisterReceiptGoods.Ref.Organization IN (&CompanyArray)
	|		AND NOT CashRegisterReceiptGoods.Ref.CashRegisterShift IN (SELECT T.CashRegisterShift FROM CashShiftsWithReportsForSelectingReceipts AS T)
	|		AND CashRegisterReceiptGoods.NumberOfPackages <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashRegisterReceiptGoods.Ref.Organization,
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.Date, MONTH),
	|		CashRegisterReceiptGoods.Products.ItemsType,
	|		CashRegisterReceiptGoods.VATRate,
	|		CASE
	|			WHEN CashRegisterReceiptGoods.Ref.PriceIncludesVAT
	|				THEN - CashRegisterReceiptGoods.Sum + CashRegisterReceiptGoods.VATAmount
	|			ELSE - CashRegisterReceiptGoods.Sum
	|		END AS Sum,
	|		-CashRegisterReceiptGoods.VATAmount
	|	FROM
	|		Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
	|			INNER JOIN Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
	|			ON (ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = CashRegisterReceiptGoods.Ref)
	|				AND (ReceiptOfCashRegisterAdjustment.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|				AND (ReceiptOfCashRegisterAdjustment.Posted)
	|				AND ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|				AND (ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_))
	|	WHERE
	|		CashRegisterReceiptGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.Organization IN (&CompanyArray)
	|		AND NOT CashRegisterReceiptGoods.Ref.CashRegisterShift IN (SELECT T.CashRegisterShift FROM CashShiftsWithReportsForSelectingReceipts AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashRegisterReceiptGoods.Ref.Organization,
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.Date, MONTH),
	|		CashRegisterReceiptGoods.Products.ItemsType,
	|		CashRegisterReceiptGoods.VATRate,
	|		SUM(CASE
	|			WHEN CashRegisterReceiptGoods.Ref.PriceIncludesVAT
	|				THEN CashRegisterReceiptGoods.Sum - CashRegisterReceiptGoods.VATAmount
	|			ELSE CashRegisterReceiptGoods.Sum
	|		END) AS Sum,
	|		SUM(CashRegisterReceiptGoods.VATAmount)
	|	FROM
	|		Document.ReceiptOfCashRegisterAdjustment.Goods AS CashRegisterReceiptGoods
	|	WHERE
	|		CashRegisterReceiptGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.CashRegisterReceipt.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.Posted
	|		AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		AND CashRegisterReceiptGoods.Ref.Organization IN (&CompanyArray)
	|		AND NOT CashRegisterReceiptGoods.Ref.CashRegisterShift IN (SELECT T.CashRegisterShift FROM CashShiftsWithReportsForSelectingReceipts AS T)
	|		AND CashRegisterReceiptGoods.Ref.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|	
	|	GROUP BY
	|		CashRegisterReceiptGoods.Ref,
	|		CashRegisterReceiptGoods.Products.ItemsType,
	|		CashRegisterReceiptGoods.VATRate
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailSalesOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailSalesOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailSalesOfGoods.Products.ItemsType,
	|		ReportOnRetailSalesOfGoods.VATRate,
	|		CASE
	|			WHEN ReportOnRetailSalesOfGoods.Ref.PriceIncludesVAT
	|				THEN ReportOnRetailSalesOfGoods.Sum - ReportOnRetailSalesOfGoods.VATAmount
	|			ELSE ReportOnRetailSalesOfGoods.Sum
	|		END AS Sum,
	|		ReportOnRetailSalesOfGoods.VATAmount
	|	FROM
	|		Document.RetailSalesReport.Goods AS ReportOnRetailSalesOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailSalesOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailSalesOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailSalesOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailSalesOfGoods.Ref.Posted
	|		AND ReportOnRetailSalesOfGoods.Products.ItemsType IN 
	|			(VALUE(Enum.ItemsTypes.Work_5),VALUE(Enum.ItemsTypes.OperationService))
	|		AND (ISNULL(ReportOnRetailSalesOfGoods.Characteristic.Principal, ReportOnRetailSalesOfGoods.Products.Principal) = UNDEFINED
	|			OR ISNULL(ReportOnRetailSalesOfGoods.Characteristic.Principal, ReportOnRetailSalesOfGoods.Products.Principal) = ReportOnRetailSalesOfGoods.Ref.Organization)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailSalesOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailSalesOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailSalesOfGoods.ItemsLocationAttributes.Products.ItemsType,
	|		ReportOnRetailSalesOfGoods.VATRate,
	|		ReportOnRetailSalesOfGoods.AmountIncludingVAT - ReportOnRetailSalesOfGoods.VATAmount AS Sum,
	|		ReportOnRetailSalesOfGoods.VATAmount
	|	FROM
	|		Document.RetailSalesReport.InventoryKinds AS ReportOnRetailSalesOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailSalesOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailSalesOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailSalesOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailSalesOfGoods.Ref.Posted
	|		AND ReportOnRetailSalesOfGoods.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CommissionAgentSReportGoods.Ref.Organization,
	|		BEGINOFPERIOD(CommissionAgentSReportGoods.Ref.Date, MONTH),
	|		CommissionAgentSReportGoods.ItemsLocationAttributes.Products.ItemsType,
	|		CommissionAgentSReportGoods.VATRate,
	|		ISNULL(DocumentAmountsInLocalCurrency.VATBaseLocal, CommissionAgentSReportGoods.AmountIncludingVAT - CommissionAgentSReportGoods.VATAmount) AS Sum,
	|		ISNULL(DocumentAmountsInLocalCurrency.VATAmountCompl, CommissionAgentSReportGoods.VATAmount)
	|	FROM
	|		Document.ConsignmentReportFromCustomer.InventoryKinds AS CommissionAgentSReportGoods
	|			INNER JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInLocalCurrency
	|			ON DocumentAmountsInLocalCurrency.Recorder = CommissionAgentSReportGoods.Ref
	|			 AND DocumentAmountsInLocalCurrency.RowID = CommissionAgentSReportGoods.RowID
	|	WHERE
	|		CommissionAgentSReportGoods.Ref.Organization IN(&CompanyArray)
	|		AND CommissionAgentSReportGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CommissionAgentSReportGoods.Ref.Posted
	|		AND CommissionAgentSReportGoods.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|		AND (NOT CommissionAgentSReportGoods.Customer.LegalEntityIndividual IN
	|			(VALUE(Enum.LegalEntityIndividual.Entity), VALUE(Enum.LegalEntityIndividual.IndividualEntrepreneur))
	|			OR CommissionAgentSReportGoods.Customer = VALUE(Catalog.Counterparties.EmptyRef))
	|		AND CommissionAgentSReportGoods.CommissionAgentSTaxInvoiceNumber = """"
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CommissionAgentSReportGoods.Ref.Organization,
	|		BEGINOFPERIOD(CommissionAgentSReportGoods.Ref.Date, MONTH),
	|		CommissionAgentSReportGoods.ItemsLocationAttributes.Products.ItemsType,
	|		CommissionAgentSReportGoods.VATRate,
	|		ISNULL(DocumentAmountsInLocalCurrency.VATBaseLocal, CommissionAgentSReportGoods.AmountIncludingVAT - CommissionAgentSReportGoods.VATAmount) AS Sum,
	|		ISNULL(DocumentAmountsInLocalCurrency.VATAmountCompl, CommissionAgentSReportGoods.VATAmount)
	|	FROM
	|		Document.ConsignmentReportFromCustomer.Goods AS CommissionAgentSReportGoods
	|			INNER JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInLocalCurrency
	|			ON DocumentAmountsInLocalCurrency.Recorder = CommissionAgentSReportGoods.Ref
	|			 AND DocumentAmountsInLocalCurrency.RowID = CommissionAgentSReportGoods.RowID
	|	WHERE
	|		CommissionAgentSReportGoods.Ref.Organization IN(&CompanyArray)
	|		AND CommissionAgentSReportGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CommissionAgentSReportGoods.Ref.Posted
	|		AND CommissionAgentSReportGoods.Products.ItemsType IN 
	|			(VALUE(Enum.ItemsTypes.Work_5),VALUE(Enum.ItemsTypes.OperationService))
	|		AND (NOT CommissionAgentSReportGoods.Customer.LegalEntityIndividual IN
	|			(VALUE(Enum.LegalEntityIndividual.Entity), VALUE(Enum.LegalEntityIndividual.IndividualEntrepreneur))
	|			OR CommissionAgentSReportGoods.Customer = VALUE(Catalog.Counterparties.EmptyRef))
	|		AND CommissionAgentSReportGoods.CommissionAgentSTaxInvoiceNumber = """"
	|		AND (ISNULL(CommissionAgentSReportGoods.Characteristic.Principal, CommissionAgentSReportGoods.Products.Principal) = UNDEFINED
	|			OR ISNULL(CommissionAgentSReportGoods.Characteristic.Principal, CommissionAgentSReportGoods.Products.Principal) = CommissionAgentSReportGoods.Ref.Organization)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailReturnsOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailReturnsOfGoods.Products.ItemsType,
	|		ReportOnRetailReturnsOfGoods.VATRate,
	|		CASE
	|			WHEN ReportOnRetailReturnsOfGoods.Ref.PriceIncludesVAT
	|				THEN - ReportOnRetailReturnsOfGoods.Sum + ReportOnRetailReturnsOfGoods.VATAmount
	|			ELSE - ReportOnRetailReturnsOfGoods.Sum
	|		END AS Sum,
	|		- ReportOnRetailReturnsOfGoods.VATAmount
	|	FROM
	|		Document.RetailReturnsReport.Goods AS ReportOnRetailReturnsOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailReturnsOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailReturnsOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailReturnsOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailReturnsOfGoods.Ref.Posted
	|		AND ReportOnRetailReturnsOfGoods.Products.ItemsType IN 
	|			(VALUE(Enum.ItemsTypes.Work_5),VALUE(Enum.ItemsTypes.OperationService))
	|		AND ReportOnRetailReturnsOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (ISNULL(ReportOnRetailReturnsOfGoods.Characteristic.Principal, ReportOnRetailReturnsOfGoods.Products.Principal) = UNDEFINED
	|			OR ISNULL(ReportOnRetailReturnsOfGoods.Characteristic.Principal, ReportOnRetailReturnsOfGoods.Products.Principal) = ReportOnRetailReturnsOfGoods.Ref.Organization)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailReturnsOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailReturnsOfGoods.ItemsLocationAttributes.Products.ItemsType,
	|		ReportOnRetailReturnsOfGoods.VATRate,
	|		- ReportOnRetailReturnsOfGoods.AmountIncludingVAT + ReportOnRetailReturnsOfGoods.VATAmount AS Sum,
	|		- ReportOnRetailReturnsOfGoods.VATAmount
	|	FROM
	|		Document.RetailReturnsReport.InventoryKinds AS ReportOnRetailReturnsOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailReturnsOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailReturnsOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailReturnsOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailReturnsOfGoods.Ref.Posted
	|		AND ReportOnRetailReturnsOfGoods.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|		AND ReportOnRetailReturnsOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|) AS RetailSales
	|
	|GROUP BY
	|	RetailSales.Organization,
	|	RetailSales.Period,
	|	RetailSales.VATRate,
	|	RetailSales.ItemsType";
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.SetParameter("InventoryTypesOwn", Enums.InventoryTypes.InventoryTypesOwn());
	
	SetPrivilegedMode(True);
	SalesTable = Query.Execute().Unload();
	
	Return SalesTable;
	
EndFunction

// Retrieves data on corrections to retail sales data for previous periods in the current period.
//
// Parameters:
//  CalculationParameters - Structure - parameters for getting sales: Organization, Beginning Of Period, End Of Period
//
// Returns:
//  ValueTable - with columns:
//		Organization, Period, Period being corrected, Nomenclature type, StavkaNDS, SummaBezNDS, SummaNDS
//
Function GetSalesCorrectionDataForPeriod(CalculationParameters) Export
	
	QueryText = 
	"SELECT DISTINCT
	|	RetailSalesReport.CashRegisterShift AS CashRegisterShift
	|INTO CashShiftsWithReports
	|FROM
	|	Document.RetailSalesReport AS RetailSalesReport
	|WHERE
	|	RetailSalesReport.Organization IN(&CompanyArray)
	|	AND RetailSalesReport.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RetailSalesReport.Posted
	|	
	|UNION
	|	
	|SELECT DISTINCT
	|	RetailReturnsReport.CashRegisterShift AS CashRegisterShift
	|FROM
	|	Document.RetailReturnsReport AS RetailReturnsReport
	|WHERE
	|	RetailReturnsReport.Organization IN(&CompanyArray)
	|	AND RetailReturnsReport.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RetailReturnsReport.Posted
	|
	|INDEX BY
	|	CashRegisterShift
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RetailSales.Organization        AS Organization,
	|	RetailSales.Period             AS Period,
	|	RetailSales.ItemsType    AS ItemsType,
	|	RetailSales.VATRate          AS VATRate,
	|	SUM(RetailSales.Sum)       AS Sum,
	|	SUM(RetailSales.VATAmount)    AS VATAmount,
	|	RetailSales.CorrectionPeriod AS CorrectionPeriod
	|FROM
	|	(SELECT
	|		CashRegisterReceiptGoods.Ref.Organization AS Organization,
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.Date, MONTH) AS Period,
	|		CashRegisterReceiptGoods.Products.ItemsType AS ItemsType,
	|		CashRegisterReceiptGoods.VATRate AS VATRate,
	|		CASE
	|			WHEN CashRegisterReceiptGoods.Ref.PriceIncludesVAT
	|				THEN - CashRegisterReceiptGoods.Sum + CashRegisterReceiptGoods.VATAmount
	|			ELSE - CashRegisterReceiptGoods.Sum
	|		END AS Sum,
	|		-CashRegisterReceiptGoods.VATAmount AS VATAmount,
	|		BEGINOFPERIOD(ReceiptOfCashRegisterAdjustment.OriginalDateOfSale, MONTH) AS CorrectionPeriod
	|	FROM
	|		Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
	|			INNER JOIN Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
	|			ON (ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = CashRegisterReceiptGoods.Ref)
	|				AND (ReceiptOfCashRegisterAdjustment.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|				AND (ReceiptOfCashRegisterAdjustment.Posted)
	|				AND ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|				AND (ReceiptOfCashRegisterAdjustment.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_))
	|	WHERE
	|		CashRegisterReceiptGoods.Ref.Date < &BeginOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.Organization IN (&CompanyArray)
	|		AND NOT CashRegisterReceiptGoods.Ref.CashRegisterShift IN (SELECT T.CashRegisterShift FROM CashShiftsWithReports AS T)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashRegisterReceiptGoods.Ref.Organization,
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.Date, MONTH),
	|		CashRegisterReceiptGoods.Products.ItemsType,
	|		CashRegisterReceiptGoods.VATRate,
	|		SUM(CASE
	|			WHEN CashRegisterReceiptGoods.Ref.PriceIncludesVAT
	|				THEN CashRegisterReceiptGoods.Sum - CashRegisterReceiptGoods.VATAmount
	|			ELSE CashRegisterReceiptGoods.Sum
	|		END) AS Sum,
	|		SUM(CashRegisterReceiptGoods.VATAmount),
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.OriginalDateOfSale, MONTH)
	|	FROM
	|		Document.ReceiptOfCashRegisterAdjustment.Goods AS CashRegisterReceiptGoods
	|	WHERE
	|		CashRegisterReceiptGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.CashRegisterReceipt.Date < &BeginOfPeriod
	|		AND CashRegisterReceiptGoods.Ref.Posted
	|		AND CashRegisterReceiptGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		AND CashRegisterReceiptGoods.Ref.Organization IN (&CompanyArray)
	|		AND NOT CashRegisterReceiptGoods.Ref.CashRegisterShift IN (SELECT T.CashRegisterShift FROM CashShiftsWithReports AS T)
	|		AND CashRegisterReceiptGoods.Ref.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|	
	|	GROUP BY
	|		CashRegisterReceiptGoods.Ref,
	|		CashRegisterReceiptGoods.Products.ItemsType,
	|		CashRegisterReceiptGoods.VATRate,
	|		BEGINOFPERIOD(CashRegisterReceiptGoods.Ref.OriginalDateOfSale, MONTH)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailSalesOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailSalesOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailSalesOfGoods.Products.ItemsType,
	|		ReportOnRetailSalesOfGoods.VATRate,
	|		CASE
	|			WHEN ReportOnRetailSalesOfGoods.Ref.PriceIncludesVAT
	|				THEN ReportOnRetailSalesOfGoods.Sum - ReportOnRetailSalesOfGoods.VATAmount
	|			ELSE ReportOnRetailSalesOfGoods.Sum
	|		END AS Sum,
	|		ReportOnRetailSalesOfGoods.VATAmount,
	|		BEGINOFPERIOD(ReportOnRetailSalesOfGoods.DocumentSalesOfGoodsAndServices.Date, MONTH)
	|	FROM
	|		Document.RetailSalesReport.Goods AS ReportOnRetailSalesOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailSalesOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailSalesOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailSalesOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailSalesOfGoods.Ref.Posted
	|		AND ReportOnRetailSalesOfGoods.Products.ItemsType IN 
	|			(VALUE(Enum.ItemsTypes.Work_5),VALUE(Enum.ItemsTypes.OperationService))
	|		AND ReportOnRetailSalesOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailSalesOfGoods.DocumentSalesOfGoodsAndServices.Date < &BeginOfPeriod
	|		AND (ISNULL(ReportOnRetailSalesOfGoods.Characteristic.Principal, ReportOnRetailSalesOfGoods.Products.Principal) = UNDEFINED
	|			OR ISNULL(ReportOnRetailSalesOfGoods.Characteristic.Principal, ReportOnRetailSalesOfGoods.Products.Principal) = ReportOnRetailSalesOfGoods.Ref.Organization)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailSalesOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailSalesOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailSalesOfGoods.ItemsLocationAttributes.Products.ItemsType,
	|		ReportOnRetailSalesOfGoods.VATRate,
	|		ReportOnRetailSalesOfGoods.AmountIncludingVAT - ReportOnRetailSalesOfGoods.VATAmount AS Sum,
	|		ReportOnRetailSalesOfGoods.VATAmount,
	|		BEGINOFPERIOD(ReportOnRetailSalesOfGoods.DocumentSalesOfGoodsAndServices.Date, MONTH)
	|	FROM
	|		Document.RetailSalesReport.InventoryKinds AS ReportOnRetailSalesOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailSalesOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailSalesOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailSalesOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailSalesOfGoods.Ref.Posted
	|		AND ReportOnRetailSalesOfGoods.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|		AND ReportOnRetailSalesOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailSalesOfGoods.DocumentSalesOfGoodsAndServices.Date < &BeginOfPeriod
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailReturnsOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailReturnsOfGoods.Products.ItemsType,
	|		ReportOnRetailReturnsOfGoods.VATRate,
	|		CASE
	|			WHEN ReportOnRetailReturnsOfGoods.Ref.PriceIncludesVAT
	|				THEN - ReportOnRetailReturnsOfGoods.Sum + ReportOnRetailReturnsOfGoods.VATAmount
	|			ELSE - ReportOnRetailReturnsOfGoods.Sum
	|		END AS Sum,
	|		- ReportOnRetailReturnsOfGoods.VATAmount,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices.Date, MONTH)
	|	FROM
	|		Document.RetailReturnsReport.Goods AS ReportOnRetailReturnsOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailReturnsOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailReturnsOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailReturnsOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailReturnsOfGoods.Ref.Posted
	|		AND ReportOnRetailReturnsOfGoods.Products.ItemsType IN 
	|			(VALUE(Enum.ItemsTypes.Work_5),VALUE(Enum.ItemsTypes.OperationService))
	|		AND ReportOnRetailReturnsOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices.Date < &BeginOfPeriod
	|		AND (ISNULL(ReportOnRetailReturnsOfGoods.Characteristic.Principal, ReportOnRetailReturnsOfGoods.Products.Principal) = UNDEFINED
	|			OR ISNULL(ReportOnRetailReturnsOfGoods.Characteristic.Principal, ReportOnRetailReturnsOfGoods.Products.Principal) = ReportOnRetailReturnsOfGoods.Ref.Organization)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailReturnsOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailReturnsOfGoods.ItemsLocationAttributes.Products.ItemsType,
	|		ReportOnRetailReturnsOfGoods.VATRate,
	|		- ReportOnRetailReturnsOfGoods.AmountIncludingVAT + ReportOnRetailReturnsOfGoods.VATAmount AS Sum,
	|		- ReportOnRetailReturnsOfGoods.VATAmount,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices.Date, MONTH)
	|	FROM
	|		Document.RetailReturnsReport.InventoryKinds AS ReportOnRetailReturnsOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailReturnsOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailReturnsOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailReturnsOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailReturnsOfGoods.Ref.Posted
	|		AND ReportOnRetailReturnsOfGoods.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|		AND ReportOnRetailReturnsOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices.Date < &BeginOfPeriod
	|) AS RetailSales
	|
	|GROUP BY
	|	RetailSales.Organization,
	|	RetailSales.Period,
	|	RetailSales.VATRate,
	|	RetailSales.ItemsType,
	|	RetailSales.CorrectionPeriod";
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.SetParameter("InventoryTypesOwn", Enums.InventoryTypes.InventoryTypesOwn());
	
	SetPrivilegedMode(True);
	SalesTable = Query.Execute().Unload();
	
	Return SalesTable;
	
EndFunction


// Receives data on retail refunds for the period.
//
// Parameters:
//  CalculationParameters - Structure - parameters for getting sales: Organization, Beginning Of Period, End Of Period
//
// Returns:
//  ValueTable - with columns:
//		Organization, Period, Nomenclature type, StavkaNDS, SummaBezNDS, SummaNDS
//
Function GetRefundDataForPeriod(CalculationParameters) Export
	
	QueryText = 
	"SELECT DISTINCT
	|	RetailReturnsReport.CashRegisterShift AS CashRegisterShift
	|INTO CashShiftsWithReports
	|FROM
	|	Document.RetailReturnsReport AS RetailReturnsReport
	|WHERE
	|	RetailReturnsReport.Organization IN(&CompanyArray)
	|	AND RetailReturnsReport.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RetailReturnsReport.Posted
	|
	|INDEX BY
	|	CashRegisterShift
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RetailReturns.Organization        AS Organization,
	|	RetailReturns.Period             AS Period,
	|	RetailReturns.ItemsType    AS ItemsType,
	|	RetailReturns.VATRate          AS VATRate,
	|	SUM(RetailReturns.Sum)       AS Sum,
	|	SUM(RetailReturns.VATAmount)    AS VATAmount,
	|	RetailReturns.DocumentSalesOfGoodsAndServices AS DocumentToBeCorrected
	|FROM
	|	(SELECT
	|		ReportOnRetailReturnsOfGoods.Ref.Organization AS Organization,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.Ref.Date, MONTH) AS Period,
	|		ReportOnRetailReturnsOfGoods.Products.ItemsType AS ItemsType,
	|		ReportOnRetailReturnsOfGoods.VATRate AS VATRate,
	|		CASE
	|			WHEN ReportOnRetailReturnsOfGoods.Ref.PriceIncludesVAT
	|				THEN ReportOnRetailReturnsOfGoods.Sum - ReportOnRetailReturnsOfGoods.VATAmount
	|			ELSE ReportOnRetailReturnsOfGoods.Sum
	|		END AS Sum,
	|		ReportOnRetailReturnsOfGoods.VATAmount AS VATAmount,
	|		ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|	FROM
	|		Document.RetailReturnsReport.Goods AS ReportOnRetailReturnsOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailReturnsOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailReturnsOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailReturnsOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailReturnsOfGoods.Ref.Posted
	|		AND NOT ReportOnRetailReturnsOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailReturnsOfGoods.Products.ItemsType IN 
	|			(VALUE(Enum.ItemsTypes.Work_5),VALUE(Enum.ItemsTypes.OperationService))
	|		AND ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices <> VALUE(Document.RetailSalesReport.EmptyRef)
	|		AND (ISNULL(ReportOnRetailReturnsOfGoods.Characteristic.Principal, ReportOnRetailReturnsOfGoods.Products.Principal) = UNDEFINED
	|			OR ISNULL(ReportOnRetailReturnsOfGoods.Characteristic.Principal, ReportOnRetailReturnsOfGoods.Products.Principal) = ReportOnRetailReturnsOfGoods.Ref.Organization)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportOnRetailReturnsOfGoods.Ref.Organization,
	|		BEGINOFPERIOD(ReportOnRetailReturnsOfGoods.Ref.Date, MONTH),
	|		ReportOnRetailReturnsOfGoods.ItemsLocationAttributes.Products.ItemsType,
	|		ReportOnRetailReturnsOfGoods.VATRate,
	|		ReportOnRetailReturnsOfGoods.AmountIncludingVAT - ReportOnRetailReturnsOfGoods.VATAmount,
	|		ReportOnRetailReturnsOfGoods.VATAmount,
	|		ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices
	|	FROM
	|		Document.RetailReturnsReport.InventoryKinds AS ReportOnRetailReturnsOfGoods
	|			INNER JOIN CashShiftsWithReports AS CashShiftsWithReports
	|			ON CashShiftsWithReports.CashRegisterShift = ReportOnRetailReturnsOfGoods.Ref.CashRegisterShift
	|	WHERE
	|		ReportOnRetailReturnsOfGoods.Ref.Organization IN(&CompanyArray)
	|		AND ReportOnRetailReturnsOfGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportOnRetailReturnsOfGoods.Ref.Posted
	|		AND NOT ReportOnRetailReturnsOfGoods.ByCorrectionReceipt
	|		AND ReportOnRetailReturnsOfGoods.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|		AND ReportOnRetailReturnsOfGoods.DocumentSalesOfGoodsAndServices <> VALUE(Document.RetailSalesReport.EmptyRef)
	|) AS RetailReturns
	|
	|GROUP BY
	|	RetailReturns.Organization,
	|	RetailReturns.Period,
	|	RetailReturns.VATRate,
	|	RetailReturns.ItemsType,
	|	RetailReturns.DocumentSalesOfGoodsAndServices";
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CompanyArray", CalculationParameters.CompanyArray);
	Query.SetParameter("BeginOfPeriod", CalculationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", CalculationParameters.EndOfPeriod);
	Query.SetParameter("InventoryTypesOwn", Enums.InventoryTypes.InventoryTypesOwn());
	
	SetPrivilegedMode(True);
	RefundTable = Query.Execute().Unload();
	
	Return RefundTable;
	
EndFunction

#EndRegion

#Region FunctionsForCheckingStateOfCashShift

// The function returns a structure that characterizes the state of the last cash shift at the KKM checkout.
//
// Parameters:
//  Object - CatalogRef.CashRegisters, CatalogRef.Peripherals - Link to the KKM sales register.
//  CashRegisterShift - DocumentRef.CashRegisterShift, Undefined - A link to the document Cash shift, the description of which must be obtained.
//
// Returns:
//  See DescriptionOfCashShift
//
Function GetCashShiftState(Object, CashRegisterShift = Undefined) Export
	
	SetPrivilegedMode(True);
	
	CashRegisterCashRegisterFiscalDevice = CashRegisterCashRegisterFiscalDevice(Object);
	FiscalDevice = CashRegisterCashRegisterFiscalDevice.FiscalDevice;
	CashRegister             = CashRegisterCashRegisterFiscalDevice.CashRegister;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CashRegisterShift.Number                      AS CashShiftNumber,
	|	CashRegisterShift.Ref                     AS CashRegisterShift,
	|	CashRegisterShift.Status                     AS CashRegisterShiftStatus,
	|	CashRegisterShift.PeriodEndTransactionsStatus AS PeriodEndTransactionsStatus,
	|	
	|	CashRegisterShift.Organization          AS Organization,
	|	CashRegisterShift.CashRegister             AS CashRegister,
	|	CashRegisterShift.FiscalDevice AS FiscalDevice,
	|	
	|	CASE
	|		WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ShiftIsOpened,
	|	
	|	CASE
	|		WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			THEN CashRegisterShift.CashRegisterShiftStart
	|		ELSE CashRegisterShift.CashRegisterShiftEnd
	|	END AS StatusChangeDate,
	|	CashRegisterShift.SettlementAddress AS SettlementAddress,
	|	CashRegisterShift.PlaceOfSettlement AS PlaceOfSettlement
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Posted
	|	AND ((CashRegisterShift.CashRegister = &CashRegister AND &CashRegister <> UNDEFINED)
	|	OR (CashRegisterShift.FiscalDevice = &FiscalDevice AND &FiscalDevice <> UNDEFINED))
	|	AND (&CashRegisterShift = UNDEFINED OR &CashRegisterShift <> UNDEFINED AND CashRegisterShift.Ref = &CashRegisterShift)
	|
	|ORDER BY
	|	CashRegisterShift.DATE DESC,
	|	CashRegisterShift DESC";
	
	Query.SetParameter("CashRegister",             CashRegister);
	Query.SetParameter("FiscalDevice", FiscalDevice);
	Query.SetParameter("CashRegisterShift",		  CashRegisterShift);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	DescriptionOfCashShift = DescriptionOfCashShift();
	
	If Selection.Next() Then
		
		FillPropertyValues(DescriptionOfCashShift, Selection);
		
		If (CurrentSessionDate() - DescriptionOfCashShift.StatusChangeDate >= 86400)
			And Selection.ShiftIsOpened Then
			DescriptionOfCashShift.Error24Hours = True;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(CashRegister) Then
		FillInDescriptionOfCashShiftAtCashRegister(DescriptionOfCashShift, CashRegister);
	EndIf;
	
	Return DescriptionOfCashShift;
	
EndFunction

// The function returns a structure that characterizes the state of the cash shift with a certain number at the cash register of the KKM.
//
// Parameters:
//  Object - CatalogRef.CashRegisters, CatalogRef.Peripherals - Link to the KKM sales register.
//  ShiftNumber - Number - The number of the cash shift.
//
// Returns:
//  See DescriptionOfCashShift
//
Function GetStateOfCashShiftByNumber(Object, ShiftNumber) Export
	
	SetPrivilegedMode(True);
	
	CashRegisterCashRegisterFiscalDevice = CashRegisterCashRegisterFiscalDevice(Object);
	FiscalDevice = CashRegisterCashRegisterFiscalDevice.FiscalDevice;
	CashRegister             = CashRegisterCashRegisterFiscalDevice.CashRegister;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CashRegisterShift.Number                      AS CashShiftNumber,
	|	CashRegisterShift.Ref                     AS CashRegisterShift,
	|	CashRegisterShift.Status                     AS CashRegisterShiftStatus,
	|	CashRegisterShift.PeriodEndTransactionsStatus AS PeriodEndTransactionsStatus,
	|	
	|	CashRegisterShift.Organization          AS Organization,
	|	CashRegisterShift.CashRegister             AS CashRegister,
	|	CashRegisterShift.FiscalDevice AS FiscalDevice,
	|	
	|	CASE
	|		WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ShiftIsOpened,
	|	
	|	CASE
	|		WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			THEN CashRegisterShift.CashRegisterShiftStart
	|		ELSE CashRegisterShift.CashRegisterShiftEnd
	|	END AS StatusChangeDate,
	|	CashRegisterShift.SettlementAddress AS SettlementAddress,
	|	CashRegisterShift.PlaceOfSettlement AS PlaceOfSettlement
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Posted
	|	AND (CashRegisterShift.Number = &ShiftNumber)	
	|	AND ((CashRegisterShift.CashRegister = &CashRegister AND &CashRegister <> UNDEFINED)
	|	OR (CashRegisterShift.FiscalDevice = &FiscalDevice AND &FiscalDevice <> UNDEFINED))";
	
	Query.SetParameter("CashRegister",             CashRegister);
	Query.SetParameter("FiscalDevice", FiscalDevice);
	Query.SetParameter("ShiftNumber",           ShiftNumber);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	DescriptionOfCashShift = DescriptionOfCashShift();
	
	If Selection.Next() Then
		
		FillPropertyValues(DescriptionOfCashShift, Selection);
		
		If (CurrentSessionDate() - DescriptionOfCashShift.StatusChangeDate >= 86400)
			And Selection.ShiftIsOpened Then
			DescriptionOfCashShift.Error24Hours = True;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(CashRegister) Then
		FillInDescriptionOfCashShiftAtCashRegister(DescriptionOfCashShift, CashRegister);
	EndIf;
	
	Return DescriptionOfCashShift;
	
EndFunction

// The function returns a structure that characterizes the status of the cash shift on the date.
//
// Parameters:
//  Object - CatalogRef.CashRegisters, CatalogRef.Peripherals - Link to the KKM sales register
//  DateTime - Date - The date on which you need to get a description of the cash shift.
//
// Returns:
//  See DescriptionOfCashShift
//
Function GetDetailsOfCashShiftOnDate(Object, DateTime) Export
	
	SetPrivilegedMode(True);
	
	CashRegisterCashRegisterFiscalDevice = CashRegisterCashRegisterFiscalDevice(Object);
	FiscalDevice = CashRegisterCashRegisterFiscalDevice.FiscalDevice;
	CashRegister             = CashRegisterCashRegisterFiscalDevice.CashRegister;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CashRegisterShift.Number  AS CashShiftNumber,
	|	CashRegisterShift.Ref AS CashRegisterShift,
	|	CashRegisterShift.Status                     AS CashRegisterShiftStatus,
	|	CashRegisterShift.PeriodEndTransactionsStatus AS PeriodEndTransactionsStatus,
	|	
	|	CashRegisterShift.Organization          AS Organization,
	|	CashRegisterShift.CashRegister             AS CashRegister,
	|	CashRegisterShift.FiscalDevice AS FiscalDevice,
	|	
	|	CASE
	|		WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ShiftIsOpened,
	|	
	|	CASE
	|		WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|			THEN CashRegisterShift.CashRegisterShiftStart
	|		ELSE CashRegisterShift.CashRegisterShiftEnd
	|	END AS StatusChangeDate,
	|	CashRegisterShift.SettlementAddress AS SettlementAddress,
	|	CashRegisterShift.PlaceOfSettlement AS PlaceOfSettlement
	|FROM
	|	(SELECT
	|		MAX(CASE
	|				WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|					THEN CashRegisterShift.CashRegisterShiftStart
	|				ELSE CashRegisterShift.CashRegisterShiftEnd
	|			END) AS StatusChangeDate,
	|		CashRegisterShift.CashRegister AS CashRegister,
	|		CashRegisterShift.FiscalDevice AS FiscalDevice
	|	FROM
	|		Document.CashRegisterShift AS CashRegisterShift
	|	WHERE
	|		CashRegisterShift.Posted
	|		AND ((CashRegisterShift.CashRegister = &CashRegister AND &CashRegister <> UNDEFINED)
	|		OR (CashRegisterShift.FiscalDevice = &FiscalDevice AND &FiscalDevice <> UNDEFINED))
	|		AND CASE
	|				WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|					THEN CashRegisterShift.CashRegisterShiftStart
	|				ELSE CashRegisterShift.CashRegisterShiftEnd
	|			END <= &DateTime
	|	
	|	GROUP BY
	|		CashRegisterShift.CashRegister,
	|		CashRegisterShift.FiscalDevice) AS RegisterShifts
	|		LEFT JOIN Document.CashRegisterShift AS CashRegisterShift
	|		ON RegisterShifts.CashRegister = CashRegisterShift.CashRegister
	|		 AND RegisterShifts.FiscalDevice = CashRegisterShift.FiscalDevice
	|			AND CashRegisterShift.Posted 
	|			AND (RegisterShifts.StatusChangeDate = CASE
	|				WHEN CashRegisterShift.Status = VALUE(Enum.CashRegisterShiftStatuses.IsOpen)
	|					THEN CashRegisterShift.CashRegisterShiftStart
	|				ELSE CashRegisterShift.CashRegisterShiftEnd
	|			END)
	|";
	
	Query.SetParameter("CashRegister",             CashRegister);
	Query.SetParameter("FiscalDevice", FiscalDevice);
	
	Query.SetParameter("DateTime",            DateTime);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	DescriptionOfCashShift = DescriptionOfCashShift();
	
	If Selection.Next() Then
		
		FillPropertyValues(DescriptionOfCashShift, Selection);
		
	EndIf;
	
	If ValueIsFilled(CashRegister) Then
		FillInDescriptionOfCashShiftAtCashRegister(DescriptionOfCashShift, CashRegister);
	EndIf;
	
	Return DescriptionOfCashShift;
	
EndFunction

// The function gets the open cash shift for the KKM cash Register in the specified period.
// Used to control the intersection of cash shifts.
// Only one cash shift can exist at a time during a single period.
//
// Parameters:
//  Object - CatalogRef.CashRegisters, CatalogRef.Peripherals - Link to the KKM sales register
//  CashRegisterShift - DocumentRef.CashRegisterShift - Link to the cash shift,
//                if specified, then checks for any other cash shift
//  CashRegisterShiftStart - Date - Start date of the cash shift
//  CashRegisterShiftEnd - Date - End date of the cash shift.
//
// Returns:
//  DocumentRef.CashRegisterShift - Open cash shift for a specified period. Or undefined if there is no open shift.
//
Function GetOpenCashShift(Object, CashRegisterShift, CashRegisterShiftStart, CashRegisterShiftEnd) Export
	
	SetPrivilegedMode(True);
	
	CashRegisterCashRegisterFiscalDevice = CashRegisterCashRegisterFiscalDevice(Object);
	FiscalDevice = CashRegisterCashRegisterFiscalDevice.FiscalDevice;
	CashRegister             = CashRegisterCashRegisterFiscalDevice.CashRegister;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	CashRegisterShift.Ref AS Ref
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.CashRegisterShiftStart <= &CashRegisterShiftStart
	|	AND CASE
	|			WHEN CashRegisterShift.CashRegisterShiftEnd = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE CashRegisterShift.CashRegisterShiftEnd >= &CashRegisterShiftStart
	|		END
	|	AND ((CashRegisterShift.CashRegister = &CashRegister AND &CashRegister <> UNDEFINED)
	|	OR (CashRegisterShift.FiscalDevice = &FiscalDevice AND &FiscalDevice <> UNDEFINED))
	|	AND CashRegisterShift.Ref <> &CashRegisterShift
	|	AND CashRegisterShift.Posted
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	CashRegisterShift.Ref
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	&CashRegisterShiftEnd <> DATETIME(1, 1, 1)
	|	AND CashRegisterShift.CashRegisterShiftStart <= &CashRegisterShiftEnd
	|	AND CASE
	|			WHEN CashRegisterShift.CashRegisterShiftEnd = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE CashRegisterShift.CashRegisterShiftEnd >= &CashRegisterShiftEnd
	|		END
	|	AND ((CashRegisterShift.CashRegister = &CashRegister AND &CashRegister <> UNDEFINED)
	|	OR (CashRegisterShift.FiscalDevice = &FiscalDevice AND &FiscalDevice <> UNDEFINED))
	|	AND CashRegisterShift.Ref <> &CashRegisterShift
	|	AND CashRegisterShift.Posted
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	CashRegisterShift.Ref
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	&CashRegisterShiftEnd = DATETIME(1, 1, 1)
	|	AND CashRegisterShift.CashRegisterShiftStart >= &CashRegisterShiftStart
	|	AND ((CashRegisterShift.CashRegister = &CashRegister AND &CashRegister <> UNDEFINED)
	|	OR (CashRegisterShift.FiscalDevice = &FiscalDevice AND &FiscalDevice <> UNDEFINED))
	|	AND CashRegisterShift.Ref <> &CashRegisterShift
	|	AND CashRegisterShift.Posted
	|";
	
	Query.SetParameter("CashRegister",               CashRegister);
	Query.SetParameter("FiscalDevice",   FiscalDevice);
	
	Query.SetParameter("CashRegisterShiftStart",    CashRegisterShiftStart);
	Query.SetParameter("CashRegisterShiftEnd", CashRegisterShiftEnd);
	Query.SetParameter("CashRegisterShift",          CashRegisterShift);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// The function checks the status of the cash shift on the date. If the shift is not open, the error description is returned.
//
// Parameters:
//  CashRegisterShift - DocumentRef.CashRegisterShift - Link to the cash shift
//  Date - Date - Date of verification
//  ErrorDescription - String - Return the error description.
//
// Returns:
//  Boolean - True if the cash shift is open on the specified date.
//
Function ShiftIsOpened(CashRegisterShift, Date, ErrorDescription = "") Export
	
	SetPrivilegedMode(True);
	
	ShiftIsOpened = False;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CashRegisterShift.Status                 AS CashRegisterShiftStatus,
	|	CashRegisterShift.CashRegisterShiftStart    AS CashRegisterShiftStart,
	|	CashRegisterShift.CashRegisterShiftEnd AS CashRegisterShiftEnd
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Posted
	|	AND CashRegisterShift.Ref = &CashRegisterShift";
	
	Query.SetParameter("CashRegisterShift", CashRegisterShift);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		If Selection.CashRegisterShiftStatus = Enums.CashRegisterShiftStatuses.IsOpen Then
			
			// If the shift is open, then no more than 24 hours should pass from the moment of opening.
			If Date - Selection.CashRegisterShiftStart < 86400 Then
				
				ShiftIsOpened = True;
				
			Else
				
				ErrorDescription = ErrorDescription24Hours();
				ShiftIsOpened = False;
				
			EndIf;
			
		ElsIf ValueIsFilled(Selection.CashRegisterShiftStatus) Then
			
			If Selection.CashRegisterShiftEnd >= Date And Selection.CashRegisterShiftStart <= Date Then
				
				ShiftIsOpened = True;
				
			Else
				
				ErrorDescription = NStr("vi = 'Đã đóng phiên thu ngân';
										|ru = 'Кассовая смена закрыта.';
										|en = 'POS shift is closed.'; fa = 'POS shift is closed.';
										|it = 'Turno di cassa chiuso.';
										|pl = 'Zmiana kasy zamknięta.';
										|tr = 'Kasa vardiyası kapandı.'");
				ShiftIsOpened = False;
				
			EndIf;
			
		EndIf;
		
	Else
		
		ErrorDescription = NStr("vi = 'Phiên thu ngân chưa được mở.';
								|ru = 'Кассовая смена не открыта.';
								|en = 'POS shift is not opened.'; fa = 'POS shift is not opened.';
								|it = 'Turno di cassa non aperto.';
								|pl = 'Zmiana kasy nie otwarta.';
								|tr = 'Kasa vardiyası açılmadı.'");
		ShiftIsOpened = False;
		
	EndIf;
	
	Return ShiftIsOpened;
	
EndFunction

#EndRegion

#Region WorkWithContractInformationFZ54

// Fill in the parameters for sending an electronic receipt to the partner.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
//
Procedure FillInParametersForSendingElectronicReceiptToPartner(Form) Export
	
	SetPrivilegedMode(True);
	
	OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.DontSend;
	
	If ValueIsFilled(Form.Partner) And Form.Partner <> Catalogs.Partners.RetailCustomer Then
		OptionOfSendingElectronicReceipt = Common.ObjectAttributeValue(Form.Partner,
														 Metadata.Catalogs.Partners.Attributes.OptionOfSendingElectronicReceipt.Name);
		
		SourcesOfContactInformation = New Array;
		SourcesOfContactInformation.Add(Form.Partner);
		
		ContactInformationKinds = New Array;
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.PartnerSPhoneNumber);
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.EmailPartner_);
		
		ObjectContactInformation = ContactsManager.ObjectsContactInformation(SourcesOfContactInformation,, ContactInformationKinds, CurrentSessionDate());
		
		AddressEmail = "";
		PhoneNumber10Characters = "";
		Phone = "";
		For Each ContactInformationItem In ObjectContactInformation Do
			If ContactInformationItem.Kind = Catalogs.ContactInformationKinds.PartnerSPhoneNumber Then
				PhoneNumber10Characters = RetailSalesClientServer.PhoneNumberIn10CharactersFormat(ContactInformationItem.Presentation);
				Phone = RetailSalesClientServer.FormatPhoneNumber(PhoneNumber10Characters);
				Form.Items.Phone.ChoiceList.Add(Phone);
			EndIf;
			If ContactInformationItem.Kind = Catalogs.ContactInformationKinds.EmailPartner_ Then
				AddressEmail = ContactInformationItem.Presentation;
				Form.Items.Email.ChoiceList.Add(AddressEmail);
			EndIf;
		EndDo;
		
		If Form.Items.Phone.ChoiceList.Count() > 0 Then
			Form.Items.Phone.DropListButton = True;
		EndIf;
		
		If Form.Items.Email.ChoiceList.Count() > 0 Then
			Form.Items.Email.DropListButton = True;
		EndIf;
		
		If Not ValueIsFilled(OptionOfSendingElectronicReceipt) Then
			OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.DontSend;
			If Not GetFunctionalOption("PrintPaperReceipt") Then
				If Not IsBlankString(AddressEmail) Then
					OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail;
				ElsIf Not IsBlankString(PhoneNumber10Characters) Then
					OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendSMS;	
				EndIf;
			EndIf;	
		EndIf;
		
		If OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail Then
			If Not IsBlankString(AddressEmail) Then
				Form.Email = AddressEmail;
			EndIf;
		ElsIf OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendSMS Then
			If Not IsBlankString(PhoneNumber10Characters) Then
				Form.PhoneNumber10Characters = PhoneNumber10Characters;
				Form.Phone = Phone;
			EndIf;
		EndIf;

	EndIf;
		
	RetailSalesClientServer.SetOptionToSendElectronicReceipt(Form, OptionOfSendingElectronicReceipt);
	
EndProcedure

// To process the data of the electronic check.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
// 
// Returns:
//  See RetailSalesClientServer.ElectronicReceiptData
//
Function ProcessElectronicReceiptData(Form) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
	
		ElectronicReceiptData = RetailSalesClientServer.ElectronicReceiptData(Form);
		CheckResult = RetailSalesClientServer.CheckWhetherElectronicReceiptDataNeedsToBeProcessed(Form);
		
		If CheckResult.YouNeedToCreatePartner Then
			
			ElectronicReceiptData.Partner = CreatePartnerForOwnerOfElectronicReceiptContactInformation(ElectronicReceiptData);
			UpdatePartnerContactInformation(ElectronicReceiptData);
			
		Else
			
			If CheckResult.NeedToUpdateContactInformation Then
				
				UpdatePartnerContactInformation(ElectronicReceiptData);
				
			EndIf;
			
			If ValueIsFilled(ElectronicReceiptData.Partner)
				And CheckResult.YouNeedToUpdateOptionForSendingPartnerSElectronicReceipt Then
				
				PartnerObject_ = ElectronicReceiptData.Partner.GetObject();
				PartnerObject_.OptionOfSendingElectronicReceipt = ElectronicReceiptData.OptionOfSendingElectronicReceipt;
				PartnerObject_.Write();
				
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		Return Undefined;
		
	EndTry;
	
	Return ElectronicReceiptData;
	
EndFunction

// The procedure creates a partner with 
// the name "loyalty card Holder" based
// on the passed structure with the loyalty card data.
//
// Parameters:
//  Structuradannyh cards - Loyalty card data, See LoyaltyCardsServer.InitializeLoyaltyCardData.
//
// Returns:
//  CatalogRef.Partners - Partner.
//
Function CreatePartnerForOwnerOfElectronicReceiptContactInformation(ElectronicReceiptData)
	
	PartnerObject_ = Catalogs.Partners.CreateItem();
	
	If ElectronicReceiptData.OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail Then
		
		PartnerObject_.Description = StrTemplate(
			NStr("vi = 'Email chủ sở hữu  %1';
				|ru = 'Владелец E-mail %1';
				|en = '%1 email owner'; fa = '%1 email owner';
				|it = 'Proprietario E-mail %1';
				|pl = 'Właściciel E-mail %1';
				|tr = '%1E-posta sahibi '"),
			ElectronicReceiptData.ContactDetailsOfElectronicReceipt);
		
	ElsIf ElectronicReceiptData.OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendSMS Then
		
		PartnerObject_.Description = StrTemplate(
			NStr("vi = 'Chủ sở hữu điện thoại  %1';
				|ru = 'Владелец телефона %1';
				|en = '%1 phone owner'; fa = '%1 phone owner';
				|it = 'Proprietario del telefono %1';
				|pl = 'Właściciel telefonu %1';
				|tr = '%1Telefon sahibi'"),
			RetailSalesClientServer.FormatPhoneNumber(
				RetailSalesClientServer.PhoneNumberIn10CharactersFormat(ElectronicReceiptData.ContactDetailsOfElectronicReceipt)));
		
	EndIf;
	
	PartnerObject_.DescriptionFull = PartnerObject_.Description;
	PartnerObject_.LegalEntityIndividual = Enums.IndividualCompany.Person_;
	PartnerObject_.Client = True;
	PartnerObject_.RegistrationDate = CurrentSessionDate();
	PartnerObject_.OptionOfSendingElectronicReceipt = ElectronicReceiptData.OptionOfSendingElectronicReceipt;
	PartnerObject_.AccessGroup = Constants.PartnerSAccessGroupAtAutoCreation.Get();
	PartnerObject_.Write();
	
	Return PartnerObject_.Ref;
	
EndFunction

Procedure UpdatePartnerContactInformation(ElectronicReceiptData)
	
	Replace = False;
	
	If ElectronicReceiptData.OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail Then
		
		ContactsManager.AddContactInformation(
			ElectronicReceiptData.Partner,
			ElectronicReceiptData.ContactDetailsOfElectronicReceipt,
			Catalogs.ContactInformationKinds.EmailPartner_,,
			Replace);
		
	ElsIf ElectronicReceiptData.OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendSMS Then
		
		ContactsManager.AddContactInformation(
			ElectronicReceiptData.Partner,
			RetailSalesClientServer.FormatPhoneNumber(
				RetailSalesClientServer.PhoneNumberIn10CharactersFormat(ElectronicReceiptData.ContactDetailsOfElectronicReceipt)),
			Catalogs.ContactInformationKinds.PartnerSPhoneNumber,,
			Replace);
		
	EndIf;
	
EndProcedure

// The function returns parameters for sending an electronic receipt to the partner.
// 
// Parameters:
//  Partner - CatalogRef.Partners
//  
// Returns:
//  Structure:
//		* OptionOfSendingElectronicReceipt - EnumRef.OptionsOfSendingElectronicReceiptToCustomer
//		* ContactOfRecipientOfElectronicCheck - String
//
Function GetParametersForSendingElectronicReceiptToPartner(Partner) Export
	
	Result = New Structure;
	Result.Insert("OptionOfSendingElectronicReceipt");
	Result.Insert("ContactOfRecipientOfElectronicCheck");
	
	If Not ValueIsFilled(Partner) Then
		Return Result;
	EndIf;
	
	OptionOfSendingElectronicReceipt = Common.ObjectAttributeValue(Partner, "OptionOfSendingElectronicReceipt");
	If Not ValueIsFilled(OptionOfSendingElectronicReceipt) Then
		OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.DontSend;
	EndIf;
	
	Result.Insert("OptionOfSendingElectronicReceipt", OptionOfSendingElectronicReceipt);
	If OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.DontSend Then
		Return Result;
	EndIf;
		
	SourcesOfContactInformation = New Array;
	SourcesOfContactInformation.Add(Partner);
		
	ContactInformationKinds = New Array;
	If OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail Then
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.EmailPartner_);
	ElsIf OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendSMS Then
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.PartnerSPhoneNumber);
	EndIf;
		
	ObjectContactInformation = ContactsManager.ObjectsContactInformation(
			SourcesOfContactInformation,, ContactInformationKinds, CurrentSessionDate());
		
	For Each ContactInformationItem In ObjectContactInformation Do
			
		If ContactInformationItem.Kind = Catalogs.ContactInformationKinds.PartnerSPhoneNumber Then
			PhoneNumber10Characters = RetailSalesClientServer.PhoneNumberIn10CharactersFormat(ContactInformationItem.Presentation);
			Phone = RetailSalesClientServer.FormatPhoneNumber(PhoneNumber10Characters);
			Result.Insert("ContactOfRecipientOfElectronicCheck", Phone);
			Break;
		EndIf;
		
		If ContactInformationItem.Kind = Catalogs.ContactInformationKinds.EmailPartner_ Then
			Email = ContactInformationItem.Presentation;
			Result.Insert("ContactOfRecipientOfElectronicCheck", Email);
			Break;
		EndIf;
			
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

// Searches for the last payment/shipment document for the transmitted order
// and puts the document in the receipt queue for remote fiscal processing.
//
// Parameters:
//	ReferenceOrder - DocumentRef.SalesOrder
// 
// Returns:
// 	Boolean
//
Function AddDocumentsByOrderToQueueOfKktChecks(ReferenceOrder) Export

	SetPrivilegedMode(True);
	
	ARAPObject = ARAPAccountingServer.ObjectOfCalculationsByReference(ReferenceOrder);
	
	Query = New Query;
	Query.Text = RetailSalesLocalization.QueryTextDocumentsByOrder();
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("ARAPObject", ARAPObject);
	SelectionByDay = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SelectionByDay.Next() Do
		
		SelectionByDocuments = SelectionByDay.Select();
		
		While SelectionByDocuments.Next() Do
			
			DocumentForFiscalization = SelectionByDocuments.Ref;
			
			If Not GeneratingFiscalChecksServerCall.AllowedPenetrationOfFiscalChecksOnDocument(DocumentForFiscalization) Then
				Continue;
			EndIf;
			
			If GeneratingFiscalChecksServerCall.FiscalCheckOnDocumentIsBroken(DocumentForFiscalization) Then
				Break;
			EndIf; 
			
			ParametersOfReceiptFiscalizationOperation = 
				GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperationBatchMode(DocumentForFiscalization);
				
			ParametersOfReceiptFiscalizationOperation.IDOfFiscalRecord = String(DocumentForFiscalization.UUID());
			
			EquipmentReceiptPrintersServerCall.AddReceiptToKKTReceiptQueue(ParametersOfReceiptFiscalizationOperation);
			
			Break;
			
		 EndDo;
		 
	 EndDo;
	
	Return True;

EndFunction

#Region BatchProcessingOfTableParts

// Adds a request to the request package to get the data required to fill in the retail Sales conditions.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextAndFillInTermsOfRetailSales(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	YouNeedToPerformFollowingActions = BatchProcessingOfTablePartServer.YouNeedToPerformAction("FillInRetailSalesTermsAndConditions",
		StructureOfActions,
		CachedValues,
		ActionParameters);
	
	If YouNeedToPerformFollowingActions Then
		
		FillByStoreFormat = TypeOf(ActionParameters.ObjectForStoringSalesTermsAndConditions) = Type("CatalogRef.StoreFormats");
		
		ListOfRequests = QueryTextsTermsOfRetailSalesBatchProcessing(FillByStoreFormat);
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("ObjectForStoringSalesTermsAndConditions" , ActionParameters.ObjectForStoringSalesTermsAndConditions);
		QueryDetails.QueryOptions.Insert("Date", ActionParameters.Date);
		QueryDetails.QueryOptions.Insert("Currency", ActionParameters.Currency);
		QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		
	EndIf;
	
EndProcedure

// Divides the rows of the transmitted table into those in which the price needs to be filled in and those in which the price does not need to be filled in. 
// It is used to separate batch processing actions of tabular parts in retail documents.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  OriginalLines - DocumentTabularSection.CashRegisterReceipt.Goods, DocumentTabularSection.CashRegisterReceiptReturn.Goods - 
//
// Returns:
//	 Structure:
//		*NotItIsRequiredToFillInPrice - Array of DocumentTabularSectionRow.CashRegisterReceipt.Goods, DocumentTabularSectionRow.CashRegisterReceiptReturn.Goods -
//		*ItIsRequiredToFillInPrice - Array of DocumentTabularSectionRow.CashRegisterReceipt.Goods, DocumentTabularSectionRow.CashRegisterReceiptReturn.Goods -
//
Function SplitArrayOfStringsForDifferentTypesOfBatchProcessing(Form, OriginalLines) Export
	
	Result = New Structure;
	Result.Insert("ItIsRequiredToFillInPrice", Common.CopyRecursive(OriginalLines));
	Result.Insert("NotItIsRequiredToFillInPrice", New Array);

	RetailSalesLocalization.SplitArrayOfStringsForDifferentTypesOfBatchProcessing(Form, OriginalLines, Result);

	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ProceduresForMakingAndWithdrawingCash

// Perform automatic Cash collection.
// 
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - KKM ticket office
//  ErrorWhenDeletingZReport - Boolean - Error When Deleting The Z Report
// 
// Returns:
//  Boolean - Perform automatic cash collection
Function PerformAutomaticCashCollection(CashRegister, ErrorWhenDeletingZReport) Export
	
	Result = True;
	
	If Not ErrorWhenDeletingZReport Then
		
		SetPrivilegedMode(True);
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	CashRegisterCWPSettings.CashRegister.Owner                      AS Organization,
		|	CashRegisterCWPSettings.CashRegister.CashCurrency         AS Currency,
		|	CashRegisterCWPSettings.CashRegister                               AS CashRegister,
		|	ISNULL(CashInCashRegistersCRBalance.SumBalance, 0) AS DocumentAmount,
		|	CashRegisterCWPSettings.AutomaticCashCollection               AS AutomaticCashCollection
		|FROM
		|	Catalog.CWPSettings.CashRegisters AS CashRegisterCWPSettings
		|		LEFT JOIN AccumulationRegister.CashInCashRegistersCR.Balance(, CashRegister = &CashRegister) AS CashInCashRegistersCRBalance
		|		ON CashInCashRegistersCRBalance.CashRegister = CashRegisterCWPSettings.CashRegister
		|WHERE
		|	CashRegisterCWPSettings.CashRegister = &CashRegister
		|	AND CashRegisterCWPSettings.Ref.Workplace = &Workplace
		|";
		
		Query.SetParameter("CashRegister", CashRegister);
		Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		If Selection.Next() And Selection.AutomaticCashCollection And Selection.DocumentAmount > 0 Then
			CreateDocumentWithdrawalOfFundsFromCashRegisterCashRegister(Selection);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ProceduresForOpeningAndClosingCashShift

// The function returns the text describing the error in filling out the retail sales report.
//
Function GetErrorTextForFillingInReport()
	
	Return NStr("vi = 'Hãy kiểm tra tùy chỉnh kho bán lẻ và quầy thu ngân.';
				|ru = 'Проверьте настройки розничного склада и кассы ККМ.';
				|en = 'Check settings of the retail warehouse and cash register.'; fa = 'Check settings of the retail warehouse and cash register.';
				|it = 'Controllate le impostazioni del magazzino al dettaglio e della cassa dei KKM (Macchinari di Registrazione e Controllo).';
				|pl = 'Sprawdź ustawienia magazynu detalicznego i kasy fiskalnej.';
				|tr = 'Perakende depo ve yazar kasa ayarlarını kontrol edin.'");
	
EndFunction

// Checks that the Cur value of operation is maintained when closing the cashier shift.
// If it is not supported, it shows the text of the recommendation to switch to the receipt archiving mode.
//
Procedure CheckOfOperationWhenClosingCashierShiftShowRecommendation()

	If Constants.TransactionOnRegisterShiftEndClosing.Get() = Enums.TransactionsOnRegisterShiftEndClosing.None Then
	
		RecommendationTemplate = NStr("vi = 'Theo tùy chỉnh hiện tại, khi đóng phiên thu ngân sẽ không lưu trữ phiếu tính tiền.
							|Chế độ hoạt động này không được khuyến nghị và không còn được hỗ trợ.
							|Chúng tôi khuyên bạn nên bật chế độ ""%1"" khi đóng phiên thu ngân.
							|Khi lưu trữ phiếu tính tiền, tất cả biến động tiền và thay đổi số dư hàng tồn kho mà được phản ánh trong phiên bằng các chứng từ ""%2""
							|và ""%3"", sau khi đóng phiên thu ngân sẽ thống kê chúng trong các chứng từ ""%4"" và ""%5"".';
							|ru = 'Согласно текущим настройкам при закрытии кассовой смены архивирование чеков не производится.
							|Этот режим работы не является рекомендуемым и более не поддерживается.
							|Рекомендуем включить режим ""%1"" при закрытии кассовой смены.
							|При архивации чеков ККМ все движения денежных средств и изменения остатков в складском учете, которые в течение смены отражаются документами ""%2""
							|и ""%3"", после закрытия кассовой смены агрегируются в документах ""%4"" и ""%5"".';
							|en = 'According to the current settings, sales slips are not archived when the POS shift is closed.
							|This mode is not recommended and is no longer supported.
							|We recommend that you enable ""%1"" mode when closing the POS shift.
							|When archiving sales slips, all cash flows and changes in inventory balances, which are registered in the ""%2""
							| and ""%3"" documents during the shift, are aggregated in the ""%4"" and ""%5"" documents after shift-end closing.'; fa = 'According to the current settings, sales slips are not archived when the POS shift is closed.
							|This mode is not recommended and is no longer supported.
							|We recommend that you enable ""%1"" mode when closing the POS shift.
							|When archiving sales slips, all cash flows and changes in inventory balances, which are registered in the ""%2""
							| and ""%3"" documents during the shift, are aggregated in the ""%4"" and ""%5"" documents after shift-end closing.';
							|it = 'Согласно текущим настройкам при закрытии кассовой смены архивирование чеков не производится.
							|Этот режим работы не является рекомендуемым и более не поддерживается.
							|Рекомендуем включить режим ""%1"" при закрытии кассовой смены.
							|При архивации чеков ККМ все движения денежных средств и изменения остатков в складском учете, которые в течение смены отражаются документами ""%2""
							|и ""%3"", после закрытия кассовой смены агрегируются в документах ""%4"" и ""%5"".';
							|pl = 'According to the current settings, sales slips are not archived when the POS shift is closed.
							|This mode is not recommended and is no longer supported.
							|We recommend that you enable ""%1"" mode when closing the POS shift.
							|When archiving sales slips, all cash flows and changes in inventory balances, which are registered in the ""%2""
							| and ""%3"" documents during the shift, are aggregated in the ""%4"" and ""%5"" documents after shift-end closing.';
							|tr = 'Mevcut ayarlara göre, kasa vardiya sonu kapanışında fişler arşivlenmez.
							|Bu çalışma modu önerilmemektedir ve artık desteklenmemektedir.
							|Kasa vardiya sonu kapanışında ""%1"" modunun etkinleştirilmesi önerilmektedir.
							|Yazar kasa fişleri arşivlenirken, vardiya süresince ""%2""
							|ve ""%3"" numaralı belgelere yansıyan tüm kasa hareketleri ve ambar bakiyelerindeki değişiklikler, kasa vardiya sonu kapanışından sonra ""%4"" ve ""%5"" numaralı belgelerde toplanır.'");
		RecommendationText = StrTemplate(RecommendationTemplate, 
										Metadata.Enums.TransactionsOnRegisterShiftEndClosing.EnumValues.CashRegisterReceiptArchiving.Synonym,
										Metadata.Documents.CashRegisterReceipt.Synonym,
										Metadata.Documents.CashRegisterReceiptReturn.Synonym,
										Metadata.Documents.RetailSalesReport.Synonym,
										Metadata.Documents.RetailReturnsReport.Synonym);
		Common.MessageToUser(RecommendationText);
	
	EndIf;
	
EndProcedure	

// The function searches for the report on retail sales in the cash change.
//
// Returns:
//  DocumentRef.RetailSalesReport, Undefined - 
//
Function FindRetailSalesReport(CashRegisterShift, VATTaxation, Posted = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RetailSalesReport = Undefined;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	RetailSalesReport.Ref AS Ref,
	|	RetailSalesReport.VATTaxation AS VATTaxation
	|FROM
	|	Document.RetailSalesReport AS RetailSalesReport
	|WHERE
	|	RetailSalesReport.CashRegisterShift = &CashRegisterShift
	|	AND RetailSalesReport.VATTaxation = &VATTaxation
	|	AND (&Posted = UNDEFINED OR RetailSalesReport.Posted = &Posted)";
	
	Query.SetParameter("CashRegisterShift", CashRegisterShift);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Posted", Posted);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		RetailSalesReport = Selection.Ref;	
	EndIf;
	
	Return RetailSalesReport;
	
EndFunction

// The function searches for a report on retail returns by cash shift.
//
// Returns:
//  DocumentRef.RetailReturnsReport, Undefined - 
//
Function FindRetailReturnsReport(CashRegisterShift, VATTaxation, Posted = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RetailReturnsReport = Undefined;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	RetailReturnsReport.Ref AS Ref,
	|	RetailReturnsReport.VATTaxation AS VATTaxation	
	|FROM
	|	Document.RetailReturnsReport AS RetailReturnsReport
	|WHERE
	|	RetailReturnsReport.CashRegisterShift = &CashRegisterShift
	|	AND RetailReturnsReport.VATTaxation = &VATTaxation
	|	AND (&Posted = UNDEFINED OR RetailReturnsReport.Posted = &Posted)";
	
	Query.SetParameter("CashRegisterShift", CashRegisterShift);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Posted", Posted);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		RetailReturnsReport = Selection.Ref;	
	EndIf;
	
	Return RetailReturnsReport;
	
EndFunction

// This function deletes pending receipts.
//
Function DeleteDeferredReceipts(CashRegisterShift, ErrorDescription)
	
	SetPrivilegedMode(True);
	
	Result = True;
	
	BeginTransaction();
	Try
		
		SelectionOfCashRegisterReceipts = SelectDeferredCashRegisterReceiptsToDelete(CashRegisterShift);
		
		While SelectionOfCashRegisterReceipts.Next() Do
			CashRegisterReceiptObject = SelectionOfCashRegisterReceipts.Ref.GetObject(); // DocumentObject
			CashRegisterReceiptObject.Delete();
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		Result = False;
		
		ErrorDescription = NStr("vi = 'Khi xóa phiếu hoãn lại đã xảy ra lỗi.
		                            |Mô tả bổ sung:
		                            |%AdditionalDetails%';
		                            |ru = 'При удалении отложенных чеков произошла ошибка.
		                            |Дополнительное описание:
		                            |%AdditionalDetails%';
		                            |en = 'An error occurred while removing deferred receipts. 
		                            |Additional description:
		                            |%AdditionalDetails%'; fa = 'An error occurred while removing deferred receipts. 
		                            |Additional description:
		                            |%AdditionalDetails%';
		                            |it = 'Durante la cancellazione degli scontrini in sospeso si è verificato un errore.
		                            |Descrizione aggiuntiva:
		                            |%AdditionalDetails%';
		                            |pl = 'Przy usuwaniu zatrzymanych paragonów wystąpił błąd.
		                            |Dodatkowy opis:
		                            |%AdditionalDetails%';
		                            |tr = 'Ertelenmiş makbuzlar silinirken bir hata oluştu. 
		                            |Ek açıklama:
		                            |%AdditionalDetails%'");
		ErrorDescription = StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
	EndTry;
	
	Return Result;
	
EndFunction

Procedure SelectFillInImplementationDocumentInLine(RowOfTablePartProducts, TableOfImplementationDocuments, RegisterShiftState, SelectionDetailRecords, ReportError_ = False)
	If ValueIsFilled(SelectionDetailRecords.CashRegisterReceiptCashRegisterShift) 
		And SelectionDetailRecords.CashRegisterReceiptCashRegisterShift <> RegisterShiftState.CashRegisterShift Then
		FilterSearchForImplementationDocument = New Structure("CashRegisterShift,VATTaxation", SelectionDetailRecords.CashRegisterReceiptCashRegisterShift, SelectionDetailRecords.CashRegisterReceiptVATTaxation);
		FoundDocuments = TableOfImplementationDocuments.FindRows(FilterSearchForImplementationDocument);
		If FoundDocuments.Count() = 0 Then
			
			ErrorDescription = NStr("vi = 'Khi tạo bảng kê bán lẻ hàng hóa theo phiên thu ngân %1 trong dòng %2 theo phiếu điều chỉnh không thể chọn chứng từ bán hàng theo phiên thu ngân %3.';
									|ru = 'При создании отчета о розничных продажах по кассовой смене %1 в строке %2 по чеку коррекции не удалось подобрать документ реализации по кассовой смене %3.';
									|en = 'Cannot pick a sales document by the %3 POS shift in line %2 for the adjustment voucher when creating a retail sales report for the %1 POS shift.'; fa = 'Cannot pick a sales document by the %3 POS shift in line %2 for the adjustment voucher when creating a retail sales report for the %1 POS shift.';
									|it = 'При создании отчета о розничных продажах по кассовой смене %1 в строке %2 по чеку коррекции не удалось подобрать документ реализации по кассовой смене %3.';
									|pl = 'Cannot pick a sales document by the %3 POS shift in line %2 for the adjustment voucher when creating a retail sales report for the %1 POS shift.';
									|tr = 'Düzeltme fişi için %2 satırında %1 kasa vardiyası için perakende satış raporu oluşturulurken, kasa vardiyası için satış belgesi seçilemedi %3.'");
			If TypeOf(RowOfTablePartProducts) = Type("DocumentTabularSectionRow.RetailReturnsReport.Goods") Then
				RowOfTablePartProducts.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
				ErrorDescription = NStr("vi = 'Khi tạo bảng kê bán lẻ hàng hóa trả lại theo phiên thu ngân %1 trong dòng %2 không thể chọn chứng từ bán hàng theo phiên thu ngân %3. Đã thay đổi phương thức xác định giá vốn trong dòng cho %4.';
										|ru = 'При создании отчета о розничных возвратах по кассовой смене %1 в строке %2 не удалось подобрать документ реализации по кассовой смене %3. Способ определения себестоимости в строке изменен на %4.';
										|en = 'Cannot pick a sales document by the %3 POS shift in line %2 when creating a retail sales report for the %1 POS shift. The cost defining method in the line is changed to %4.'; fa = 'Cannot pick a sales document by the %3 POS shift in line %2 when creating a retail sales report for the %1 POS shift. The cost defining method in the line is changed to %4.';
										|it = 'При создании отчета о розничных возвратах по кассовой смене %1 в строке %2 не удалось подобрать документ реализации по кассовой смене %3. Способ определения себестоимости в строке изменен на %4.';
										|pl = 'Cannot pick a sales document by the %3 POS shift in line %2 when creating a retail sales report for the %1 POS shift. The cost defining method in the line is changed to %4.';
										|tr = '%1 yazar kasa vardiyası için perakende iade raporu %2 satırında oluşturulurken, %3 yazar kasa vardiyası için satış belgesi seçilemedi. Hattaki maliyet belirleme yöntemi %4 olarak değiştirildi.'");
				ErrorDescription = StrTemplate(ErrorDescription, RegisterShiftState.CashRegisterShift, RowOfTablePartProducts.LineNumber, SelectionDetailRecords.CashRegisterReceiptCashRegisterShift, Enums.WaysToCalculateReturnCost.FromCurrentDocument);
			Else
				ErrorDescription = StrTemplate(ErrorDescription, RegisterShiftState.CashRegisterShift, RowOfTablePartProducts.LineNumber, SelectionDetailRecords.CashRegisterReceiptCashRegisterShift);
			EndIf;

			WriteLogEvent(NStr("vi = 'Bán lẻ';
								|ru = 'Розничные продажи';
								|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
								|it = 'Розничные продажи';
								|pl = 'Sprzedaże detaliczne';
								|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()), EventLogLevel.Warning, , , ErrorDescription);

			If ReportError_ = True Then
				Common.MessageToUser(ErrorDescription);
			EndIf;
			
		Else
			RowOfTablePartProducts.DocumentSalesOfGoodsAndServices = FoundDocuments[0].DocumentSalesOfGoodsAndServices;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FunctionsForCheckingStateOfCashShift

// It is determined by cash account Cash register fiscal device or by fiscal device - cash account Cash register.
// 
// Parameters:
//  Object - CatalogRef.Peripherals, CatalogRef.CashRegisters - Object
// 
// Returns:
//  Structure - Cash account KKMFISCAL device:
// * FiscalDevice - CatalogRef.Peripherals - 
// * CashRegister - CatalogRef.CashRegisters - 
Function CashRegisterCashRegisterFiscalDevice(Object) Export
	
	SetPrivilegedMode(True);
	
	FiscalDevice = Undefined;
	CashRegister             = Undefined;
	
	If TypeOf(Object) = Type("CatalogRef.CashRegisters") Then
		
		CashRegister = Object;
		
		Query = New Query(
		"SELECT TOP 1
		|	CashRegisters.Peripherals AS FiscalDevice
		|FROM
		|	Catalog.CWPSettings.CashRegisters AS CashRegisters
		|WHERE
		|	CashRegisters.CashRegister = &CashRegister
		|	AND NOT CashRegisters.UseWithoutConnectingPeripherals
		|	AND CashRegisters.Ref.Workplace = &Workplace
		|");
		
		Query.SetParameter("CashRegister",     CashRegister);
		Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FiscalDevice = Selection.FiscalDevice;
		
	Else
		
		FiscalDevice = Object;
		
		Query = New Query(
		"SELECT TOP 1
		|	CashRegisters.CashRegister AS CashRegister
		|FROM
		|	Catalog.CWPSettings.CashRegisters AS CashRegisters
		|WHERE
		|	CashRegisters.Peripherals = &FiscalDevice
		|	AND CashRegisters.Ref.Workplace = &Workplace
		|");
		
		Query.SetParameter("FiscalDevice", FiscalDevice);
		Query.SetParameter("Workplace",         EquipmentManagerServerCall.GetClientSWorkplace());
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		CashRegister = Selection.CashRegister;
		
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("FiscalDevice", FiscalDevice);
	ReturnValue.Insert("CashRegister",             CashRegister);
	
	Return ReturnValue;
	
EndFunction

// Gets a description of the cash shift at the KKM checkout
// 
// Parameters:
// 	DescriptionOfCashShift - Structure - Data structure for the cash shift
// 	CashRegister - CatalogRef.CashRegisters - KKM sales register for getting a description 
Procedure FillInDescriptionOfCashShiftAtCashRegister(DescriptionOfCashShift, CashRegister)
	
	Query = New Query(
	"SELECT
	|	ISNULL(CashInCashRegistersCRBalance.SumBalance, 0) AS CashOnHand,
	|	CashRegisters.CashCurrency                              AS Currency,
	|	CashRegisters.CashCurrency.Presentation                AS CurrencyPresentation,
	|	CashRegisters.Warehouse                                  AS Warehouse,
	|	CashRegisters.Warehouse.RetailPriceType                 AS PriceKind,
	|	CashRegisters.Warehouse.RetailPriceType.PriceIncludesVAT AS PriceIncludesVAT,
	|	CashRegisters.Owner                               AS Organization,
	|	CashRegisters.Department                          AS Department,
	|	CashRegisters.ItinerantTrade                     AS ItinerantTrade
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|		LEFT JOIN AccumulationRegister.CashInCashRegistersCR.Balance(, CashRegister = &CashRegister) AS CashInCashRegistersCRBalance
	|		ON (CashInCashRegistersCRBalance.CashRegister = CashRegisters.Ref)
	|WHERE
	|	CashRegisters.Ref = &CashRegister");
		
	Query.SetParameter("CashRegister", CashRegister);
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	DescriptionOfCashShift.CashRegister            = CashRegister;
	DescriptionOfCashShift.Warehouse               = Selection.Warehouse;
	DescriptionOfCashShift.PriceKind             = Selection.PriceKind;
	DescriptionOfCashShift.PriceIncludesVAT     = Selection.PriceIncludesVAT;
	DescriptionOfCashShift.Organization         = Selection.Organization;
	DescriptionOfCashShift.CashOnHand    = Selection.CashOnHand;
	DescriptionOfCashShift.Currency              = Selection.Currency;
	DescriptionOfCashShift.CurrencyPresentation = Selection.CurrencyPresentation;
	DescriptionOfCashShift.Department       = Selection.Department;
	
	DescriptionOfCashShift.InformationAboutCompany = PrintFormGeneration.InformationAboutLegalEntity(Selection.Organization, CurrentSessionDate());
	DescriptionOfCashShift.WarehouseAddress          = ContactsManager.ObjectContactInformation(Selection.Warehouse, Catalogs.ContactInformationKinds.WarehouseAddress);
	
	DescriptionOfCashShift.ItinerantTrade  = Selection.ItinerantTrade;

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillParameters.Organization = Selection.Organization;
	FillParameters.Date = CurrentSessionDate();
	FillParameters.Warehouse = Selection.Warehouse;
	If ValueIsFilled(Selection.Department) Then
		FillParameters.Department = Selection.Department;
	EndIf;
	FillParameters.Retail_ = True;
	VATAccountingERP.FillInSalesVATTaxation(DescriptionOfCashShift.VATTaxation, FillParameters);
		
	If DescriptionOfCashShift.VATTaxation = Enums.VATTaxationTypes.SalesByPatent Then
		DescriptionOfCashShift.TaxationSystem = Enums.CRETaxationSystemTypes.Patent;
	ElsIf DescriptionOfCashShift.VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToUTII Then
		DescriptionOfCashShift.TaxationSystem = Enums.CRETaxationSystemTypes.UTII;
	Else
		DescriptionOfCashShift.TaxationSystem = RetailSalesLocalization.FiscalTransactionTaxationSystem(Selection.Organization);
	EndIf;
	
EndProcedure

// Error description24 hours
// 
// Returns:
//  String - error description
//
Function ErrorDescription24Hours() Export
	
	Return NStr("vi = 'Đã quá 24 giờ kể từ khi mở phiên làm việc lần trước. Cần đóng phiên thu ngân.';
				|ru = 'С момента открытия кассовой смены истекло более 24 часов. Необходимо выполнить закрытие кассовой смены.';
				|en = 'More than 24 hours have passed since the POS shift was opened. Close the POS shift.'; fa = 'More than 24 hours have passed since the POS shift was opened. Close the POS shift.';
				|it = 'Dall''apertura dello cambio di cassa, sono trascorse più di 24 ore. È necessario completare la chiusura della cassa.';
				|pl = 'Od czasu otwarcia zmiany w kasie upłynęło ponad 24 godziny. Konieczne jest zamknięcie zmiany kasy fiskalnej.';
				|tr = 'Kasa vardiyası açıldığından beri 24 saat geçti. Kasa vardiyasını kapatın.'");
	
EndFunction

#EndRegion

#Region Other

// Fill in the details of the "cashier's Details" form.
//
// Parameters:
//  Cashier - CatalogRef.Users - Cashier.
//  Organization - CatalogRef.Companies - Organization for selection in the directory of responsible organizations.
//  DateTime - Date - For selection by Datanachal period - end Date in the reference list, responsible organizations.
//
// Returns:
// Structure:
// 	*TIN - String - 
// 	*Description - String - Full name of the cashier.
// 	*JobTitle - String - Cashier position.
// 
Function DetailsOfTheCashier(Cashier, Organization = Undefined, DateTime = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	Users.Individual AS Individual,	
	|	ISNULL(Users.Individual.TIN, """") AS TIN,
	|	ISNULL(Users.Individual.Description, """") AS Description,
	|	"""" AS JobTitle
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Ref = &Cashier");
	Query.SetParameter("Cashier", Cashier);
	
	DetailsOfTheCashier = New Structure;
	DetailsOfTheCashier.Insert("TIN", "");
	DetailsOfTheCashier.Insert("Description", NStr("vi = 'Người quản trị';
													|ru = 'Администратор';
													|en = 'Administrator'; fa = 'مدیر سیستم';
													|it = 'Amministratore';
													|pl = 'Administrator';
													|tr = 'Yönetici'"));
	DetailsOfTheCashier.Insert("JobTitle", "");
	
	SampleCashierDetails = Query.Execute().Select();
	If SampleCashierDetails.Next() Then
		
		If ValueIsFilled(SampleCashierDetails.Description) Then
			DetailsOfTheCashier.Description = TrimAll(SampleCashierDetails.Description);
		EndIf;
		
		DetailsOfTheCashier.TIN = SampleCashierDetails.TIN;
		
		If ValueIsFilled(SampleCashierDetails.Individual)
			And ValueIsFilled(Organization)	Then
			If Not ValueIsFilled(DateTime) Then
				DateTime = CurrentSessionDate();
			EndIf;
			
			FilterParameters = New Structure;
			FilterParameters.Insert("Owner", Organization);
			FilterParameters.Insert("EmployeeInCharge_", Enums.PersonsResponsibleAndCompanies.Cashier);
			FilterParameters.Insert("Date", DateTime); 
			CashiersOfOrganization = ResponsiblePersonsServer.GetTableOfResponsiblePersonsForSelection(FilterParameters);
			
			DataOfResponsiblePerson = CashiersOfOrganization.FindRows(New Structure("Individual", SampleCashierDetails.Individual));			
			If DataOfResponsiblePerson.Count() Then
				DetailsOfTheCashier.JobTitle = DataOfResponsiblePerson[0].JobTitle;
			EndIf;	
		EndIf;	
		
	EndIf;
	
	Return DetailsOfTheCashier;
	
EndFunction

Function AddItem(Form, CommandName, Parent, IndexOf)
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form.Items, CommandName) Then
		Return Form.Items[CommandName];
	EndIf;
	NewButton = Form.Items.Add(CommandName, Type("FormButton"), Form.Items[Parent + IndexOf]);
	
	Return NewButton;
	
EndFunction

Function SelectDeferredCashRegisterReceiptsToDelete(CashRegisterShift = Undefined)
	
	Query = New Query(
	"SELECT
	|	CashRegisterReceiptPaymentWithPaymentCards.Ref AS Ref
	|INTO CashRegisterReceiptsThatCannotBeDeleted
	|FROM
	|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS CashRegisterReceiptPaymentWithPaymentCards
	|WHERE
	|	CashRegisterReceiptPaymentWithPaymentCards.Ref.Status <> VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND CashRegisterReceiptPaymentWithPaymentCards.PaymentKind_ = VALUE(Enum.TypesOfCashRegisterPaymentSystem.InstantPayments)
	|	AND NOT (CashRegisterReceiptPaymentWithPaymentCards.SBPPaymentStatus = VALUE(Enum.TypesOfSBPPaymentStatuses.EmptyRef)
	|			OR CashRegisterReceiptPaymentWithPaymentCards.SBPPaymentStatus = VALUE(Enum.TypesOfSBPPaymentStatuses.RolledBack))
	|	AND (CashRegisterReceiptPaymentWithPaymentCards.Ref.CashRegisterShift = &CashRegisterShift
	|			OR &CashRegisterShift = UNDEFINED)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Document.Ref AS Ref,
	|	Document.Date AS Date,
	|	Document.DeferredUntil AS DeferredUntil,
	|	Document.CashRegisterShift AS CashRegisterShift
	|INTO CashRegisterReceipts
	|FROM
	|	Document.CashRegisterReceipt AS Document
	|WHERE
	|	Document.Status <> VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND (Document.CashRegisterShift = &CashRegisterShift
	|			OR &CashRegisterShift = UNDEFINED)
	|	AND NOT Document.Ref IN (SELECT
	|								Ref AS Ref
	|							FROM CashRegisterReceiptsThatCannotBeDeleted AS CashRegisterReceiptsThatCannotBeDeleted)
	|
	|UNION
	|
	|SELECT
	|	Document.Ref,
	|	Document.Date,
	|	Document.CashRegisterShift.CashRegisterShiftEnd,
	|	Document.CashRegisterShift
	|FROM
	|	Document.CashRegisterReceiptReturn AS Document
	|WHERE
	|	Document.Status <> VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	AND (Document.CashRegisterShift = &CashRegisterShift
	|			OR &CashRegisterShift = UNDEFINED)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashRegisterReceipt.Ref
	|FROM
	|	CashRegisterReceipts AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.DeferredUntil <> DATETIME(1, 1, 1)
	|	AND CashRegisterReceipt.DeferredUntil < &CurrentTime
	|
	|UNION
	|
	|SELECT
	|	CashRegisterReceipt.Ref
	|FROM
	|	CashRegisterReceipts AS CashRegisterReceipt
	|		LEFT JOIN Constant.NumberOfDeferredReceiptStorageDays AS NumberOfDeferredReceiptStorageDays
	|		ON (TRUE)
	|WHERE
	|	NumberOfDeferredReceiptStorageDays.Value > 0
	|	AND DATEADD(CashRegisterReceipt.Date, DAY, NumberOfDeferredReceiptStorageDays.Value) < &CurrentTime
	|
	|UNION
	|
	|SELECT
	|	CashRegisterReceipt.Ref
	|FROM
	|	CashRegisterReceipts AS CashRegisterReceipt
	|		LEFT JOIN Constant.NumberOfDeferredReceiptStorageDays AS NumberOfDeferredReceiptStorageDays
	|		ON (TRUE)
	|WHERE
	|	NumberOfDeferredReceiptStorageDays.Value = 0
	|	AND CashRegisterReceipt.CashRegisterShift.Status <> VALUE(Enum.CashRegisterShiftStatuses.IsOpen)");
	
	Query.SetParameter("CashRegisterShift", CashRegisterShift);
	Query.SetParameter("CurrentTime",  CurrentSessionDate());
	
	Result = Query.Execute();
	Return Result.Select();
	
EndFunction

Function DevicePresentation(TSRow)
	
	Presentation = "";
	
	If TSRow.EquipmentType = Enums.PeripheralTypes.LabelPrintingScales Then
		Presentation = NStr("vi = 'Cân có in nhãn tem';
							|ru = 'Весы с печатью этикеток';
							|en = 'Label printing scales'; fa = 'ترازوی چاپگر برچسب';
							|it = 'Pesi con la stampa delle etichette';
							|pl = 'Wagi z drukarką etykiet';
							|tr = 'Etiket baskı ölçüleri'");
	ElsIf TSRow.EquipmentType = Enums.PeripheralTypes.CustomerDisplay Then
		Presentation = NStr("vi = 'Màn hình khách hàng';
							|ru = 'Дисплей покупателя';
							|en = 'Customer display'; fa = 'Customer display';
							|it = 'Display dell''acquirente';
							|pl = 'Wyświetlacz klienta';
							|tr = 'Müşteri ekranı'");
	ElsIf OfflinePeripheralsServerCallLocalization.ThisIsTypeOfOfflineEquipmentCashRegister(TSRow.EquipmentType) Then
		Presentation = NStr("vi = 'Máy tính tiền Offline';
							|ru = 'ККМ Offline';
							|en = 'Offline cash register'; fa = 'صندوق فروش آفلاین';
							|it = 'KKM (Macchinari di Registrazione e Controllo) Offline';
							|pl = 'ККМ Offline';
							|tr = 'Çevrimdışı yazar kasa'");
	ElsIf TSRow.EquipmentType = Enums.PeripheralTypes.BarcodeScanner Then
		Presentation = NStr("vi = 'Máy quét mã vạch';
							|ru = 'Сканер штрихкода';
							|en = 'Barcode scanner'; fa = 'Barcode scanner';
							|it = 'Lettore di codici a barre';
							|pl = 'Skaner kodów kreskowych';
							|tr = 'Barkod tarayıcı'");
	ElsIf TSRow.EquipmentType = Enums.PeripheralTypes.MagneticStripeCardReaders Then
		Presentation = NStr("vi = 'Máy đọc thẻ từ';
							|ru = 'Считыватель магнитных карт';
							|en = 'Magnetic stripe card reader'; fa = 'کارت‌خوان نوار مغناطیسی';
							|it = 'Lettore di carte magnetiche';
							|pl = 'Czytnik kart magnetycznych';
							|tr = 'Manyetik kart okuyucu'");
	ElsIf TSRow.EquipmentType = Enums.PeripheralTypes.PortableDataCollectionTerminal Then
		Presentation = NStr("vi = 'Thiết bị thu thập dữ liệu';
							|ru = 'Терминал сбора данных';
							|en = 'Portable data terminal'; fa = 'Portable data terminal';
							|it = 'Terminale di raccolta dati';
							|pl = 'Terminal do zbierania danych';
							|tr = 'El terminali'");
	ElsIf TSRow.EquipmentType = Enums.PeripheralTypes.FiscalCashRegisters Then
		Presentation = NStr("vi = 'Máy ghi nhận tiền mặt';
							|ru = 'Фискальный регистратор';
							|en = 'Fiscal cash register'; fa = 'صندوق فروش مالی';
							|it = 'Registratore fiscale';
							|pl = 'Rejestrator fiskalny';
							|tr = 'Mali yazar kasa'");
	ElsIf TSRow.EquipmentType = Enums.PeripheralTypes.POSTerminal Then
		Presentation = NStr("vi = 'Thiết bị thẻ thanh toán';
							|ru = 'Эквайринговый терминал';
							|en = 'POS terminal'; fa = 'پایانه فروش (POS)';
							|it = 'Terminale di pagamento POS';
							|pl = 'Terminal acquiringowy';
							|tr = 'PoS terminali'");
	ElsIf TSRow.EquipmentType = Enums.PeripheralTypes.DigitalRetailScales Then
		Presentation = NStr("vi = 'Cân điện tử';
							|ru = 'Электронные весы';
							|en = 'Digital retail scales'; fa = 'ترازوهای دیجیتال خرده‌فروشی';
							|it = 'Pesi elettronici';
							|pl = 'Wagi elektroniczne';
							|tr = 'Elektronik tartı'");
	EndIf;
	
	Return Presentation;
	
EndFunction

// Fill in the equipment table on the form
//
// Parameters:
//  Form - ClientApplicationForm - The Form contains, among other things:
//  	* Equipment - ValueTable - 
//  SupportedPeripheralTypes - String - Supported hardware types.
//
Procedure FillInEquipmentTable(Form, SupportedPeripheralTypes) Export
	
	SoftwareTypes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(SupportedPeripheralTypes, ",", True, True);
	
	Workplace = EquipmentManagerServerCall.GetClientSWorkplace();
	EquipmentList = EquipmentManagerServerCall.EquipmentByParameters(
		SoftwareTypes,
		Undefined,
		Workplace);
	
	For Each TSRow In EquipmentList Do
		If TSRow.EquipmentType = Enums.PeripheralTypes.CREWithDataTransfer
			Or TSRow.EquipmentType = Enums.PeripheralTypes.ReceiptPrinter Then
			Continue;
		EndIf;
		NewRow = Form.Equipment.Add();
		FillPropertyValues(NewRow, TSRow);
		NewRow.Attached    = 1;
		NewRow.Presentation = DevicePresentation(NewRow);
	EndDo;
	
	If SoftwareTypes.Find("FiscalCashRegisters") <> Undefined Then
		
		Query = New Query(
		"SELECT ALLOWED
		|	CashRegisters.CashRegister AS Object,
		|	VALUE(Enum.PeripheralTypes.FiscalCashRegisters) AS EquipmentType,
		|	CashRegisters.Peripherals AS Ref
		|FROM
		|	Catalog.CWPSettings.CashRegisters AS CashRegisters
		|WHERE
		|	CashRegisters.Ref.Workplace = &Workplace
		|	AND CashRegisters.CashRegister.CashRegisterType = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
		|	AND NOT CashRegisters.UseWithoutConnectingPeripherals
		|");
		Query.SetParameter("Workplace", Workplace);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			NewRow = Form.Equipment.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Attached    = 1;
			NewRow.Presentation = DevicePresentation(NewRow);
		EndDo;
		
	EndIf;
	
EndProcedure

Function DeviceRegistrationParameters(Val DeviceID)
	
	Return PeripheralsReceiptPrinters.DeviceRegistrationParameters(DeviceID);
	
EndFunction

// Prepares the parameter structure for processing the cash shift status
//
// Parameters:
// 	Equipment - CatalogRef.Peripherals
// 
// Returns:
// 	Structure
//
Function GetShiftStateProcessingParameters(Equipment) Export
	
	Result = New Structure;
	
	Result.Insert("StructureRegisterShiftState", 
				RetailSalesServerCall.RegisterShiftState(Equipment));
	Result.Insert("AccessRights", SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser()));
	
	Return Result;
	
EndFunction

// Parameters:
//	ErrorText - String - error text (localized)
//	Event - String - the name of the event (localized) or the method from where the call originated
//	Data - AnyRef, DocumentObject - the link or object that the error is associated with
//	Level - String - possible options: "Error", "Warning"
Procedure LogEntry(Val ErrorText, Val Event, Data = Undefined, Val Level = "Error") Export
	
	If Lower(Level) = Lower("Warning") Then
		ELLevel = EventLogLevel.Warning;
	Else
		ELLevel = EventLogLevel.Error;
	EndIf;
	
	TransactionActive = TransactionActive();
	WriteLogEvent(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Bán lẻ.%1';
				|ru = 'Розничные продажи.%1';
				|en = 'Retail sales.%1'; fa = 'Retail sales.%1';
				|it = 'Розничные продажи.%1';
				|pl = 'Retail sales.%1';
				|tr = 'Perakende satışlar.%1'", Common.DefaultLanguageCode()), 
			Event), 
		ELLevel, 
		?(TransactionActive Or Data = Undefined, Undefined, Data.Metadata()), 
		?(TransactionActive Or Data = Undefined, Undefined, Data), 
		ErrorText);
	
EndProcedure

#EndRegion

#Region BatchProcessingOfTablePartsIsService

Function TextOfSourceRequestTermsOfRetailSales(Val FillByStoreFormat)
	
	If FillByStoreFormat Then
		
		QueryText =
		"(SELECT
		|	StoreFormats.SpecialPriceType AS PriceKind,
		|	1 AS Priority
		|FROM
		|	Catalog.StoreFormats AS StoreFormats
		|WHERE
		|	StoreFormats.Ref = &ObjectForStoringSalesTermsAndConditions
		|
		|UNION ALL
		|
		|SELECT
		|	StoreFormats.RetailPriceType,
		|	2
		|FROM
		|	Catalog.StoreFormats AS StoreFormats
		|WHERE
		|	StoreFormats.Ref = &ObjectForStoringSalesTermsAndConditions)";
		
	Else
		
		QueryText =
		"(SELECT
		|	Warehouses.SpecialPriceType AS PriceKind,
		|	1 AS Priority
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &ObjectForStoringSalesTermsAndConditions
		|
		|UNION ALL
		|
		|SELECT
		|	Warehouses.RetailPriceType,
		|	2
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &ObjectForStoringSalesTermsAndConditions)";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns a list of requests for getting retail sales conditions.
//
// Parameters:
// 	FillByStoreFormat - Boolean
//
// Returns:
// 	ValueList of String
//
Function QueryTextsTermsOfRetailSalesBatchProcessing(Val FillByStoreFormat) Export
	
	Result = New ValueList;
	
	QueryText = 
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	TTDataSource.Products AS Products,
	|	TTDataSource.Package AS Package,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE TTDataSource.Characteristic.ItemsCharacteristicForPricing
	|	END AS PricingVariant,
	|	ISNULL(CASE
	|			WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|				THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|			ELSE TTDataSource.Series.ItemsBatchForPricing
	|		END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE TTDataSource.Package
	|	END AS PricingPackage
	|INTO TableProductsDOP
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (ItemKinds.Ref = TTDataSource.Products.ProductKind)";
	
	Result.Add(QueryText, "TableProductsDOP");
	
	QueryText =
	"SELECT
	|	NestedQuery.PriceKind AS PriceKind,
	|	MIN(NestedQuery.Priority) AS Priority
	|INTO TemporaryTableTypesOfPrices
	|FROM
	|	&TextOfSalesTermsAndConditionsSourceRequest AS NestedQuery
	|WHERE
	|	NestedQuery.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|GROUP BY
	|	NestedQuery.PriceKind";
	
	QueryText = StrReplace(QueryText,
		"&TextOfSalesTermsAndConditionsSourceRequest",
		TextOfSourceRequestTermsOfRetailSales(FillByStoreFormat));
	
	Result.Add(QueryText, "TemporaryTableTypesOfPrices");
	
	QueryText = 
	"SELECT
	|	FilterTable.IdOfTTRow AS IdOfTTRow,
	|	FilterTable.Products AS Products,
	|	FilterTable.Package AS Package,
	|	FilterTable.PricingVariant AS PricingVariant,
	|	FilterTable.PricingBatch AS PricingBatch,
	|	FilterTable.PricingPackage AS PricingPackage,
	|	TemporaryTableTypesOfPrices.PriceKind AS PriceKind,
	|	MIN(TemporaryTableTypesOfPrices.Priority) AS Priority
	|INTO FilterTable
	|FROM
	|	TableProductsDOP AS FilterTable
	|		LEFT JOIN TemporaryTableTypesOfPrices AS TemporaryTableTypesOfPrices
	|		ON (TRUE)
	|GROUP BY
	|	FilterTable.IdOfTTRow,
	|	FilterTable.Products,
	|	FilterTable.Package,
	|	FilterTable.PricingVariant,
	|	FilterTable.PricingBatch,
	|	FilterTable.PricingPackage,
	|	TemporaryTableTypesOfPrices.PriceKind
	|
	|INDEX BY
	|	IdOfTTRow,
	|	Products,
	|	Package,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind";
	
	Result.Add(QueryText, "FilterTable");
	
	QueryText =
	"SELECT
	|	CurrencyRatesPrices.Currency AS Currency,
	|	CurrencyRatesPrices.CourseNumerator AS CourseNumerator,
	|	CurrencyRatesPrices.CourseDenominator AS CourseDenominator
	|INTO TableOfExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|
	|INDEX BY
	|	Currency";
	
	Result.Add(QueryText, "TableOfExchangeRates");
	
	QueryText =
	"SELECT
	|	Price_Table.Products AS Products,
	|	Price_Table.PricingVariant AS PricingVariant,
	|	Price_Table.PricingBatch AS PricingBatch,
	|	Price_Table.Package AS Package,
	|	Price_Table.PricingPackage AS PricingPackage,
	|	Price_Table.PriceKind AS PriceKind,
	|	Price_Table.Currency AS Currency,
	|	Price_Table.Price AS Price
	|INTO ItemPricesCrossSectionOfTheLatest
	|FROM
	|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, PricingVariant, PricingBatch,
	|		PricingPackage, PriceKind) IN
	|		(SELECT
	|			T.Products,
	|			T.PricingVariant,
	|			T.PricingBatch,
	|			T.PricingPackage,
	|			T.PriceKind
	|		FROM
	|			FilterTable AS T)) AS Price_Table
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind";
	
	Result.Add(QueryText, "ItemPricesCrossSectionOfTheLatest");
	
	QueryText = 
	"SELECT
	|	FilterTable.IdOfTTRow AS IdOfTTRow,
	|	ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) /
	|		ISNULL(&QueryTextPackagingFactor2, 1) * CASE
	|		WHEN &Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|				WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|				AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator / (Currency_Rates.CourseNumerator *
	|						CurrencyRatesPrices.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END AS Price,
	|	FilterTable.PriceKind AS PriceKind,
	|	FilterTable.Products AS Products,
	|	FilterTable.PricingVariant AS PricingVariant,
	|	FilterTable.PricingBatch AS PricingBatch,
	|	FilterTable.PricingPackage AS PricingPackage,
	|	FilterTable.Priority AS Priority
	|INTO ResultTable2
	|FROM
	|	FilterTable AS FilterTable
	|		LEFT JOIN ItemPricesCrossSectionOfTheLatest AS ItemPricesCrossSectionOfTheLatest
	|		ON FilterTable.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND FilterTable.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND FilterTable.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND FilterTable.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		AND FilterTable.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|		LEFT JOIN TableOfExchangeRates AS CurrencyRatesPrices
	|		ON ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
	|		LEFT JOIN TableOfExchangeRates AS Currency_Rates
	|		ON Currency_Rates.Currency = &Currency
	|
	|INDEX BY
	|	IdOfTTRow,
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(FilterTable.Package AS Catalog.PackagesAndUnitsOfMeasure)",
			"CAST(FilterTable.Products AS Catalog.Products)"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	
	Result.Add(QueryText, "ResultTable2");
	
	QueryText =
	"SELECT
	|	ResultTable2.IdOfTTRow AS IdOfTTRow,
	|	ResultTable2.Products AS Products,
	|	ResultTable2.PricingVariant AS PricingVariant,
	|	ResultTable2.PricingBatch AS PricingBatch,
	|	ResultTable2.PricingPackage AS PricingPackage,
	|	MIN(ResultTable2.Priority) AS Priority
	|INTO ResultTablePriorities
	|FROM
	|	ResultTable2 AS ResultTable2
	|GROUP BY
	|	ResultTable2.IdOfTTRow,
	|	ResultTable2.Products,
	|	ResultTable2.PricingVariant,
	|	ResultTable2.PricingBatch,
	|	ResultTable2.PricingPackage";
	
	Result.Add(QueryText, "ResultTablePriorities");
	
	QueryText =
	"SELECT
	|	ResultTable2.IdOfTTRow AS IdOfTTRow,
	|	ResultTable2.PriceKind AS PriceKind,
	|	ResultTable2.Price AS Price
	|INTO FillInRetailSalesTermsAndConditionsPreliminary
	|FROM
	|	ResultTablePriorities AS ResultTablePriorities
	|		INNER JOIN ResultTable2 AS ResultTable2
	|		ON ResultTablePriorities.IdOfTTRow = ResultTable2.IdOfTTRow
	|		AND ResultTablePriorities.Products = ResultTable2.Products
	|		AND ResultTablePriorities.PricingVariant = ResultTable2.PricingVariant
	|		AND ResultTablePriorities.PricingBatch = ResultTable2.PricingBatch
	|		AND ResultTablePriorities.PricingPackage = ResultTable2.PricingPackage
	|		AND ResultTablePriorities.Priority = ResultTable2.Priority
	|
	|INDEX BY
	|	IdOfTTRow";
	
	Result.Add(QueryText, "FillInRetailSalesTermsAndConditionsPreliminary");
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	ISNULL(TablePreliminary.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) AS PriceKind,
	|	ISNULL(TablePreliminary.Price, 0) AS Price
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN FillInRetailSalesTermsAndConditionsPreliminary AS TablePreliminary
	|		ON TTDataSource.IdOfTTRow = TablePreliminary.IdOfTTRow";
	
	Result.Add(QueryText, "FillInRetailSalesTermsAndConditions");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
