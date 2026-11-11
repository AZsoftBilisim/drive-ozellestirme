
#Region Public

// Checks whether the TIN meets the requirements.
//
// Parameters:
//  TIN                - String - check the individual number of the taxpayer.
//  IsLegalEntity - Boolean - indicates whether the TIN owner is a legal entity.
//  MessageText     - String - text of the error message.
//
// Returns:
//  Boolean - True if it matches.
//
Function TINMeetsRequirements(Val TIN, IsLegalEntity, MessageText) Export
	
	MeetsRequirements_ = True;
	MessageText = "";
	
	TIN      = TrimAll(TIN);
	TINLength = StrLen(TIN);
	
	If IsLegalEntity = Undefined Then
		MessageText = MessageText + NStr("vi = 'Chưa xác định kiểu đối tượng chủ MST';
										|ru = 'Не определен тип владельца ИНН';
										|en = 'TIN owner type is not defined.'; fa = 'TIN owner type is not defined.';
										|it = 'Tipo di proprietario del Codice Fiscale Individuale non definito';
										|pl = 'Niezdefiniowany typ właściciela NIP';
										|tr = 'VKN sahip türü tanımlanmamış'");
		Return False;
	EndIf;
	
	If Not CommonCELClientServer.OnlyNumbersInString(TIN) Then
		MeetsRequirements_ = False;
		MessageText = MessageText + NStr("vi = 'MST chỉ bao gồm các chữ số';
										|ru = 'ИНН должен состоять только из цифр';
										|en = 'TIN must consist of numbers only.'; fa = 'TIN must consist of numbers only.';
										|it = 'Codice Fiscale Individuale deve contenere solo numeri';
										|pl = 'Numer NIP musi składać się wyłącznie z liczb';
										|tr = 'VKN yalnızca rakamlardan oluşmalıdır'");
	EndIf;
	
	If IsLegalEntity And TINLength <> 10 Then
		MeetsRequirements_ = False;
		MessageText = MessageText + ?(ValueIsFilled(MessageText), Chars.LF, "")
			+ NStr("vi = 'MST của pháp nhân cần có 10 chữ số';
					|ru = 'ИНН юридического лица должен состоять из 10 цифр';
					|en = 'TIN of a legal entity must contain 10 digits'; fa = 'TIN of a legal entity must contain 10 digits';
					|it = 'Codice Fiscale Individuale della persona giuridica deve essere composto da 10 cifre';
					|pl = 'NIP podmiotu prawnego musi składać się z 10 cyfr.';
					|tr = 'Tüzel kişiye ait VKN 10 rakamdan oluşmalıdır'");
	ElsIf Not IsLegalEntity And TINLength <> 12 Then
		MeetsRequirements_ = False;
		MessageText = MessageText + ?(ValueIsFilled(MessageText), Chars.LF, "")
			+ NStr("vi = 'MST cá nhân phải có 12 số';
					|ru = 'ИНН физического лица должен состоять из 12 цифр';
					|en = 'Person''s TIN must contain 12 digits'; fa = 'Person''s TIN must contain 12 digits';
					|it = 'Codice Fiscale Individuale di un individuo deve essere composto da 12 cifre';
					|pl = 'NIP podmiotu prawnego musi składać się z 12 cyfr.';
					|tr = 'Gerçek kişiye ait VKN 12 rakamdan oluşmalıdır'");
	EndIf;
	
	If MeetsRequirements_ Then
		If IsLegalEntity Then
			Checksum = 0;
			For IndexOf = 1 To 9 Do
				If IndexOf = 1 Then
					Multiplier = 2;
				ElsIf IndexOf = 2 Then
					Multiplier = 4;
				ElsIf IndexOf = 3 Then
					Multiplier = 10;
				ElsIf IndexOf = 4 Then
					Multiplier = 3;
				ElsIf IndexOf = 5 Then
					Multiplier = 5;
				ElsIf IndexOf = 6 Then
					Multiplier = 9;
				ElsIf IndexOf = 7 Then
					Multiplier = 4;
				ElsIf IndexOf = 8 Then
					Multiplier = 6;
				ElsIf IndexOf = 9 Then
					Multiplier = 8;
				EndIf;
				Figure = Number(Mid(TIN, IndexOf, 1));
				Checksum = Checksum + Figure * Multiplier;
			EndDo;
			
			CheckDigit = (Checksum %11) %10;
			If CheckDigit <> Number(Mid(TIN, 10, 1)) Then
				MeetsRequirements_ = False;
				MessageText = MessageText + ?(ValueIsFilled(MessageText), Chars.LF, "")
				               + NStr("vi = 'Số kiểm tra cho MST không khớp với số đã tính';
										|ru = 'Контрольное число для ИНН не совпадает с рассчитанным';
										|en = 'The control number for the TIN does not match the calculated number'; fa = 'The control number for the TIN does not match the calculated number';
										|it = 'Numero di controllo per Codice Fiscale Individuale non corrisponde a quello calcolato';
										|pl = 'Numer kontrolny NIP nie pasuje do obliczonego';
										|tr = 'VKN referans numarası hesaplanan numarayla eşleşmiyor'");
			EndIf;
		Else
			Checksum11 = 0;
			Checksum12 = 0;
			For IndexOf = 1 To 11 Do
				// Calculation of the multiplier for the 11th and 12th digits.
				If IndexOf = 1 Then
					Multiplier11 = 7;
					Multiplier12 = 3;
				ElsIf IndexOf = 2 Then
					Multiplier11 = 2;
					Multiplier12 = 7;
				ElsIf IndexOf = 3 Then
					Multiplier11 = 4;
					Multiplier12 = 2;
				ElsIf IndexOf = 4 Then
					Multiplier11 = 10;
					Multiplier12 = 4;
				ElsIf IndexOf = 5 Then
					Multiplier11 = 3;
					Multiplier12 = 10;
				ElsIf IndexOf = 6 Then
					Multiplier11 = 5;
					Multiplier12 = 3;
				ElsIf IndexOf = 7 Then
					Multiplier11 = 9;
					Multiplier12 = 5;
				ElsIf IndexOf = 8 Then
					Multiplier11 = 4;
					Multiplier12 = 9;
				ElsIf IndexOf = 9 Then
					Multiplier11 = 6;
					Multiplier12 = 4;
				ElsIf IndexOf = 10 Then
					Multiplier11 = 8;
					Multiplier12 = 6;
				ElsIf IndexOf = 11 Then
					Multiplier11 = 0;
					Multiplier12 = 8;
				EndIf;

				Figure = Number(Mid(TIN, IndexOf, 1));
				Checksum11 = Checksum11 + Figure * Multiplier11;
				Checksum12 = Checksum12 + Figure * Multiplier12;
				
			EndDo;
			
			CheckDigit11 = (Checksum11 %11) %10;
			CheckDigit12 = (Checksum12 %11) %10;
			
			If CheckDigit11 <> Number(Mid(TIN,11,1)) Or CheckDigit12 <> Number(Mid(TIN,12,1)) Then
				MeetsRequirements_ = False;
				MessageText = MessageText + ?(ValueIsFilled(MessageText), Chars.LF, "")
				               + NStr("vi = 'Số kiểm tra cho MST không khớp với số đã tính';
										|ru = 'Контрольное число для ИНН не совпадает с рассчитанным';
										|en = 'The control number for the TIN does not match the calculated number'; fa = 'The control number for the TIN does not match the calculated number';
										|it = 'Numero di controllo per Codice Fiscale Individuale non corrisponde a quello calcolato';
										|pl = 'Numer kontrolny NIP nie pasuje do obliczonego';
										|tr = 'VKN referans numarası hesaplanan numarayla eşleşmiyor'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return MeetsRequirements_;
	
EndFunction 

#Region Constructors

// Fills in the structure of General parameters of the fiscal storage device.
//
// Returns:
//  Structure
//
Function GeneralFiscalStorageParameters() Export
	
	Parameters = New Structure();
	// FFD 1.0
	Parameters.Insert("CRERegistrationNumber"); // KKT registration number
	Parameters.Insert("CREIdentificationNumber");  // Factory number of the KKT 
	Parameters.Insert("ManufaturerNumberOfFiscalStorage");   // Fn factory number
	Parameters.Insert("FFDFNVersion");  // FFD FN version (one of the following values "1.0","1.1")
	Parameters.Insert("VersionFDFCRE"); // FFD CCT version (one of the following values "1.0","1.05","1.1")
	
	Parameters.Insert("CompanyName"); // Organization name
	Parameters.Insert("CompanyTIN");      // TIN organization
	
	Parameters.Insert("AddressOfSettlementsConduction"); // Settlement address
	Parameters.Insert("CalculationPlace"); // The place of settlement
	
	Parameters.Insert("TaxationSystemCodes"); // Cheats the tax system
	
	Parameters.Insert("IndicatesOfflineMode"  , False); // Flag for offline mode
	Parameters.Insert("IndicatesThatDataIsEncrypted"   , False); // Data encryption flag
	Parameters.Insert("IndicatesSettlementsForServices"   , False); // The basis of payment for services
	Parameters.Insert("SellExcisableGoods" , False); // Sale of excisable goods
	
	Parameters.Insert("GamblingConducting"     , False); // A sign of gambling
	Parameters.Insert("LotteryConducting"         , False); // The sign of the lottery
	Parameters.Insert("AgentCharacteristics");                   // Agent Feature Codes
	Parameters.Insert("IndicatesThatAccountableFormsAreGenerated"    , False); // A sign of the formation of AS BSO
	
	Parameters.Insert("IndicatesThatSettlementsAreMadeOnlyViaInternet", False);  // The KKT attribute for calculations only on the Internet
	Parameters.Insert("InstallPrinterAutomatically"    , False);  // Indicates whether the printer is installed in the machine
	Parameters.Insert("IndicatesAutomaticMode"  , False);  // Automatic mode flag
	Parameters.Insert("MachineNumberForAutomaticMode"); // The number of the machine for automatic operation
	Parameters.Insert("OFDINNOrganization");      // Name of the organization OFD
	Parameters.Insert("OrganizationOfdname"); // TIN of the organization OFD
	
	Parameters.Insert("EmailSender"); // The email address of the sender of the receipt.
	Parameters.Insert("FTSWebsiteAddress");    // The website address of the authorized body (FTS). 
	// FFD 1.2
	Parameters.Insert("CarryingOutCalculationOnInternet"  , False); // The KKT attribute for calculations on the Internet
	Parameters.Insert("SaleOfMarkedGoods" , False); // A sign of the CCT of trade in goods subject to mandatory labeling by means of identification
	Parameters.Insert("PawnshopUsageFlag" , False); // A sign of the use of CCT in the implementation of pawnshops lending to citizens
	Parameters.Insert("IndicationOfInsuranceActivity" , False); // A sign of application in the implementation of insurance activities
	// FFD 1.2 - Order of the Federal Tax Service of Russia dated 12.04.2023 N ED-7-20/239@
	Parameters.Insert("AutomaticVendingMachineSign"  , False); // Whether it is used in an automatic vending machine
	Parameters.Insert("WhetherPublicCateringServicesAreProvided" , False); // A sign of use in the provision of catering services
	Parameters.Insert("IndicatesWholesaleTradeWithOrganizations"     , True); // Whether to apply for wholesale trade with organizations and sole proprietors
	                                                           
	Return Parameters; 
	
EndFunction

// Fills in the structure of KKT registration parameters.
//
// Returns:
//  Structure
//
Function CRERegistrationParameters() Export
	
	Parameters = GeneralFiscalStorageParameters();                                           
	Parameters.Insert("ShowsWhetherFiscalizationIsUsed");        // A sign of registration of a fiscal storage device.    
	Parameters.Insert("SupportTSPIoT");            // KKT supports work with external TC PioT
	Parameters.Insert("FiscalizationDocumentNumber"); // Document number registration of the fiscal storage device.
	Parameters.Insert("DateAndTimeOfFiscalization");      // Date and time of the fiscal storage registration operation.
	Return Parameters; 
	
EndFunction

// Fills in the structure of FN fiscal Parameters.
//
// Returns:
//  Structure
//
Function ParametersOfDriveFiscalizationOperation() Export
	
	Parameters = GeneralFiscalStorageParameters();
	
	Parameters.Insert("CodeOfReasonForReregistration"); 
	Parameters.Insert("CodesOfReasonsForChangingInformation"); 
	Parameters.Insert("OperationType", 1);
	
	Parameters.Insert("Cashier"     , NStr("vi = 'Người quản trị';
											|ru = 'Администратор';
											|en = 'Administrator'; fa = 'مدیر سیستم';
											|it = 'Amministratore';
											|pl = 'Administrator';
											|tr = 'Yönetici'")); // Line, Required - full name of the person and position who made the settlement with the buyer (client), who issued the cash receipt.
	Parameters.Insert("CashierTIN"  , Undefined); // String,Optional - Taxpayer identification number of the cashier, if available.
	
	Return Parameters; 
	
EndFunction

// Fills in the structure of operation parameters.
//
// Returns:
//  Structure
//
Function OperationExecutionParameters() Export;
	
	OperationParametersList = New Structure();
	OperationParametersList.Insert("Cashier"     , NStr("vi = 'Người quản trị';
														|ru = 'Администратор';
														|en = 'Administrator'; fa = 'مدیر سیستم';
														|it = 'Amministratore';
														|pl = 'Administrator';
														|tr = 'Yönetici'")); // Full name of the person and position who performed the operation.
	OperationParametersList.Insert("CashierTIN"  , Undefined); // Taxpayer identification number of the cashier, if available.
	Return OperationParametersList;
	
EndFunction

// Fills in the agent's data structure.
//
// Returns:
//  Structure:
//   * PaymentAcceptanceOperator - Structure:
//      ** Phone - Undefined -
//   * TransferOperator - Structure:
//      ** Phone - String - 
//      ** Description - String -
//      ** Address - String - 
//      ** TIN - String - 
//   * PayingAgent - Structure:
//      ** Operation - String - 
//      ** Phone - String - 
//
Function ParametersAgentData() Export
	
	// FFD - The values of the "agent data" props (tag 1223) are shown in Table 22.
	Parameters = New Structure();
	
	PayingAgent = New Structure();
	PayingAgent.Insert("Operation", Undefined);  // String - The payment agent's operation.
	PayingAgent.Insert("Phone" , Undefined);  // String - The payment agent's phone number. In the +{C} format.
	Parameters.Insert("PayingAgent", PayingAgent);
	
	TransferOperator = New Structure();
	TransferOperator.Insert("Phone"     , Undefined); // String - Phone number of the transfer operator. In the +{C} format.
	TransferOperator.Insert("Description", Undefined); // String - Name of the transfer operator.
	TransferOperator.Insert("Address"       , Undefined); // String - Address of the transfer operator.
	TransferOperator.Insert("TIN"         , Undefined); // String - TIN of the transfer operator.
	Parameters.Insert("TransferOperator", TransferOperator);
	
	PaymentAcceptanceOperator = New Structure();
	PaymentAcceptanceOperator.Insert("Phone", Undefined); // String - Phone number of the payment acceptance operator. In the +{C} format.
	Parameters.Insert("PaymentAcceptanceOperator", PaymentAcceptanceOperator);
	
	Return Parameters; 
	
EndFunction

// Fills in the supplier's data structure.
//
// Returns:
// 	Structure - LongDesc:
//   * TIN - String 
//   * Description - String 
//   * Phone - String
//
Function ParametersSupplierData() Export
	
	Parameters = New Structure();
	Parameters.Insert("Phone");      // String - Supplier's phone number. In the +{C} format.
	Parameters.Insert("Description"); // String - Name of the supplier.
	Parameters.Insert("TIN");          // String - Supplier's INN.
	Return Parameters; 
	
EndFunction

// Fills in the data structure of the product item code.
//
// Returns:
// 	Structure - LongDesc:
//   * ProductCodeValue - String 
//   * ProductCodeType - String
//   * ProductCodeDetails - String
//   * SerialNumber - String
//   * GlobalTradeUnitIdentifier - String 
//   * ControlIdentificationMark - String
//   * TypeOfMarking - EnumRef.CREMarkingTypes - 
//
Function ParametersDataOfProductCode() Export
	
	Parameters = New Structure();
	
	// Tag formation 1162, for FFD 1.05, 1.1
	Parameters.Insert("TypeOfMarking"); // Enumeration.The type of marking is KKT, Optional - The type of marking. 
	// Previously, within the framework of pilot projects (in 2017-2019) on marking and registration of the disposal of control marks (KM) 
	// through the CCT, the Federal Tax Service provided a separate algorithm for encoding tag 1162 for each type of marking 
	// containing information about KM. That is why this enumeration was created - the type of labeling of the CCT.
	// But in accordance with the order of the Federal Tax Service dated 29.08.2019 No. MMV-7-20/434@ "On Amendments to Appendix No. 2 
	// to the order of the Federal Tax Service dated 21.03.2017 No. MMV-7-20/229@“ registered on 25.12.2019 No. 56978 
	// and effective from 01.03.2020, the coding algorithm of tag 1162 has become uniform for all types of labeling.
	// Thus, this enumeration and attribute are outdated. Left for compatibility.
	Parameters.Insert("ControlIdentificationMark");       // String,Optional - A Control Identification Mark (KiZ).
	Parameters.Insert("GlobalTradeUnitIdentifier"); // String,Optional - Global identifier of the Trading Unit (GTIN).
	Parameters.Insert("SerialNumber"); // String,Optional - Serial number.
	Parameters.Insert("ProductCodeDetails"); // String,Optional -The value of the item code details (Tag value 1162). Encoded by Base64 encoded text.                
	
	// Tag formation 1163, for FFD 1.2
	Parameters.Insert("ProductCodeType"); // Row,Optional - Table 118
	Parameters.Insert("ProductCodeValue"); // String,Optional - The value of the product code in Base64 (Table 118) 
	
	Return Parameters; 
	
EndFunction

// Fills in the fractional quantity data structure for a product item.
//
// Returns:
//  Structure
//
Function ParametersFractionalQuantity() Export
	
	Parameters = New Structure();
	Parameters.Insert("Numerator"   , Undefined); // The number, Necessarily - The numerator of the fractional quantity - the number of goods sold from the package.
	Parameters.Insert("Denominator" , Undefined); // A number, Necessarily - The denominator of a fractional quantity - the total number of goods in consumer packaging. 
	Return Parameters; 
	
EndFunction

// Fills in the structure of additional user details.
//
// Returns:
//  Structure:
//    * Description - String
//    * Value - String
//
Function ParametersOfAdditionalUserDetails() Export
	
	Parameters = New Structure();
	Parameters.Insert("Description", ""); // String,Optional - The name of the additional user details (Tag 1085).
	Parameters.Insert("Value", "");     // String,Optional - The value of the additional user's details (Tag 1086).
	Return Parameters; 
	
EndFunction

// Fills in the structure of the QR code parameters.
//
// Returns:
//  Structure
//
Function QRCodeParameters() Export
	
	Parameters = New Structure();
	Parameters.Insert("CodeValue"); // String,Optional - QR Code values.
	Parameters.Insert("UserText", NStr("vi = 'Hãy lưu phiếu để trả lại';
										|ru = 'Сохраните чек для возврата';
										|en = 'Save the receipt for refund'; fa = 'Save the receipt for refund';
										|it = 'Conservare scontrino per il reso';
										|pl = 'Zapisz paragon do zwrotu';
										|tr = 'İade için fişi kaydedin'")); // String,Optional - Text output to the user.
	
	Return Parameters; 
	
EndFunction

// Fills in the structure of the operational details of the receipt.
//
// Returns:
//  Structure
//
Function ParametersOperationalDetails() Export 
	
	// Nested tags 1270
	Parameters = New Structure();
	Parameters.Insert("DateAndTimeOfOperation");  // Date,Optional - Tag 1273 - Date, time of operation	
	Parameters.Insert("OperationID"); // Integer, Optional - Tag 1271 - Operation ID. 
	Parameters.Insert("OperationData"); // Line[64],Optional - Tag 1272 - Operation data.
	Return Parameters; 
	
EndFunction

// Fills in the structure of the industry details of the receipt.
// 1260 - industry details of the subject of calculation.
// 1261 - industry details of the receipt.
//
// Returns:
//  Structure
//
Function ParametersIndustryDetails() Export  
	
	// Nested tags 1260 & 1261
	Parameters = New Structure();
	// The values of the props "ID of the FOIV" (tag 1262) are given in Table 149.
	Parameters.Insert("IDOfFOIV"); // Line[3],Optional - Tag 1262 - Id of the FOIV.
	// Date of the regulatory act of the federal executive authority regulating the procedure 
	// for filling in the details "the value of the industry details" (tag 1265)
	Parameters.Insert("BaseDocumentDate");  // Date,Optional - Tag 1263 - Date of the foundation document	
	// The number of the regulatory act of the federal executive authority regulating the procedure 
	// for filling in the props "the value of the industry props" (tag 1265)
	Parameters.Insert("ReferenceDocumentNumber"); // Line[64],Optional - Tag 1264 is the number of the foundation document.
	// The composition of the values defined by the regulatory act of the federal executive authority 
	Parameters.Insert("AttributeValue"); // Line[256],Optional - Tag 1265 - The number of the foundation document.
	Return Parameters; 
	
EndFunction             

// Fills in the structure of customer information.
//
// Returns:
//  Structure
//
Function ParametersBuyerInformation() Export
	
	// Nested tags 1256 - Information about the buyer (client).
	Parameters = New Structure(); 
	// Details starting from FFD 1.1 (Introduced by order of 09.04.2018 N MMV-7-20/207@)
	// Name of the organization or surname, first name, patronymic (if any)
	Parameters.Insert("Customer");    // String,Optional - Tag 1227 - Recipient (buyer)	
	Parameters.Insert("BuyerTin"); // String,Optional - Tag 1228 - INN of the buyer (client)	 
	Parameters.Insert("BuyerAddress"); // String,Optional - Tag 1254 - Address of the buyer (client)	 
	Return Parameters; 
	
EndFunction

// Fills in the structure of the buyer's personal data.
//
// Returns:
//  Structure
//
Function ParametersPersonalDataOfBuyer() Export
	
	Parameters = New Structure(); 
	Parameters.Insert("TIN");             // String,Optional - TIN of the buyer (client)	 
	Parameters.Insert("BirthDate");    // Date, Optional - Date of birth of the buyer (client)	
	Parameters.Insert("Citizenship");     // String,Optional - Citizenship of the buyer (client)	 
	Parameters.Insert("DocumentKind");    // Enumeration, Optional - Code of the type of identity document	
	Parameters.Insert("DocumentData"); // String,Optional - Data of the identity document	 
	Return Parameters; 
	
EndFunction

// Fills in the structure of parameters for the receipt fiscalization operation.
//
// Returns:
// 	Structure - LongDesc:
//   * CorrectionData - Structure -:
//      ** PrescriptionNumber - Number
//      ** CorrectionDate_ - Date
//      ** AdjustmentDescription - String
//      ** AdjustmentType - Number -
//   * CRENonApplication - Boolean -
//   * DocumentToBeCorrected - Arbitrary
//   * ThereIsPersonalData - Boolean -
//   * IndividualModeOfDataPreparationForVOFDTransmission - Boolean -
//   * AllowableDiscrepancyOfFormatLogicalControl - Number -
//   * MethodOfFormatLogicalControl - Undefined -
//   * ProcessCorrectionCheck - Boolean -
//   * AdditionalUserDetails - Structure:
//      ** Value - Arbitrary
//      ** Description - String
//   * AdditionalAttribute - Undefined -
//   * NonFiscalDocuments - Array of String
//   * CashRegister - Arbitrary - 
//   * ReceiptTemplate - Arbitrary
//   * TableOfPayment - Array 
//   * ReceiptPositions - Array of See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptSFiscalLine.
//   * InformationAboutNonCashPayment - Array of See PeripheralsReceiptPrintersClientServer.ParametersInformationAboutNonCashPayment.
//   * CopiesOfReceipt - Number -
//   * FooterText - String -
//   * HeaderText - String -
//   * DateTime - Date -
//   * ShiftNumber - Number
//   * ReceiptNumber - String
//   * CheckoutNumber - String
//   * StoreName_ - String 
//   * StoreAddress - String
//   * CompanyCRTR - String
//   * CompanyTIN - String
//   * CompanyName - String
//   * SerialNumber - String
//   * BeneficiaryTIN - String
//   * Recipient - String
//   * VendorData - Structure:
//      ** TIN - String
//      ** Description - String
//      ** Phone - String
//   * AgentData - Structure:
//      ** PaymentAcceptanceOperator - Structure:
//          *** Phone - Undefined -
//      ** TransferOperator - Structure:
//          *** Phone - String -
//          *** Description - String -
//          *** Address - String -
//          *** TIN - String -
//      ** PayingAgent - Structure:
//          *** Operation - String -
//          *** Phone - String -
//   * AgentAttribute - Undefined -
//   * BuyerNumber - String
//   * EmailSender - String
//   * BuyerEmail - String
//   * PlaceOfSettlement - String
//   * SettlementAddress - String
//   * TaxationSystem - EnumRef.CRETaxationSystemTypes -
//   * Sends1CEmail - Boolean -
//   * Sends1CSMS - Boolean -
//   * CalculationType - EnumRef.CashSettlementTypes -
//   * Electronically - Boolean -
//   * RetailFacility - Undefined -
//   * Organization - Undefined -
//   * IDOfFiscalRecord - Undefined -
//   * DocumentBasis - Undefined -
//   * CashierTIN - Undefined -
//   * Cashier - String -
//   * TextOfShortSlipReceipt - String - text of a short slip receipt
//   * AutonomousCCT - Boolean - indicates that the CCT is not being used to break through the receipt      
//
Function ParametersOfReceiptFiscalizationOperation() Export;
	
	ReceiptParameters = OperationExecutionParameters();
	// Common requisites for all types of equipment.
	ReceiptParameters.Insert("DocumentBasis" , Undefined); // Link, Required. The document on which the receipt is being punched.
	ReceiptParameters.Insert("IDOfFiscalRecord", Undefined); // String,Optional. ID of the fiscal record. 
	ReceiptParameters.Insert("Organization"       , Undefined); // Link, Required. The organization for which the receipt is being processed.
	ReceiptParameters.Insert("RetailFacility"    , Undefined); // Link, Optional. The object on which the receipt is being punched.
	ReceiptParameters.Insert("Electronically"        , False); // Boolean, Mandatory - The receipt will be provided in electronic form, without printing. False is the default value.
	ReceiptParameters.Insert("CalculationType"        , PredefinedValue("Enum.CashSettlementTypes.CashReceipt")); // necessarily.
	ReceiptParameters.Insert("Sends1CSMS"   , False); // Boolean, Mandatory - SMS is sent by means of 1C.   False is the default value.
	ReceiptParameters.Insert("Sends1CEmail" , False); // Boolean, Mandatory - The email is sent by means of 1C. False is the default value.
	
	// Taxation systems - "Transfer.Types of Tax systemsaccount"
	ReceiptParameters.Insert("TaxationSystem", PredefinedValue("Enum.CRETaxationSystemTypes.GTS")); // Necessarily. Filled with the default value.  
	ReceiptParameters.Insert("SettlementAddress"     ); // String,Optional - Settlement address (Tag 1009).
	ReceiptParameters.Insert("PlaceOfSettlement"     ); // String,Optional - The place of calculations (Tag 1187).
	ReceiptParameters.Insert("MachineNumber"     ); // String,Optional - The Number of the machine (Tag 1036).
	ReceiptParameters.Insert("EmailSender"  ); // String,Optional - The email address of the sender of the receipt (Tag 1117).
	ReceiptParameters.Insert("BuyerEmail"   ); // String,Optional - The buyer's email address.
	ReceiptParameters.Insert("BuyerNumber"   ); // String,Optional - The buyer's phone number. In the format +{C}.
	ReceiptParameters.Insert("CompanyName" ); // String,Optional - The name of the organization.
	ReceiptParameters.Insert("CompanyTIN"      ); // String,Optional - INN of the organization.
	
	// The agent's attribute is "Enumeration.Signs of the agent", (FFD, Tag 1057, Decryption - Table 10)
	ReceiptParameters.Insert("AgentAttribute"     , Undefined); // Enumeration is an agent Attribute (Tag 1057).
	ReceiptParameters.Insert("AgentData"      , ParametersAgentData());     // Structure, Filling optional - Agent data.
	ReceiptParameters.Insert("VendorData"  , ParametersSupplierData()); // Structure, Filling optional - Supplier data.
	
	// Details starting from FFD 1.1 (Introduced by order of 09.04.2018 N MMV-7-20/207@)
	ReceiptParameters.Insert("Recipient"         );  // String,Optional - Tag 1227 - Recipient (buyer)	
	ReceiptParameters.Insert("BeneficiaryTIN"      );  // String,Optional - Tag 1228 - Recipient's TIN (buyer's TIN)	
	
	// Details starting from FFD 1.2 (Introduced by order of 14.09.2020 N ED-7-20/662@)
	ReceiptParameters.Insert("PersonalDataSubject"); // Optional - A natural person who is directly or indirectly identified or determined using personal data.
	ReceiptParameters.Insert("ThereIsPersonalData", False); // Boolean, Optional - The receipt parameters contain personal data.
	ReceiptParameters.Insert("PersonalDataType");        // Enum link.Type of personal data, Optional - Type of personal data.
	
	ReceiptParameters.Insert("BuyerInformation" , ParametersBuyerInformation());  // Structure,Filling optional - Tag 1256 - Information about the buyer (client)	
	ReceiptParameters.Insert("OperationalDetails", ParametersOperationalDetails()); // Structure,Filling optional - Tag 1270 - 
	ReceiptParameters.Insert("IndustryProps"  , ParametersIndustryDetails());   // Structure, Optional filling - Tag 1261 - Industry Attributes of the receipt,
	// Support of FFD changes by order N ED-7-20/236@ 
	ReceiptParameters.Insert("Internet"   , False); // Boolean, Optional - The use of CCT when making a cashless payment on the Internet.
	ReceiptParameters.Insert("TimeArea", Undefined); // The number, Optionally the number of the time zone of the place (address) of settlement in accordance with the legislation of the Russian Federation.
	// The hours of the season - Must be indicated for the fiscal receipt in which there is a marked product.
	
	// Parameters required for FR
	ReceiptParameters.Insert("SerialNumber"       ); // String,Optional - Factory number Cash register (compatible with FR).
	ReceiptParameters.Insert("CompanyCRTR"      ); // Line,Optional - the organization's checkpoint (For the UTII receipt).
	ReceiptParameters.Insert("StoreAddress"       ); // String,Optional - The address of the store (For the UTI receipt).
	ReceiptParameters.Insert("StoreName_"); // String,Optional - The name of the store (For the UTII receipt).
	ReceiptParameters.Insert("CheckoutNumber"          ); // Line, Optional - The cashier's Number (For the UTII receipt).
	ReceiptParameters.Insert("ReceiptNumber"           ); // Number, Optional - The number of the receipt (For the UTII receipt).
	ReceiptParameters.Insert("ShiftNumber"          ); // Number, Optional - Shift number (For the UTII receipt).
	ReceiptParameters.Insert("DateTime", CommonCELClientServer.SessionDate()); // Date time, Optional - Date time in the receipt (For the UTI check).
	// APK: 374-off message in the receipts
	ReceiptParameters.Insert("HeaderText"   , NStr("vi = 'CHÀO MỪNG!';
													|ru = 'ДОБРО ПОЖАЛОВАТЬ!';
													|en = 'WELCOME'; fa = 'WELCOME';
													|it = 'BENVENUTO!';
													|pl = 'WITAMY!';
													|tr = 'HOŞ GELDİNİZ!'"));   // String - filled with the default value. 
	ReceiptParameters.Insert("FooterText" , NStr("vi = 'CẢM ƠN QUÝ KHÁCH!';
												|ru = 'СПАСИБО ЗА ПОКУПКУ!';
												|en = 'THANK YOU FOR YOUR PURCHASE'; fa = 'THANK YOU FOR YOUR PURCHASE';
												|it = 'GRAZIE PER L''ACQUISTO!';
												|pl = 'DZIĘKUJĘ ZA ZAKUP!';
												|tr = 'SATIN ALIMINIZ İÇİN TEŞEKKÜRLER!'")); // String - filled with the default value. 
	// APK: 374-on
	ReceiptParameters.Insert("CopiesOfReceipt"    , 1); // The number, Optional - How many copies of the UTII checks to print on the receipt printer.

	// Check positions for fiscalization.
	ReceiptParameters.Insert("ReceiptPositions"  , New Array()); // Array of "Structure" elements. Necessarily.
	// Check payment table
	ReceiptParameters.Insert("TableOfPayment" , New Array()); // Array of "Structure" elements. Absolutely.
	// Example of filling in the payment line: Payment
	// line = Payment Parametersstroke();
	// Payment string.Payment types = Predefined value ("Enumeration.Types of platforms.Cash"); Cash
	// Payment string.Amount = Amount of Payment;
	// Parameters of the check.Table of payments.Add(Payment string);
	ReceiptParameters.Insert("InformationAboutNonCashPayment" , New Array()); // Array of "Structure" elements. Absolutely.
	// Example of filling in the payment line: Payment
	// line = The parameters of the Cashless payment();
	// Payment string.Amount = Amount of Payment;
	// Parameters of the check.Cashless payment information.Add(Payment string);
	
	// Parameters for printing a receipt according to a template.
	ReceiptParameters.Insert("ReceiptTemplate"            ); // Link, Optional - A custom template for generating a receipt.
	ReceiptParameters.Insert("CashRegister"              ); // Link,Optional - KKM Cash Register. 
	ReceiptParameters.Insert("NonFiscalDocuments" , New Array()); // Array of non-fiscal documents. Not necessarily.
	ReceiptParameters.Insert("PrintDevice"); // Link, Optional - Document printing device. Optional.
	ReceiptParameters.Insert("DocumentsPackage", New Map()); // Compliance of additional documents and devices with the receipt for printing. Optional.
	
	// String,Optional - Additional details of the receipt (Tag 1192).
	ReceiptParameters.Insert("AdditionalAttribute"  , Undefined); 
	// Structure, Filling is optional - additional user details (Tag 1084).
	ReceiptParameters.Insert("AdditionalUserDetails", ParametersOfAdditionalUserDetails());
	ReceiptParameters.Insert("ProcessCorrectionCheck", False); // Boolean, Optional - generate a correction check, only for FFD 1.1.
	ReceiptParameters.Insert("GenerateCorrectionReceiptForReverse", True); // Boolean, Optional - Generate correction checks in reverse according to the scenarios of the Federal Tax Service.

	// Format-logical control - "Enumerationslink.Methods of chronological control"
	ReceiptParameters.Insert("MethodOfFormatLogicalControl", Undefined);     // Enumeration, Optional - A method of format-logical control. 
	ReceiptParameters.Insert("AllowableDiscrepancyOfFormatLogicalControl", 0.01); // Number,Optional - the default value is set. 
	ReceiptParameters.Insert("IndividualModeOfDataPreparationForVOFDTransmission", False); // Boolean, Optional - the default value is set. 
	ReceiptParameters.Insert("SingleReceipt", False);  // Boolean, Optional - One fiscal operation is linked to several documents.
	
	// Fast payment system and FSS certificates
	ReceiptParameters.Insert("PaymentSystemType"); // Enum link.Type of payment system, Optional - Type of payment system.
	ReceiptParameters.Insert("PaymentSystemPaymentID"); // String,Optional - Payment ID of the payment system.
	ReceiptParameters.Insert("QRCode", QRCodeParameters()); // Structure, Filling optional - QR code parameters in the body of the receipt.
	ReceiptParameters.Insert("DetailedPayment", New Array()); // Array of elements "Structure" - parametersdetalization of the payment system()
	
	// Short slip check
	ReceiptParameters.Insert("TextOfShortSlipReceipt", ""); // String - text of the short slip receipt
	// Autonomous CCTS
	ReceiptParameters.Insert("AutonomousCCT", False);
	ReceiptParameters.Insert("CloudCashRegister", False);
	// Flag for collapsing identical lines on the printed form of the document.
	ReceiptParameters.Insert("CollapseIdenticalLinesWhenPrinting", False);
	
	// Signs of USAIS
	ReceiptParameters.Insert("ThereAreEGAISAlcoholicBeverages", False);
	ReceiptParameters.Insert("ThereAreDraftManufacturedProductsOfUSAIS", False);
	
	Return ReceiptParameters; 
	
EndFunction

// Fills in the structure of the fiscal line parameters for the receipt fiscalization.
//
// Returns:
//  Structure:
//   * Barcode - String
//   * SectionNumber_ - Number -
//   * AdditionalAttribute - Arbitrary
//   * ExciseTaxAmount - Number
//   * CustomsDeclarationNumber - String 
//   * CountryCodeOfOrigin - String
//   * ProductProductCodeData - Structure:
//      ** SerialNumber - String
//      ** GlobalTradeUnitIdentifier - String 
//      ** ControlIdentificationMark - String
//      ** TypeOfMarking - String 
//   * UnitOfMeasure - Arbitrary
//   * VendorData - Structure:
//      ** TIN - String
//      ** Description - String
//      ** Phone - String
//   * AgentData - See ParametersAgentData
//   * AttributeOfAgentForSubjectOfCalculation - Number 
//   * SettlementSubjectFlag - Undefined -
//   * ShowsCalculationMethod - Undefined -
//   * VATAmount - Undefined -
//   * VATRate - Undefined -
//   * Profit - Number
//   * Sum - Number -
//   * DiscountedPrice - Number -
//   * Price - Number -
//   * Count - Number -
//   * Description - String
//   * ItemLineNumber - Number
//   * FiscalLine - String
// 
Function ParametersOfReceiptSFiscalLine() Export;
	
	RowParameters = New Structure();
	RowParameters.Insert("FiscalLine");  // String,Required - String type. Outgoing service parameter. 
	RowParameters.Insert("ItemLineNumber"); // Number, Required - An additional parameter for processing receipt lines for format-logical control.
	// Required banking details
	RowParameters.Insert("Description");        // String,Required - The name of the subject of calculation
	RowParameters.Insert("Count"     , 0);  // Number, Required - The number of the subject of calculation 
	RowParameters.Insert("Price"           , 0);  // Number, Required - Price excluding discounts and extra charges (Required for FR and FFD 1.0)
	RowParameters.Insert("DiscountedPrice" , 0);  // Number, Required - Price including discounts and extra charges (Required starting from FFD 1.05 and higher)
	RowParameters.Insert("Sum"          , 0);  // Number, Required - The cost of the subject of calculation, taking into account discounts and margins
	RowParameters.Insert("Profit");         // The number, Optional - The amount of discounts and margins, is not included in the FFD.
	RowParameters.Insert("VATRate" , Undefined); // Number,Required - VAT rate (Values: Undefined-without VAT, 0, 5, 7, 10, 20, 22, 18, 105, 107, 110, 118, 120, 122)
	RowParameters.Insert("VATAmount"  , Undefined); // Number, Required - The amount of VAT
	
	// Banking details starting from FFD 1.05
	// Enumeration - Features of the account - (FFD, Tag 1214, Decryption - Table 28)
	RowParameters.Insert("ShowsCalculationMethod", Undefined); // Indication of the calculation method. Required for FFD 1.05 and higher.
	                                         
	// Banking details starting from FFD 1.1
	// Enumeration - Features of the account - (FFD, Tag 1030, Decryption - Table 29)
	RowParameters.Insert("SettlementSubjectFlag", Undefined); // A sign of the subject of calculation. Required for FFD 1.1 and higher.
	
	// Enumeration - Agent features - (FFD, Tag 1222, Decryption - Table 21)
	RowParameters.Insert("AttributeOfAgentForSubjectOfCalculation");  // Optional, The attribute of the agent for the subject of calculation, Tag 1222.
	RowParameters.Insert("AgentData"     , ParametersAgentData());     // Structure - Agent data, Tag 1223. Filling is optional.
	RowParameters.Insert("VendorData" , ParametersSupplierData()); // Structure - Agent data, Tag 1224. Filling is optional.
	
	RowParameters.Insert("UnitOfMeasure");         // Optional, the unit of measurement of the subject of calculation. 
	RowParameters.Insert("ProductProductCodeData", ParametersDataOfProductCode());  // Codes of the commodity nomenclature.
	RowParameters.Insert("ProductClassificationTypeCode"); // String,Optional - The type code of the nomenclature classification.
		
	// Details starting from FFD 1.1 (Introduced by Order of April 9, 2018 N MMV-7-20/207@)
	RowParameters.Insert("CountryCodeOfOrigin"); // String, Optional - The digital code of the country of origin of the goods in accordance with the All-Russian Classifier of the countries of the world.
	RowParameters.Insert("CustomsDeclarationNumber");    // String,Optional - The registration number of the customs declaration.
	RowParameters.Insert("ExciseTaxAmount");                  // Number, Optional - The amount of excise tax included in the cost of the subject of calculation.
	RowParameters.Insert("AdditionalAttribute"); // String,Optional - Additional details of the subject of calculation, Tag 1191.
	
	// Banking details starting from FFD 1.2
	
	// Fractional quantity, recommendations of the CRPT "WITHDRAWAL OF GOODS FROM CIRCULATION WHEN sold TO end consumers (PARTIAL SALE)"
	// for 1.05 and 1.1 - we write in 1191, Formation and transfer of a fiscal document to GIS MT 
	// for 1.2 - we write in 1291
	RowParameters.Insert("FractionalQuantity", ParametersFractionalQuantity());     
	RowParameters.Insert("ControlMark"); // String,Optional - The code of the control mark. Encoded by Base64 encoded text.
	RowParameters.Insert("UnitCode"); // String, Required - The code of the unit of measurement in accordance with the All-Russian classifier of units of measurement.
	RowParameters.Insert("IndustryProps", ParametersIndustryDetails()); // Structure, Optional filling - Tag 1260 - Industry Attributes of the subject of calculation.      
	// Additional attributes for generating the data of the report on the disposal of MT for LM CHZ.
	RowParameters.Insert("NormalizedLabelingCode"); // String,Optional - Normalized marking code.
	
	// Additional details not included in the FFD.
	RowParameters.Insert("SectionNumber_" , 0); // Number, Optional - FR section number (for compatibility), 0-Default value.
	RowParameters.Insert("Barcode");        // String,Optional - Barcode
	RowParameters.Insert("BarcodeBASE64");  // The string, Optionally a Barcode, Is encoded with Base64-encoded text.
	
	// Sale of goods in the provision of catering services (HORECA)
	RowParameters.Insert("PublicCatering", False); // Boolean, Optional - A sign of the product that it is sold in public catering
	
	// Sale of goods in volume and variety accounting.
	RowParameters.Insert("VolumetricAndVarietalAccounting", False); // Boolean,Optional - A sign of the product that it is subject to volume-grade accounting.
	RowParameters.Insert("QuantityOfWeightProduct", Undefined); // The number, Optionally - The quantity of the weight product for volume-grade accounting. 
	// The date of production of the product for the formation of industry tags when selling dairy products with unreadable DataMatrix.
	RowParameters.Insert("ProductionDate"); // Date, Optional - Date of production of the product.
	
	// Sale of veterinary medicinal product
	RowParameters.Insert("VeterinaryDrug", False); // Boolean,Optional - Product attribute, veterinary medicinal product.    
	RowParameters.Insert("VeterinaryRequirement", False); // Boolean,Optional - A sign of the product that the veterinary requirement is used.    
	RowParameters.Insert("RecipeNumber"); // String,Optional - Recipe numberequirements 
	RowParameters.Insert("RecipeDate");  // Date, Optional - Date of the prescriptionequirement.
	
	// Permissive code verification system 
	RowParameters.Insert("CodeVerificationRequest", ParametersCodeVerificationRequest()); // Code verification request data for a permissive system   
	// Complete changes were made to the TSR Labeling Rules, one of which implies the Transfer of information to the GIS MT (subclause O of clause 98):
	// o) information of the industry Attributes of the subject of calculation of the fiscal document on the sale of goods 
	// confirming the purchase of goods using an electronic certificate at the expense of the federal budget and the budget 
	// Pension and Social Insurance Fund of the Russian Federation.
	RowParameters.Insert("SSFCertificateIsUsed", False); // Boolean, Optional - A sign of the implementation of the position using FSS Certificates
	// Outdated. For compatibility.
	RowParameters.Insert("NTIN"); // string,optional - ntin item ids  
	
	Return RowParameters; 
	
EndFunction

// Fills in the structure of text string parameters for fiscal receipt.
//
// Parameters:
//  Text - String - Text string
//
// Returns:
//  Structure
//
Function ReceiptTextStringParameters(Text = Undefined) Export;
	
	RowParameters = New Structure();
	RowParameters.Insert("TextString");       // Line type. Outgoing service parameter. 
	RowParameters.Insert("Text", Text);          // String, Required - Text string
	RowParameters.Insert("LineBreak", False);   // Boolean, Optional - Line break, the default value is set.  
	RowParameters.Insert("Align" , "Left"); // String, Optional - Text Alignment, Values: "Left", "Right", "Center".
	Return RowParameters; 
	
EndFunction

// Fills in the structure of barcode parameters in the line for fiscal receipt.
//
// Parameters:
//  BarcodeTypeVal - String - Barcode type.  
//  BarCodeVal - String - Barcode value.
//  BarcodeBASE64 - String - The barcode value in Base64.
//
// Returns:
//  Structure
//
Function ParametersBarcodeInReceiptLine(BarcodeTypeVal = Undefined, BarCodeVal = Undefined, BarcodeBASE64 = Undefined) Export;
	
	RowParameters = New Structure();
	RowParameters.Insert("BarcodeType", BarcodeTypeVal); // String, Required - Barcode type.  
	RowParameters.Insert("Barcode"    , BarCodeVal);     // String, Required - Barcode value.
	RowParameters.Insert("BarcodeBASE64", BarcodeBASE64);   // String,Required - The value of the barcode in Base64.
	Return RowParameters; 
	
EndFunction

// Fills in the structure of payment line parameters.
//
// Returns:
//  Structure
//
Function PaymentLineParameters(Sum = 0) Export
	
	RowParameters = New Structure();
	RowParameters.Insert("TypeOfPayment", PredefinedValue("Enum.CREPaymentTypes.CashPayment")); 
	RowParameters.Insert("Sum"    , Sum);
	Return RowParameters; 
	
EndFunction

// Fills in the structure of the payment line detail parameters.
//
// Parameters:
//  NameOfPaymentType - String
//  Sum - Number
// 
// Returns:
//  Structure
//
Function PaymentLineDetailParameters(NameOfPaymentType = Undefined, Sum = 0) Export
	
	RowParameters = New Structure();
	RowParameters.Insert("NameOfPaymentType", NameOfPaymentType); // String,Necessarily a Text string
	RowParameters.Insert("Sum", Sum);
	Return RowParameters; 
	
EndFunction

// Fills in the structure of parameters of non-cash payment information.
//
// Parameters:
//  Amount - Number - The amount of non-cash payment     
//  Payment Method Attribute - Number - A non-cash payment method attribute    
//  Identifiers - String - Non-cash payment identifiers  
//  Additional Messages - Line - Additional information about non-cash payment                                                                  
// Returns:
//  Structure
//
Function ParametersInformationAboutNonCashPayment() Export
	
	RowParameters = New Structure();    
	RowParameters.Insert("Sum", 0);  // Number, Required - The amount of non-cash payment   
	RowParameters.Insert("PaymentMethodAttribute", 0);  // Number,Required - Indicates the non-cash payment method  
	RowParameters.Insert("IDs");  // String,Optional - Non-cash payment IDs 
	RowParameters.Insert("AdditionalInfrmation");  // Line,Optional - Additional information about non-cash payment 
	Return RowParameters; 
	
EndFunction

// Fills in the structure of payment line parameters.
//
// Returns:
//  Structure
//
Function ParametersCorrectionData()  Export
	
	CorrectionData = New Structure();
	CorrectionData.Insert("AdjustmentType", 0);   // Number, Required - Type of correction: 0-independently, 1-by prescription.
	CorrectionData.Insert("AdjustmentDescription"); // String, Optional - Description of the correction.
	CorrectionData.Insert("CorrectionDate_");     // Datetime, Required - The date of the corrected calculation.
	CorrectionData.Insert("PrescriptionNumber");  // Line, Required - The number of the tax authority's order.
	Return CorrectionData; 
	
EndFunction

// Fills in the structure of parameters for performing the correction receipt operation.
//
// Returns:
//  Structure
//
Function ParametersOfCorrectionReceiptOperation() Export;
	
	ReceiptParameters = ParametersOfReceiptFiscalizationOperation();
	ReceiptParameters.Insert("DocumentToBeCorrected");
	ReceiptParameters.Insert("CRENonApplication", False); 
	ReceiptParameters.Insert("CorrectionData", ParametersCorrectionData()); 
	
	Return ReceiptParameters; 
	
EndFunction

// Fills in the structure of shift opening and closing parameters.
//
// Returns:
//  Structure
//
Function ParametersForOpeningClosingShift() Export;
	
	OperationParametersList = OperationExecutionParameters();
	
	OperationParametersList.Insert("SettlementAddress"); // String,Optional - Settlement address (Tag 1009).
	OperationParametersList.Insert("PlaceOfSettlement"); // String,Optional - The place of calculations (Tag 1187). 
	OperationParametersList.Insert("CashRegister"); //The type being determined.cash register, optional - Cash register for closing the shift.
	OperationParametersList.Insert("Print", True); // Boolean, Optional - It is necessary to print the required document.
	OperationParametersList.Insert("TimeSynchronization", False); // Boolean, Optional - A sign of the necessary synchronization of the CCT time with the PC.
	OperationParametersList.Insert("AutonomousCCT", False); // Boolean,Optional - A Sign of an autonomous CCT.
	OperationParametersList.Insert("CloudCashRegister", False); // Boolean,Optional - A Sign of a cloud CCT.
	
	Return OperationParametersList; 
	
EndFunction

// Fills in the structure of the collection parameters on the fiscal device.
//
// Returns:
//  Structure
//
Function CollectionParameters() Export;
	
	OperationParametersList = OperationExecutionParameters();
	OperationParametersList.Insert("DocumentBasis" , Undefined); // Link, Optional. The document on which the operation is formed.
	OperationParametersList.Insert("Organization"       , Undefined); // Link, Optional. The organization for which the operation is formed.
	OperationParametersList.Insert("RetailFacility"    , Undefined); // Link, Optional. The object on which the operation is formed. 
	OperationParametersList.Insert("CashRegister"          , Undefined); // Link, Optional. The object on which the operation is formed.
	
	OperationParametersList.Insert("TypeOfCollection"); // Number, Required - Type of collection (1-deposit, 0-withdrawal)
	OperationParametersList.Insert("Sum", 0);      // The number, Necessarily - The Amount of collection.
	
	Return OperationParametersList; 
	
EndFunction

// Fills in the structure of the parameters for printing a copy of the receipt.
//
// Returns:
//  Structure
//
Function ParametersPrintCopyOfReceipt() Export;
	
	OperationParametersList = OperationExecutionParameters();        
	OperationParametersList.Insert("DocumentRef" , Undefined); // The link is the document on which the receipt is made.
	OperationParametersList.Insert("KKTReceiptNumber" , Undefined); // String - Fiscal receipt number.
	OperationParametersList.Insert("Hardware" , True);  // Boolean - A copy of the receipt is printed using hardware according to the CCT data, otherwise according to the register of fiscal transactions.
	OperationParametersList.Insert("ReceiptNumber" , Undefined); // String - The receipt number for hardware printing of the receipt on the KKT.
	OperationParametersList.Insert("FiscalFlag"); // String - Fiscal attribute of the document.
	Return OperationParametersList; 
	
EndFunction

// Fills in the structure of the check cancellation parameters.
//
// Returns:
//  Structure
//
Function ParametersOfReceiptCancellationOperation() Export;
	
	OperationParametersList = OperationExecutionParameters();
	OperationParametersList.Insert("CalculationType" , PredefinedValue("Enum.CashSettlementTypes.CashReceipt"));
	OperationParametersList.Insert("Fiscal_" , True); 
	Return OperationParametersList; 
	
EndFunction

// Fills in the structure of the QR code printing on the fiscal device.
//
// Returns:
//  Structure
//
Function OptionsForPrintingQRCodeOnFiscalDevice() Export;
	
	OperationParametersList = New Structure();
	
	OperationParametersList.Insert("PaymentSystemType"); // Enum link.Type of payment system, Optional - Type of payment system.
	OperationParametersList.Insert("PaymentSystemPaymentID"); // String,Optional - Payment ID of the payment system.
	OperationParametersList.Insert("QRCode", QRCodeParameters()); // Structure, Filling optional - QR code parameters in the body of the receipt.
	OperationParametersList.QRCode.UserText = NStr("vi = 'Để thanh toán, hãy quét mã QR';
													|ru = 'Для совершения платежа отсканируйте QR-код';
													|en = 'Scan the QR code to pay'; fa = 'Scan the QR code to pay';
													|it = 'Per completare il pagamento, scansionare il codice QR';
													|pl = 'Aby dokonać płatności zeskanuj kod QR';
													|tr = 'Ödeme yapmak için QR kodu taratın'");
	OperationParametersList.Insert("TransactionAmount", Undefined); // Number, Optional - The amount of the operation.
	
	Return OperationParametersList; 
	
EndFunction

// Parameters of operation counters.
//
// Returns:
//  Structure - Parameters Of Normalized Fiscal Data:
//   * NumberOfSalesSlipsAccountableFormsPerShift - Number - 
//   * AmountOfChecks - Number -
//   * NumberOfCorrectionChecks - Number -
//   * AmountOfCorrectionChecks - Number -
//
Function ParametersOfOperationCounters() Export 
	
	ResultingStructure = New Structure();
	
	ResultingStructure.Insert("NumberOfSalesSlipsAccountableFormsPerShift");
	ResultingStructure.Insert("AmountOfChecks");
	ResultingStructure.Insert("NumberOfCorrectionChecks");
	ResultingStructure.Insert("AmountOfCorrectionChecks");
	
	Return ResultingStructure;
	
EndFunction

// Fills in the structure of parameters for normalized fiscal data.
// 
// Returns:
//  Structure - Parameters Of Normalized Fiscal Data:
//   * CREShiftDate - Number -
//   * CREShiftNumber - Number -
//   * KKTReceiptNumber - Number -
//   * ShiftReceiptNumber - Number -
//   * ShiftStatus - Undefined -
//   * CountersForArrivalOperations - Structure -:
//      ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//      ** AmountOfChecks - Number
//      ** NumberOfCorrectionChecks - Number
//      ** AmountOfCorrectionChecks - Number
//   * CountersForRefundOperations - Structure -:
//      ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//      ** AmountOfChecks - Number
//      ** NumberOfCorrectionChecks - Number
//      ** AmountOfCorrectionChecks - Number
//   * OperationCountersExpense - Structure -:
//      ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//      ** AmountOfChecks - Number
//      ** NumberOfCorrectionChecks - Number
//      ** AmountOfCorrectionChecks - Number
//   * OperationCountersRefundOfExpenses - Structure -:
//      ** NumberOfSalesSlipsAccountableFormsPerShift - Number
//      ** AmountOfChecks - Number
//      ** NumberOfCorrectionChecks - Number
//      ** AmountOfCorrectionChecks - Number
//   * NumberOfSalesSlipsAccountableFormsPerShift - Number
//   * CashBalance - Number
//   * FDOResponseTimeoutExceeded - Boolean -
//   * UnpostedFDCount - Undefined -
//   * NumberOfFirstUntransmittedFD - Undefined -
//   * DateAndTimeOfFirstOfUnsentFD - Undefined -
//   * UrgentReplacementOfFNIsNeeded - Boolean -
//   * ShowsThatFiscalStorageMemoryIsFull - Boolean -
//   * FiscalStorageResourceExceeded - Boolean -
//
Function ParametersOfNormalizedFiscalData() Export
	
	ResultingStructure = New Structure();
	
	ResultingStructure.Insert("CREShiftDate"     , Undefined); // Open date/closed shift.
	ResultingStructure.Insert("CREShiftNumber"    , 0); // The number of the open/closed shift.
	ResultingStructure.Insert("KKTReceiptNumber"     , 0); // The number of the last fiscal receipt.
	ResultingStructure.Insert("ShiftReceiptNumber" , 0); // The number of the last check for the shift.
	ResultingStructure.Insert("ShiftStatus"      , Undefined); // Shift status: 1-Closed, 2-Open, 3-Expired.        
	ResultingStructure.Insert("NumberOfSalesSlipsAccountableFormsPerShift"  , 0); // The number of checks and correction checks with all signs of calculations
	ResultingStructure.Insert("CountersForArrivalOperations"        , ParametersOfOperationCounters()); // Counters of operations of the "arrival" type.
	ResultingStructure.Insert("CountersForRefundOperations", ParametersOfOperationCounters()); // Counters of operations of the "return of receipt" type.
	ResultingStructure.Insert("OperationCountersExpense"        , ParametersOfOperationCounters()); // Counters of operations of the "expense" type.
	ResultingStructure.Insert("OperationCountersRefundOfExpenses", ParametersOfOperationCounters()); // Counters of operations of the "return of expense" type.
	ResultingStructure.Insert("CashBalance"); // Cash balance at the cash desk
	ResultingStructure.Insert("FDOResponseTimeoutExceeded", False);
	ResultingStructure.Insert("UnpostedFDCount"   , Undefined); // The number of documents not transferred.
	ResultingStructure.Insert("NumberOfFirstUntransmittedFD", Undefined); // The number of the first untransmitted document. 
	ResultingStructure.Insert("DateAndTimeOfFirstOfUnsentFD" , Undefined); // Date and time of the first of the untransmitted documents.
	
	ResultingStructure.Insert("UrgentReplacementOfFNIsNeeded"  , False); // A sign of the need for urgent replacement of the FN.
	ResultingStructure.Insert("ShowsThatFiscalStorageMemoryIsFull"        , False); // A sign of an overflow of the FN memory.
	ResultingStructure.Insert("FiscalStorageResourceExceeded"           , False); // A sign of exhaustion of the resource of the FN.
	ResultingStructure.Insert("FNValidityPeriod"             , Undefined); // FN Validity Period

	Return ResultingStructure;
	
EndFunction

// Fills in the structure of text printing parameters.
//
// Parameters:
//  LinesOfText - String
//
// Returns:
//  Structure
//
Function TextPrintingOptions(LinesOfText = Undefined) Export
	
	Parameters = New Structure();
	Parameters.Insert("LinesOfText", LinesOfText); 
	Return Parameters; 
	
EndFunction

// Fills in the structure of the KM request parameters.
// 
// Returns:
//  Structure - Km request parameters:
//   * QueryID - String - Unique Request ID
//   * PerformValidation - Boolean - perform verification of the marking code by means of BPO
//   * IgnoreKMCheckResult - Boolean - ignore the result of the KM check and automatically confirm the sale of the product.
//   * RequestForVerificationOfKMByMeansOfKKT - Boolean - execute a KM verification request on a remote ICM server (ISMP).
//                                     Usually this flag is reset to False when using volume-grade accounting.
//   * ExpectOISMResponse - Boolean - Will it be expected to receive a response from the OI SEE (ISMP)
//   * SendToOISMServer - Boolean - (outdated) The CM request is generated locally or sent to the CM server.
//   * Count - Number - Count
//   * FractionalQuantity - See PeripheralsReceiptPrintersClientServer.ParametersFractionalQuantity.
//   * ControlMark - String - The code of the control mark. Encoded by Base64 encoded text.
//   * UnitCode - String -  The unit code is in accordance with the all-Russian classifier of units 
//                                     of measurement. If the Attribute value is filled in, it is used, otherwise the amount of the account parameter.
//   * MeasureOfQuantityOfSubjectOfCalculation - EnumRef.QuantityMeasureOfCRCalculationSubject - A measure of the quantity of the object of calculation. 
//                                     Tag 2108. The value from table 114 (FFD).
//   * PlannedProductStatus - EnumRef
//   * Description - String - string name of the calculation item, for display of operations in the check log of the marking code
//   * AdditionalParameters - Undefined, Structure - additional parameters that can be passed to of operation,
//                               this value will be returned in the notification when performing of operation.
//   * KMSalesPermitRequest - Boolean - a sales permit request was executed
//   * ServerAddressOfPermissionRequest - String - the address of the server where the permission request was executed
//   * QueryTextPermissions - String - Query Text for permission
//   * PermissionResponseCode - Undefined, String - the response code that was received from the remote server, if the code is not set, and the value of the flag 
//                           The salesresolution requestm is set to True, then the code will contain the text Timeout.
//   * ResultOfPermissionRequest - String - JSON string, response from a remote GIS MT server
//   * IdOfPermissionRequest - String - ID of the permission request received
//   * TimeOfPermissionRequest - Undefined, String, Date - timestamp received from a remote server
//   * SaleIsAllowed - Boolean - The sale is allowed, the record form will display that the sale is allowed.
//   * ProhibitionReason - String - The reason for the sale ban, for display on the record form
//   * AdditionalInfo - Array of See AdditionalInformationAboutKMRequest
//
Function KmRequestParameters() Export
		
	Parameters = New Structure();
	Parameters.Insert("Result", True);
	Parameters.Insert("ErrorText");    
	
	Parameters.Insert("QueryID", "");
	Parameters.Insert("PerformValidation", False);
	Parameters.Insert("IgnoreKMCheckResult", False);
	Parameters.Insert("RequestForVerificationOfKMByMeansOfKKT", True);
	Parameters.Insert("ExpectOISMResponse", True);
	Parameters.Insert("SendToOISMServer", True);
	Parameters.Insert("Count", 0);
	Parameters.Insert("FractionalQuantity", ParametersFractionalQuantity());
	Parameters.Insert("ControlMark", "");
	Parameters.Insert("UnitCode", "");
	Parameters.Insert("MeasureOfQuantityOfSubjectOfCalculation");
	Parameters.Insert("PlannedProductStatus");
	Parameters.Insert("Description");  
	Parameters.Insert("AdditionalParameters", Undefined);  
	
	// request to the GIS MT server
	Parameters.Insert("KMSalesPermitRequest", False);
	Parameters.Insert("ServerAddressOfPermissionRequest", "");
	Parameters.Insert("QueryTextPermissions", "");
	Parameters.Insert("PermissionResponseCode", Undefined);
	Parameters.Insert("ResultOfPermissionRequest", "");
	Parameters.Insert("IdOfPermissionRequest", "");
	Parameters.Insert("TimeOfPermissionRequest", Undefined);
	Parameters.Insert("SaleIsAllowed", False);
	Parameters.Insert("ProhibitionReason", "");
	Parameters.Insert("AdditionalInfo", New Array);
	
	// Service fields
	Parameters.Insert("XMLParameters", "");
	
	Return Parameters; 
	
EndFunction

// Additional information about the KM request to display on the form of the record of operation
// 
// Returns:
//  Structure:
//   * Title - String - element title
//   * Value - Arbitrary
Function AdditionalInformationAboutKMRequest() Export

	Result = New Structure;
	Result.Insert("Title", "");
	Result.Insert("Value");
	Return Result;

EndFunction

// Fills in the structure of the KM request parameters.
// 
// Returns:
//  Structure -KM Verification Parameters:
//   * DisplayAForm - Boolean - display a form with the progress of execution using the library
//   * NotifyAboutCompletion - Boolean - notify forms ON changes in the KM verification State
//   * WaitingForResponseFromKMVerification - Boolean - (not used) wait for the End of the request from the remote ICM server (ISMP).
//   * KMRequests - Array of See KmRequestParameters - array of KM requests
//
Function KMVerificationParameters() Export

	Parameters = New Structure();
	Parameters.Insert("DisplayAForm", False);
	Parameters.Insert("NotifyAboutCompletion", True);
	Parameters.Insert("WaitingForResponseFromKMVerification", False); // It was expected to receive a response from the ICM
	Parameters.Insert("KMRequests", New Array());

	Return Parameters; 
	
EndFunction

// Fills in the structure of the KM request parameters.
//
// Returns:
//   Structure:
//   * QueryID - String - Unique Request ID 
//
Function KmConfirmationParameters() Export
	
	Parameters = New Structure();
	Parameters.Insert("QueryID"); // String,Required - The unique identifier of the request
	Parameters.Insert("Disposal", True); // Boolean, Mandatory - KM will be implemented as part of the document on the sale of the marked goods.
	Return Parameters; 
	
EndFunction

// Fills in the structure of a batch operation to add it to the receipt queue
//
// Returns:
//   Structure:
//   * OperationType - EnumRef.BatchOperationTypesInReceiptQueue
//   * IDOfItem - CatalogRef.Peripherals - Acquiring terminal for transaction processing
//   * SlipReceiptInBodyOfFiscal - Boolean, Undefined - Output a slip check in the fiscal body, a true slip check will be output
//                          in the fiscal body, a false short slip check will not be output, An indefinite short slip check 
//                          will be output if the hardware driver supports it.
//   * AcquiringTransactionParameters - Structure:
//      ** PaymentKind_ - String -
//      ** CommissionPercentage - Number - 
//      ** QrCardAttributes - String -
//   * ParametersSaleWithCashWithdrawal - Structure:
//      ** IssueAmount - Number - the amount of cash disbursement, in the case of a sale with cash disbursement operation
//      ** AgentData - See PeripheralsReceiptPrintersClientServer.ParametersAgentData
//      ** VendorData - See PeripheralsReceiptPrintersClientServer.ParametersSupplierData
//      ** DocumentBasisOfIssue - DefinedType.BaseDocumentForFiscalPLTransaction, Undefined - 
//      ** DocumentBasisOfRefund - DefinedType.BaseDocumentForFiscalPLTransaction, Undefined - 
//
Function BatchOperationParametersInReceiptQueue() Export
	
	Parameters = New Structure();
	Parameters.Insert("OperationType", PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.NotBatchOperation"));
	Parameters.Insert("IDOfItem");
	Parameters.Insert("SlipReceiptInBodyOfFiscal");
	
	AcquiringTransactionParameters =  New Structure();
	AcquiringTransactionParameters.Insert("PaymentKind_");
	AcquiringTransactionParameters.Insert("CommissionPercentage");
	AcquiringTransactionParameters.Insert("QrCardAttributes", "");
	
	Parameters.Insert("AcquiringTransactionParameters", AcquiringTransactionParameters);
	
	ParametersSaleWithCashWithdrawal =  New Structure();
	ParametersSaleWithCashWithdrawal.Insert("IssueAmount");
	ParametersSaleWithCashWithdrawal.Insert("AgentData",              ParametersAgentData());
	ParametersSaleWithCashWithdrawal.Insert("VendorData",          ParametersSupplierData());
	ParametersSaleWithCashWithdrawal.Insert("DocumentBasisOfIssue",   Undefined);
	ParametersSaleWithCashWithdrawal.Insert("DocumentBasisOfRefund", Undefined);

	Parameters.Insert("ParametersSaleWithCashWithdrawal", ParametersSaleWithCashWithdrawal);
	Return Parameters; 
	
EndFunction

// Parameters of the fiscal operation.
// 
// Returns:
//  Structure - Parameters Of the Fiscal Operation:
//  * Cashier - DefinedType.PersonalDataSubjectCEL
//  * DocumentBasis - DefinedType.BaseDocumentForFiscalPLTransaction
//  * Organization - DefinedType.CompanyCEL
//  * RetailFacility - DefinedType.RetailFacilityCEL
//  * CREShiftNumber - Number -
//  * KKTReceiptNumber - Number -
//  * ShiftStatus - Number -
//  * DateTime - Date
//  * XMLParameters - String -
//  * XMLResult - String -
//  * CashRegisterShift - DocumentRef.CashRegisterShift
//  * TestReceipts - Boolean
//  * ReceiptText - String
//  * AdditionalParameters - Arbitrary 
//  * Result - Boolean -
//  * ErrorText - String     
//
Function ParametersOfFiscalOperation() Export
	
	OperationData = New Structure();
	OperationData.Insert("Cashier");
	OperationData.Insert("DocumentBasis");
	OperationData.Insert("Organization");
	OperationData.Insert("RetailFacility");
	
	OperationData.Insert("CREShiftNumber" , 0);
	OperationData.Insert("KKTReceiptNumber"  , 0);
	OperationData.Insert("ShiftStatus", 0);
	OperationData.Insert("DateTime");
	OperationData.Insert("XMLParameters", "");
	OperationData.Insert("XMLResult", "");
	OperationData.Insert("CashRegisterShift");
	OperationData.Insert("TestReceipts");
	OperationData.Insert("ReceiptText");
	OperationData.Insert("AdditionalParameters");
	OperationData.Insert("Result", True);
	OperationData.Insert("ErrorText");
	OperationData.Insert("DescriptionOfLastCashShift");
	
	Return OperationData;
	
EndFunction 

// Fills in the data structure of the code verification request for the authorization system.
// Returns:
//  Structure
//
Function ParametersCodeVerificationRequest() Export  
	
	Parameters = New Structure();   
	Parameters.Insert("QueryID"); // String,Required - Unique request ID.
	Parameters.Insert("StampOfTime");  // String, Required - Date and time accurate to milliseconds of the request formation in text form.  
	// Implementation from September 1, 2025
	Parameters.Insert("InstanceId"); // String,Required - ID of the instance of LM CHZ inst
	Parameters.Insert("DatabaseVersion"); // String,Necessarily - The version of the database on which the ver check was performed
	Return Parameters; 
	
EndFunction  


#EndRegion


#Region OFDCodes

///////////////////////////////////////////////////////////////////////////////
// Taxation system

// Get the code of the KKT tax system.
// 
// Parameters:
//  KktTaxationSystem - EnumRef.CRETaxationSystemTypes - The KKT taxation system.
// 
// Returns:
//  Arbitrary, Number - Code of the KKT tax system
Function CktTaxSystemCode(KktTaxationSystem) Export
	
	Code = 0;
	PeripheralsReceiptPrintersClientServerLocalization.CktTaxSystemCode(Code, KktTaxationSystem);
	Return Code;
	
EndFunction

// Get the KKT tax system by code
// 
// Parameters:
//  CktTaxSystemCode - Number - The code of the KKT taxation system.
// 
// Returns:
//  Arbitrary, EnumRef.CRETaxationSystemTypes - Tax system Ktpo code
Function KktTaxSystemByCode(CktTaxSystemCode) Export
	
	Value = 0;
	PeripheralsReceiptPrintersClientServerLocalization.KktTaxSystemByCode(Value, CktTaxSystemCode);
	Return Value;
	
EndFunction

// Get the name of the tax system by code.
// 
// Parameters:
//  TaxationSystem - Number, Arbitrary - Taxation system
//  Brief1 - Boolean - Brief1
// 
// Returns:
//  String, Arbitrary - Name of the tax system
Function NameOfTaxSystem(TaxationSystem, Brief1 = False) Export;
	
	Description = 0;
	PeripheralsReceiptPrintersClientServerLocalization.NameOfTaxSystem(Description, TaxationSystem, Brief1);
	Return Description;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Codes of types of documents

// Returns the code of the type of identity document CCT.
// 
// Parameters:
//  TypeOfIdentityDocument - EnumRef - Type of identity document
// 
// Returns:
//  Arbitrary, Number - Code type of identity document
Function CodeTypeOfIdentityDocument(TypeOfIdentityDocument) Export
	
	Code = 0;
	PeripheralsReceiptPrintersClientServerLocalization.CodeTypeOfIdentityDocument(Code, TypeOfIdentityDocument);
	Return Code;
	
EndFunction

// Returns the type of identity document CCT by code.
// 
// Parameters:
//  CodeOfTypeOfIdentityDocument - Number - The code of the type of identity document.
// 
// Returns:
//  EnumRef, Arbitrary - Type of identity document by code
Function TypeOfIdentityDocumentByCode(CodeOfTypeOfIdentityDocument) Export
	
	Value = "";
	PeripheralsReceiptPrintersClientServerLocalization.TypeOfIdentityDocumentByCode(Value, CodeOfTypeOfIdentityDocument);
	Return Value;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Codes of calculations, signs of calculations and objects of calculations

// Get the cash settlement code.
// 
// Parameters:
//  CalculationType - EnumRef.CashSettlementTypes - Type of calculation.
// 
// Returns:
//  Arbitrary, Number - Cash settlement code
Function CashSettlementCode(CalculationType) Export
	
	TypesOfCalculation = New Map();
	TypesOfCalculation.Insert(PredefinedValue("Enum.CashSettlementTypes.CashReceipt")        , 1);
	TypesOfCalculation.Insert(PredefinedValue("Enum.CashSettlementTypes.Refund")       , 2);
	TypesOfCalculation.Insert(PredefinedValue("Enum.CashSettlementTypes.CashOutflow")        , 3);
	TypesOfCalculation.Insert(PredefinedValue("Enum.CashSettlementTypes.CashOutflowRefund"), 4);
	
	Return TypesOfCalculation.Get(CalculationType);
	
EndFunction

// Get the name of the cash settlement code by code.
// 
// Parameters:
//  CalculationCode - EnumRef.CashSettlementTypes - Type of calculation.
// 
// Returns:
//  String - Name Of The Cash Settlement Code
Function NameOfCashSettlementCode(CalculationCode) Export
	
	TypesOfCalculation = New Map();
	TypesOfCalculation.Insert(1, NStr("vi = 'NHẬP';
										|ru = 'ПРИХОД';
										|en = 'INCOME'; fa = 'INCOME';
										|it = 'ПРИХОД';
										|pl = 'INCOME';
										|tr = 'GİRİŞ'"));          // The sales receipt     
	TypesOfCalculation.Insert(2, NStr("vi = 'TRẢ LẠI NHẬP';
										|ru = 'ВОЗВРАТ ПРИХОДА';
										|en = 'RECEIPT RETURN'; fa = 'RECEIPT RETURN';
										|it = 'RESTITUZIONE ENTRATA';
										|pl = 'ZWROT PRZYCHODU';
										|tr = 'GİRİŞ İADESİ'")); // Sales refund receipt 
	TypesOfCalculation.Insert(3, NStr("vi = 'XUẤT';
										|ru = 'РАСХОД';
										|en = 'EXPENSE'; fa = 'EXPENSE';
										|it = 'РАСХОД';
										|pl = 'EXPENSE';
										|tr = 'ÇIKIŞ'"));          // Purchase receipt 
	TypesOfCalculation.Insert(4, NStr("vi = 'TRẢ LẠI XUẤT';
										|ru = 'ВОЗВРАТ РАСХОДА';
										|en = 'EXPENSE RETURN'; fa = 'EXPENSE RETURN';
										|it = 'RESTITUZIONE USCITA';
										|pl = 'ZWROT ROZCHODU';
										|tr = 'GİDER İADESİ'")); // Purchase refund receipt 
	
	Return TypesOfCalculation.Get(CalculationCode);
	
EndFunction

// Get the type of cash settlement by code.
// 
// Parameters:
//  CodeForCalculationAttribute - Number - Code of the calculation attribute.
// 
// Returns:
//  EnumRef.CashSettlementTypes, Arbitrary - The calculation of the cash code
Function CashPaymentByCode(CodeForCalculationAttribute) Export
	
	TypesOfCalculation = New Map();
	TypesOfCalculation.Insert(1, PredefinedValue("Enum.CashSettlementTypes.CashReceipt"));
	TypesOfCalculation.Insert(2, PredefinedValue("Enum.CashSettlementTypes.Refund"));
	TypesOfCalculation.Insert(3, PredefinedValue("Enum.CashSettlementTypes.CashOutflow"));
	TypesOfCalculation.Insert(4, PredefinedValue("Enum.CashSettlementTypes.CashOutflowRefund"));
	
	Return TypesOfCalculation.Get(CodeForCalculationAttribute);
	
EndFunction

// Get the code for the calculation method attribute.
// 
// Parameters:
//  ShowsCalculationMethod - EnumRef.CalculationMethodFlags - Indication of the calculation method.
// 
// Returns:
//  Arbitrary, Number - Code of the calculation method attribute
Function CodeForCalculationMethodAttribute(ShowsCalculationMethod) Export
	
	CalculationMethodFlags = New Map();
	CalculationMethodFlags.Insert(PredefinedValue("Enum.CalculationMethodFlags.FullPrepayment")         , 1); 
	CalculationMethodFlags.Insert(PredefinedValue("Enum.CalculationMethodFlags.PartialPrepayment")      , 2);
	CalculationMethodFlags.Insert(PredefinedValue("Enum.CalculationMethodFlags.Prepayment_")                    , 3); 
	CalculationMethodFlags.Insert(PredefinedValue("Enum.CalculationMethodFlags.TransferWithFullPayment")   , 4); 
	CalculationMethodFlags.Insert(PredefinedValue("Enum.CalculationMethodFlags.TransferWithPartialPayment"), 5);  
	CalculationMethodFlags.Insert(PredefinedValue("Enum.CalculationMethodFlags.TransferWithoutPayment")        , 6);  
	CalculationMethodFlags.Insert(PredefinedValue("Enum.CalculationMethodFlags.PaymentForLoan")            , 7);  
	
	Return CalculationMethodFlags.Get(ShowsCalculationMethod);
	
EndFunction

// Get the attribute of the calculation method by code.
// 
// Parameters:
//  CodeForCalculationMethodAttribute - Number - The code of the calculation method attribute.
// 
// Returns:
//  Arbitrary, EnumRef.CalculationMethodFlags - Indicates the method of calculation by code
Function FlagForCodeCalculationMethod(CodeForCalculationMethodAttribute) Export
	
	CalculationMethodFlags = New Map();
	CalculationMethodFlags.Insert(1, PredefinedValue("Enum.CalculationMethodFlags.FullPrepayment")); 
	CalculationMethodFlags.Insert(2, PredefinedValue("Enum.CalculationMethodFlags.PartialPrepayment"));
	CalculationMethodFlags.Insert(3, PredefinedValue("Enum.CalculationMethodFlags.Prepayment_")); 
	CalculationMethodFlags.Insert(4, PredefinedValue("Enum.CalculationMethodFlags.TransferWithFullPayment")); 
	CalculationMethodFlags.Insert(5, PredefinedValue("Enum.CalculationMethodFlags.TransferWithPartialPayment"));  
	CalculationMethodFlags.Insert(6, PredefinedValue("Enum.CalculationMethodFlags.TransferWithoutPayment"));  
	CalculationMethodFlags.Insert(7, PredefinedValue("Enum.CalculationMethodFlags.PaymentForLoan"));  
	
	Return CalculationMethodFlags.Get(CodeForCalculationMethodAttribute);
	
EndFunction

// Get the name of the attribute of the calculation method by code.
// 
// Parameters:
//  CodeForCalculationMethodAttribute - Number, Arbitrary - Code of the calculation method attribute
// 
// Returns:
//  String, Arbitrary - Name of the calculation method attribute
Function NameOfCalculationMethodAttribute(CodeForCalculationMethodAttribute) Export;
	
	CalculationMethodFlags = New Map();
	
	CalculationMethodFlags.Insert(1, NStr("vi = 'TRẢ TRƯỚC 100%';
											|ru = 'ПРЕДОПЛАТА 100%';
											|en = 'PREPAYMENT 100%'; fa = 'PREPAYMENT 100%';
											|it = 'Prepagamento 100%';
											|pl = 'PRZEDPŁATA 100%';
											|tr = '% 100 ÖN ÖDEME'"));
	CalculationMethodFlags.Insert(2, NStr("vi = 'TRẢ TRƯỚC';
											|ru = 'ПРЕДОПЛАТА';
											|en = 'PREPAYMENT'; fa = 'PREPAYMENT';
											|it = 'PREPAGAMENTO';
											|pl = 'PREPAYMENT';
											|tr = 'ÖN ÖDEME'"));
	CalculationMethodFlags.Insert(3, NStr("vi = 'ỨNG TRƯỚC';
											|ru = 'АВАНС';
											|en = 'ADVANCE'; fa = 'ADVANCE';
											|it = 'PAGAMENTO ANTICIPATO';
											|pl = 'ADVANCE';
											|tr = 'AVANS'"));
	CalculationMethodFlags.Insert(4, NStr("vi = 'TÍNH ĐẦY ĐỦ';
											|ru = 'ПОЛНЫЙ РАСЧЕТ';
											|en = 'FULL CALCULATION'; fa = 'FULL CALCULATION';
											|it = 'CALCOLO TOTALE';
											|pl = 'PEŁNE ROZLICZENIE';
											|tr = 'TAM HESAPLAMA'"));
	CalculationMethodFlags.Insert(5, NStr("vi = 'HẠCH TOÁN TỪNG PHẦN VÀ TRẢ SAU';
											|ru = 'ЧАСТИЧНЫЙ РАСЧЕТ И КРЕДИТ';
											|en = 'PARTIAL SETTLEMENT AND CREDIT'; fa = 'PARTIAL SETTLEMENT AND CREDIT';
											|it = 'CALCOLO PARZIALE E CREDITO';
											|pl = 'CZĘŚCIOWE ROZLICZENIE I KREDYT';
											|tr = 'KISMİ UZLAŞMA VE ALACAK'"));
	CalculationMethodFlags.Insert(6, NStr("vi = 'CHUYỂN SANG TRẢ SAU';
											|ru = 'ПЕРЕДАЧА В КРЕДИТ';
											|en = 'TRANSFER TO CREDIT'; fa = 'TRANSFER TO CREDIT';
											|it = 'TRASFERIMENTO A CREDITO';
											|pl = 'PRZEKAZANIE NA KREDYT';
											|tr = 'ALACAK TRANSFERİ'"));
	CalculationMethodFlags.Insert(7, NStr("vi = 'THANH TOÁN TRẢ SAU';
											|ru = 'ОПЛАТА КРЕДИТА';
											|en = 'CREDIT PAYMENT'; fa = 'CREDIT PAYMENT';
											|it = 'PAGA CREDITO';
											|pl = 'PŁATNOŚĆ KREDYTU';
											|tr = 'ALACAK ÖDEMESİ'"));
	
	Return CalculationMethodFlags.Get(CodeForCalculationMethodAttribute);
	
EndFunction

// Get the code for the calculation method attribute.
// 
// Parameters:
//  SettlementSubjectFlag - EnumRef.SettlementSubjectFlags - A sign of the subject of calculation.
// 
// Returns:
//  Arbitrary, Number - Code of the subject of calculation attribute
Function CodeForCalculationItemAttribute(SettlementSubjectFlag) Export
	
	Code = 0;
	PeripheralsReceiptPrintersClientServerLocalization.CodeForCalculationItemAttribute(Code, SettlementSubjectFlag);
	Return Code;
	
EndFunction

// Get the attribute of the calculation method by code.
// 
// Parameters:
//  CodeForCalculationItemAttribute - Number - The code of the attribute of the subject of calculation.
// 
// Returns:
//  EnumRef.SettlementSubjectFlags, Arbitrary - Attribute of the subject of calculation by code
Function AttributeOfSubjectOfCalculationByCode(CodeForCalculationItemAttribute) Export
	
	Value = 0;
	PeripheralsReceiptPrintersClientServerLocalization.AttributeOfSubjectOfCalculationByCode(Value, CodeForCalculationItemAttribute);
	Return Value;
	
EndFunction

// Get the name of the attribute of the subject of calculation by the code.
// 
// Parameters:
//  CodeForCalculationItemAttribute -Number - The code of the attribute of the subject of calculation.
// 
// Returns:
//  String, Arbitrary - Name of the attribute of the subject of calculation
Function NameOfAttributeOfSubjectOfCalculation(CodeForCalculationItemAttribute) Export

	Description = "";
	PeripheralsReceiptPrintersClientServerLocalization.NameOfAttributeOfSubjectOfCalculation(Description, CodeForCalculationItemAttribute);
	Return Description;
	
EndFunction

// Returns a text Presentation of the payment type on the KKT according to the FFD version
// 
// Parameters:
//  PaymentTypeCCT - EnumRef.CREPaymentTypes
//  FDFVersion - String - "1.0", "1.1", "1.2"
// 
// Returns:
//  String
Function NameOfPaymentTypeCCT(PaymentTypeCCT, FDFVersion) Export
	
	Description = "";
	PeripheralsReceiptPrintersClientServerLocalization.NameOfPaymentTypeCCT(Description, PaymentTypeCCT, FDFVersion);
	Return Description;
	
EndFunction

// Establishes a sign that the taxation system is based on
// 
// Parameters:
//  ThisIsOSN - Boolean
//  TaxationSystem - EnumRef.CRETaxationSystemTypes
//
Procedure IsMTS(ThisIsOSN, TaxationSystem) Export
	
	If TaxationSystem = PredefinedValue("Enum.CRETaxationSystemTypes.GTS") Then
		ThisIsOSN = True;
	Else
		ThisIsOSN = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions


#EndRegion

#EndRegion

#Region Internal

// Returns True if the CCT is used without hardware connection
//
// Parameters:
//  OperationParametersList - Structure - parameters for performing the operation.
//
// Returns:
//  Boolean
Function ThisIsKKTWithoutConnection(OperationParametersList) Export
	
	Return ValueIsFilled(OperationParametersList) 
		And OperationParametersList.Property("CashRegister") 
		And ValueIsFilled(OperationParametersList.CashRegister);
	
EndFunction

#Region GeneratingCCTData

#If Not WebClient Then

// Get the xmlpackage for the operation.
// 
// Parameters:
//  CommonParameters - Structure, Boolean - General settings
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  String - Get the Xmlpackage for the operation
Function GetXMLPacketForOperation(CommonParameters, InterfaceRevision = 0) Export
	
	XMLWriter = New XMLWriter();
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("InputParameters");
	XMLWriter.WriteStartElement("Parameters");
	
	If InterfaceRevision >= 3000 Then  // Standard version 3.0 (OFD 1.1)
		XMLWriter.WriteAttribute("CashierName", ?(CommonParameters.Property("Cashier"), XMLString(CommonParameters.Cashier), NStr("vi = 'Người quản trị';
																																	|ru = 'Администратор';
																																	|en = 'Administrator'; fa = 'مدیر سیستم';
																																	|it = 'Administrator';
																																	|pl = 'Administrator';
																																	|tr = 'Yönetici'")));
		XMLWriter.WriteAttribute("CashierINN" , ?(CommonParameters.Property("CashierTIN"), XMLString(CommonParameters.CashierTIN), ""));
		If CommonParameters.Property("SettlementAddress") And Not IsBlankString(CommonParameters.SettlementAddress) Then   
			XMLWriter.WriteAttribute("SaleAddress", XMLString(CommonParameters.SettlementAddress));
		EndIf;
		If CommonParameters.Property("PlaceOfSettlement") And Not IsBlankString(CommonParameters.PlaceOfSettlement) Then  
			XMLWriter.WriteAttribute("SaleLocation", XMLString(CommonParameters.PlaceOfSettlement));
		EndIf;
		If InterfaceRevision >= 4000 Then // Standard version 4.0 (OFD 1.2)
			If CommonParameters.Property("Print") And Not IsBlankString(CommonParameters.Print) Then  
				XMLWriter.WriteAttribute("PrintRequired", XMLString(CommonParameters.Print));
			EndIf; 
		EndIf; 
		If InterfaceRevision >= 4007 Then // Standard version 4.7
			If CommonParameters.Property("TimeSynchronization") Then  
				XMLWriter.WriteAttribute("TimeSynchronization", XMLString(CommonParameters.TimeSynchronization));
			EndIf; 
		EndIf;                 
	Else
		XMLWriter.WriteAttribute("CashierName" , ?(CommonParameters.Property("Cashier"), XMLString(CommonParameters.Cashier), NStr("vi = 'Người quản trị';
																																	|ru = 'Администратор';
																																	|en = 'Administrator'; fa = 'مدیر سیستم';
																																	|it = 'Administrator';
																																	|pl = 'Administrator';
																																	|tr = 'Yönetici'")));
		XMLWriter.WriteAttribute("CashierVATIN", ?(CommonParameters.Property("CashierTIN"), XMLString(CommonParameters.CashierTIN), ""));
	EndIf;
	
	XMLWriter.WriteEndElement();
	XMLWriter.WriteEndElement();
	
	Return XMLWriter.Close();
	
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
	
	Result = New Array();
	
	// Batch printing of the receipt. Preparation of the package.
	XMLWriter = New XMLWriter();
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("Document");
	                              
	If Not IsBlankString(TextString) Then
		XMLWriter.WriteStartElement("Positions");
		
		For LineNumber = 1 To StrLineCount(TextString) Do
			
			SelectedRow = StrGetLine(TextString, LineNumber);
			
			If ((Find(SelectedRow, "[cut_1]") > 0)
				 Or (Find(SelectedRow, "[cut]") > 0))
				 And LineNumber < StrLineCount(TextString) Then
				 
				// Completing the recording of the current package. 
				XMLWriter.WriteEndElement();
				XMLWriter.WriteEndElement();
				Text = XMLWriter.Close();
				Result.Add(Text);
				
				// A new package.
				XMLWriter = New XMLWriter();
				XMLWriter.SetString("UTF-8");
				XMLWriter.WriteXMLDeclaration();
				XMLWriter.WriteStartElement("Document");
				XMLWriter.WriteStartElement("Positions");
				
			ElsIf (Find(SelectedRow, "|Barcode|") > 0) Then
				SelectedRow = Mid(SelectedRow, StrLen("|Barcode|") + 1);
				TimeBarcodeType = Mid(SelectedRow, 1, Find(SelectedRow, "|") - 1);
	 			VremBarcode = TrimAll(Mid(SelectedRow, Find(SelectedRow, "|") + 1)); 
				XMLWriter.WriteStartElement("Barcode");
				If InterfaceRevision >= 3000 Then  // Standard version 3.0 (OFD 1.1)
					XMLWriter.WriteAttribute("Type", XMLString(TimeBarcodeType));
					// Barcode value. The barcode is encoded with Base64 encoded text.
					If InterfaceRevision >= 3003 Then
						BarcodeBASE64 = EquipmentManagerClientServer.BarcodeInBase64(VremBarcode);
						XMLWriter.WriteAttribute("ValueBase64", XMLString(BarcodeBASE64));
					Else
						XMLWriter.WriteAttribute("Value", XMLString(VremBarcode));
					EndIf;
				Else
					XMLWriter.WriteAttribute("BarcodeType", XMLString(TimeBarcodeType));
					XMLWriter.WriteAttribute("Barcode", XMLString(VremBarcode));
				EndIf;
				XMLWriter.WriteEndElement();
			Else
				XMLWriter.WriteStartElement("TextString");
				XMLWriter.WriteAttribute("Text", XMLString(SelectedRow));
				XMLWriter.WriteEndElement();
			EndIf;
		EndDo;
		
		XMLWriter.WriteEndElement();
	EndIf;
		
	XMLWriter.WriteEndElement();
	Text = XMLWriter.Close();
	
	Result.Add(Text);
	
	Return Result;

EndFunction  

// The procedure fills in an XML package for printing a text document
// 
// Parameters:
//  TestReceipts - Array of String - 
//  NonFiscalDocuments - Array of See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  ConnectionParameters - See EquipmentManagerClientServer.ConnectionParameters
//  LineWidth_ - Number - width of the printer line
//
Procedure FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_ = 32) Export
	
	InterfaceRevision = ConnectionParameters.InterfaceRevision;
	TypesOfEquipment = ConnectionParameters.TypesOfEquipment;
	                    
	For Each ReceiptPositions In NonFiscalDocuments Do
		
		// Batch printing of the receipt. Preparation of the package.
		XMLWriter = New XMLWriter();
		XMLWriter.SetString("UTF-8");
		XMLWriter.WriteXMLDeclaration();
		XMLWriter.WriteStartElement("Document");
		
		// Table part
		If ReceiptPositions <> Undefined Then
			XMLWriter.WriteStartElement("Positions");
			For ArrayIndex = 0 To ReceiptPositions.Count() - 1 Do
				CurrentPosition = ReceiptPositions[ArrayIndex]; // See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptSFiscalLine
				If CurrentPosition.Property("FiscalLine") Then
					XMLWriter.WriteStartElement("FiscalString");
					XMLWriter.WriteAttribute("Name"      , XMLString(CurrentPosition.Description));
					XMLWriter.WriteAttribute("Quantity"  , XMLString(CurrentPosition.Count));
					XMLWriter.WriteAttribute("Price"     , XMLString(CurrentPosition.Price));
					XMLWriter.WriteAttribute("Amount"    , XMLString(CurrentPosition.Sum));
					XMLWriter.WriteAttribute("Department", XMLString(CurrentPosition.SectionNumber_));
					If Not IsBlankString(CurrentPosition.VATRate) Then 
						XMLWriter.WriteAttribute("Tax"   , XMLString(CurrentPosition.VATRate));
					Else
						XMLWriter.WriteAttribute("Tax"   , "none");
					EndIf;
					XMLWriter.WriteEndElement();
				ElsIf CurrentPosition.Property("TextString") Then
					If CurrentPosition.Property("LineBreak") And CurrentPosition.LineBreak Then 
						TextStrings = PeripheralsReceiptPrintersClientServer.BuildFieldByHyphenation(CurrentPosition.Text, LineWidth_);
					Else
						TextStrings = CurrentPosition.Text;
					EndIf;
					Align = ?(CurrentPosition.Property("Align"),  CurrentPosition.Align, "Left"); 
					For LineNumber = 1 To StrLineCount(TextStrings) Do
						SelectedRow = StrGetLine(TextStrings, LineNumber);
						SelectedRow = PeripheralsReceiptPrintersClientServer.Align_Field(SelectedRow, LineWidth_, Align); 
						XMLWriter.WriteStartElement("TextString");
						XMLWriter.WriteAttribute("Text", XMLString(SelectedRow));
						XMLWriter.WriteEndElement();  
					EndDo;
				ElsIf CurrentPosition.Property("Barcode") Then // Barcode
					XMLWriter.WriteStartElement("Barcode");
					If InterfaceRevision >= 3003 Then
						XMLWriter.WriteAttribute("Type" , XMLString(CurrentPosition.BarcodeType));
						// Barcode value. The barcode is encoded with Base64 encoded text.
						BarcodeBASE64 = EquipmentManagerClientServer.BarcodeInBase64(CurrentPosition.Barcode);
						If CurrentPosition.Property("BarcodeBASE64")
							And Not IsBlankString(CurrentPosition.BarcodeBASE64) Then
							BarcodeBASE64 = CurrentPosition.BarcodeBASE64;
						EndIf;
						XMLWriter.WriteAttribute("ValueBase64", XMLString(BarcodeBASE64));
					ElsIf InterfaceRevision >= 3000 And TypesOfEquipment.CREWithDataTransfer Then
						XMLWriter.WriteAttribute("Type" , XMLString(CurrentPosition.BarcodeType));
						XMLWriter.WriteAttribute("Value", XMLString(CurrentPosition.Barcode));
					Else
						XMLWriter.WriteAttribute("BarcodeType" , XMLString(CurrentPosition.BarcodeType));
						XMLWriter.WriteAttribute("Barcode", XMLString(CurrentPosition.Barcode));
					EndIf;
					XMLWriter.WriteEndElement();
				EndIf;
		EndDo;
			XMLWriter.WriteEndElement();
		EndIf;
		
		XMLWriter.WriteEndElement();
		Text = XMLWriter.Close();
		TestReceipts.Add(Text);
		
	EndDo;
	
EndProcedure  

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
//
Function GetStateParametersFromXMLPackage(Data, ShiftNumber = Undefined) Export
	
	Parameters = PeripheralsReceiptPrintersClientServer.ParametersOfNormalizedFiscalData();
	Parameters.CREShiftNumber = ShiftNumber;
	
	If Not IsBlankString(Data) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(Data);
		XMLReader.MoveToContent();
		If XMLReader.Name = "StatusParameters" And XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.Read() And XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
				UnpostedFDCount = XMLReader.AttributeValue("BacklogDocumentsCounter");
				Parameters.UnpostedFDCount    = ?(IsBlankString(UnpostedFDCount), 0, Number(UnpostedFDCount));
				Parameters.NumberOfFirstUntransmittedFD = XMLReader.AttributeValue("BacklogDocumentFirstNumber");
				DateAndTimeOfFirstOfUnsentFD = XMLReader.AttributeValue("BacklogDocumentFirstDateTime");
				If Not IsBlankString(DateAndTimeOfFirstOfUnsentFD) Then
					Parameters.DateAndTimeOfFirstOfUnsentFD = XMLValue(Type("Date"), DateAndTimeOfFirstOfUnsentFD);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return Parameters;
	
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
	
	Parameters = PeripheralsReceiptPrintersClientServer.ParametersOfNormalizedFiscalData();
	Parameters.CREShiftNumber = CREShiftNumber;
	Parameters.KKTReceiptNumber  = KKTReceiptNumber;
	
	If Not IsBlankString(XMLData1) Then
		
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLData1);
		XMLReader.MoveToContent(); 
		
		If InterfaceRevision >= 3000 Then  // Standard version 3.0 (OFD 1.1)
			If XMLReader.Name = "OutputParameters" And XMLReader.NodeType = XMLNodeType.StartElement Then
				If XMLReader.Read() And XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					Parameters.CREShiftNumber = XMLReader.AttributeValue("ShiftNumber");
					Parameters.KKTReceiptNumber  = XMLReader.AttributeValue("CheckNumber");
					CREShiftDate = XMLReader.AttributeValue("DateTime");
					If Not IsBlankString(CREShiftDate) Then
						Parameters.CREShiftDate = XMLValue(Type("Date"), CREShiftDate);
					EndIf;
					Parameters.ShiftReceiptNumber = XMLReader.AttributeValue("ShiftClosingCheckNumber");
					Parameters.ShiftStatus      = Number(XMLReader.AttributeValue("ShiftState"));
					Parameters.CashBalance  = XMLReader.AttributeValue("CashBalance");
					
					UnpostedFDCount = XMLReader.AttributeValue("BacklogDocumentsCounter");
					Parameters.UnpostedFDCount    = ?(IsBlankString(UnpostedFDCount), 0, Number(UnpostedFDCount));
					
					Parameters.NumberOfFirstUntransmittedFD = XMLReader.AttributeValue("BacklogDocumentFirstNumber");
					
					NumberOfSalesSlipsAccountableFormsPerShift = XMLReader.AttributeValue("DocumentsCounter");
					Parameters.NumberOfSalesSlipsAccountableFormsPerShift    = ?(IsBlankString(NumberOfSalesSlipsAccountableFormsPerShift), 0, Number(NumberOfSalesSlipsAccountableFormsPerShift));
					
					DateAndTimeOfFirstOfUnsentFD = XMLReader.AttributeValue("BacklogDocumentFirstDateTime");
					If Not IsBlankString(DateAndTimeOfFirstOfUnsentFD) Then
						Parameters.DateAndTimeOfFirstOfUnsentFD = XMLValue(Type("Date"), DateAndTimeOfFirstOfUnsentFD);
					EndIf;
					Parameters.UrgentReplacementOfFNIsNeeded = Upper(XMLReader.AttributeValue("FNError")) = "TRUE";
					Parameters.ShowsThatFiscalStorageMemoryIsFull       = Upper(XMLReader.AttributeValue("FNOverflow")) = "TRUE";
					Parameters.FiscalStorageResourceExceeded          = Upper(XMLReader.AttributeValue("FNFail")) = "TRUE";
					FNValidityPeriod = XMLReader.AttributeValue("FNValidityDate");
					If Not IsBlankString(FNValidityPeriod) Then
						Parameters.FNValidityPeriod = XMLValue(Type("Date"), FNValidityPeriod);
					EndIf;
				EndIf;
			EndIf;
		Else
			If XMLReader.Name = "OutputParameters" And XMLReader.NodeType = XMLNodeType.StartElement Then
				If XMLReader.Read() And XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					Parameters.FDOResponseTimeoutExceeded = Upper(XMLReader.AttributeValue("OFDtimeout")) = "TRUE";
					Parameters.UrgentReplacementOfFNIsNeeded = Upper(XMLReader.AttributeValue("UrgentReplacementFN")) = "TRUE";
					Parameters.ShowsThatFiscalStorageMemoryIsFull        = Upper(XMLReader.AttributeValue("MemoryOverflowFN")) = "TRUE";
					Parameters.FiscalStorageResourceExceeded           = Upper(XMLReader.AttributeValue("ResourcesExhaustionFN")) = "TRUE";
					UnpostedFDCount = XMLReader.AttributeValue("BacklogDocumentsCounter");
					Parameters.UnpostedFDCount    = ?(IsBlankString(UnpostedFDCount), 0, Number(UnpostedFDCount));
					Parameters.NumberOfFirstUntransmittedFD = XMLReader.AttributeValue("BacklogDocumentFirstNumber");
					DateAndTimeOfFirstOfUnsentFD = XMLReader.AttributeValue("BacklogDocumentFirstDateTime");
					If Not IsBlankString(DateAndTimeOfFirstOfUnsentFD) Then
						Parameters.DateAndTimeOfFirstOfUnsentFD = XMLValue(Type("Date"), DateAndTimeOfFirstOfUnsentFD);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return Parameters;
	
EndFunction

#EndIf

#EndRegion

#EndRegion

#Region Private

// Builds a line along the length of the field. if the field is long, it moves it to the next line.
// 
// Parameters:
//  Text - Undefined, String - Text
//  FieldLength - Number - Field length
//  GoodSymbol - String - Dob symbol
//  Centered - Boolean - Centered
// 
// Returns:
//  Undefined, String - Create a field by moving it
Function BuildFieldByHyphenation(Val Text, Val FieldLength, GoodSymbol = "", Centered = False) Export
	
	GoodSymbol = ?(IsBlankString(GoodSymbol), " ", GoodSymbol);
	
	If StrLen(Text) > FieldLength Then 
		FullText = "";
		While StrLen(Text) > FieldLength Do
			FullText = FullText + ?(IsBlankString(FullText), "", Chars.LF) +  Left(Text, FieldLength);
			Text = Mid(Text, FieldLength + 1);
		EndDo;
		FullText = FullText + ?(IsBlankString(Text), "", Chars.LF + Text);
	Else
		If Centered Then
			FullText = Text;
			AddOnRight = True; 
			While StrLen(FullText) < FieldLength Do
				If AddOnRight Then
					FullText = FullText + GoodSymbol;
				Else
					FullText = GoodSymbol + FullText;
				EndIf;
				AddOnRight = Not AddOnRight;
			EndDo;
		Else
			FullText = Text;
		EndIf;
	EndIf;
		
	Return FullText;
	
EndFunction

// Truncates the string passed to the field length if the field is too short - complements the characters.
//
// Parameters:
//  Text - String - Text
//  FieldLength - Number - Field length
//  GoodSymbol - String - Dob symbol
//  AddOnRight - Boolean - if true, add a DOB character on the right, otherwise on the left.
// 
// Returns:
//  String
//
Function BuildField(Val Text, Val FieldLength, GoodSymbol = "", AddOnRight = True) Export
	
	GoodSymbol = ?(IsBlankString(GoodSymbol), " ", GoodSymbol);
	
	FullText = Left(Text, FieldLength);
	While StrLen(FullText) < FieldLength Do
		If AddOnRight Then
			FullText = FullText + GoodSymbol;
		Else
			FullText = GoodSymbol + FullText;
		EndIf;
	EndDo;
	          
	Return FullText;
	
EndFunction

// Generates a string of two fields, if one field is passed, and adds characters to the desired size.
//
// Parameters:
//  Text1 - String
//  Text2 - String
//  FieldLength - Number
//
// Returns:
//  String
//
Function BuildFields(Val Text1, Val Text2 = "", Val FieldLength = 32) Export
	
	If IsBlankString(Text2) Then
		FullText = BuildField(Text1, StrLen(Text1) + Int((FieldLength - StrLen(Text1))/2), , False);
		FullText = BuildField(FullText, FieldLength);
	ElsIf StrLen(Text1) + StrLen(Text2) < FieldLength Then
		FullText = BuildField(Text1, FieldLength - StrLen(Text2)) + Text2;
	Else
		FullText = BuildField(Text1, FieldLength) + Chars.LF + BuildField(Text2, FieldLength, ,False)
	EndIf;
	
	Return FullText;
	
EndFunction

// Align the transmitted string to the length of the field, if the field is too short, it adds characters.
// 
// Parameters:
//  Text - String - Text
//  FieldLength - Number - Field length
//  Align - String - Align
//  GoodSymbol - String - Dob symbol
// 
// Returns:
//  String - Aligned field
Function Align_Field(Val Text, Val FieldLength = 32, Val Align = "Left", GoodSymbol = "") Export
	
	GoodSymbol = ?(IsBlankString(GoodSymbol), " ", GoodSymbol);
	StartingPosition = True;
	FullText = Left(Text, FieldLength);
	While StrLen(FullText) < FieldLength Do
		If Align = "Left" Then
			FullText = FullText + GoodSymbol;
		ElsIf Align = "Right" Then
			FullText = GoodSymbol + FullText;
		Else
			If StartingPosition Then
				FullText = FullText + GoodSymbol;
				StartingPosition = False;
			Else
				FullText = GoodSymbol + FullText;
				StartingPosition = True;
			EndIf;
		EndIf;
	EndDo;
	          
	Return FullText;
	
EndFunction

#EndRegion