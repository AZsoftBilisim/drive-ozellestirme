#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ARAPAccounting

// Creates and fills in/deletes elements of the Calculation Objects directory before writing the associated object.
// For payment documents, the creation takes place earlier, in the method of mutual settlement Server.Check to fill in the payment decryption.
//
// Parameters:
// 	Object - CatalogObject, DocumentObject - the object being recorded.
// 	StructuresArray - Array of See ARAPAccountingServer.MechanismParameters - Array of structures for settlement parameters.
// 	WriteMode - DocumentWriteMode - Write mode if the method is called from a pre-Write event.
// 	Cancel - Boolean - The Bounce from object flag.
//
Procedure CheckCalculationObjectsBeforeRecording(Object, StructuresArray, WriteMode, Cancel) Export
	
	// Clearing an object from references to calculation objects.
	If WriteMode = DocumentWriteMode.UndoPosting Then
		ClearCalculationObjects(Object, StructuresArray);
	EndIf;
	
	ArrayOfDecryptionObjects = New Array();
	TableOfParties = TableOfParties(Object, StructuresArray);
	Ref = TMCommonUseClientServer.DataAlongWay(Object, "Object.Ref");
	
	For Each ParametersStructure In StructuresArray Do
		
		If ParametersStructure.Property("RefToNew") Then
			Ref = ParametersStructure.RefToNew;
		EndIf;
		
		//Creating directory elements
		ARAPObject = Undefined;
		If ReferenceIsObjectOfCalculations(Object, ParametersStructure) Then
			ARAPObject = CheckFillInCalculationObjectByStructure(Object, ParametersStructure,,WriteMode);
		EndIf;
		
		//Filling out the payment transcript
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption)
			And ParametersStructure.ChangesCalculations Then
			
			DocumentAmounts        = ARAPAccountingInternal.DocumentAmounts(Object, ParametersStructure);
			
			//The document is multicurrency, we do not check the decryption.
			If DocumentAmounts.AmountOfDocumentWithoutCollateral = Undefined Then
				Return;
			EndIf;
			
			ARAPDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption); // TabularSection
			CommonClientServer.SupplementArray(ArrayOfDecryptionObjects, ARAPDetails.Unload().UnloadColumn("ARAPObject"));
			
			Currency                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentCurrency);
			Date                  = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
			OrderBase        = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
			Contract               = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
			ARAPObjectSettings       = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
			Organization           = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
			PaymentType_           = ParametersStructure.PaymentType_;
			
			//In the return documents, the Settlement Procedure is not cached and is derived from the contract.
			If ARAPObjectSettings = Undefined Then
				Contract = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
				If ValueIsFilled(Contract) Then
					ARAPObjectSettings = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings")
				EndIf;
			EndIf;
			
			If ParametersStructure.IsItPaymentOrOtherDocument
				And Metadata.DefinedTypes.ARAPObjectPrepayment.Type.ContainsType(TypeOf(Ref))
				And WriteMode = DocumentWriteMode.UndoPosting Then
				// When canceling the transaction, we delete the AR/AP object of the payment.
				TableOfParties.Clear();
				
			ElsIf ParametersStructure.IsItPaymentOrOtherDocument
				And Metadata.DefinedTypes.ARAPObjectPrepayment.Type.ContainsType(TypeOf(Ref)) Then
				
				LinesWithEmptyObject = ARAPDetails.Unload(New Structure("ARAPObject",Catalogs.ARAPObjects.EmptyRef()));
				ArrayOfSettlementCurrencies = LinesWithEmptyObject.UnloadColumn("ARAPCurrency");
				ArrayOfSettlementCurrencies = CommonClientServer.CollapseArray(ArrayOfSettlementCurrencies);
				If ArrayOfSettlementCurrencies.Count() > 1 Then
					ErrorText = NStr("vi = 'Cấm chỉ ra tiền tệ hạch toán công nợ khác nhau đối với khoản thanh toán chưa phân bổ.';
									|ru = 'Запрещено указывать разные валюты взаиморасчетов для неразнесенного платежа.';
									|en = 'You cannot specify different settlement currencies for an undistributed payment.'; fa = 'You cannot specify different settlement currencies for an undistributed payment.';
									|it = 'Vietato indicare valute dei conti reciproci diverse per il pagamento non pubblicato.';
									|pl = 'Jest zabronione podawanie różnych walut rozliczeń wzajemnych dla nieplanowanej płatności.';
									|tr = 'Dağıtılmayan ödeme için farklı mutabakat para birimleri belirtmek yasaktır.'");
					Common.MessageToUser(ErrorText,,,,Cancel);
				EndIf;
				
				ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(
					Currency,
					Date,
					ARAPDetails,
					Organization);
				
				FillInVATRate = ARAPDetails.Count() > 0 
					And CommonClientServer.HasAttributeOrObjectProperty(ARAPDetails[0], "VATRate");
				VATRate = Catalogs.VATRates.EmptyRef();
				
				If LinesWithEmptyObject.Count() > 0 And ValueIsFilled(OrderBase) And ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders Then
					ARAPObject = GetCalculationObjectFromLink(OrderBase, Organization, PaymentType_);
					If FillInVATRate Then
						VATRate = CashServer.VATRateOfSettlementObject(Organization, ARAPObject, PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
					EndIf;
					
					CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
					RowsToProcess = New Array();
					
					For Each DecryptionString In ARAPDetails Do
						If Not ValueIsFilled(DecryptionString.ARAPObject) Then
							DecryptionString.ARAPObject = ARAPObject;
							If FillInVATRate And ValueIsFilled(VATRate) Then
								DecryptionString.VATRate = VATRate;
								RowsToProcess.Add(DecryptionString);
							EndIf;
						EndIf;
					EndDo;
					
					StructureOfRecalculationOfAmount = New Structure("PriceIncludesVAT", True);
					StructureOfActions = New Structure("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					
					BatchProcessingOfTablePartServer.ProcessTSStrings(
						RowsToProcess,
						StructureOfActions,
						ARAPDetails,
						CachedValues);
					
				ElsIf LinesWithEmptyObject.Count() > 0 And ValueIsFilled(Contract) And ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
					ARAPObject = GetCalculationObjectFromLink(Contract, Organization, PaymentType_);
					If FillInVATRate Then
						VATRate = CashServer.VATRateOfSettlementObject(Organization, ARAPObject, PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
					EndIf;
					
					CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
					RowsToProcess = New Array();
					
					For Each DecryptionString In ARAPDetails Do
						If Not ValueIsFilled(DecryptionString.ARAPObject) Then
							DecryptionString.ARAPObject = ARAPObject;
							If FillInVATRate And ValueIsFilled(VATRate) Then
								DecryptionString.VATRate = VATRate;
								RowsToProcess.Add(DecryptionString);
							EndIf;
						EndIf;
					EndDo;
					
					StructureOfRecalculationOfAmount = New Structure("PriceIncludesVAT", True);
					StructureOfActions = New Structure("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					BatchProcessingOfTablePartServer.ProcessTSStrings(
						RowsToProcess,
						StructureOfActions,
						ARAPDetails,
						CachedValues);
						
				Else
					ARAPObjects = CheckFillInCalculationObjectByStructure(Object, ParametersStructure, True, WriteMode);
					
					TheStructureOfTheSearch = New Structure;
					TheStructureOfTheSearch.Insert("Organization");
					TheStructureOfTheSearch.Insert("Counterparty");TheStructureOfTheSearch.Insert("Partner");
					
					CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
					RowsToProcess = New Array();
					
					For Each DecryptionString In ARAPDetails Do
						If Not ValueIsFilled(DecryptionString.ARAPObject)
							And ARAPObjects.Count() > 0 Then
							
							If TypeOf(Object) = Type("ClientApplicationForm") Then
								Id = DecryptionString.GetID();
							Else
								Id = DecryptionString.LineNumber;
							EndIf;
							
							If ParametersStructure.OrganizationInRows Then
								TheStructureOfTheSearch.Organization = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization, Id);
							Else
								TheStructureOfTheSearch.Organization = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
							EndIf;
							
							If ParametersStructure.CounterpartyInLines Then
								TheStructureOfTheSearch.Counterparty = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Counterparty, Id);
							Else
								TheStructureOfTheSearch.Counterparty = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Counterparty);
							EndIf;
							
							If ParametersStructure.PartnerInRows Then
								TheStructureOfTheSearch.Partner = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Partner, Id);
							Else
								TheStructureOfTheSearch.Partner = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Partner);
							EndIf;
							
							DecryptionString.ARAPObject = ARAPObjects.FindRows(TheStructureOfTheSearch)[0].ARAPObject;
							If FillInVATRate
								And Not ValueIsFilled(DecryptionString.VATRate) Then
								VATRate = CashServer.VATRateOfSettlementObject(Organization, DecryptionString.ARAPObject, PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
								If ValueIsFilled(VATRate) Then
									DecryptionString.VATRate = VATRate;
									RowsToProcess.Add(DecryptionString);
								EndIf;
							EndIf;
						EndIf;
					EndDo;
					
					StructureOfRecalculationOfAmount = New Structure("PriceIncludesVAT", True);
					StructureOfActions = New Structure("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					BatchProcessingOfTablePartServer.ProcessTSStrings(
						RowsToProcess,
						StructureOfActions,
						ARAPDetails,
						CachedValues);
				EndIf;
				
			ElsIf ParametersStructure.ThisIsSalePurchase And ValueIsFilled(ARAPObject) Then
				
				DocumentAmount        = DocumentAmounts.PackageDepositValue + DocumentAmounts.AmountOfDocumentWithoutCollateral;
				AmountARAP   = DocumentAmounts.AmountOfSettlementsWithoutCollateral + DocumentAmounts.AmountARAPByPackage;
				ARAPAccountingServer.FillInAmountOfInvoiceDecryption(DocumentAmount, AmountARAP, ARAPDetails, ARAPObject);
				
			EndIf;
		EndIf;
		
		If ParametersStructure.Organization = Catalogs.Companies.ManagementCompany Then
			ArrayOfDecryptionObjects.Add(TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObject));
		EndIf;
		
	EndDo;
	
	// Removing unnecessary elements of the directory.
	Query = New Query("
	|SELECT
	|	TableOfParties.Organization AS Organization,
	|	TableOfParties.Counterparty  AS Counterparty,
	|	TableOfParties.Partner     AS Partner,
	|	TableOfParties.ARAPCurrency AS ARAPCurrency,
	|	TableOfParties.PaymentType_ AS PaymentType_
	|INTO TableOfParties
	|FROM &TableOfParties AS TableOfParties
	|;
	|SELECT
	|	ARAPObjects.Ref AS Ref,
	|	ARAPObjects.OnlyBalance AS OnlyBalance
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN TableOfParties AS TableOfParties
	|			ON TableOfParties.Organization = ARAPObjects.Organization
	|				AND TableOfParties.PaymentType_ = ARAPObjects.PaymentType_
	|				AND TableOfParties.Counterparty = ARAPObjects.Counterparty
	|				AND TableOfParties.Partner = ARAPObjects.Partner
	|				AND TableOfParties.ARAPCurrency = ARAPObjects.ARAPCurrency
	|				AND NOT ARAPObjects.OnlyBalance
	|WHERE
	|	ARAPObjects.Object = &Ref
	|	AND TableOfParties.PaymentType_ IS NULL
	|	AND ARAPObjects.Ref NOT IN (&ArrayOfDecryptionObjects)");
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("TableOfParties", TableOfParties);
	Query.SetParameter("ArrayOfDecryptionObjects", ArrayOfDecryptionObjects);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ARAPObjects");
		LockItem.Mode = DataLockMode.Shared;
		LockItem.SetValue("Ref", Selection.Ref);
		Block.Lock();
		
		CheckDeleteCalculationObject(Selection.Ref, Cancel, Not Selection.OnlyBalance);
	EndDo;
	
	//Filling calculation objects into an Object
	If Not Cancel And WriteMode <> DocumentWriteMode.UndoPosting Then
		FillInClearARAPObject(Object, StructuresArray, WriteMode);
	EndIf;
	
EndProcedure

// Creates, refills, if necessary, and returns a reference to the settlement object based on the parameters of the settlement mechanism.
// If several object elements were created within the same structure, it returns the first one.
// 
// Parameters:
// 	Object - DocumentObject, CatalogObject - The object that the calculation object is checked by reference to.
// 	ParametersStructure - Structure - The current set of parameters. See ARAPAccountingServer.MechanismParameters.
// 	ReturnAllObjects - Boolean - Return a single calculation object or a table of all calculation objects.
// 	WriteMode - DocumentWriteMode - Write mode if the method is called from a pre-Write event.
// 	
// Returns:
// 	CatalogRef.ARAPObjects - Reference to the calculation object.
//
Function CheckFillInCalculationObjectByStructure(Object, ParametersStructure, ReturnAllObjects = False, WriteMode = Undefined) Export
	
	If ParametersStructure.Property("RefToNew") Then
		Ref = ParametersStructure.RefToNew;
	Else
		Ref = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Ref);
	EndIf;
	
	OrganizationInRows = ParametersStructure.OrganizationInRows And TypeOf(ParametersStructure.Organization) = Type("String");
	CounterpartyInLines  = ParametersStructure.CounterpartyInLines And TypeOf(ParametersStructure.Counterparty) = Type("String");
	
	TableOfParties = TableOfParties(Object, ParametersStructure);
	TableOfParties.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	
	AmountARAP = 0;
	If ParametersStructure.IsItPaymentOrOtherDocument  And ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
		TabularSection = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption); // TabularSection
		For Each Page1 In TabularSection Do
			If CommonClientServer.HasAttributeOrObjectProperty(Page1, "AmountARAP") Then
				AmountARAP = AmountARAP + Page1.AmountARAP;
			EndIf;
		EndDo;
	EndIf;
	
	For Each Page1 In TableOfParties Do
		
		CalculationObjectParameters_ = DetailsOfObjectOfCalculationsByStructure(Object, Ref, ParametersStructure, WriteMode);
		
		//Key details.
		CalculationObjectParameters_.Organization = Page1.Organization;
		CalculationObjectParameters_.Counterparty = Page1.Counterparty;
		CalculationObjectParameters_.Partner =  Page1.Partner;
		
		If ValueIsFilled(Page1.ARAPCurrency) Or TypeOf(CalculationObjectParameters_.ARAPCurrency) = Type("Array") Then
			CalculationObjectParameters_.ARAPCurrency = Page1.ARAPCurrency;
		EndIf;
		If AmountARAP > 0 Then
			CalculationObjectParameters_.AmountARAP = AmountARAP;
		EndIf;
		
		AdditionalAttributes = ?(Object.Metadata().TabularSections.Find("AdditionalAttributes") <> Undefined,
									Object.AdditionalAttributes.Unload(),
									Undefined);
		
		IBUpdate = ParametersStructure.Property("OnlyBalance") And ParametersStructure.OnlyBalance;
		
		ThereAreChangesInCalculationObject = False;
		If ValueIsFilled(CalculationObjectParameters_.Organization)
			And ValueIsFilled(CalculationObjectParameters_.Counterparty)
			And ValueIsFilled(CalculationObjectParameters_.Partner)
			And ValueIsFilled(CalculationObjectParameters_.ARAPCurrency) Then
			Page1.ARAPObject = CheckCreateCalculationObject(CalculationObjectParameters_, AdditionalAttributes, IBUpdate, ThereAreChangesInCalculationObject);
		EndIf;
		If ThereAreChangesInCalculationObject Then
			Object.AdditionalProperties.Insert("NotifyAboutChangesToPaymentObject", True);
			Object.AdditionalProperties.Insert("ModifiedCalculationObject", Page1.ARAPObject);
		EndIf;
		
	EndDo;
	
	If ReturnAllObjects Then
		If OrganizationInRows And CounterpartyInLines Then
			TableOfParties.Indexes.Add("Organization, Counterparty");
		ElsIf OrganizationInRows Then
			TableOfParties.Indexes.Add("Organization");
		Else
			TableOfParties.Indexes.Add("Counterparty");
		EndIf;
		
		Return TableOfParties;
	ElsIf TableOfParties.Count() > 0 Then
		Return TableOfParties[0].ARAPObject;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Creates, refills, if necessary, and returns a reference to the settlement object based on the parameters of the settlement mechanism.
// If several object elements were created within the same structure, it returns the first one.
// 
// Parameters:
// 	Object - DocumentObject, CatalogObject - The object that the calculation object is checked by reference to.
// 	Ref - DocumentRef, CatalogRef - object reference.
// 	ParametersStructure - Structure - The current set of parameters. See ARAPAccountingServer.MechanismParameters.
// 	WriteMode - DocumentWriteMode - Write mode if the method is called from a pre-Write event.
// 	
// Returns:
// 	Structure - The structure of the parameters, where:
// 		* Object - DefinedType.ARAPObject
// 		* PaymentType_ - EnumRef.PartnersARAPAccountingTypes
// 		* Organization - CatalogRef.Companies
// 		* Counterparty - CatalogRef.Counterparties
// 		* Partner - CatalogRef.Partners
// 		* Description - String
// 		* RefType - See Common.MetadataObjectID
// 		* DeletionMark - Boolean
// 		* FinancialAccountingGroup - CatalogRef.FinancialAccountingGroupsOfARAP
// 		* Manager - CatalogRef.Users
// 		* Department - CatalogRef.BusinessStructure 
// 		* PaymentID - String 
// 		* VATTaxation - EnumRef.VATTaxationTypes 
// 		* IncomingDocumentNumber - String
// 		* IncomingDocumentDate - Date
// 		* SourceDocumentName - String
// 		* Sum - Number
// 		* Currency - CatalogRef.Currencies 
// 		* ARAPCurrency - CatalogRef.Currencies 
// 		* AmountARAP - Number 
// 		* Contract - CatalogRef.CounterpartyContracts
// 		          - CatalogRef.IntercompanyContracts
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness 
// 		* ForeignCurrencyTransaction - Boolean
// 		* Number - String
// 		* Date-  Date
// 		* Comment - String 
// 		* CompanyBankAccount - CatalogRef.CompaniesBankAccounts 
// 		* CounterpartyBankAccount - CatalogRef.CounterpartyBankAccounts
// 		* CashAccount - CatalogRef.CashAccounts 
// 		* PaymentMethod - EnumRef.PaymentForms
// 		* OnlyBalance - Boolean
// 		* IsInternal - Boolean
//
Function DetailsOfObjectOfCalculationsByStructure(Object, Ref, ParametersStructure, WriteMode) Export
	
	IsDocument = Documents.AllRefsType().ContainsType(TypeOf(Ref));
	
	CalculationObjectParameters_ = New Structure;
	
	//Key details.
	If ParametersStructure.Property("RefToNew") Then
		CalculationObjectParameters_.Insert("Object", ParametersStructure.RefToNew);
	Else
		CalculationObjectParameters_.Insert("Object", Ref);
	EndIf;
	CalculationObjectParameters_.Insert("PaymentType_", ParametersStructure.PaymentType_);
	CalculationObjectParameters_.Insert("Organization", TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization, ,Catalogs.Companies.EmptyRef()));
	CalculationObjectParameters_.Insert("Counterparty",  TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Counterparty, ,Catalogs.Counterparties.EmptyRef()));
	CalculationObjectParameters_.Insert("Partner",     TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Partner, ,Catalogs.Partners.EmptyRef()));
	
	//Service details.
	CalculationObjectParameters_.Insert("Description", ?(String(Object)="",NStr("vi = '<Trống>';
																				|ru = '<Пустой>';
																				|en = '<Empty>'; fa = '<Empty>';
																				|it = '<Vuoto>';
																				|pl = '<Empty>';
																				|tr = '<Boş>'"),String(Object)));
	
	CalculationObjectParameters_.Insert("RefType", Common.MetadataObjectID(TypeOf(Ref)));
	DeletionMark = TMCommonUseClientServer.DataAlongWay(Object,"Object.DeletionMark");
	CalculationObjectParameters_.Insert("DeletionMark", DeletionMark);
	
	If WriteMode = DocumentWriteMode.Posting Then
		State = 1;
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		State = ?(CalculationObjectParameters_.DeletionMark,2,0);
	Else
		If IsDocument Then
			State = ?(TMCommonUseClientServer.DataAlongWay(Object,"Object.Posted"),1,?(CalculationObjectParameters_.DeletionMark,2,0));
		Else
			State = ?(CalculationObjectParameters_.DeletionMark,2,0);
		EndIf;
	EndIf;
	
	CalculationObjectParameters_.Insert("State", State);
	
	If ParametersStructure.IsCatalog Then
		ARAPObjectType = Enums.ARAPObjectTypes.Contract;
	ElsIf ParametersStructure.ThisIsOrder Then
		ARAPObjectType = Enums.ARAPObjectTypes.OrderDocument;
	ElsIf ParametersStructure.ThisIsSalePurchase Then
		ARAPObjectType = Enums.ARAPObjectTypes.Invoice;
	Else
		ARAPObjectType = Enums.ARAPObjectTypes.PaymentReturn;
	EndIf;
	CalculationObjectParameters_.Insert("ARAPObjectType", ARAPObjectType);
	
	ARAPCurrency = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPCurrency,,Catalogs.Currencies.EmptyRef());
	
	DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object, ParametersStructure);
	DocumentAmount = DocumentAmounts.DocumentAmount;
	AmountARAP = DocumentAmounts.AmountARAP;
	
	CalculationObjectParameters_.Insert("FinancialAccountingGroup", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.FinancialAccountingGroup,,Catalogs.FinancialAccountingGroupsOfARAP.EmptyRef()));
	CalculationObjectParameters_.Insert("Manager",
		TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.Manager,, Catalogs.Users.EmptyRef()));
	CalculationObjectParameters_.Insert("Department", 
		TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.Department,,Catalogs.BusinessStructure.EmptyRef()));
	CalculationObjectParameters_.Insert("PaymentID", 
		TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.PaymentID,,""));
	CalculationObjectParameters_.Insert("VATTaxation", 
		TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.VATTaxation,,Enums.VATTaxationTypes.EmptyRef()));
	CalculationObjectParameters_.Insert("IncomingDocumentNumber",
		TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.IncomingDocumentNumber,,""));
	CalculationObjectParameters_.Insert("IncomingDocumentDate",
		TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.IncomingDocumentDate,,Date(1,1,1)));
	CalculationObjectParameters_.Insert("SourceDocumentName",
		TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.SourceDocumentName,,""));
	CalculationObjectParameters_.Insert("Sum",
		DocumentAmount);
	CalculationObjectParameters_.Insert("Currency", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentCurrency,,Catalogs.Currencies.EmptyRef()));
	CalculationObjectParameters_.Insert("ARAPCurrency", 
		?(ValueIsFilled(ARAPCurrency),ARAPCurrency,CalculationObjectParameters_.Currency));
	CalculationObjectParameters_.Insert("AmountARAP", 
		AmountARAP);
	CalculationObjectParameters_.Insert("Contract", 
		?(ParametersStructure.IsCatalog 
			And (TypeOf(Ref) = Type("CatalogRef.CounterpartyContracts")
				Or TypeOf(Ref) = Type("CatalogRef.IntercompanyContracts")), 
			Ref, 
			TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract,, Undefined)));
	LineOfBusiness = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.LineOfBusiness,, Catalogs.LinesOfBusiness.EmptyRef());
	If ValueIsFilled(LineOfBusiness) Then
		AttributeValuesOfLB = Common.ObjectAttributesValues(LineOfBusiness, "IncomeAccounting,VendorARAP");
		If ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting And Not AttributeValuesOfLB.IncomeAccounting
			Or ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting And Not AttributeValuesOfLB.VendorARAP Then
				LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		EndIf;
	EndIf;
	CalculationObjectParameters_.Insert("LineOfBusiness", LineOfBusiness);
	CalculationObjectParameters_.Insert("ForeignCurrencyTransaction", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ForeignCurrencyTransaction,, False));
	CalculationObjectParameters_.Insert("Number", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Number, ,""));
	CalculationObjectParameters_.Insert("Date", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date, ,Date(1,1,1)));
	CalculationObjectParameters_.Insert("Comment", 
		TMCommonUseClientServer.DataAlongWay(Object, "Object.Comment", ,""));
	CalculationObjectParameters_.Insert("CompanyBankAccount", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CompanyBankAccount,,Catalogs.CompaniesBankAccounts));
	CalculationObjectParameters_.Insert("CounterpartyBankAccount", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CounterpartyBankAccount,,Catalogs.CounterpartyBankAccounts.EmptyRef()));
	CalculationObjectParameters_.Insert("CashAccount", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CashAccount,,Catalogs.CashAccounts.EmptyRef()));
	CalculationObjectParameters_.Insert("PaymentMethod", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PaymentMethod,, Enums.PaymentForms.EmptyRef()));
		
	EmptyAgreement = ?(ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, 
		Catalogs.TermsOfSale.EmptyRef(),
		Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	CalculationObjectParameters_.Insert("Terms", 
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Terms,,EmptyAgreement));
		
	CalculationObjectParameters_.Insert("OnlyBalance", ParametersStructure.OnlyBalance);
	CalculationObjectParameters_.Insert("IsInternal", ParametersStructure.ARAPObjectInternal);
	
	If ParametersStructure.OperationWithSelfEmployedPerson = False
		And TypeOf(CalculationObjectParameters_.Object) = Type("DocumentRef.SourceDocument")
		And ValueIsFilled(CalculationObjectParameters_.Contract)
		And CommonClientServer.HasAttributeOrObjectProperty(CalculationObjectParameters_.Contract, "ContractWithSelfEmployedPerson") Then
		ParametersStructure.OperationWithSelfEmployedPerson = Common.ObjectAttributeValue(CalculationObjectParameters_.Contract, "ContractWithSelfEmployedPerson");
	EndIf;
	
	CalculationObjectParameters_.Insert("OperationWithSelfEmployedPerson",
		TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OperationWithSelfEmployedPerson, , False));
	
	If ARAPObjectType = Enums.ARAPObjectTypes.Contract
			And CommonClientServer.HasAttributeOrObjectProperty(Object,"ARAPObjectSettings")
			And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
		Or ARAPObjectType = Enums.ARAPObjectTypes.OrderDocument
			And CommonClientServer.HasAttributeOrObjectProperty(Object,"ARAPObjectSettings")
			And Object.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice Then
		ControlPrepaymentBalance = True;
	Else
		ControlPrepaymentBalance = False;
	EndIf;
	
	CalculationObjectParameters_.Insert("ControlPrepaymentBalance", ControlPrepaymentBalance);
	
	Return CalculationObjectParameters_;
	
EndFunction

#EndRegion

#Region Shared

// Returns a reference to an existing calculation object.
// Payments with different partners and counterparties are not supported.
// 
// Parameters: 
// 	Ref - DocumentRef, CatalogRef - a reference to the source object.
// 	Organization - CatalogRef.Companies - Organization.
// 	PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Calculation type of the calculation object.
// 	AdditionalSearchCriteria_1 - See ARAPObjectsServer.AdditionalSearchCriteria_1.
// 
// Returns: 
// 	CatalogRef.ARAPObjects - Reference to the calculation object.
//
Function GetCalculationObjectFromLink(Ref, Organization = Undefined, PaymentType_ = Undefined, AdditionalSearchCriteria_1 = Undefined) Export
	
	If Not ValueIsFilled(Ref) Then
		Return Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	
	Array = New Array;
	Array.Add(Ref);
	
	If AdditionalSearchCriteria_1 = Undefined Then
		AdditionalSearchCriteria_1 = AdditionalSearchCriteria_1();
		AdditionalSearchCriteria_1.ReturnFirstOne = True;
	EndIf;
	
	Return GetCalculationObjectsFromLinks(Array, Organization, PaymentType_, AdditionalSearchCriteria_1)[Ref];
	
EndFunction

// Returns the corresponding references to the existing objects of calculations.
// 
// Parameters: 
// 	ReferencesArrray - Array of DocumentRef, CatalogRef - An array of references to the original objects.
// 	Organization - CatalogRef.Companies - Who the organization is.
// 	PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of calculations for calculation objects.
// 	AdditionalSearchCriteria_1 - See ARAPObjectsServer.AdditionalSearchCriteria_1.
// 
// Returns: 
// 	Map of KeyAndValue:
// 		* Key - DocumentRef, CatalogRef - the original link.
// 		* Value - CatalogRef.ARAPObjects - Reference to the calculation object.
//
Function GetCalculationObjectsFromLinks(ReferencesArrray, Organization = Undefined, PaymentType_ = Undefined, AdditionalSearchCriteria_1 = Undefined) Export
	
	If AdditionalSearchCriteria_1 = Undefined Then
		AdditionalSearchCriteria_1 = AdditionalSearchCriteria_1();
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ARAPObjects.Object AS Object,
	|	ARAPObjects.Ref AS Ref,
	|	ARAPObjects.OnlyBalance AS OnlyBalance,
	|	ARAPObjects.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|	ON ARAPObjects.Object = Contracts.Ref
	|WHERE
	|	ARAPObjects.Object IN (&ReferencesArrray)
	|	AND (ARAPObjects.Organization = &Organization OR &AnyOrganization)
	|	AND (ARAPObjects.PaymentType_ = &PaymentType_ OR &AnyType)
	|	AND (CASE WHEN &ItIsSubsidiaryPartner
	|			AND VALUETYPE(ARAPObjects.Object) = TYPE(Catalog.CounterpartyContracts) AND ISNULL(Contracts.ItIsAllowedToWorkWithSubsidiaryPartners, FALSE)
	|		THEN
	|			Contracts.Partner
	|		ELSE
	|			&Partner
	|	END = ARAPObjects.Partner OR &AnyPartner)
	|	AND (ARAPObjects.Counterparty = &Counterparty OR &AnyCounterparty)
	|	AND &ARAPCurrency
	|	AND &ConditionOnlyRemains";
	
	Query.SetParameter("ReferencesArrray",     ReferencesArrray);
	Query.SetParameter("Organization",      Organization);
	Query.SetParameter("PaymentType_",      PaymentType_);
	Query.SetParameter("Partner",          AdditionalSearchCriteria_1.Partner);
	Query.SetParameter("ItIsSubsidiaryPartner", False);
	If ValueIsFilled(AdditionalSearchCriteria_1.Partner) Then
		Query.SetParameter("ItIsSubsidiaryPartner",  
			ValueIsFilled(Common.ObjectAttributeValue(AdditionalSearchCriteria_1.Partner, "Parent")));
	EndIf;
	Query.SetParameter("Counterparty",       AdditionalSearchCriteria_1.Counterparty);
	Query.SetParameter("ARAPCurrency", AdditionalSearchCriteria_1.ARAPCurrency);
	Query.SetParameter("IBUpdate",     AdditionalSearchCriteria_1.IBUpdate);
	Query.SetParameter("AnyOrganization", ?(Organization = Undefined, True, False));
	Query.SetParameter("AnyType",         ?(PaymentType_ = Undefined, True, False));
	Query.SetParameter("AnyPartner",     ?(AdditionalSearchCriteria_1.Partner     = Undefined, True, False));
	Query.SetParameter("AnyCounterparty",  ?(AdditionalSearchCriteria_1.Counterparty  = Undefined, True, False));
	
	If AdditionalSearchCriteria_1.Property("OnlyBalance") Then
		Query.Text = StrReplace(Query.Text,"&ConditionOnlyRemains", "ARAPObjects.OnlyBalance = &OnlyBalance");
		Query.SetParameter("OnlyBalance", AdditionalSearchCriteria_1.OnlyBalance);
	Else
		Query.Text = StrReplace(Query.Text,"&ConditionOnlyRemains", "TRUE");
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&ARAPCurrency", 
		?(AdditionalSearchCriteria_1.IBUpdate 
			And ValueIsFilled(AdditionalSearchCriteria_1.ARAPCurrency), 
			"ARAPObjects.ARAPCurrency = &ARAPCurrency", 
			"TRUE"));
	
	SetPrivilegedMode(True);
	ARAPObjects = Query.Execute().Unload();
	ARAPObjects.Indexes.Add("Object");
	
	Result = New Map;
	For Each Ref In ReferencesArrray Do
		ObjectsStrings = ARAPObjects.Copy(New Structure("Object", Ref));
		If ObjectsStrings.Count() > 1 Then
			If AdditionalSearchCriteria_1.ReturnFirstOne Then
				ObjectsStrings.Sort("DeletionMark ASC, OnlyBalance ASC");
				Result.Insert(Ref, ObjectsStrings[0].Ref);
			Else
				Raise(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Theo %1 tìm thấy một số đối tượng thanh toán.';
						|ru = 'По %1 найдено несколько объектов расчетов.';
						|en = 'Multiple AR/AP objects were found for %1.'; fa = 'Multiple AR/AP objects were found for %1.';
						|it = 'Per %1 sono stati trovati più oggetti di regolamenti.';
						|pl = 'Dla %1 znaleziono kilka obiektów rozliczeń,';
						|tr = '%1 için birden çok alacak/borç nesnesi bulundu.'"),
					Ref));
			EndIf;
		ElsIf ObjectsStrings.Count() = 1 Then
			Result.Insert(Ref, ObjectsStrings[0].Ref);
		Else
			Result.Insert(Ref, Catalogs.ARAPObjects.EmptyRef());
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns all calculation objects by reference.
// 
// Parameters:
// 	Ref - DocumentRef - the object for which you need to find calculation Objects.
// Returns:
// 	Array of CatalogRef.ARAPObjects - Array of calculation objects.
//
Function AllObjectsAreCalculatedByReference(Ref) Export
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ARAPObjects.Ref AS Ref
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE 
	|	NOT ARAPObjects.DeletionMark 
	|	AND ARAPObjects.Object = &Ref";
	Query.SetParameter("Ref", Ref);
	ARAPObjects = Query.Execute().Unload().UnloadColumn("Ref");
	Return ARAPObjects;
EndFunction

// Returns the structure of additional software parameters for searching for default calculation objects
// 
// Returns:
// 	Structure - LongDesc:
// 		* IBUpdate - Boolean - A sign indicating that it should search among the objects of incorrect calculations
// 		* ReturnFirstOne - Boolean - Flag indicating that the first object found should be returned.
// 		* Partner - Undefined, CatalogRef.Partners - Search value for the Partner field
// 		* ARAPCurrency - Undefined, CatalogRef.Currencies - Search value for the Partner field
// 		* Counterparty - Undefined, CatalogRef.Counterparties - The value of the search field, the Counterparty
Function AdditionalSearchCriteria_1() Export
	
	SearchCriteriaForCalculationObject = New Structure();
	SearchCriteriaForCalculationObject.Insert("Counterparty", Undefined);
	SearchCriteriaForCalculationObject.Insert("Partner", Undefined);
	SearchCriteriaForCalculationObject.Insert("ARAPCurrency", Undefined);
	SearchCriteriaForCalculationObject.Insert("IBUpdate", False);
	SearchCriteriaForCalculationObject.Insert("ReturnFirstOne", False);
	
	Return SearchCriteriaForCalculationObject;
	
EndFunction

// Creates, refills, if necessary, and returns a reference to the calculation object based on the passed details structure.
// 
// Parameters:
// 	ObjectAttributes - Structure - The current set of details of the object calculations.
// 	AdditionalSourceDetails - ValueTable - Table of additional properties and their values for the source object.
// 	IBUpdate - Boolean - Indicates whether the information database is being updated.
// 	HasChanges - Boolean - A variable passed to the procedure to mark the presence of changes in the calculation object
// 
// Returns:
// 	CatalogRef.ARAPObjects - Reference to the calculation object.
//
Function CheckCreateCalculationObject(ObjectAttributes, AdditionalSourceDetails = Undefined, IBUpdate = False, HasChanges = False) Export
	
	If Not ValueIsFilled(ObjectAttributes.Object) Then
		Raise(NStr("vi = 'Không thể tạo đối tượng giải quyết. Các thông số cần thiết không được chỉ định.';
					|ru = 'Невозможно создать объект расчетов. Не указаны обязательные параметры.';
					|en = 'Cannot create AR/AP object. Required parameters are missing.'; fa = 'Cannot create AR/AP object. Required parameters are missing.';
					|it = 'Impossibile creare oggetto di regolamenti. Parametri obbligatori non indicati.';
					|pl = 'Niemożliwe jest utworzenie obiektu rozliczeń. Nie podano niezbędnych parametrów.';
					|tr = 'Bir alacak/borç nesnesi oluşturulamıyor. Hiçbir gerekli parametre belirtilmedi.'"))
	EndIf;
	
	If TypeOf(ObjectAttributes.Counterparty) = Type("CatalogRef.Companies")
		And (ObjectAttributes.Contract = Undefined
			Or TypeOf(ObjectAttributes.Contract) <> Type("CatalogRef.IntercompanyContracts")) Then
		ObjectAttributes.Contract = Catalogs.IntercompanyContracts.EmptyRef();
	ElsIf TypeOf(ObjectAttributes.Counterparty) <> Type("CatalogRef.Companies")
		And (ObjectAttributes.Contract = Undefined
			Or TypeOf(ObjectAttributes.Contract) <> Type("CatalogRef.CounterpartyContracts")) Then
		ObjectAttributes.Contract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	CatalogAttributes = DetailsOfSettlementObjectsCatalog();
	
	Query = New Query;
	Query.Text = "
	|SELECT *
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Object = &Object
	|	AND ARAPObjects.Organization = &Organization
	|	AND ARAPObjects.Counterparty = &Counterparty
	|	AND ARAPObjects.Partner = &Partner
	|	AND ARAPObjects.PaymentType_ = &PaymentType_
	|	AND &ARAPCurrency";
	Query.SetParameter("Object", ObjectAttributes.Object);
	Query.SetParameter("Organization", ObjectAttributes.Organization);
	Query.SetParameter("Counterparty", ObjectAttributes.Counterparty);
	Query.SetParameter("Partner", ObjectAttributes.Partner);
	Query.SetParameter("PaymentType_", ObjectAttributes.PaymentType_);
	Query.Text = StrReplace(Query.Text, "&ARAPCurrency", 
		?(ValueIsFilled(ObjectAttributes.ARAPCurrency), "ARAPObjects.ARAPCurrency = &ARAPCurrency" , "TRUE"));
	Query.SetParameter("ARAPCurrency", ObjectAttributes.ARAPCurrency);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		RequiredReFilling = False;
		
		For Each Attribute In CatalogAttributes Do
			If ObjectAttributes.Property(Attribute) And Selection[Attribute] <> ObjectAttributes[Attribute] Then
				RequiredReFilling = True;
			EndIf;
		EndDo;
		
		If AdditionalSourceDetails <> Undefined Then
			AdditionalDetailsOfSettlementObject = Selection.AdditionalAttributes.Unload(); // ValueTable -
			AdditionalDetailsOfSettlementObject.Indexes.Add("Property");
			For Each Attribute In AdditionalSourceDetails Do
				If PropertyManager.CheckObjectProperty(Selection.Ref,Attribute.Property) Then
					AdditionalPropsLine = AdditionalDetailsOfSettlementObject.Find(Attribute.Property);
					If AdditionalPropsLine = Undefined
						Or AdditionalPropsLine.Value <> Attribute.Value Then
						RequiredReFilling = True;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
		If Selection.DeletionMark <> ObjectAttributes.DeletionMark Then
			RequiredReFilling = True;
		EndIf;
		
		If RequiredReFilling Then
			SetPrivilegedMode(True);
			CatalogObject = Selection.Ref.GetObject(); // CatalogObject -
			FillPropertyValues(CatalogObject, ObjectAttributes);
			
			If AdditionalSourceDetails <> Undefined Then
				For Each Attribute In AdditionalSourceDetails Do
					If PropertyManager.CheckObjectProperty(Selection.Ref,Attribute.Property) Then
						AdditionalPropsLine = AdditionalDetailsOfSettlementObject.Find(Attribute.Property);
						If AdditionalPropsLine = Undefined Then
							AdditionalPropsLine = AdditionalDetailsOfSettlementObject.Add();
						EndIf;
						AdditionalPropsLine.Property = Attribute.Property;
						AdditionalPropsLine.Value = Attribute.Value;
						AdditionalPropsLine.TextString = Attribute.TextString;
					EndIf;
				EndDo;
				CatalogObject.AdditionalAttributes.Load(AdditionalDetailsOfSettlementObject);
			EndIf;
			
			CatalogObject.Write();
			SetPrivilegedMode(False);
			HasChanges = True;
			Return CatalogObject.Ref;
		EndIf;
		
		Return Selection.Ref;
		
	Else
		SetPrivilegedMode(True);
		CatalogObject = Catalogs.ARAPObjects.CreateItem();
		FillPropertyValues(CatalogObject, ObjectAttributes);
		CatalogObject.UUID = New UUID();
		
		If AdditionalSourceDetails <> Undefined Then
			For Each Attribute In AdditionalSourceDetails Do
				If PropertyManager.CheckObjectProperty(CatalogObject.Ref,Attribute.Property) Then
					AdditionalPropsLine = CatalogObject.AdditionalAttributes.Add();
					AdditionalPropsLine.Property = Attribute.Property;
					AdditionalPropsLine.Value = Attribute.Value;
					AdditionalPropsLine.TextString = Attribute.TextString;
				EndIf;
			EndDo;
		EndIf;
		
		CatalogObject.Write();
		SetPrivilegedMode(False);
		Return CatalogObject.Ref;
	EndIf;
	
EndFunction

// Checks for references in data objects to the passed calculation object. If there are no references, it deletes the object directly.
//
// Parameters:
// 	ARAPObject - CatalogRef.ARAPObjects - Reference to the calculation object.
// 	Cancel - Boolean - The flag of refusal from the object.
// 	RaiseException1 - Boolean - Whether to throw an exception if the calculation object cannot be deleted.
Procedure CheckDeleteCalculationObject(ARAPObject, Cancel, RaiseException1) Export
	
	If Not ValueIsFilled(ARAPObject)  Then
		Raise(NStr("vi = 'Không thể tạo đối tượng giải quyết. Các thông số cần thiết không được chỉ định.';
					|ru = 'Невозможно создать объект расчетов. Не указаны обязательные параметры.';
					|en = 'Cannot create AR/AP object. Required parameters are missing.'; fa = 'Cannot create AR/AP object. Required parameters are missing.';
					|it = 'Impossibile creare oggetto di regolamenti. Parametri obbligatori non indicati.';
					|pl = 'Niemożliwe jest utworzenie obiektu rozliczeń. Nie podano niezbędnych parametrów.';
					|tr = 'Bir alacak/borç nesnesi oluşturulamıyor. Hiçbir gerekli parametre belirtilmedi.'"))
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT TOP 100
	|	ARAPObject.Ref AS Ref
	|FROM
	|	FilterCriterion.ARAPObject(&ARAPObject) AS ARAPObject
	|WHERE
	|	ARAPObject.Ref <> &Ref
	|
	|;
	|SELECT DISTINCT TOP 100
	|	Calculations.Recorder AS Ref
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.Recorder <> &Ref
	|
	|UNION
	|
	|SELECT DISTINCT TOP 100
	|	Calculations.DocumentRecorder AS Ref
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.DocumentRecorder <> &Ref
	|	AND NOT Calculations.DocumentRecorder REFS Document.ExchangeDifferenceCalculation
	|
	|UNION
	|
	|SELECT DISTINCT TOP 100
	|	Calculations.Recorder AS Ref
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|WHERE
	|	Calculations.SalesOrder = &ARAPObject
	|	AND Calculations.Recorder <> &Ref
	|	AND NOT Calculations.Recorder REFS Document.ExchangeDifferenceCalculation
	|
	|UNION
	|
	|SELECT DISTINCT TOP 100
	|	Calculations.Recorder AS Ref
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.Recorder <> &Ref
	|
	|UNION
	|
	|SELECT DISTINCT TOP 100
	|	Calculations.DocumentRecorder AS Ref
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.ARAPObject = &ARAPObject
	|	AND Calculations.DocumentRecorder <> &Ref
	|	AND NOT Calculations.DocumentRecorder REFS Document.ExchangeDifferenceCalculation
	|
	|UNION
	|
	|SELECT DISTINCT TOP 100
	|	Calculations.Recorder AS Ref
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|WHERE
	|	Calculations.PurchaseOrder = &ARAPObject
	|	AND Calculations.Recorder <> &Ref
	|	AND NOT Calculations.Recorder REFS Document.ExchangeDifferenceCalculation
	|";
	Query.SetParameter("ARAPObject", ARAPObject);
	Query.SetParameter("Ref", Common.ObjectAttributeValue(ARAPObject, "Object"));
	
	SetPrivilegedMode(True);
	Results = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	ThereAreRefs = Not Results[0].IsEmpty();
	ThereAreRegisteredRecords = Not Results[1].IsEmpty();
	
	If Not ThereAreRefs And Not ThereAreRegisteredRecords Then
		SetPrivilegedMode(True);
		CalculationObjectObject = ARAPObject.GetObject();
		Try
			CalculationObjectObject.Lock();
		Except
			Raise(NStr("vi = 'Cấm thay đổi, đối tượng hạch toán đang được dùng trong các phiên làm việc khác.';
						|ru = 'Изменение запрещено, объект расчетов уже используется в других сеансах.';
						|en = 'Cannot make changes. The AR/AP object is already used in other sessions.'; fa = 'Cannot make changes. The AR/AP object is already used in other sessions.';
						|it = 'Non è possibile modificare, l''oggetto dei calcoli è già utilizzato in altre sessioni.';
						|pl = 'Zmiana jest zabroniona, obiekt rozliczeń jest już używany w innych sesjach.';
						|tr = 'Değişiklik yasaktır, alacak/borç nesnesi zaten başka oturumlarda kullanılmaktadır.'"));
		EndTry;
		CalculationObjectObject.Delete();
		SetPrivilegedMode(False);
	ElsIf ThereAreRefs And Not ThereAreRegisteredRecords Then
		SetPrivilegedMode(True);
		CalculationObjectObject = ARAPObject.GetObject();
		Try
			CalculationObjectObject.Lock();
		Except
			Raise(NStr("vi = 'Cấm thay đổi, đối tượng hạch toán đang được dùng trong các phiên làm việc khác.';
						|ru = 'Изменение запрещено, объект расчетов уже используется в других сеансах.';
						|en = 'Cannot make changes. The AR/AP object is already used in other sessions.'; fa = 'Cannot make changes. The AR/AP object is already used in other sessions.';
						|it = 'Non è possibile modificare, l''oggetto dei calcoli è già utilizzato in altre sessioni.';
						|pl = 'Zmiana jest zabroniona, obiekt rozliczeń jest już używany w innych sesjach.';
						|tr = 'Değişiklik yasaktır, alacak/borç nesnesi zaten başka oturumlarda kullanılmaktadır.'"));
		EndTry;
		If Not CalculationObjectObject.DeletionMark Then
			CalculationObjectObject.SetDeletionMark(True);
		EndIf;
		SetPrivilegedMode(False);
	ElsIf RaiseException1 And ThereAreRegisteredRecords Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cấm thay đổi, đối tượng hạch toán %1 đang được dùng trong các đối tượng khác:';
					|ru = 'Изменение запрещено, объект расчетов %1 используется в других объектах:';
					|en = 'Cannot make changes. Reason: AR/AP object %1 is used by other objects:'; fa = 'Cannot make changes. Reason: AR/AP object %1 is used by other objects:';
					|it = 'Vietato modificare, l''oggetto di regolamenti %1 è in uso in altri oggetti:';
					|pl = 'Zmiana jest zabroniona, obiekt rozliczeń %1 jest używany w innych obiektach:';
					|tr = 'Değiştirilmesi yasaktır, %1 alacak/borç nesnesi diğer nesnelerde kullanılır:'"),
				ARAPObject);
		Common.MessageToUser(ErrorText,,,,Cancel);
		Selection = Results[1].Select();
		While Selection.Next() Do
			Message = New UserMessage();
			Message.DataKey = Selection.Ref;
			Message.Text = Chars.Tab + Selection.Ref;
			Message.Message();
		EndDo;
	EndIf;
	
EndProcedure

// Returns a structure with required data for generating / searching the calculation object
// 
// Returns:
// 	Structure - LongDesc:
// 		* Object - DefinedType.ARAPObject - Link to the source of the calculation object.
// 		* PaymentType_ - EnumRef.PartnersARAPAccountingTypes - In which calculations is reflected, with customers or with suppliers.
// 		* Organization - CatalogRef.Companies - Organization of the payment object.
// 		* Counterparty - Undefined - Counterparty of the settlement object.
// 		* Partner - CatalogRef.Partners - Partner of the payment object.
// 		* Contract - Undefined - The contract of object calculations.
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness - The direction of activity for which the object of calculations is reflected.
Function GetCalculationObjectParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Object");
	ParametersStructure.Insert("PaymentType_");
	ParametersStructure.Insert("Organization",             Catalogs.Companies.EmptyRef());
	ParametersStructure.Insert("Currency",                  Catalogs.Currencies.EmptyRef());
	ParametersStructure.Insert("Partner",                 Catalogs.Partners.EmptyRef());
	ParametersStructure.Insert("Counterparty",              Undefined);
	ParametersStructure.Insert("Contract",                 Undefined);
	ParametersStructure.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	
	Return ParametersStructure;
	
EndFunction

// Complements the array of links with links to related calculation objects.
// 
// Parameters:
// 	ReferencesArrray - Array of DocumentRef, CatalogRef - Array of links to documents and reference books.
//
Procedure AddLinksToCalculationObjects(ReferencesArrray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ARAPObjects.Ref AS Ref
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Object IN (&ReferencesArrray)
	|	AND NOT ARAPObjects.DeletionMark";
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	ArrayOfCalculationObjects_ = Query.Execute().Unload().UnloadColumn("Ref");
	
	CommonClientServer.SupplementArray(ReferencesArrray,ArrayOfCalculationObjects_);
	
EndProcedure

// Checks that the reference of the specified object can be contained in the calculation object
// 
// Parameters:
// 	Object - CatalogObject, DocumentObject - the object being checked.
// 	ParametersStructure - Structure - The current set of parameters. See ARAPAccountingServer.MechanismParameters.
// 
// Returns:
// 	Boolean - True if it is the object of calculations
//
Function ReferenceIsObjectOfCalculations(Object, ParametersStructure) Export
	
	ChangesCalculations               = ParametersStructure.ChangesCalculations;
	IsCatalog                 = ParametersStructure.IsCatalog;
	ThisIsOrder                      = ParametersStructure.ThisIsOrder;
	ThisIsSalePurchase             = ParametersStructure.ThisIsSalePurchase;
	IsItPaymentOrOtherDocument    = ParametersStructure.IsItPaymentOrOtherDocument;
	ItCanBeARAPObject = ParametersStructure.ItCanBeARAPObject;
	ARAPObjectSettings               = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings, , Enums.ARAPObjectSettings.ByARAPDocuments);
	InvoiceForOrders            = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.InvoiceForOrders, ,False);
	OrderBase                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
	UseExtended       = ParametersStructure.CustomerSettlementDocument And Not ParametersStructure.OrderAsAProformaInvoice
									Or ParametersStructure.DocumentOfSettlementsWithSuppliers;
	
	Return ItCanBeARAPObject
		And (IsCatalog
			Or ThisIsOrder And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
														Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			Or ThisIsSalePurchase And ChangesCalculations 
				And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
					Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
					Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
					Or (Not UseExtended Or Not InvoiceForOrders) And ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders) 
					// Adjustments to realizations and acquisitions.
					And ParametersStructure.Ref = "Object.Ref"
			Or IsItPaymentOrOtherDocument And ChangesCalculations
				// Returns of goods not under contracts.
				And ValueIsFilled(ParametersStructure.ARAPObject) And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts
				// Returns of customers' goods are not on request.
				And Not (ValueIsFilled(OrderBase) And ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders));
	
EndFunction

// Finds the used calculation object (or several) by the specified link
//
// Parameters:
// 	Ref - CatalogRef, DocumentRef - a document or reference book using the accounting mechanism of Mutual settlements
// 
// Returns:
// 	- CatalogRef.ARAPObjects - Found calculation object
// 	- Array of CatalogRef.ARAPObjects - If multiple calculation objects are found
//
Function ObjectOfCalculationsFromLink(Ref) Export
	
	ManagerModule = Common.ObjectManagerByRef(Ref);
	SettlementParameters_ = ManagerModule.SettlementParameters_(Ref);
	
	If TypeOf(SettlementParameters_) = Type("Array") Then
		ParametersArray = SettlementParameters_;
	Else
		ParametersArray = CommonClientServer.ValueInArray(SettlementParameters_);
	EndIf;
	
	ARAPObject = Catalogs.ARAPObjects.EmptyRef();
	For Each ParametersStructure In ParametersArray Do
		If ValueIsFilled(ParametersStructure.ARAPObject) Then
			PathParts = StrSplit(ParametersStructure.ARAPObject, ".");
			If PathParts.Count() = 2 Then // OR in requesite
				ARAPObject = Common.ObjectAttributeValue(Ref, PathParts[1]);
			ElsIf PathParts.Count() = 3 Then // OR in the tabular part
				MetadataByLink = Ref.Metadata();
				If MetadataByLink.TabularSections.Find(PathParts[1]) <> Undefined Then
					Query = New Query;
					Query.Text = 
						"SELECT DISTINCT
						|	TabularSection.AttributeName AS ARAPObject
						|FROM
						|	&TabularSection AS TabularSection
						|WHERE
						|	TabularSection.Ref = &Ref";
					Query.Text = StrReplace(Query.Text, "&TabularSection", MetadataByLink.FullName() + "." + PathParts[1]);
					Query.Text = StrReplace(Query.Text, "AttributeName", PathParts[2]);
					Query.SetParameter("Ref", Ref);
					ArrayOfCalculationObjects_ = Query.Execute().Unload().UnloadColumn("ARAPObject");
					If ArrayOfCalculationObjects_.Count() > 1 Then
						ARAPObject =  ArrayOfCalculationObjects_;
					ElsIf ArrayOfCalculationObjects_.Count() = 1 Then 
						ARAPObject = ArrayOfCalculationObjects_[0];
					EndIf;
				Else
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong mô-đun quản lý chứng từ đã chỉ ra sai đường dẫn đến đối tượng hạch toán %1';
							|ru = 'В модуле менеджера документа указан некоррекный путь к объекту расчетов %1';
							|en = 'Incorrect path to the %1 AR/AP object is specified in the document manager module'; fa = 'Incorrect path to the %1 AR/AP object is specified in the document manager module';
							|it = 'Nel modulo del manager del documento è indicato un percorso errato all''oggetto dei calcoli %1';
							|pl = 'W module menedżera dokumentu jest podana niepoprawna ścieżka do obiektu obliczeń %1';
							|tr = 'Belge yöneticisi modülünde %1 alacak/borç nesnesinin yolu yanlış belirtildi'"),
						ParametersStructure.ARAPObject));
				EndIf;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	Return ARAPObject;
	
EndFunction

// Receives the AR/AP object based on the payment
// 
// Parameters:
// 	PaymentPurpose - CatalogRef, DocumentRef - 
// 
// Returns:
// 	- CatalogRef.ARAPObjects - The AR/AP object found.
//
Function ARAPObjectOnBasisOfPayment(Val PaymentPurpose) Export
	
	SearchLink = PaymentPurpose;
	
	If TypeOf(PaymentPurpose) = Type("DocumentRef.CustomerCommercialInvoice")
	Then
		DocumentBasis = Common.ObjectAttributeValue(PaymentPurpose, "DocumentBasis");
		If ValueIsFilled(DocumentBasis) Then
			SearchLink = DocumentBasis;
		EndIf;
	EndIf;
	
	ObjectOfCalculationsByReference = GetCalculationObjectFromLink(SearchLink);
	
	If ValueIsFilled(ObjectOfCalculationsByReference) Then
		Return ObjectOfCalculationsByReference;
	EndIf;
	
	ObjectOfCalculationsFromLink = ObjectOfCalculationsFromLink(SearchLink);
	
	If TypeOf(ObjectOfCalculationsFromLink) = Type("Array") Then
		If ObjectOfCalculationsFromLink.Count() > 0 Then
			ARAPObject = ObjectOfCalculationsFromLink[0];
		Else
			ARAPObject = Undefined;
		EndIf;
	Else
		ARAPObject = ObjectOfCalculationsFromLink;
	EndIf;
	
	Return ARAPObject;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Returns matches of links to elements of the calculation objects reference list
// 
// Parameters:
// 	SearchTable - ValueTable - table of search links:
// 	 * LineNumber - Number - number of the search string.
// Returns:
// 	Map of KeyAndValue:
// 		* Key - Number - Row number in the Search table
//		* Value - CatalogRef.ARAPObjects
//
Function FindCalculationObjectsBasedOnPartnerAccountingAnalytics(SearchTable) Export

	Query = New Query;
	Query.Text =
		"SELECT
		|	SearchData_.LineNumber,
		|	SearchData_.Organization,
		|	SearchData_.Partner,
		|	SearchData_.Counterparty,
		|	SearchData_.Contract,
		|	SearchData_.LineOfBusiness,
		|	SearchData_.PaymentType_,
		|	SearchData_.ARAPCurrency
		|INTO TTSearchData
		|FROM 
		|	&SearchData_ AS SearchData_
		|;
		|
		|SELECT
		|	SearchData_.LineNumber AS LineNumber,
		|	ARAPObjects.Ref AS ARAPObject
		|FROM
		|	TTSearchData AS SearchData_
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON ARAPObjects.Organization = SearchData_.Organization
		|		AND ARAPObjects.Partner = SearchData_.Partner
		|		AND ARAPObjects.Counterparty = SearchData_.Counterparty
		|		AND ARAPObjects.Contract = SearchData_.Contract
		|		AND ARAPObjects.LineOfBusiness = SearchData_.LineOfBusiness
		|		AND ARAPObjects.PaymentType_ = SearchData_.PaymentType_
		|		AND ARAPObjects.ARAPCurrency = SearchData_.ARAPCurrency
		|		AND ARAPObjects.Object = UNDEFINED";
	
	Query.SetParameter("SearchData_", SearchTable);
	ARAPObjects = Query.Execute().Unload();

	Result = New Map;
	For Each AnalyticsLine_ In SearchTable Do
		ObjectsStrings = ARAPObjects.FindRows(New Structure("LineNumber", AnalyticsLine_.LineNumber));
		If ObjectsStrings.Count() > 1 Then
			Raise(NStr("vi = 'Lỗi điền đối tượng tính toán. Tìm thấy một số đối tượng tính toán.';
						|ru = 'Ошибка заполнения объекта расчетов. Найдено несколько объектов расчетов.';
						|en = 'Error while filling the AR/AP object. Reason: multiple AR/AP objects were found.'; fa = 'Error while filling the AR/AP object. Reason: multiple AR/AP objects were found.';
						|it = 'Errore di compilazione di oggetto di regolamenti. Trovati più oggetti di regolamenti.';
						|pl = 'Błąd wypełnienia obiektu rozliczeń. Znaleziono kilka obiektów rozliczeń.';
						|tr = 'Alacak/Borç nesnesi doldurulurken hata oluştu. Birkaç alacak/borç nesnesi bulundu.'"));
		ElsIf ObjectsStrings.Count() = 1 Then
			Result.Insert(AnalyticsLine_.LineNumber, ObjectsStrings[0].ARAPObject);
		Else
			Result.Insert(AnalyticsLine_.LineNumber, Catalogs.ARAPObjects.EmptyRef());
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable:
// 		* LineNumber             - Number
// 		* Organization             - CatalogRef.Companies
// 		* Counterparty              - CatalogRef.Counterparties
// 		                          - CatalogRef.Companies
// 		* Partner                 - CatalogRef.Partners
// 		* Contract                 - CatalogRef.CounterpartyContracts
// 		                          - CatalogRef.IntercompanyContracts
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness
// 		* PaymentType_             - EnumRef.PartnersARAPAccountingTypes 
// 		* ARAPCurrency    - CatalogRef.Currencies
//
Function SearchParametersForEmptyCalculationObject() Export
	
	SearchParameters = New ValueTable();
	SearchParameters.Columns.Add("LineNumber",             New TypeDescription("Number"));
	SearchParameters.Columns.Add("Organization",             New TypeDescription("CatalogRef.Companies"));
	
	ListOfCounterpartyTypes = New Array();
	ListOfCounterpartyTypes.Add(Type("CatalogRef.Companies"));
	ListOfCounterpartyTypes.Add(Type("CatalogRef.Counterparties"));
	SearchParameters.Columns.Add("Counterparty",              New TypeDescription(ListOfCounterpartyTypes));
	SearchParameters.Columns.Add("Partner",                 New TypeDescription("CatalogRef.Partners"));
	
	ListOfContractTypes = New Array();
	ListOfContractTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	ListOfContractTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	SearchParameters.Columns.Add("Contract",                 New TypeDescription(ListOfContractTypes));
	SearchParameters.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	SearchParameters.Columns.Add("PaymentType_",             New TypeDescription("EnumRef.PartnersARAPAccountingTypes"));
	SearchParameters.Columns.Add("ARAPCurrency",    New TypeDescription("CatalogRef.Currencies"));

	Return SearchParameters;
	
EndFunction

// Generates and fills in the AR/AP objects in the tabular part of the document Entering the Balances of settlements
//
// Parameters:
//   Object - DocumentObject.OBEntryARAP
//
Procedure GenerateFillInARAPObject(Object) Export
	
	Objects = Common.ObjectsAttributesValues(
				Object.PartnersARAPAccounting.UnloadColumn("ARAPObjectSender"),
				"Object, Organization",
				True);
	
	For Each TSRow In Object.PartnersARAPAccounting Do
		
		If TSRow.ARAPObjectSender = Catalogs.ARAPObjects.EmptyRef() 
			Or Objects.Get(TSRow.ARAPObjectSender) <> Undefined
				And (TSRow.ARAPObject <> Objects.Get(TSRow.ARAPObjectSender).Object
					Or Object.Organization <> Objects.Get(TSRow.ARAPObjectSender).Organization) Then
			
			SourceOfCalculationObject = TSRow.ARAPObject;
			
			If ValueIsFilled(SourceOfCalculationObject) Then
				If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor
					Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable Then
						PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
				ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
					Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable Then
						PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
				EndIf;
				
				BlockingSourceOfCalculationObject = New DataLock;
				
				LockItem = BlockingSourceOfCalculationObject.Add(SourceOfCalculationObject.Metadata().FullName());
				LockItem.SetValue("Ref", SourceOfCalculationObject);
				LockItem.Mode = DataLockMode.Shared;
				
				BlockingSourceOfCalculationObject.Lock();
			
				If TypeOf(SourceOfCalculationObject) = Type("DocumentRef.SourceDocument") Then
					TSRow.ARAPObjectSender = Documents.SourceDocument.GenerateCalculationObject(SourceOfCalculationObject.GetObject());
				Else
					SourceObject = SourceOfCalculationObject.GetObject();
					ObjectManager = Common.ObjectManagerByRef(SourceOfCalculationObject);
					SettlementParameters_ = ObjectManager.SettlementParameters_(SourceObject);
					AdvancedParameters = ARAPAccountingServer.AugmentedMechanismParameters(SourceObject, SettlementParameters_);
					For Each ParametersStructure In AdvancedParameters.ParametersArray Do
						If TMCommonUseClientServer.DataAlongWay(SourceObject, ParametersStructure.Organization) = Object.Organization
							And TMCommonUseClientServer.DataAlongWay(SourceObject, ParametersStructure.PaymentType_) = PaymentType_ Then
							SettlementParameters_ = ParametersStructure;
							Break;
						EndIf;
					EndDo;
					
					If ReferenceIsObjectOfCalculations(SourceObject, SettlementParameters_) Then
						ReferenceObjectOfCalculations = CheckFillInCalculationObjectByStructure(SourceObject, SettlementParameters_);
						TSRow.ARAPObjectSender = ReferenceObjectOfCalculations;
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure ClearCalculationObjects(Object, StructuresArray)
	
	For Each ParametersStructure In StructuresArray Do
		
		PaymentObjectDetails = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.ARAPObject);
		IsCatalog          = ParametersStructure.IsCatalog;
		Ref                 = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Ref);
		
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption)
			And ParametersStructure.ChangesCalculations
			And ParametersStructure.IsItPaymentOrOtherDocument
			And Metadata.DefinedTypes.ARAPObjectPrepayment.Type.ContainsType(TypeOf(Ref)) Then
			ARAPDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption);
			ARAPObjects = ARAPDetails.UnloadColumn("ARAPObject");
			ObjectsOfCalculationObjects = Common.ObjectsAttributeValue(ARAPObjects, "Object");
			For Each TSRow In ARAPDetails Do
				If ObjectsOfCalculationObjects[TSRow.ARAPObject] = Ref Then
					TSRow.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
				EndIf;
			EndDo;
		EndIf;
		
		If PaymentObjectDetails = Undefined And Not IsCatalog Then
			Return;
		EndIf;
		
		TSPaymentSteps              = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
		
		If PaymentObjectDetails <> Undefined Then
			If StrSplit(ParametersStructure.ARAPObject,".").Count() = 3 Then
				For Each TSRow In PaymentObjectDetails.Data Do
					TSRow[PaymentObjectDetails.Name] = Catalogs.ARAPObjects.EmptyRef();
				EndDo;
			Else
				PaymentObjectDetails.Data[PaymentObjectDetails.Name] = Catalogs.ARAPObjects.EmptyRef();
			EndIf;
			If TSPaymentSteps <> Undefined And TSPaymentSteps.Count() > 0 
				And CommonClientServer.HasAttributeOrObjectProperty(TSPaymentSteps[0],"ARAPObject") Then
				For Each TSRow In TSPaymentSteps Do
					TSRow.ARAPObject = Catalogs.ARAPObjects.EmptyRef();
				EndDo;
			EndIf;
		EndIf;
		
		If ParametersStructure.ThisIsSalePurchase  And ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
			TSDetails = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption);
			TSDetails.Clear();
		EndIf;
		
	EndDo;
	
EndProcedure

Function DetailsOfSettlementObjectsCatalog()
	
	ServiceDetails_ = New Array;
	ServiceDetails_.Add("Ref");
	ServiceDetails_.Add("DeletionMark");
	ServiceDetails_.Add("Object");
	ServiceDetails_.Add("Organization");
	ServiceDetails_.Add("PaymentType_");
	ServiceDetails_.Add("RefType");
	ServiceDetails_.Add("UUID");
	
	CatalogAttributes = Metadata.Catalogs.ARAPObjects.Attributes;
	
	Attributes = New Array();
	
	For Each Attribute In CatalogAttributes Do
		If ServiceDetails_.Find(Attribute.Name) = Undefined Then
			Attributes.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	Attributes.Add("Description");
	
	Return Attributes;
	
EndFunction

Procedure FillInClearARAPObject(Object, StructuresArray, WriteMode = Undefined)
	
	For Each ParametersStructure In StructuresArray Do
		
		PaymentObjectDetails     = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.ARAPObject);
		IsCatalog              = ParametersStructure.IsCatalog;
		
		If PaymentObjectDetails = Undefined
			Or ParametersStructure.Organization = Catalogs.Companies.ManagementCompany Then 
			// For a management organization, the Calculation object is filled in before being recorded in the document object module
			Continue;
		EndIf;
		
		ThisIsOrder                   = ParametersStructure.ThisIsOrder;
		ThisIsSalePurchase          = ParametersStructure.ThisIsSalePurchase;
		IsItPaymentOrOtherDocument = ParametersStructure.IsItPaymentOrOtherDocument;
		PaymentType_                = ParametersStructure.PaymentType_;
		OrganizationOfContract        = ParametersStructure.OrganizationOfContract;
		ChangesCalculations               = ParametersStructure.ChangesCalculations;
		
		PropsNameTSOrder        = ParametersStructure.PropsNameTSOrder;
		Organization                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
		OrderBase             = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
		TS                         = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData);
		TSPaymentSteps              = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
		
		Contract               = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
		InvoiceForOrders    = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.InvoiceForOrders, , False);
		If ParametersStructure.Property("RefToNew") Then
			Ref = ParametersStructure.RefToNew;
		Else
			Ref = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Ref);
		EndIf;
		
		ARAPObjectSettings            = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
		If ARAPObjectSettings = Undefined And ValueIsFilled(Contract) Then
			ARAPObjectSettings = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings");
		EndIf;
		
		AdditionalSearchCriteria_1 = AdditionalSearchCriteria_1();
		AdditionalSearchCriteria_1.Counterparty = ?(Not ParametersStructure.CounterpartyInLines,
			TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Counterparty),
			Undefined);
		AdditionalSearchCriteria_1.Partner = ?(Not ParametersStructure.PartnerInRows,
			TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Partner),
			Undefined);
		
		ARAPObjectDoesNotNeedToBeFilledIn = False;
		//Definition.
		AdditionalSearchCriteria_1.ReturnFirstOne = True;
		If ReferenceIsObjectOfCalculations(Object, ParametersStructure) Then
			ARAPObject = GetCalculationObjectFromLink(Ref, Organization, PaymentType_, AdditionalSearchCriteria_1);
		ElsIf ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			And (ThisIsOrder Or ThisIsSalePurchase Or IsItPaymentOrOtherDocument And ValueIsFilled(ParametersStructure.ARAPObject)) And ChangesCalculations
			Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice And ThisIsOrder And ChangesCalculations Then
				
			If Not ValueIsFilled(Contract) And WriteMode = DocumentWriteMode.Posting Then
				Raise (StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Chưa điền trường ""Hợp đồng"".';
										|ru = 'Не заполнено поле ""Договор"".';
										|en = 'The ""Contract"" field is not filled in.'; fa = 'The ""Contract"" field is not filled in.';
										|it = 'Не заполнено поле ""Договор"".';
										|pl = 'Nie wypełniono pola ""Umowa"".';
										|tr = '""Sözleşme"" alanı doldurulmamış.'"),
									Contract));
			EndIf;
			
			ARAPObject = GetCalculationObjectFromLink(Contract, Organization, PaymentType_, AdditionalSearchCriteria_1);
			If Not ValueIsFilled(ARAPObject) And ValueIsFilled(OrganizationOfContract) Then
				ARAPObject = GetCalculationObjectFromLink(Contract, OrganizationOfContract, PaymentType_, AdditionalSearchCriteria_1);
			EndIf;
			
			If Not ValueIsFilled(ARAPObject) And WriteMode = DocumentWriteMode.Posting Then
				Raise (StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không thể tìm thấy đối tượng giải quyết cho hợp đồng %1.';
										|ru = 'Не удалось найти объект расчетов для договора %1.';
										|en = 'Cannot find the AR/AP object for the contract: %1.'; fa = 'Cannot find the AR/AP object for the contract: %1.';
										|it = 'Не удалось найти объект расчетов для договора %1.';
										|pl = 'Nie udało się znaleźć obiektu rozliczeń dla umowy %1.';
										|tr = '%1 sözleşmesi için alacak/borç nesnesi bulunamadı.'"),
									Contract));
			EndIf;
			
		ElsIf ThisIsSalePurchase And InvoiceForOrders And Not ValueIsFilled(PropsNameTSOrder) And ValueIsFilled(OrderBase) And ChangesCalculations
			Or IsItPaymentOrOtherDocument And ValueIsFilled(OrderBase) And ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders And ChangesCalculations Then
			
			ARAPObject = GetCalculationObjectFromLink(OrderBase, Organization, PaymentType_, AdditionalSearchCriteria_1);
			
			If Not ValueIsFilled(ARAPObject) And WriteMode = DocumentWriteMode.Posting Then
				Raise (StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không thể tìm thấy đối tượng giải quyết cho %1. Kiểm tra sự tuân thủ của các chi tiết chính với đơn hàng.';
										|ru = 'Не удалось найти объект расчетов для %1. Проверьте соответствие ключевых реквизитов заказу.';
										|en = 'Cannot find the AR/AP object for %1. Check whether the key attributes match the order.'; fa = 'Cannot find the AR/AP object for %1. Check whether the key attributes match the order.';
										|it = 'Не удалось найти объект расчетов для %1. Проверьте соответствие ключевых реквизитов заказу.';
										|pl = 'Nie udało się znaleźć obiektu rozliczeń dla %1. Sprawdź zgodność kluczowych atrybutów zamówienia.';
										|tr = '%1 için alacak/borç nesnesi bulunamadı. Anahtar özniteliklerin siparişle uygunluğunu kontrol et.'"),
									OrderBase));
			EndIf;
			
		ElsIf ThisIsSalePurchase And InvoiceForOrders And ValueIsFilled(PropsNameTSOrder) 
			And ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders And ChangesCalculations Then
			
			Orders = TS.UnloadColumn(PropsNameTSOrder);
		
			If Orders.Count() > 0 Then
				ARAPObject = GetCalculationObjectsFromLinks(Orders, Organization, PaymentType_, AdditionalSearchCriteria_1);
			Else
				Return;
			EndIf;
			
			If Not ARAPObject = Undefined Then 
				For Each Item In ARAPObject Do
					If Not ValueIsFilled(ARAPObject.Get(Item.Key)) And WriteMode = DocumentWriteMode.Posting Then
						Raise (StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Không thể tìm thấy đối tượng giải quyết cho %1. Kiểm tra sự tuân thủ của các chi tiết chính với đơn hàng.';
												|ru = 'Не удалось найти объект расчетов для %1. Проверьте соответствие ключевых реквизитов заказу.';
												|en = 'Cannot find the AR/AP object for %1. Check whether the key attributes match the order.'; fa = 'Cannot find the AR/AP object for %1. Check whether the key attributes match the order.';
												|it = 'Не удалось найти объект расчетов для %1. Проверьте соответствие ключевых реквизитов заказу.';
												|pl = 'Nie udało się znaleźć obiektu rozliczeń dla %1. Sprawdź zgodność kluczowych atrybutów zamówienia.';
												|tr = '%1 için alacak/borç nesnesi bulunamadı. Anahtar özniteliklerin siparişle uygunluğunu kontrol et.'"),
											Item.Key));
					EndIf;
				EndDo;
			EndIf;
			
		// Adjustments to sales and acquisitions.
		ElsIf TypeOf(Ref) = Type("DocumentRef.SaleAdjustment")
			Or TypeOf(Ref) = Type("DocumentRef.PurchaseAdjustment") Then
			ARAPObject = GetCalculationObjectFromLink(
					TMCommonUseClientServer.DataAlongWay(Object, "Object.DocumentBasis"),
					Organization,
					ParametersStructure.PaymentType_,
					AdditionalSearchCriteria_1);
			
			If Not ValueIsFilled(ARAPObject) And WriteMode = DocumentWriteMode.Posting Then
				Raise (StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không thể tìm thấy đối tượng giải quyết cho %1.';
										|ru = 'Не удалось найти объект расчетов для %1.';
										|en = 'Cannot find the AR/AP object for %1.'; fa = 'Cannot find the AR/AP object for %1.';
										|it = 'Не удалось найти объект расчетов для %1.';
										|pl = 'Nie udało się znaleźć obiektu rozliczeń dla %1.';
										|tr = '%1 için alacak/borç nesnesi bulunamadı.'"),
									Object));
			EndIf;
		Else
			// Clearing the Attributes
			ARAPObject = Catalogs.ARAPObjects.EmptyRef();
			ARAPObjectDoesNotNeedToBeFilledIn = True;
		EndIf;
		
		If Not ValueIsFilled(ARAPObject) And Not ARAPObjectDoesNotNeedToBeFilledIn 
			And (IsCatalog And Not TMCommonUseClientServer.DataAlongWay(Object, "Object.DeletionMark")
				Or Not IsCatalog And TMCommonUseClientServer.DataAlongWay(Object, "Object.Posted")) Then
				Raise (NStr("vi = 'Không thể tìm thấy đối tượng giải quyết.';
							|ru = 'Не удалось найти объект расчетов.';
							|en = 'Cannot find the AR/AP object.'; fa = 'Cannot find the AR/AP object.';
							|it = 'Не удалось найти объект расчетов.';
							|pl = 'Nie udało się znaleźć obiektu rozliczeń.';
							|tr = 'Alacak/Borç nesnesi bulunamadı.'"))
		EndIf;
		
		IsDocument = Documents.AllRefsType().ContainsType(TypeOf(Ref));
		
		If Not IsDocument
			Or WriteMode = DocumentWriteMode.Posting
			Or WriteMode = DocumentWriteMode.Write Then
			//Assignment.
			If PaymentObjectDetails <> Undefined Then
				If TypeOf(ARAPObject) = Type("Map") Then
					For Each TSRow In TS Do
						TSRow[PaymentObjectDetails.Name] = ARAPObject[TSRow[PropsNameTSOrder]];
					EndDo;
					If TSPaymentSteps <> Undefined And TSPaymentSteps.Count() > 0
						And CommonClientServer.HasAttributeOrObjectProperty(TSPaymentSteps[0], "OrderDocument") Then
						For Each TSRow In TSPaymentSteps Do
							TSRow.ARAPObject = ARAPObject[TSRow.OrderDocument];
						EndDo;
					EndIf;
				Else
					If StrSplit(ParametersStructure.ARAPObject,".").Count() = 3 Then
						For Each TSRow In PaymentObjectDetails.Data Do
							TSRow[PaymentObjectDetails.Name] = ARAPObject;
						EndDo;
					Else
						PaymentObjectDetails.Data[PaymentObjectDetails.Name] = ARAPObject;
					EndIf;
					If TSPaymentSteps <> Undefined And TSPaymentSteps.Count() > 0 
						And CommonClientServer.HasAttributeOrObjectProperty(TSPaymentSteps[0],"ARAPObject") Then
						For Each TSRow In TSPaymentSteps Do
							TSRow.ARAPObject = ARAPObject;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
// 	Object - DocumentObject,CatalogObject - .
// 	
// Returns:
// 	ValueTable
//
Function TableOfParties(Object, Parameters)
	
	TypesList = New Array;
	TypesList.Add(Type("CatalogRef.Companies"));
	TypesList.Add(Type("CatalogRef.Counterparties"));
	DescriptionOfCounterpartyFieldType = New TypeDescription(TypesList);
	
	TableOfParties = New ValueTable;
	TableOfParties.Columns.Add("Counterparty", New TypeDescription(DescriptionOfCounterpartyFieldType));
	TableOfParties.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	TableOfParties.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
	TableOfParties.Columns.Add("ARAPCurrency",New TypeDescription("CatalogRef.Currencies"));
	TableOfParties.Columns.Add("PaymentType_",New TypeDescription("EnumRef.PartnersARAPAccountingTypes"));
	
	If TypeOf(Parameters) <> Type("Array") Then
		StructuresArray = CommonClientServer.ValueInArray(Parameters);
	Else
		StructuresArray = Parameters;
	EndIf;
	
	For Each ParametersStructure In StructuresArray Do
		
		If ParametersStructure.Property("RefToNew") Then
			Ref = ParametersStructure.RefToNew;
		Else
			Ref = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Ref);
		EndIf;
		
		OrganizationInRows  = ParametersStructure.OrganizationInRows And TypeOf(ParametersStructure.Organization) = Type("String");
		CounterpartyInLines   = ParametersStructure.CounterpartyInLines And TypeOf(ParametersStructure.Counterparty) = Type("String");
		PartnerInRows      = ParametersStructure.PartnerInRows And TypeOf(ParametersStructure.Partner) = Type("String");
		CurrencyOfMutualSettlementsInLines = ParametersStructure.CurrencyOfMutualSettlementsInLines And TypeOf(ParametersStructure.ARAPCurrency) = Type("String");
		DocumentCurrency = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentCurrency);
		
		If OrganizationInRows Or CounterpartyInLines Or PartnerInRows Or CurrencyOfMutualSettlementsInLines Then
			
			If OrganizationInRows And CounterpartyInLines
				And StrSplit(ParametersStructure.Organization, ".")[1] <> StrSplit(ParametersStructure.Counterparty, ".")[1] Then
				Raise(NStr("vi = 'Lỗi nhúng. Các phần bảng có chứa đối tác và doanh nghiệp khác nhau.';
							|ru = 'Ошибка встраивания. Отличаются табличные части содержащие контрагента и организацию.';
							|en = 'Embedding error. Tables containing counterparty and company are different.'; fa = 'Embedding error. Tables containing counterparty and company are different.';
							|it = 'Errore di incorporamento. Le tabelle contenenti la contraparte e l''azienda differiscono.';
							|pl = 'Błąd włączenia. Różnią się sekcje tabelaryczne zawierające kontrahenta i firmę.';
							|tr = 'Yerleştirme hatası. Cari hesabı ve iş yerini içeren tablo bölümleri farklıdır.'"));
			EndIf;
			
			If OrganizationInRows Then
				Names = StrSplit(ParametersStructure.Organization, ".");
				Names.Delete(Names.UBound());
				TabularSection = TMCommonUseClientServer.DataAlongWay(Object, StrConcat(Names, ".")); // TabularSection 
			ElsIf CounterpartyInLines Or PartnerInRows Or CurrencyOfMutualSettlementsInLines Then
				TabularSection = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentDecryption); // TabularSection
			EndIf;
			
			CalculationObjectsInLines = False;
			If TabularSection.Count() > 0 And CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "ARAPObject") Then
				CalculationObjectsInLines = True;
				Objects = Common.ObjectsAttributesValues(
					CommonClientServer.CollapseArray(TabularSection.Unload(,"ARAPObject").UnloadColumn("ARAPObject")),"Object");
			EndIf;
			
			For Each Page1 In TabularSection Do
				
				If Not ReferenceIsObjectOfCalculations(Object, ParametersStructure) 
					And Not (CalculationObjectsInLines
							And (Not ValueIsFilled(Page1.ARAPObject)
									Or Objects[Page1.ARAPObject].Object = Ref)) Then
					Continue;
				EndIf;
				
				NwRw = TableOfParties.Add();
				
				If TypeOf(Object) = Type("ClientApplicationForm") Then
					Id = Page1.GetID();
				Else
					Id = Page1.LineNumber;
				EndIf;
				
				If OrganizationInRows Then
					NwRw.Organization = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization, Id);
				Else
					NwRw.Organization = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
				EndIf;
				
				If CounterpartyInLines Then
					NwRw.Counterparty = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Counterparty, Id);
				Else
					NwRw.Counterparty = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Counterparty);
				EndIf;
				
				If PartnerInRows Then
					NwRw.Partner = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Partner, Id);
				Else
					NwRw.Partner = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Partner);
				EndIf;
				
				If CommonClientServer.HasAttributeOrObjectProperty(Page1, "ARAPCurrency") Then
					NwRw.ARAPCurrency = ?(ValueIsFilled(Page1.ARAPCurrency), Page1.ARAPCurrency, DocumentCurrency);
				Else
					NwRw.ARAPCurrency = TMCommonUseClientServer.DataAlongWay(
						Object, ?(ValueIsFilled(ParametersStructure.ARAPCurrency), 
									ParametersStructure.ARAPCurrency, 
									ParametersStructure.DocumentCurrency));
				EndIf;
				
				NwRw.PaymentType_ = ParametersStructure.PaymentType_;
				
			EndDo;
			
		Else
			If ReferenceIsObjectOfCalculations(Object, ParametersStructure)
				And (ValueIsFilled(ParametersStructure.ARAPObject) Or ParametersStructure.IsCatalog)
				Or ParametersStructure.OnlyBalance Then
				NwRw = TableOfParties.Add();
				NwRw.Organization = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
				NwRw.Counterparty = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Counterparty);
				NwRw.Partner = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Partner);
				NwRw.ARAPCurrency = TMCommonUseClientServer.DataAlongWay(
						Object, ?(ValueIsFilled(ParametersStructure.ARAPCurrency), 
									ParametersStructure.ARAPCurrency, 
									ParametersStructure.DocumentCurrency));
				NwRw.PaymentType_ = ParametersStructure.PaymentType_;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return TableOfParties;
	
EndFunction

#EndRegion

#EndIf
