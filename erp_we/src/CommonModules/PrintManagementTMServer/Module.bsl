
#Region Public

#Region DocumentCustomerInvoiceServices 

// Generates a printed form of the document Customer Invoice-Service using a Template
// in the format of an office document Office Open XML.
//
// Parameters:
//  DocumentRef      - AnyRef - the object for which you want to create a printed form.
//  ObjectTemplateAndData - Map - a collection of references to objects and their data.
//  TemplateName           - String - the name of the Template for printing.
//
// Returns:
//  String - the address of the storage where the generated file is placed.
//
Function PrintCertificateOfCompletedWorkMicrosoftWord(DocumentRef, ObjectTemplateAndData, TemplateName) Export

	TemplatesBinaryData	= ObjectTemplateAndData.Templates.TemplatesBinaryData;
	Sections_					= ObjectTemplateAndData.Templates.DescriptionOfSections;
	ObjectData = ObjectTemplateAndData.Data[DocumentRef][TemplateName];

	Template = PrintManagement.InitializeOfficeDocumentTemplate(TemplatesBinaryData[TemplateName],"");
	If Template = Undefined Then
		Return "";
	EndIf;
	
	ClosePrintFormWindow = False;
	
	Try
		PrintForm = PrintManagement.InitializePrintForm("",, Template);
		PrintFormStorageAddress = "";
		If PrintForm = Undefined Then
			PrintManagement.ClearRefs(Template);
			Return "";
		EndIf;
		
		PrintForm = PrintManagement.InitializePrintForm("",,Template);

		// Output of document headers and footers.
		Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Header"]);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
	
		Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Footer"]);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].DocumentTitle);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		If ValueIsFilled(ObjectData.AdditionalInformationOfHeader) Then
			Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].AdditionalInformationOfHeader);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		EndIf;
		
		Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].HeaderHeader);
		PrintManagement.AttachArea(PrintForm, Area, False);
		
		ThereIsVAT       = ObjectData.ConsiderVAT;
		ThereAreDiscounts    = ObjectData.ThereAreDiscounts;
		ShowVAT = ObjectData.ShowVAT;
		
		AreaSuffix = ?(ThereAreDiscounts, "WithDiscount", "") + ?(ThereIsVAT And ShowVAT, "WITHVAT", "");
		
		HeaderArea = PrintManagement.TemplateArea(Template,Sections_[TemplateName]["TableHeader" + AreaSuffix]);
		PrintManagement.AttachArea(PrintForm, HeaderArea, False);

		LineAreaStandard = Sections_[TemplateName]["String" + AreaSuffix];
		If ObjectData.UseSets Then
			RowAreaSet              = Sections_[TemplateName]["String"  + AreaSuffix + "Set"];
			RowAreaComponents      = Sections_[TemplateName]["String"  + AreaSuffix + "Components"];
			RowAreaItSEnd = Sections_[TemplateName]["String"  + AreaSuffix + "ItSEnd"];
		EndIf;
		
		IndexOf = 0;
		TotalRows = ObjectData.Services.Count();
		For Each TSRow In ObjectData.Services Do
			
			IndexOf = IndexOf + 1;
			
			If SetsClientServer.UseSetArea(TSRow, ObjectData.UseSets) Then
				RowArea = RowAreaSet;
			ElsIf SetsClientServer.UseScope(TSRow, ObjectData.UseSets) And IndexOf < TotalRows Then
				RowArea = RowAreaComponents;
			ElsIf SetsClientServer.UseScope(TSRow, ObjectData.UseSets) Then
				RowArea = RowAreaItSEnd;
			Else
				RowArea = LineAreaStandard;
			EndIf;
			
			Mass = New Array;
			Mass.Add(TSRow);
			
			Area = PrintManagement.TemplateArea(Template, RowArea);
			PrintManagement.JoinAndFillCollection(PrintForm, Area, Mass, False);
			
		EndDo;
		
		Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].InTotal);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		If ThereIsVAT Then
			Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].TotalVAT_);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		EndIf;
		
		Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].AmountInWords);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].Signatures);
		PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
		If ValueIsFilled(ObjectData.AdditionalInformation) Then
			Area = PrintManagement.TemplateArea(Template,Sections_[TemplateName].AdditionalInformation);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		EndIf;

		PrintFormStorageAddress = PrintManagement.GenerateDocument(PrintForm);
	Except
		
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
		Return "";
		
	EndTry;
			
	PrintManagement.ClearRefs(PrintForm);
	PrintManagement.ClearRefs(Template);
	
	Return PrintFormStorageAddress;
	
EndFunction	

#EndRegion

#Region DocumentARAPSettlement

// Generates a printed form of the document Netting agreement of debt using a Template
// in the format of an office document Office Open XML.
//
// Parameters:
//  DocumentRef      - AnyRef - the object for which you want to create a printed form.
//  ObjectTemplateAndData - Map - a collection of references to objects and their data.
//  TemplateName           - String - the name of the Template for printing.
//
// Returns:
//  String - the address of the storage where the generated file is placed.
//
Function PrintingActOfDebtOffsetMicrosoftWord(DocumentRef, ObjectTemplateAndData, TemplateName) Export
	
	TemplatesBinaryData	= ObjectTemplateAndData.Templates.TemplatesBinaryData;
	Sections_					= ObjectTemplateAndData.Templates.DescriptionOfSections;
	ObjectData = ObjectTemplateAndData.Data[DocumentRef][TemplateName];
	
	Template = PrintManagement.InitializeOfficeDocumentTemplate(TemplatesBinaryData[TemplateName], "");
	If Template = Undefined Then
		Return "";
	EndIf;
	
	Try
		PrintForm = PrintManagement.InitializePrintForm("",,Template);
		PrintFormStorageAddress = "";
		If PrintForm = Undefined Then
			PrintManagement.ClearRefs(Template);
			Return "";
		EndIf;
		
		If Not ObjectData.SettlementOfARAP Then
			
			If ObjectData.NettingBetweenOrganizations Then
				Text = NStr("vi = 'Để đối trừ giữa hai doanh nghiệp, cần in biên bản chuyển nợ.';
							|ru = 'Для взаимозачета с участием двух организаций требуется печатать акт переуступки долга.';
							|en = 'For offsetting between two companies, print a debt assignment protocol.'; fa = 'For offsetting between two companies, print a debt assignment protocol.';
							|it = 'For offsetting between two companies, print a debt assignment protocol.';
							|pl = 'For offsetting between two companies, print a debt assignment protocol.';
							|tr = 'İki iş yerini kapsayan mahsup işlemleri, bir borç temlik senedinin basılmasını gerektirmektedir.'");
			Else
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không cần in biên bản hạch toán đối với chứng từ %1';
						|ru = 'Не требуется печатать акт взаимозачета для документа %1';
						|en = 'It is not required to print netting agreement for document%1'; fa = 'It is not required to print netting agreement for document%1';
						|it = 'Non è richiesta la stampa dell''atto di compensazione per il documento %1';
						|pl = 'Nie trzeba drukować akt kompensaty dla dokumentu %1';
						|tr = '%1 belgesi için mahsuplaşma anlaşması yazdırılması gerekmiyor'"),
					DocumentRef);
			EndIf;
			Common.MessageToUser(
				Text,
				DocumentRef);
			Return "";

		Else
		
			// Output of document headers and footers.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Header"]);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
		
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Footer"]);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
			
			// Output the title of the document.	
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].DocumentTitle);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			// We output the data of accounts receivable;
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].AccountsReceivable);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableHeader);
			PrintManagement.AttachArea(PrintForm, Area, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableRow);
			PrintManagement.JoinAndFillCollection(PrintForm,Area, ObjectData.AccountsReceivable, False);
			
			// We output the accounts payable data.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].AccountsPayable);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableHeader);
			PrintManagement.AttachArea(PrintForm, Area, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableRow);
			PrintManagement.JoinAndFillCollection(PrintForm,Area, ObjectData.AccountsPayable, False);
			
			// We output the document's basement.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].Footer);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);

			PrintFormStorageAddress = PrintManagement.GenerateDocument(PrintForm);
			
		EndIf;
		
	Except
	
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Return "";
		
	EndTry;

	PrintManagement.ClearRefs(PrintForm);
	PrintManagement.ClearRefs(Template);

	Return PrintFormStorageAddress;
	
EndFunction

// Generates a printed form of the document The Act of assignment of debt using a Template
// in the format of an office document Office Open XML.
//
// Parameters:
//  DocumentRef      - AnyRef - the object for which you want to create a printed form.
//  ObjectTemplateAndData - Map - a collection of references to objects and their data.
//  TemplateName           - String - the name of the Template for printing.
//
// Returns:
//  String - the address of the storage where the generated file is placed.
//
Function PrintingActOfAssignmentOfDebtMicrosoftWord(DocumentRef, ObjectTemplateAndData, TemplateName) Export

	TemplatesBinaryData	= ObjectTemplateAndData.Templates.TemplatesBinaryData;
	Sections_					= ObjectTemplateAndData.Templates.DescriptionOfSections;
	ObjectData = ObjectTemplateAndData.Data[DocumentRef][TemplateName];
	
	Template = PrintManagement.InitializeOfficeDocumentTemplate(TemplatesBinaryData[TemplateName], "");
	If Template = Undefined Then
		Return "";
	EndIf;
	
	Try
		PrintForm = PrintManagement.InitializePrintForm("",,Template);
		PrintFormStorageAddress = "";
		If PrintForm = Undefined Then
			PrintManagement.ClearRefs(Template);
			Return "";
		EndIf;
		
		If ObjectData.SettlementOfARAP Or ObjectData.NettingBetweenOrganizations Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần in biên bản chuyển nhượng công nợ đối với chứng từ %1';
					|ru = 'Не требуется печатать акт переуступки долга для документа %1';
					|en = 'It is not required to print a debt assignment protocol for document %1'; fa = 'It is not required to print a debt assignment protocol for document %1';
					|it = 'Non è necessario stampare l''atto di trasferimento del debito per il documento %1';
					|pl = 'Nie trzeba drukować akt przejęcia zobowiązania do dokumentu %1';
					|tr = '%1 belgesi için atama tutanağının yazdırılmasına gerek yok'"),
				DocumentRef);
			Common.MessageToUser(
				Text,
				DocumentRef);
			
		Else

			// Output of document headers and footers.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Header"]);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Footer"]);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
			
			// Output the title of the document.	
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].DocumentTitle);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			// We output the data of accounts receivable;
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].AccountsReceivable);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableHeader);
			PrintManagement.AttachArea(PrintForm, Area, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableRow);
			PrintManagement.JoinAndFillCollection(PrintForm,Area, ObjectData.AccountsReceivable, False);
			
			// We output the accounts payable data.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].AccountsPayable);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableHeader);
			PrintManagement.AttachArea(PrintForm, Area, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableRow);
			PrintManagement.JoinAndFillCollection(PrintForm,Area, ObjectData.AccountsPayable, False);
			
			// We output the document's basement.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].Total);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].Footer);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			PrintFormStorageAddress = PrintManagement.GenerateDocument(PrintForm);

		EndIf;	

	Except
	
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return "";
		
	EndTry;

	PrintManagement.ClearRefs(PrintForm);
	PrintManagement.ClearRefs(Template);
	
	Return PrintFormStorageAddress;
	
EndFunction

// Forms a printed form of the document The Act of assignment of debt between organizations using a Template
// in the format of an office document Office Open XML.
//
// Parameters:
//  DocumentRef      - AnyRef - the object for which you want to create a printed form.
//  ObjectTemplateAndData - Map - a collection of references to objects and their data.
//  TemplateName           - String - the name of the Template for printing.
//
// Returns:
//  String - the address of the storage where the generated file is placed.
//
Function PrintingActOfAssignmentOfDebtBetweenMicrosoftWordOrganizations(DocumentRef, ObjectTemplateAndData, TemplateName) Export
	
	TemplatesBinaryData	= ObjectTemplateAndData.Templates.TemplatesBinaryData;
	Sections_					= ObjectTemplateAndData.Templates.DescriptionOfSections;
	ObjectData = ObjectTemplateAndData.Data[DocumentRef][TemplateName];
	
	Template = PrintManagement.InitializeOfficeDocumentTemplate(TemplatesBinaryData[TemplateName], "");
	If Template = Undefined Then
		Return "";
	EndIf;
	
	Try
		PrintForm = PrintManagement.InitializePrintForm("",,Template);
		PrintFormStorageAddress = "";
		If PrintForm = Undefined Then
			PrintManagement.ClearRefs(Template);
			Return "";
		EndIf;
		
		If ObjectData.SettlementOfARAP Or Not ObjectData.NettingBetweenOrganizations Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không cần in biên bản chuyển nhượng công nợ đối với chứng từ %1';
					|ru = 'Не требуется печатать акт переуступки долга для документа %1';
					|en = 'It is not required to print a debt assignment protocol for document %1'; fa = 'It is not required to print a debt assignment protocol for document %1';
					|it = 'Non è necessario stampare l''atto di trasferimento del debito per il documento %1';
					|pl = 'Nie trzeba drukować akt przejęcia zobowiązania do dokumentu %1';
					|tr = '%1 belgesi için atama tutanağının yazdırılmasına gerek yok'"),
				DocumentRef);
			Common.MessageToUser(
				Text,
				DocumentRef);
			Return "";
		Else
			// Output of document headers and footers.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Header"]);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName]["Footer"]);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, False);
			
			// Output the title of the document.	
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].DocumentTitle);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			// We output the data of accounts receivable;
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].AccountsReceivable);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableHeader);
			PrintManagement.AttachArea(PrintForm, Area, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableRow);
			PrintManagement.JoinAndFillCollection(PrintForm,Area, ObjectData.AccountsReceivable, False);
			
			// We output the accounts payable data.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].AccountsPayable);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableHeader);
			PrintManagement.AttachArea(PrintForm, Area, False);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].TableRow);
			PrintManagement.JoinAndFillCollection(PrintForm,Area, ObjectData.AccountsPayable, False);
			
			// We output the document's basement.
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].Total);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			Area = PrintManagement.TemplateArea(Template, Sections_[TemplateName].Footer);
			PrintManagement.AttachAreaAndFillParameters(PrintForm, Area, ObjectData, True);
			
			PrintFormStorageAddress = PrintManagement.GenerateDocument(PrintForm);
		EndIf;
		
	Except
	
		Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Return "";
		
	EndTry;

	PrintManagement.ClearRefs(PrintForm);
	PrintManagement.ClearRefs(Template);
	
	Return PrintFormStorageAddress;

EndFunction

#EndRegion

#Region OverridablePrintManagementFunctions

// See PrintManagementOverridable.OnDefinePrintSettings
Procedure OnDefinePrintSettings(Settings) Export
	
	InventoryInOperationServer.OnDefinePrintSettings(Settings);
	NonCurrentAssets.OnDefinePrintSettings(Settings);
	RMManagement.OnDefinePrintSettings(Settings);
	ListOfObjects = Settings.PrintObjects;
	ListOfObjects.Add(Catalogs.RouteSheets);
	ListOfObjects.Add(Catalogs.TechnologicalProcesses);
	ListOfObjects.Add(Catalogs.WorkCenters);
	ListOfObjects.Add(Documents.MaterialProviderOrder2_5);
	ListOfObjects.Add(Documents.WIPOpeningBalancesByProductionLots);
	ListOfObjects.Add(Documents.InitialWIPBalancesByBusinessUnits);
	ListOfObjects.Add(Documents.ReportToMaterialProvider2_5);
	ListOfObjects.Add(Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany);
	ListOfObjects.Add(Documents.ProductionOrder2_2);
	ListOfObjects.Add(Documents.ProductionStage2_2);
	ListOfObjects.Add(Documents.ProductionOperation2_2);
	ListOfObjects.Add(Documents.EngineeringChangeOrder);
	ListOfObjects.Add(Documents.StandardCosting2_2);
	ListOfObjects.Add(Documents.ShiftTask);
	ListOfObjects.Add(Documents.GoodsQualityResearch);
	ListOfObjects.Add(DataProcessors.ExecutionOfOperations2_2);
	ListOfObjects.Add(DataProcessors.PerformOperationsMES);
	
	
	ListOfObjects.Add(Catalogs.ProductionLots);
	ListOfObjects.Add(Catalogs.BillsOfMaterials);
	ListOfObjects.Add(Catalogs.ExtDimension);
	ListOfObjects.Add(Documents.InternalAcceptanceCertificate);
	ListOfObjects.Add(Documents.WorkOutput);
	ListOfObjects.Add(Documents.MovementOfProductsAndMaterials);
	ListOfObjects.Add(Documents.OrderOfMaterialsForProduction);
	ListOfObjects.Add(Documents.SubcontractOrder2_5);
	ListOfObjects.Add(Documents.SubcontractorReport2_5);
	
	ListOfObjects.Add(Documents.ProductionPlan);
	ListOfObjects.Add(Documents.BackflushProduction);
	ListOfObjects.Add(Documents.CalculationOfInventoryImpairmentProvision);
	ListOfObjects.Add(Documents.RecyclableWasteAllocation);
	ListOfObjects.Add(Documents.ProductionCostAllocation);
	ListOfObjects.Add(Documents.BudgetEntryForm);
	ListOfObjects.Add(Documents.IntangibleAssetsPhysicalCount);
	ListOfObjects.Add(Documents.FixedAssetsPhysicalCount);
	ListOfObjects.Add(Documents.ReceiptOfGoodsFromCustodian);
	ListOfObjects.Add(Documents.GoodsReceiptForStorage);
	ListOfObjects.Add(Documents.TransferOfGoodsToBailee);
	ListOfObjects.Add(Documents.RedemptionOfGoodsFromStorage);
	ListOfObjects.Add(Documents.RedemptionOfGoodsByCustodian);
	ListOfObjects.Add(Documents.RecognitionOfStockSurplusShippedToCustomer);
	ListOfObjects.Add(Documents.GoodsShipmentToCustomer);
	ListOfObjects.Add(Documents.GoodsShipmentFromStorage);
	ListOfObjects.Add(Documents.ReportOnVMIAdjustment);
	ListOfObjects.Add(Documents.WriteOffOfShippedGoods);
	ListOfObjects.Add(Documents.MisgradingOfGoodsAtCustodian);
	ListOfObjects.Add(Documents.DamageAtCustodian);
	ListOfObjects.Add(Documents.RequestForGoodsQualityControl);
	ListOfObjects.Add(Documents.GoodsQualityControlCertificate);
	
	ListOfObjects.Add(Documents.GoodsMisgradingNote);
	ListOfObjects.Add(DataProcessors.ReturnablePackagingManagement);
	ListOfObjects.Add(Catalogs.IntercompanyContracts);
	ListOfObjects.Add(Catalogs.BusinessStructure);
	
	ListOfObjects.Add(Catalogs.CounterpartyBankAccounts);
	ListOfObjects.Add(Catalogs.CompaniesBankAccounts);
	ListOfObjects.Add(Catalogs.OptionsOfLoansAndDepositsSchedules);
	ListOfObjects.Add(Catalogs.CustomerRebatesKinds);
	ListOfObjects.Add(Catalogs.VendorRebateKinds);
	ListOfObjects.Add(Catalogs.KeyboardShortcuts);
	ListOfObjects.Add(Catalogs.AnalyticalInventoryGroups);
	ListOfObjects.Add(Catalogs.InventoryAccountingGroups);
	ListOfObjects.Add(Catalogs.CounterpartyContracts);
	ListOfObjects.Add(Catalogs.LoanAndDepositContracts);
	ListOfObjects.Add(Catalogs.AcquiringContracts);
	ListOfObjects.Add(Catalogs.LoyaltyCards);
	ListOfObjects.Add(Catalogs.Counterparties);
	ListOfObjects.Add(Catalogs.CWPSettings);
	ListOfObjects.Add(Catalogs.Products);
	ListOfObjects.Add(Catalogs.StorageAreas);
	ListOfObjects.Add(Catalogs.Companies);
	ListOfObjects.Add(Catalogs.Partners);
	ListOfObjects.Add(Catalogs.GiftCertificates);
	ListOfObjects.Add(Catalogs.RulesOfExchangeWithOfflinePeripherals);
	ListOfObjects.Add(Catalogs.Complaints);
	ListOfObjects.Add(Catalogs.WarehouseZones);
	ListOfObjects.Add(Catalogs.SalesOpportunitiesToCustomer);
	ListOfObjects.Add(Catalogs.QualityCertificates);
	ListOfObjects.Add(Catalogs.Warerooms);
	ListOfObjects.Add(Catalogs.StorageBins);
	ListOfObjects.Add(Catalogs.Warehouses);
	ListOfObjects.Add(Catalogs.TermsOfSale);
	ListOfObjects.Add(Catalogs.TermsOfPurchaseFromVendors);
	ListOfObjects.Add(Documents.ExpenseReport);
	ListOfObjects.Add(Documents.CustomerInvoiceServices);
	ListOfObjects.Add(Documents.DiscrepancyReportFollowingShipment);
	ListOfObjects.Add(Documents.DiscrepancyReportFollowingTransfer);
	ListOfObjects.Add(Documents.DiscrepancyReportFollowingReceipt);
	ListOfObjects.Add(Documents.CustomerBonusCertificate);
	ListOfObjects.Add(Documents.VendorBonusCertificate);
	ListOfObjects.Add(Documents.DepositCashIntoCashRegister);
	ListOfObjects.Add(Documents.ReturnOfGiftCards);
	ListOfObjects.Add(Documents.CashWithdrawalFromCashRegister);
	ListOfObjects.Add(Documents.OBEntry);
	ListOfObjects.Add(Documents.OBEntryCash);	
	ListOfObjects.Add(Documents.OBEntryARAP);
	ListOfObjects.Add(Documents.OBEntrySalesForPastPeriods);	
	ListOfObjects.Add(Documents.OBEntryFinancialInstruments);
	ListOfObjects.Add(Documents.OBEntryOtherExpenses);
	ListOfObjects.Add(Documents.OBEntryOtherAssetsAndLiabilities);
	ListOfObjects.Add(Documents.OBEntryAcquiringContractARAP);
	ListOfObjects.Add(Documents.OBEntryARAPAdvanceHolders);
	ListOfObjects.Add(Documents.OBEntryGoods);
	ListOfObjects.Add(Documents.ARAPSettlement);
	ListOfObjects.Add(Documents.InventoryConsumption);
	ListOfObjects.Add(Documents.IntercompanyGoodsReturn);
	ListOfObjects.Add(Documents.ReturnOfGoodsFromCustomer);
	ListOfObjects.Add(Documents.ReturnOfGoodsToVendor);
	ListOfObjects.Add(Documents.ReturnablePackagingRedemptionByCustomer);
	ListOfObjects.Add(Documents.IssuedLetterOfAuthority);
	ListOfObjects.Add(Documents.TransportationJob);
	ListOfObjects.Add(Documents.JobForSalesRepresentative);
	ListOfObjects.Add(Documents.SalesOrder);
	ListOfObjects.Add(Documents.InventoryConsumptionOrder);
	ListOfObjects.Add(Documents.DeliveryOrder);
	ListOfObjects.Add(Documents.TransferOrder);
	ListOfObjects.Add(Documents.ByAssemblyDisassemblyOrder);
	ListOfObjects.Add(Documents.PurchaseOrder);
	ListOfObjects.Add(Documents.RequestForReturnOfGoodsFromCustomer);
	ListOfObjects.Add(Documents.ApplicationForBusinessTrip);
	ListOfObjects.Add(Documents.PaymentRequest);
	ListOfObjects.Add(Documents.ProductRangeChange);
	ListOfObjects.Add(Documents.PhysicalCountReport);
	ListOfObjects.Add(Documents.PhysicalCountOfCashAccounts);
	ListOfObjects.Add(Documents.InventoryAdjustmentGoodsShipmentOrder);
	ListOfObjects.Add(Documents.PurchaseAdjustment);
	ListOfObjects.Add(Documents.SaleAdjustment);
	ListOfObjects.Add(Documents.RegisterAdjustment);
	ListOfObjects.Add(Documents.CashFlowLimits);
	ListOfObjects.Add(Documents.AccrualOfCustomerRebates);
	ListOfObjects.Add(Documents.AccrualOfVendorRebates);
	ListOfObjects.Add(Documents.SalesPlansAllocationBaseByCategories);
	ListOfObjects.Add(Documents.PlannedCashReceipt);
	ListOfObjects.Add(Documents.PaymentCardTransaction);
	ListOfObjects.Add(Documents.InventorySurplusRecognition);
	ListOfObjects.Add(Documents.GoodsSurplusesNote);
	ListOfObjects.Add(Documents.GoodsShortageNote);
	ListOfObjects.Add(Documents.DamageNote);
	ListOfObjects.Add(Documents.GoodsTransferNote);
	ListOfObjects.Add(Documents.GoodsPickingPlacement);
	ListOfObjects.Add(Documents.CashDepositWithdrawalDiscrepancies);
	ListOfObjects.Add(Documents.BankReportOnAcquiringTransactions);
	ListOfObjects.Add(Documents.ConsignmentReportFromCustomer);
	ListOfObjects.Add(Documents.WriteOffReportFromCommissionAgent);
	ListOfObjects.Add(Documents.ConsignmentReportToVendor);
	ListOfObjects.Add(Documents.PurchaseInvoiceConsignmentStockLost);
	ListOfObjects.Add(Documents.PurchasingReportToConsignorPrincipal);
	ListOfObjects.Add(Documents.RetailSalesReport);
	ListOfObjects.Add(Documents.RetailReturnsReport);	
	ListOfObjects.Add(Documents.CommissionReportIntercompany);
	ListOfObjects.Add(Documents.CommissionWriteOffReportIntercompany);
	ListOfObjects.Add(Documents.SourceDocument);
	ListOfObjects.Add(Documents.CustomerInvoiceIntercompany);
	ListOfObjects.Add(Documents.InventoryTransfer);
	ListOfObjects.Add(Documents.GoodsMisgrading);
	ListOfObjects.Add(Documents.InventoryRecount);
	ListOfObjects.Add(Documents.PurchasePlan);
	ListOfObjects.Add(Documents.PlanOfGoodsStock);
	ListOfObjects.Add(Documents.SalesPlan);
	ListOfObjects.Add(Documents.SalesPlanByCategories);
	ListOfObjects.Add(Documents.InventoryConsumptionPlan);
	ListOfObjects.Add(Documents.AssemblyDisassemblyPlan);
	ListOfObjects.Add(Documents.GoodsDamage);
	ListOfObjects.Add(Documents.InstructionForShippingAgent);
	ListOfObjects.Add(Documents.BankAccountReceiptNote);
	ListOfObjects.Add(Documents.ReceiptOfGoodsToWarehouse);
	ListOfObjects.Add(Documents.GoodsReceiptFromCustomer);
	ListOfObjects.Add(Documents.ReceiptOfServicesToBusinessUnit);
	ListOfObjects.Add(Documents.BankConfirmationAboutCashReceiptOnEmployeeAccount);
	ListOfObjects.Add(Documents.VendorInvoice);
	ListOfObjects.Add(Documents.VendorInvoiceServicesAndAssets);
	ListOfObjects.Add(Documents.CashAccountReceiptNote);
	ListOfObjects.Add(Documents.GoodsReceiptNote);
	ListOfObjects.Add(Documents.OtherGoodsRecordingAsReceived);
	ListOfObjects.Add(Documents.OtherIncomeExpenses);
	ListOfObjects.Add(Documents.CashTransferReferenceOrder);
	ListOfObjects.Add(Documents.AllocationOfIncomeByLinesOfBusiness);
	ListOfObjects.Add(Documents.AllocationOfOtherCosts);
	ListOfObjects.Add(Documents.DeferredExpensesAllocation);
	ListOfObjects.Add(Documents.CashVoucher);
	ListOfObjects.Add(Documents.GoodsIssueNote);
	ListOfObjects.Add(Documents.InventoryCostCalculation);
	ListOfObjects.Add(Documents.GiftCertificateSale);
	ListOfObjects.Add(Documents.CustomerInvoice);
	ListOfObjects.Add(Documents.CustomerInvoiceServicesAndAssets);
	ListOfObjects.Add(Documents.VendorPriceList);
	ListOfObjects.Add(Documents.Trip);
	ListOfObjects.Add(Documents.AssemblyFromComponents);
	ListOfObjects.Add(Documents.ARAPReconciliation2_4);
	ListOfObjects.Add(Documents.ARAPReconciliation2_5_11);
	ListOfObjects.Add(Documents.ReconcileOpeningBalancesByWarehouses);
	ListOfObjects.Add(Documents.BankAccountIssue);
	ListOfObjects.Add(Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
	ListOfObjects.Add(Documents.ARAPAdjustment);
	ListOfObjects.Add(Documents.WriteOffOfGoodsShortages);
	ListOfObjects.Add(Documents.CustomerCommercialInvoice);
	ListOfObjects.Add(Documents.CCDImport);
	ListOfObjects.Add(Documents.PackingList);
	ListOfObjects.Add(Documents.ConditionsOfCustomerRebates);
	ListOfObjects.Add(Documents.ConditionsOfVendorRebates);
	ListOfObjects.Add(Documents.SetStorageBinLocks);
	ListOfObjects.Add(Documents.SetProductRangeQuotas);
	ListOfObjects.Add(Documents.PriceSetup);
	ListOfObjects.Add(Documents.CashRegisterReceipt);
	ListOfObjects.Add(Documents.CashRegisterReceiptReturn);
	ListOfObjects.Add(Documents.ReceiptOfCashRegisterAdjustment);
	ListOfObjects.Add(DataProcessors.WorkplaceOfDeliveryOfficer);
	ListOfObjects.Add(DataProcessors.ShipGoodsFromWarehouse);
	ListOfObjects.Add(DataProcessors.ManagementOfTransferredReturnablePackaging);
	ListOfObjects.Add(DataProcessors.InboundWarehouseMangement);
	ListOfObjects.Add(DataProcessors.WarehouseGoodsIssueReceipt);
	
	ListOfObjects.Add(Documents.ReversingEntry);
	
	VATAccountingERP.OnDefinePrintSettings(Settings);
EndProcedure

// See PrintManagementOverridable.OnDefineObjectsWithPrintCommands
Procedure DefineObjectsWithPrintCommands(ListOfObjects) Export
	ListOfObjects.Add(Documents.CommercialProposalForCustomer);
	ListOfObjects.Add(Catalogs.Persons);
	VATAccountingERP.OnDefineObjectsWithPrintCommands(ListOfObjects);
EndProcedure

// See PrintManagementOverridable.BeforeAddPrintCommands
//
Procedure AddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
	If FormName = "Document.DamageNote.Form.ListForm" Then
		
		StandardProcessing = False;
		
		CollectionOfPrintCommands = PrintManagement.CreatePrintCommandsCollection();
		Documents.BankAccountIssue.AddPrintCommands(CollectionOfPrintCommands);
		For Each PrintCommand In CollectionOfPrintCommands Do
			If IsBlankString(PrintCommand.PrintManager) Then
				PrintCommand.PrintManager = "Document.DamageNote";
			EndIf;
		EndDo;
		AdditionalReportsAndDataProcessors.OnReceivePrintCommands(CollectionOfPrintCommands, "Document.DamageNote");
		
		CommonClientServer.SupplementTable(CollectionOfPrintCommands, PrintCommands);
		
	
	ElsIf FormName = "DocumentJournal.ReportsToConsignors.Form.DocumentsListForm" Then
		
		StandardProcessing = False;
		
		Documents.ConsignmentReportToVendor.AddPrintCommands(PrintCommands);
		For Each PrintCommand In PrintCommands Do
			If IsBlankString(PrintCommand.PrintManager) Then
				PrintCommand.PrintManager = "Document.ConsignmentReportToVendor";
			EndIf;
		EndDo;
		
		PrintCommandsToAdd = PrintManagement.CreatePrintCommandsCollection();
		Documents.PurchaseInvoiceConsignmentStockLost.AddPrintCommands(PrintCommandsToAdd);
		For Each PrintCommand In PrintCommandsToAdd Do
			If IsBlankString(PrintCommand.PrintManager) Then
				PrintCommand.PrintManager = "Document.PurchaseInvoiceConsignmentStockLost";
			EndIf;
			Filter = New Structure("Id,Presentation,PrintManager,Handler");
			FillPropertyValues(Filter, PrintCommand);
			FoundCommands = PrintCommands.FindRows(Filter);
			If FoundCommands.Count() = 0 Then
				FillPropertyValues(PrintCommands.Add(), PrintCommand);
			EndIf;
		EndDo;
		
		AdditionalReportsAndDataProcessors.OnReceivePrintCommands(PrintCommands, "Document.ConsignmentReportToVendor");
		AdditionalReportsAndDataProcessors.OnReceivePrintCommands(PrintCommands, "Document.PurchaseInvoiceConsignmentStockLost");
	
	ElsIf FormName = "DataProcessor.LogOfPurchaseDocuments.Form.ReferenceChoiceForm" Then
		
		StandardProcessing = False;
		
		Documents.PurchaseOrder.AddPrintCommands(PrintCommands);
		For Each PrintCommand In PrintCommands Do
			If IsBlankString(PrintCommand.PrintManager) Then
				PrintCommand.PrintManager = "Document.PurchaseOrder";
			EndIf;
		EndDo;
		
		AdditionalReportsAndDataProcessors.OnReceivePrintCommands(PrintCommands, "Document.PurchaseOrder");
	
	ElsIf FormName = "Catalog.QualityCertificates.Form.ContextListForm" 
	 Or FormName = "Catalog.QualityCertificates.Form.ListForm" Then
		
		StandardProcessing = False;
		
		Catalogs.QualityCertificates.AddPrintCommands(PrintCommands);
		
		AdditionalReportsAndDataProcessors.OnReceivePrintCommands(PrintCommands, "Catalog.QualityCertificates");
		
	EndIf;
	
	VATAccountingERP.BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing);
		
	PrintManagementLocalization.BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing);
	
EndProcedure

// See PrintManagementOverridable.OnGetPrintCommandListSettings
Procedure GetPrintCommandListSettings(ListSettings) Export
	
	PrintManagementLocalization.OnGetPrintCommandListSettings(ListSettings);
	
EndProcedure

// see Print managementdetermined.In the heat of the moment
Procedure OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If TypeOf(ObjectsArray) = Type("Array")
		And ObjectsArray.Count()
		And TypeOf(ObjectsArray[0]) = Type("DocumentRef.TransportationJob") Then
		GoodsDelivery.OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	ElsIf TypeOf(ObjectsArray) = Type("DocumentRef.TransportationJob") Then
		ArrayOfTasks = New Array;
		ArrayOfTasks.Add(ObjectsArray);
		GoodsDelivery.OnPrint(ArrayOfTasks, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	EndIf;
	
	PrintManagementLocalization.OnPrint(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// see Print managementdetermined.Before sending by Post
Procedure BeforeSendingByEmail(SendOptions, OutputParameters, PrintObjects, PrintForms) Export
	
EndProcedure

// See PrintManagementOverridable.PrintDocumentsOnCreateAtServer
Procedure PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	PrintManagementLocalization.PrintDocumentsOnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

// See PrintManagementOverridable.OnDefineKeyAttributesOfDefaultPrintForms
Procedure OnDefineKeyAttributesOfDefaultPrintForms(Ref, KeyAttributes) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DocumentsRegistry.Organization AS Organization,
		|	DocumentsRegistry.Counterparty.Key AS Recipient
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.Ref = &Ref";
	
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		FillPropertyValues(KeyAttributes, Selection);
	EndIf;
	
EndProcedure

#EndRegion

// Constructor for the PrintForm Collection parameter of the Print procedure.
// 
// Parameters:
//  TemplatesNames - String - Layout Names
// 
// Returns:
//  ValueTable - empty collection of printed forms:
//   * TemplateName - String - ID of the printed form;
//   * UpperCaseName - String - ID in uppercase characters for quick search;
//   * TemplateSynonym - String - presentation of the printed form;
//   * SpreadsheetDocument - SpreadsheetDocument - printed form;
//   * Copies2 - Number - number of copies to print;
//   * Picture - Picture - (not use);
//   * FullTemplatePath - String - used to quickly switch to editing the layout of a printed form;
//   * PrintFormFileName - String - file name;
//                           - Map - file names for each object:
//                              ** Key - AnyRef - link to the print object;
//                              ** Value - String - file name;
//   * OfficeDocuments - Map - collection of printed forms in the format of office documents:
//                         ** Key - String - address in the temporary storage of binary data of the printed form;
//                         ** Value - String - name of the print form file.
Function PreparePrintFormsCollection(Val TemplatesNames) Export
	
	Templates = New ValueTable;
	Templates.Columns.Add("TemplateName");
	Templates.Columns.Add("UpperCaseName");
	Templates.Columns.Add("TemplateSynonym");
	Templates.Columns.Add("SpreadsheetDocument");
	Templates.Columns.Add("Copies2");
	Templates.Columns.Add("Picture");
	Templates.Columns.Add("FullTemplatePath");
	Templates.Columns.Add("PrintFormFileName");
	Templates.Columns.Add("OfficeDocuments");
	
	If TypeOf(TemplatesNames) = Type("String") Then
		TemplatesNames = StrSplit(TemplatesNames, ",");
	EndIf;
	
	For Each TemplateName In TemplatesNames Do
		Template = Templates.Find(TemplateName, "TemplateName");
		If Template = Undefined Then
			Template = Templates.Add();
			Template.TemplateName = TemplateName;
			Template.UpperCaseName = Upper(TemplateName);
			Template.Copies2 = 1;
		Else
			Template.Copies2 = Template.Copies2 + 1;
		EndIf;
	EndDo;
	
	Return Templates;
	
EndFunction

#EndRegion