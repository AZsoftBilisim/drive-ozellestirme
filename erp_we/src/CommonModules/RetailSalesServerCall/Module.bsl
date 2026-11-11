
#Region Public

// Opens the cash shift for the KKM cash register.
//
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - Cash registers.
//  AdditionalParameters - Structure - 
//  ErrorDescription - String - error description.
//
// Returns:
//  Boolean - True if the operation was completed successfully.
//
Function OpenRegisterShift(CashRegister, AdditionalParameters, ErrorDescription = "") Export
	
	Return RetailSales.OpenRegisterShift(CashRegister, AdditionalParameters, ErrorDescription);
	
EndFunction

// Closes the cash register shift for the cash registers.
//
// Parameters:
//  Object - CatalogRef.CashRegisters, CatalogRef.Peripherals - Cash registers.
//  ErrorWhenDeletingZReport - Boolean - Indicates whether the z-report was successfully removed.
//  ErrorDescription - String - Output parameter-error description.
//
// Returns:
//  Array - An array of created retail sales reports.
//
Function CloseRegisterShift(Object, ErrorWhenDeletingZReport, ErrorDescription = "") Export
	
	Return RetailSales.PerformCashShiftClosingOperation(Object, ErrorWhenDeletingZReport, ErrorDescription);
	
EndFunction

// Create a document for depositing funds to the cash register of KKM.
//
// Parameters:
//  InputData - Structure - Details of the document.
//  LinkToDocumentIntroduction - Undefined, DocumentRef.DepositCashIntoCashRegister - Optional, a link to the created document in the event of a failure is Undefined.
//  ErrorDescription - String - Optional description of the error.
// 
// Returns:
//   Boolean - True if the document creation is successful.
//
Function CreateDocumentDepositingFundsToCashRegister(InputData, LinkToDocumentIntroduction = Undefined, ErrorDescription = Undefined) Export
	
	Result = True;
	
	Try
		
		LinkToDocumentIntroduction = RetailSales.CreateDocumentDepositingFundsToCashRegister(InputData);
		
	Except
		
		Result = False;
		LinkToDocumentIntroduction = Undefined;
		ErrorDescription = BriefErrorDescription(ErrorInfo());
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", CommonClientServer.DefaultLanguageCode()),
		                         EventLogLevel.Error, , ,
		                         NStr("vi = 'Trong thời gian tạo chứng từ nhập tiền vào quầy thu ngân, đã xảy ra lỗi.';
										|ru = 'Во время создания документа внесения денежных средств в кассу ККМ произошла ошибка.';
										|en = 'An error occurred while creating the document of putting cash into the cash register.'; fa = 'An error occurred while creating the document of putting cash into the cash register.';
										|it = 'Se è verificato un errore durante il processo di creazione del documento di versamento dei contanti nel registratore di cassa.';
										|pl = 'Wystąpił błąd podczas tworzenia dokumentu depozytu gotówkowego w kasie KF.';
										|tr = 'Yazar Kasaya para yatırma belgesi oluşturulurken hata oluştu.'")
		                         + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Result;
	
EndFunction

// Create the document withdrawal of funds from the cash register of KKM.
//
// Parameters:
//  InputData - Structure - Structure with details of the document.
//  LinkToDocumentNotch - Undefined, DocumentRef.CashWithdrawalFromCashRegister - Optional, a link to the created document in the event of a failure is Undefined.
//  ErrorDescription - String - Optional description of the error.
// 
// Returns:
//   Boolean - True if the document creation is successful.
//
Function CreateDocumentWithdrawalOfFundsFromCashRegisterCashRegister(InputData, LinkToDocumentNotch = Undefined, ErrorDescription = Undefined) Export
	
	Result = True;
	
	Try
		
		LinkToDocumentNotch = RetailSales.CreateDocumentWithdrawalOfFundsFromCashRegisterCashRegister(InputData);
		
	Except
		
		Result = False;
		LinkToDocumentNotch = Undefined;
		ErrorDescription = BriefErrorDescription(ErrorInfo());
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", CommonClientServer.DefaultLanguageCode()),
		                         EventLogLevel.Error, , ,
		                         NStr("vi = 'Trong thời gian tạo chứng từ rút tiền từ quầy thu ngân, đã xảy ra lỗi.';
										|ru = 'Во время создания документа выемки денежных средств из кассы ККМ произошла ошибка.';
										|en = 'An error occurred while creating the document of taking cash out of the cash register.'; fa = 'An error occurred while creating the document of taking cash out of the cash register.';
										|it = 'Se è verificato un errore durante il processo di creazione del documento di estrazione dei contanti nel registratore di cassa.';
										|pl = 'Wystąpił błąd podczas tworzenia dokumentu wypłaty gotówki z kasy fiskalnej.';
										|tr = 'Yazar Kasadan nakit çekme belgesi oluşturulurken hata oluştu.'")
		                         + Chars.LF + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Result;
	
EndFunction

// Deletes the document when the fiscal transaction is canceled.
//
// Parameters:
//  Ref - DocumentRef - Link to the document being deleted.
// 
// Returns:
//   Boolean - True if the document was deleted successfully.
//
Function DeleteDocumentWhenCancelingFiscalTransaction(Ref) Export
	
	Result = True;
	
	If ValueIsFilled(Ref) Then
		
		ErrorTextLines = New Array;
		ErrorHeaderTextTemplate = NStr("vi = 'Khi hủy giao dịch tài chính, không thể xóa chứng từ %1';
										|ru = 'При отмене фискальной операции не удалось удалить документ %1';
										|en = 'Cannot delete the %1 document when cancelling the fiscal transaction'; fa = 'Cannot delete the %1 document when cancelling the fiscal transaction';
										|it = 'Cannot delete the %1 document when cancelling the fiscal transaction';
										|pl = 'Cannot delete the %1 document when cancelling the fiscal transaction';
										|tr = 'Mali işlemin iptali esnasında %1 belgesi silinemedi'");

		ThereIsRightToAddChanges = (TypeOf(Ref) = Type("DocumentRef.CashRegisterReceipt")
											Or TypeOf(Ref) = Type("DocumentRef.CashRegisterReceiptReturn"))
										And Users.RolesAvailable("AddEditCashRegisterReceipts")
									Or (TypeOf(Ref) = Type("DocumentRef.GiftCertificateSale")
											Or TypeOf(Ref) = Type("DocumentRef.ReturnOfGiftCards"))
										And Users.RolesAvailable("AddEditSaleReturnOfGiftCard");
										
		SalesSettingsForUser = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
		If ThereIsRightToAddChanges And SalesSettingsForUser.LineAdjustment Then
			
			DocumentStatus = Common.ObjectAttributeValue(Ref, Ref.Metadata().Attributes.Status.Name, True);
			If DocumentStatus = Undefined Then
				
				Result = False;
				ErrorTextLines.Add(StrTemplate(ErrorHeaderTextTemplate, Ref));
				ErrorTextLines.Add(NStr("vi = 'do: Chứng từ không tồn tại hoặc người sử dụng không đủ quyền';
										|ru = 'по причине: Документ не существует или у пользователя недостаточно прав';
										|en = 'Reason: The document does not exist, or the user does not have sufficient rights'; fa = 'Reason: The document does not exist, or the user does not have sufficient rights';
										|it = 'Reason: The document does not exist, or the user does not have sufficient rights';
										|pl = 'Reason: The document does not exist, or the user does not have sufficient rights';
										|tr = 'sebep: Belge mevcut değil veya kullanıcının izinleri yetersiz'"));
				
			ElsIf DocumentStatus = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
					
				Result = False;
				ErrorTextLines.Add(StrTemplate(ErrorHeaderTextTemplate, Ref));
				ErrorTextLines.Add(NStr("vi = 'do: không thể xóa phiếu đã đánh';
										|ru = 'по причине: Пробитый чек не может быть удален';
										|en = 'Reason: An issued receipt cannot be deleted'; fa = 'Reason: An issued receipt cannot be deleted';
										|it = 'Reason: An issued receipt cannot be deleted';
										|pl = 'Reason: An issued receipt cannot be deleted';
										|tr = 'sebep: Düzenlenmiş fiş silinemez'"));
					
			Else
				
				DocumentObject = Ref.GetObject(); // DocumentObject
				If Not DocumentObject = Undefined Then
					DocumentObjectType = TypeOf(DocumentObject.Ref);
					DocumentObjectNumber = String(DocumentObject.Number);
					DocumentDateObject = String(DocumentObject.Date);
					
					Try
	
						If Not DocumentObject.DeletionMark Then
							DocumentObject.SetDeletionMark(True);
						EndIf;
	
						RemovalLinks = New Array;
						RemovalLinks.Add(DocumentObject.Ref);
						SetPrivilegedMode(True);
						DeleteObjects(RemovalLinks, False);
						SetPrivilegedMode(False);
	
					Except
	
						If PrivilegedMode() Then
							SetPrivilegedMode(False);
						EndIf;
	
						Result = False;
						ErrorTextLines.Add(StrTemplate(ErrorHeaderTextTemplate, DocumentObjectType));
						ErrorTextLines.Add(DocumentObjectNumber);
						ErrorTextLines.Add(DocumentDateObject);
						ErrorTextLines.Add(StrTemplate(NStr("vi = 'do: %4';
															|ru = 'по причине: %4';
															|en = 'Reason: %4'; fa = 'Reason: %4';
															|it = 'Reason: %4';
															|pl = 'Reason: %4';
															|tr = 'sebep: %4'", ErrorProcessing.DetailErrorDescription(ErrorInfo()))));
						
					EndTry;
				EndIf;
				
			EndIf;
		Else
			
			Result = False;
			ErrorTextLines.Add(StrTemplate(ErrorHeaderTextTemplate, Ref));
			ErrorTextLines.Add(NStr("vi = 'do: Người sử dụng không đủ quyền';
									|ru = 'по причине: У пользователя недостаточно прав';
									|en = 'Reason: Insufficient user rights'; fa = 'Reason: Insufficient user rights';
									|it = 'Reason: Insufficient user rights';
									|pl = 'Reason: Insufficient user rights';
									|tr = 'sebep: Kullanıcının izinleri yetersiz'"));
			
		EndIf;
		
		If ErrorTextLines.Count() Then
			LogEventName = NStr("vi = 'Bán lẻ';
								|ru = 'Розничные продажи';
								|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
								|it = 'Vendite al dettaglio';
								|pl = 'Sprzedaże detaliczne';
								|tr = 'Perakende satışlar'", Common.DefaultLanguageCode());
			ErrorText = StrConcat(ErrorTextLines, " ");
			WriteLogEvent(LogEventName, EventLogLevel.Error,,, ErrorText);
			Common.MessageToUser(ErrorText);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Gets the structure of the description of the cash shift for the cash register of KKM.
//
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - Cash registers.
//
// Returns:
//  See RetailSales.DescriptionOfCashShift
//
Function RegisterShiftState(CashRegister) Export
	
	Return RetailSales.GetCashShiftState(CashRegister);
	
EndFunction

// Returns Item barcodes.
//
// Parameters:
//	ProductData_8 - Structure - a collection containing information about the product.
//
// Returns:
//	Array of String - Barcodes of the nomenclature.
//
Function GetProductBarcodes(ProductData_8) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfSinglePackages,
	|	ProductPackages.Owner AS Owner,
	|	ProductPackages.Ref AS Ref
	|INTO ProductPackages
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|WHERE
	|	ProductPackages.DeletionMark = FALSE
	|	AND (ProductPackages.Owner = &Owner
	|		OR ProductPackages.Owner = &PackagingGroup)
	|	AND ProductPackages.Owner.UnitOfMeasure = ProductPackages.UnitOfMeasure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductPackages.NumberOfSinglePackages AS NumberOfSinglePackages,
	|	ProductPackages.Owner AS Owner,
	|	ProductPackages.Ref AS Ref
	|FROM
	|	ProductPackages AS ProductPackages
	|WHERE
	|	ProductPackages.NumberOfSinglePackages = 1";
	
	PackagingGroup = Common.ObjectAttributeValue(ProductData_8.Products, "PackagingGroup");
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"ProductPackages",
									Undefined));
	
	Query.SetParameter("Owner",		ProductData_8.Products);
	Query.SetParameter("PackagingGroup",	PackagingGroup);
	
	Selection = Query.Execute().Select();
	
	ArrayOfBarcodes = New Array;
	
	FilterParameters = InformationRegisters.ItemsBarcodes.DefaultParametersForSelectingItemBarcodes();
	FillPropertyValues(FilterParameters, ProductData_8);
	
	If Selection.Next() Then
		SinglePackaging = Selection.Ref;
		// The search for barcodes by unit package and by unit of measurement makes sense only
		// when the item has 1 package with a coefficient of 1 and a unit of 1.
		If Not Selection.Next() Then
			FilterParameters.Package = ?(SinglePackaging = ProductData_8.Package,
										Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(),
										SinglePackaging);
			
			ArrayOfBarcodes = InformationRegisters.ItemsBarcodes.ItemsBarcodes(FilterParameters);
		EndIf;
	EndIf;
	
	FillPropertyValues(FilterParameters, ProductData_8);
	
	If ArrayOfBarcodes.Count() = 0 Then
		ArrayOfBarcodes = InformationRegisters.ItemsBarcodes.ItemsBarcodes(FilterParameters);
	Else
		ArrayOfStructurePackingBarcodes = InformationRegisters.ItemsBarcodes.ItemsBarcodes(FilterParameters);
		
		For Each Barcode In ArrayOfStructurePackingBarcodes Do
			ArrayOfBarcodes.Add(Barcode);
		EndDo;
	EndIf;
	
	Return ArrayOfBarcodes;
	
EndFunction

// Fill in the details of the "cashier's Details" form.
//
// Parameters:
//  Cashier - CatalogRef.Users - Cashier.
//  Organization - CatalogRef.Companies - Organization for selection in the directory of responsible organizations.
//  DateTime - Date - For selection by Datanachal period - end Date in the reference list, responsible organizations.
//
// Returns:
//  See RetailSales.DetailsOfTheCashier
// 
Function DetailsOfTheCashier(Val Cashier = Undefined, Val Organization = Undefined, Val DateTime = Undefined) Export
	
	If Not ValueIsFilled(Cashier) Then
		Cashier = Users.CurrentUser();
	EndIf;
	
	Return RetailSales.DetailsOfTheCashier(Cashier, Organization, DateTime);
	
EndFunction

// Returns the organization value for the connected hardware
// 
// Parameters:
//  FiscalDevice - CatalogRef.Peripherals
// 
// Returns:
//  Undefined, Arbitrary - Company's Fiscal Arrangement
Function CompanySFiscalArrangement(Val FiscalDevice) Export
	
	If Not TypeOf(FiscalDevice) = Type("CatalogRef.Peripherals") Then
		Return Undefined;
	EndIf;
	
	If Not ValueIsFilled(FiscalDevice) Then
		Return Undefined;
	EndIf;
	
	Return Common.ObjectAttributeValue(FiscalDevice, "Organization");
	
EndFunction

Function DetailsOfAddressOfPlaceOfSettlement(Val FiscalDevice) Export
	
	DetailsOfAddressOfPlaceOfSettlement = New Structure;
	DetailsOfAddressOfPlaceOfSettlement.Insert("SettlementAddress", "");
	DetailsOfAddressOfPlaceOfSettlement.Insert("PlaceOfSettlement", "");
	
	CashRegister = Catalogs.CashRegisters.CashDeskCashRegisterForPlugInEquipmentForCWP(FiscalDevice);
	
	If CashRegister <> Undefined Then
		CashRegisterDetails = Catalogs.CashRegisters.CashRegisterDetails(CashRegister);
		
		If TypeOf(CashRegisterDetails) = Type("Structure")
			And CashRegisterDetails.Property("Warehouse") Then
			
			Warehouse = CashRegisterDetails.Warehouse;
			If ValueIsFilled(Warehouse) And TypeOf(Warehouse) = Type("CatalogRef.Warehouses") Then
				DetailsOfAddressOfPlaceOfSettlement.SettlementAddress = ContactsManager.ObjectContactInformation(Warehouse, Catalogs.ContactInformationKinds.WarehouseAddress);
				DetailsOfAddressOfPlaceOfSettlement.PlaceOfSettlement = Common.ObjectAttributeValue(Warehouse, "Description");
			EndIf;
			
		EndIf;
			
	EndIf;
	
	Return DetailsOfAddressOfPlaceOfSettlement;
	
EndFunction

Function UsedByKKTFZ54(CashRegisterShift) Export
	
	UsedByKKTFZ54 = False;
	
	Query = New Query(
	"SELECT
	|	CashRegisterShift.FiscalDevice.EquipmentType AS EquipmentType
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Ref = &CashRegisterShift
	|");
	Query.SetParameter("CashRegisterShift", CashRegisterShift);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		UsedByKKTFZ54 = (Selection.EquipmentType = Enums.PeripheralTypes.CREWithDataTransfer);
		
	EndIf;
	
	Return UsedByKKTFZ54;
	
EndFunction

Function FindPartnerUsingContactDetailsOfElectronicReceipt(OptionOfSendingElectronicReceipt, ContactDetails) Export
	
	ReturnValue = Undefined;
	
	If OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendSMS Then
		
		SearchParameter = "%" + Right(ContactDetails, 10);
		QueryText = 
		"SELECT TOP 1
		|	PartnersContactInformation.Ref,
		|	PartnersContactInformation.Ref.OptionOfSendingElectronicReceipt AS OptionOfSendingElectronicReceipt,
		|	PartnersContactInformation.EMAddress AS EMAddress,
		|	PartnersContactInformation.PhoneNumber AS PhoneNumber
		|FROM
		|	Catalog.Partners.ContactInformation AS PartnersContactInformation
		|WHERE
		|	PartnersContactInformation.PhoneNumber LIKE &ContactDetails";
		
	ElsIf OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail Then
		
		SearchParameter = ContactDetails;
		QueryText = 
		"SELECT TOP 1
		|	PartnersContactInformation.Ref,
		|	PartnersContactInformation.Ref.OptionOfSendingElectronicReceipt AS OptionOfSendingElectronicReceipt,
		|	PartnersContactInformation.EMAddress AS EMAddress,
		|	PartnersContactInformation.PhoneNumber AS PhoneNumber
		|FROM
		|	Catalog.Partners.ContactInformation AS PartnersContactInformation
		|WHERE
		|	PartnersContactInformation.EMAddress = &ContactDetails";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("ContactDetails", SearchParameter);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ReturnValue = New Structure;
		ReturnValue.Insert("Partner",                         Selection.Ref);
		ReturnValue.Insert("OptionOfSendingElectronicReceipt", Selection.OptionOfSendingElectronicReceipt);
		ReturnValue.Insert("Email",                           Selection.EMAddress);
		ReturnValue.Insert("Phone",                         RetailSalesClientServer.PhoneNumberIn10CharactersFormat(Selection.PhoneNumber));
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Returns the status of the partner, whether he is a retail customer.
// 
// Parameters:
//  Partner - CatalogRef.Partners - Partner
// 
// Returns:
//  Boolean - A partner is a retail client
Function PartnerIsRetailCustomer(Partner) Export
	
	ThisIsRetailCustomer = False;
	
	LegalEntityIndividual = Common.ObjectAttributeValue(Partner, "LegalEntityIndividual");
	If LegalEntityIndividual = Enums.IndividualCompany.Person_ Then
		ThisIsRetailCustomer = True;
	EndIf;
	
	Return ThisIsRetailCustomer;
	
EndFunction

// returns the Status of the counterparty, whether it is an individual.
// 
// Parameters:
//  Counterparty - CatalogRef.Counterparties - Counterparty
// 
// Returns:
//  Boolean - A counterparty is an individual
Function Counterparty_Is_Individual(Counterparty) Export
	
	ThisIsRetailCustomer = False;
	
	CompanyIndividual = Common.ObjectAttributeValue(Counterparty, "LegalEntityIndividual");
	If CompanyIndividual = Enums.LegalEntityIndividual.Person Then
		ThisIsRetailCustomer = True;
	EndIf;
	
	Return ThisIsRetailCustomer;
	
EndFunction

// This function retrieves the parameters of the cash register KKM.
//
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - Cash registers.
// 
// Returns:
//  Structure - with properties:
//   * DeviceID - String - Device ID.
//   * UseWithoutConnectingPeripherals - Boolean - Use without connecting equipment.
//   * ThisIsFiscalRegistrar - Boolean - A sign of the fiscal registrar.
//   * UseWarerooms - Boolean - a sign of the use of storage facilities.
//   * CashRegister - CatalogRef.CashRegisters - Cash registers.
//   * CWPSettings - CatalogRef.CWPSettings - Link to the RMK settings.
Function CashRegisterParameters(CashRegister) Export
	
	Return New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(CashRegister));
	
EndFunction

// This function determines the CMC by connecting Equipment for the current RMK.
//
// Returns:
//	 CatalogRef.CashRegisters - The found cash register of the KKM.
//
Function CashDeskCashRegisterForPlugInEquipmentForCWP(FiscalDevice) Export

	Return Catalogs.CashRegisters.CashDeskCashRegisterForPlugInEquipmentForCWP(FiscalDevice);
	
EndFunction

// Returns the fiscal option
// 
// Returns:
// 	Boolean
Function FiscalizationIsAvailable() Export

	Return GetFunctionalOption("UseRetailSales")
		And GetFunctionalOption("UsePeripherals");

EndFunction

// Returns the possibility of remote fiscalization
// 
// Returns:
// 	Boolean
Function RemoteFiscalizationIsAvailable() Export

	Return FiscalizationIsAvailable() And CollaborationSystem.CanUse();

EndFunction

// Returns the ability to print a separate receipt slip for the acquiring operation.
// If True, it is assumed that the acquiring terminal's slip check is displayed separately and
// the fiscal check does not contain the data of the acquiring operation.
// 
// Returns:
// 	Boolean
Function PrintSeparateSlipReceiptOfAcquiringOperation() Export

	Return RetailSalesLocalization.PrintSeparateSlipReceiptOfAcquiringOperation();

EndFunction

// Writes sensitive data to secure storage.
// The calling code must set the privileged mode itself.
//
// Secure storage is not readable by users (other than administrators),
// and is only available to code that accesses only its own part of the data and
// in a context that involves reading or writing sensitive data.
//
// Parameters:
//  Owner - ExchangePlanRef
//           - CatalogRef
//           - String - a reference to an information database object
//             representing the owner of the stored password or a string of up to 128 characters.
//             For objects of other types, it is recommended to use as the owner a reference to
//             a metadata element of this type in the Catalog of Metadata object IDENTIFIERS
//             or a key in the form of a string, taking into account the names of subsystems.
//             For example, for BSP:
//               Owner = General purpose.Identifier of the Data objectmetadata("Register of entries.Address objects");
//             if you need 1 storage per BSP subsystem:
//               Owner = "Standard Subsystems.Access managementreferences";
//             if you need more than 1 storage per BSP subsystem:
//               Owner = "Standard Subsystems.Access management.<Clarification>";
//
//  Data  - Arbitrary - data placed in secure storage. Undefined-deletes all data.
//             To delete data by key, use the delete data from secure Storage procedure.
//  Var_Key    - String       - the key of the saved settings, by default "Password".
//                           The key must comply with the rules for naming identifiers:
//                           1. The first character of the key must be a letter or an underscore (_).
//                           2. Each of the subsequent characters can be a letter, a number, or an underscore (_).
//
// Example:
//  Procedure For Writing To The Server(Failure, Current Object, Record Parameters)
//      If The Current User Can Change The Password Then
//          Installprivileged Mode(True);
//          General purpose.Write Down The Data In The Secure Storage (Current Object.Link, Username, " Login");
//          General purpose.Write Down The Data In The Secure Storage (Current Object.Link, Password);
//          Installprivileged Mode(False);
//      Conicelli;
//  End of procedure
//
Procedure WriteDataToSecureStorage(Owner, Data, Var_Key = "Password") Export
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Owner, Data, Var_Key);
	SetPrivilegedMode(False);
	
EndProcedure

// Deletes sensitive data to secure storage.
// The calling code must set the privileged mode itself.
//
// Secure storage is not readable by users (other than administrators),
// and is only available to code that accesses only its own part of the data and
// in a context that involves reading or writing sensitive data.
//
// Parameters:
//  Owner - ExchangePlanRef
//           - CatalogRef
//           - String - a reference to an information database object
//               representing the owner of the stored password or a string of up to 128 characters.
//  Keys    - String - contains a comma-separated list of names of data to delete. 
//               Undefined-deletes all data.
//
// Example:
//	Procedure before removal (Refusal)
//		
//		Checking the value of the property is deceptive.There is no download, since it is necessary to delete data
//		from secure storage even when deleting an object during data exchange.
//		
//		Set the Privileged mode(True);
//		General purpose.Delete the data from the secure storage (Link);
//		Set the Privileged mode(False);
//		
//	End of the procedure
//
Procedure DeleteDataFromSecureStorage(Owner, Keys = Undefined) Export
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Owner, Keys);
	SetPrivilegedMode(False);
	
EndProcedure

// determines whether the item is an alcoholic beverage that has a unique identifier (labeled)
// 
// Parameters:
//  Products - CatalogRef.Products - item to check
// 
// Returns:
//  Boolean - true if the item is an alcoholic product that has a unique identifier (marked)
Function EGAISLabeledAlcoholicBeverages(Products) Export
	
	Return RetailSalesLocalization.EGAISLabeledAlcoholicBeverages(Products);
	
EndFunction

// To register errors that occur on the client side when using blind asynchronous calls,
//  for example, Client sales.printcheck_performance.
//  The record uses an independent transaction mode see Sintax -assistant recording log registration.
// Parameters:
//  EventName - String
//  MetadataObject - MetadataObject -
//  Data - AnyRef, Number, String, Date, Boolean, Undefined, Null, Type - 
//  Comment - String
//
//@skip-check method-too-many-params
Procedure LogEntryLevelError(EventName = "", MetadataObject = Undefined, Data = Undefined, Comment = "") Export
	
	WriteLogEvent(EventName, EventLogLevel.Error, MetadataObject, Data, Comment, EventLogEntryTransactionMode.Independent);
	
EndProcedure

// Calculates whether there are completed shipment documents entered based on the order.
// 
// Parameters:
//  Ref - DocumentRef.SalesOrder, DocumentRef.RequestForReturnOfGoodsFromCustomer - 
//
// Returns:
//  Boolean -
//
Function ShipmentHasBeenMadeBasedOnOrder(Ref) Export
	Result = False;
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.SalesOrder = &Ref
	|	AND CustomerInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.CustomerInvoiceServices AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.SalesOrder = &Ref
	|	AND CustomerInvoice.Posted
	|";
	Query.SetParameter("Ref", Ref);
	
	Result = Not Query.Execute().IsEmpty();
	Return Result;
EndFunction

// Updates Statuses and information about sales of goods
// 
// Parameters:
//  Object - DocumentObject.CashRegisterReceipt - The document from which the procedure is called.
Procedure UpdateStatusesAndAllowedItems(Object) Export
	
	RetailSalesLocalization.UpdateStatusesAndAllowedItems(Object);
	
EndProcedure

#EndRegion

#Region Private

// The procedure populates the passed value details "of Cossacks" and "Organization" have the cash shift.
// 
// Parameters:
// 	CashRegisterShift - DocumentRef.CashRegisterShift - cash shift
// 	CashRegister - CatalogRef.CashRegisters - set the value
// 	Organization - CatalogRef.Companies - set the value
// 
Procedure FillInOrganizationSCashRegister(CashRegisterShift, CashRegister, Organization) Export
	
	CashShiftObject = CashRegisterShift.GetObject();
	CashShiftObject.CashRegister    = CashRegister;
	CashShiftObject.Organization = Organization;
	CashShiftObject.Write(DocumentWriteMode.Posting);
	
EndProcedure

// Parameters:
//	Equipment - See RetailSales.GetShiftStateProcessingParameters.Equipment
//
// Returns:
//	See RetailSales.GetShiftStateProcessingParameters
//
Function GetShiftStateProcessingParameters(Equipment) Export
	
	Return RetailSales.GetShiftStateProcessingParameters(Equipment);
	
EndFunction

// Receives ETH equipment with the sign of checking the same cover and cross-change
// 
// Parameters:
//  Equipment - CatalogRef.Peripherals - ID of the CCT device
// 
// Returns:
//  Array of CatalogRef.Peripherals - equipment et.
//
Function EquippingAcquiringTerminalForReconciliationOfTotals(Equipment) Export
	Return	Catalogs.POSTerminals.PlugInEquipmentOfAcquiringTerminalForReconciliationOfTotals(Equipment);
EndFunction

// Parameters:
//	ErrorText - See RetailSales.LogEntry.ErrorText
//	Event - See RetailSales.LogEntry.Event
//	Data - See RetailSales.LogEntry.Data
//	Level - See RetailSales.LogEntry.Level
Procedure LogEntry(Val ErrorText, Val Event, Data = Undefined, Val Level = "Error") Export
	RetailSales.LogEntry(ErrorText, Event, Data, Level);
EndProcedure

// Recalculates data on non-cancelled payments by payment cards, used in the CWP return and CWP return forms of gift certificates.
//
// Parameters:
//  AddressOfTableOfNonCancelledPaymentsByPaymentCards - String - an address that points to a value in temporary storage.
//  LineNumberOfPaymentCardBeingCancelled - Number - The line number of the payment being canceled is used for recalculation relative to a specific line.
//  AmountOfCancelledPayment - Number - The amount of the canceled payment is used for recalculation relative to a specific line.
//
// Returns:
//  Structure - with properties:
//   *CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards - Array of Number - 
//   *LowestAmountOfNonCancelledPaymentByPaymentCard - Number - 
//   *NumberOfOutstandingPaymentsByPaymentCards - Number - 
//   *DataOfFirstNonCancelledPaymentByPaymentCards - Undefined, Structure of KeyAndValue - 
//
Function RecalculateDataOfNonCanceledPaymentsByPaymentCards(Val AddressOfTableOfNonCancelledPaymentsByPaymentCards, 
																	 Val LineNumberOfPaymentCardBeingCancelled = Undefined,
																	 Val AmountOfCancelledPayment = 0) Export
	
	Result = New Structure;
	Result.Insert("CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards", New Array);
	Result.Insert("LowestAmountOfNonCancelledPaymentByPaymentCard", 0);
	Result.Insert("NumberOfOutstandingPaymentsByPaymentCards", 0);
	Result.Insert("DataOfFirstNonCancelledPaymentByPaymentCards", Undefined);
	
	TableOfNonCancelledPaymentsByPaymentCards = GetFromTempStorage(AddressOfTableOfNonCancelledPaymentsByPaymentCards);
	If Not TableOfNonCancelledPaymentsByPaymentCards = Undefined Then
		
		If Not LineNumberOfPaymentCardBeingCancelled = Undefined Then
			LinesOfCanceledPaymentByPaymentCard = TableOfNonCancelledPaymentsByPaymentCards.FindRows(New Structure("LineNumber", LineNumberOfPaymentCardBeingCancelled));
			If LinesOfCanceledPaymentByPaymentCard.Count() Then
				LineOfCanceledPayment = LinesOfCanceledPaymentByPaymentCard[0];
				If LineOfCanceledPayment.Sum = AmountOfCancelledPayment Then
					TableOfNonCancelledPaymentsByPaymentCards.Delete(LineOfCanceledPayment);
				Else
					LineOfCanceledPayment.Sum = LineOfCanceledPayment.Sum - AmountOfCancelledPayment;
				EndIf;
				AddressOfTableOfNonCancelledPaymentsByPaymentCards = PutToTempStorage(TableOfNonCancelledPaymentsByPaymentCards, AddressOfTableOfNonCancelledPaymentsByPaymentCards);		
			EndIf;
		EndIf;

		Result.NumberOfOutstandingPaymentsByPaymentCards = TableOfNonCancelledPaymentsByPaymentCards.Count();
		If Result.NumberOfOutstandingPaymentsByPaymentCards > 0 Then
			Result.DataOfFirstNonCancelledPaymentByPaymentCards = Common.ValueTableRowToStructure(TableOfNonCancelledPaymentsByPaymentCards[0]);
			Result.LowestAmountOfNonCancelledPaymentByPaymentCard = Result.DataOfFirstNonCancelledPaymentByPaymentCards.Sum;
			For Each PaymentLine_ In TableOfNonCancelledPaymentsByPaymentCards Do
				Result.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards.Add(PaymentLine_.Sum);
				If Result.LowestAmountOfNonCancelledPaymentByPaymentCard > PaymentLine_.Sum Then
					Result.LowestAmountOfNonCancelledPaymentByPaymentCard = PaymentLine_.Sum;
				EndIf;
			EndDo;
			ToSupplementArrayOfNumbersWithCombinationsOfSumsOfItsElements(Result.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards, 0, 0, Result.NumberOfOutstandingPaymentsByPaymentCards);			
		EndIf;
				
	EndIf;
	
	Return Result;
	
EndFunction

// Complements the array of numbers with various combinations of the sums of the first elements of the same array.
//
// Parameters:
//  ArrayOfCombinations - Array of Number -
//  StartPosition - Number - The values start from 0 and cannot be more than the number of the first elements for processing-1
//  AccumulatedAmount - Number -
//  NumberOfFirstItemsToProcess - Number - The number of the first elements from the array passed in the first parameter for which sum combinations will be calculated.
//
Procedure ToSupplementArrayOfNumbersWithCombinationsOfSumsOfItsElements(ArrayOfCombinations, Val StartPosition, AccumulatedAmount, Val NumberOfFirstItemsToProcess)

	If AccumulatedAmount <> 0 And ArrayOfCombinations.Find(AccumulatedAmount) = Undefined Then
		ArrayOfCombinations.Add(AccumulatedAmount);		
	EndIf;
	
	For Position = StartPosition To NumberOfFirstItemsToProcess - 1 Do
		ToSupplementArrayOfNumbersWithCombinationsOfSumsOfItsElements(ArrayOfCombinations, Position + 1, AccumulatedAmount + ArrayOfCombinations[Position], NumberOfFirstItemsToProcess);
	EndDo;
	
EndProcedure


#EndRegion
