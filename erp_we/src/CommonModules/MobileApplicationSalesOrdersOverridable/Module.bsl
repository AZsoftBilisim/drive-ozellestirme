////////////////////////////////////////////////////////////////////////////////
//THE MODULE CONTAINS PROCEDURES AND FUNCTIONS FOR WORKING WITH EXCHANGE PACKAGES WITH THE 1C:ORDERS MOBILE APPLICATION:
// - working with exchange nodes
// - unloading of exchange objects
// - loading exchange objects
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region DataExport

// Records information on balances in an exchange message for the exchange node with the mobile app.
//
// Parameters:
//  XMLWriter - XMLWriter - the message exchange;
//  ExchangeNode - ExchangePlanRef - exchange node with a mobile app;
//  AuxProperties - Structure - contains data for continuing the exchange.
//
Procedure UnloadAvailableBalances(XMLWriter, ExchangeNode, AuxProperties) Export
	
	If Not AuxProperties = Undefined Then
		BalanceTable = AuxProperties.BalanceTable;
		ExportedObjects = AuxProperties.ExportedObjects;
	Else
		BalanceTable = DataForUnloadingBalances(ExchangeNode);
		ExportedObjects = New Map;
	EndIf;
	
	ExchangeStartTime = CurrentSessionDate();
	Required2Continued = False;
	For Each RemainderLine_ In BalanceTable Do
		// Let's check the correctness of the nomenclature characteristics.
		RefSearchStructure = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			RemainderLine_.Products, RemainderLine_.Characteristic, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		If RefSearchStructure.ItemVariantsAreUsed
			And Not ValueIsFilled(RefSearchStructure.Characteristic) Then
			Continue;
		EndIf;
		ProductsIdentifier = TrimAll(RemainderLine_.Products.UUID());
		ItemVariantID = ?(ValueIsFilled(RemainderLine_.Characteristic),
			TrimAll(RemainderLine_.Characteristic.UUID()), "");
		If RefSearchStructure.ItemVariantsAreUsed Then
			RemainderLine_.ref = IDOfMPObject(ProductsIdentifier, ItemVariantID, "");
		Else
			RemainderLine_.ref = ProductsIdentifier;
		EndIf;
		RemainderLine_.WarehouseRef = TrimAll(RemainderLine_.Warehouse.UUID());
		WriteStringOfXMLResidues(XMLWriter, RemainderLine_);
		RemainderLine_.Exported = True;
		TimeToUnloadLeftovers = CurrentSessionDate();
		If TimeToUnloadLeftovers - ExchangeStartTime > 30 Then
			Required2Continued = True;
			Break;
		EndIf;
	EndDo;
	
	AuxProperties = New Structure("Continued", False);
	If Required2Continued Then
		UnloadedRows = BalanceTable.FindRows(New Structure("Exported", True));
		For Each RowToDelete In UnloadedRows Do
			BalanceTable.Delete(RowToDelete);
		EndDo;
		AuxProperties.Insert("Continued", True);
		AuxProperties.Insert("BalanceTable", BalanceTable);
		AuxProperties.Insert("ExportedObjects", ExportedObjects);
	EndIf;
EndProcedure

// Writes task data to an exchange message for the exchange node with the mobile app.
//
// Parameters:
//  XMLWriter - XMLWriter - the message exchange;
//  ExchangeNode - ExchangePlanRef - the site plan of exchange with a mobile app;
//  ExchangeMessage - String - return the message exchange;
//  MessageNo - Number - the number of the data exchange message.
//
Procedure UploadTasksForSharing(XMLWriter, ExchangeNode, ExchangeMessage, MessageNo) Export
	
	FilterChanges = New Array;
	FilterChanges.Add(Metadata.Documents.JobForSalesRepresentative);
	
	ArrayOfChanges = ArrayOfChanges(ExchangeNode, MessageNo, FilterChanges);
	
	UseAgreementsAndContracts = GetFunctionalOption("ToUseTermsOfSales")
		Or GetFunctionalOption("UseCustomerContracts");
	For Each Data In ArrayOfChanges Do
		
		If TypeOf(Data) = Type("ObjectDeletion") Then
			// Deleting an object is not passed to the main IB.
			ExchangePlans.DeleteChangeRecords(ExchangeNode, Data);
			Continue;
		EndIf;
				
		If TypeOf(Data) = Type("DocumentObject.JobForSalesRepresentative") Then
			If Not (Data.Status = Enums.SalesRepresentativeTaskStatuses.ToProcessing
			Or Data.Status = Enums.SalesRepresentativeTaskStatuses.Processed_) Then
				ExchangePlans.DeleteChangeRecords(ExchangeNode, Data);
				Continue;
			EndIf;
		EndIf;
		
		If Data.Status = Enums.SalesRepresentativeTaskStatuses.Processed_ Then
			WritePrintedOrderFormForTask(XMLWriter, Data)
		Else
			ProcessObjectBeforeWritingToExchangePacket(Data);
			WriteTaskToExchangePackage(XMLWriter, Data, UseAgreementsAndContracts);
		EndIf;
		
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Data);
	EndDo;
EndProcedure

// Writes client data to an exchange message for the exchange node with the mobile app.
//
// Parameters:
//  XMLWriter - XMLWriter - the message exchange;
//  ExchangeNode - ExchangePlanRef - exchange node with a mobile app;
//  AuxProperties - Structure - contains data for continuing the exchange.
//  UploadCompleteDossier - Boolean - flag for uploading the full dossier. 
//
Procedure UnloadClientsForExchange(XMLWriter, ExchangeNode, AuxProperties, UploadCompleteDossier = False) Export
	
	If Not AuxProperties = Undefined Then
		TableOfModified = AuxProperties.TableOfModified;
		ExportedObjects = AuxProperties.ExportedObjects;
	Else
		TableOfModified = DataForUnloadingClients(ExchangeNode);
		ExportedObjects = New Map;
	EndIf;
	
	CorrespondenceTableForIndividualPrices = New ValueTable;
	CorrespondenceTableForIndividualPrices.Columns.Add("Terms",
		New TypeDescription("CatalogRef.TermsOfSale"));
	CorrespondenceTableForIndividualPrices.Columns.Add("IDOfSalesCondition",
		New TypeDescription("String"));
	CorrespondenceTableForIndividualPrices.Columns.Add("AgreementID_",
		New TypeDescription("String"));
	CorrespondenceTableForIndividualPrices.Columns.Add("PriceKind",
		New TypeDescription("CatalogRef.TypesOfPrices"));
	CorrespondenceTableForIndividualPrices.Columns.Add("ProductSegment",
		New TypeDescription("CatalogRef.ProductSegments"));
	CorrespondenceTableForIndividualPrices.Columns.Add("Currency",
		New TypeDescription("CatalogRef.Currencies"));
	CorrespondenceTableForIndividualPrices.Columns.Add("Warehouse",
		New TypeDescription("CatalogRef.Warehouses"));
	CorrespondenceTableForIndividualPrices.Columns.Add("UseCharacteristics",
		New TypeDescription("Boolean"));
	CorrespondenceTableForIndividualPrices.Columns.Add("UseProductSegments",
		New TypeDescription("Boolean"));
	
	ProductSegmentsAreUsed = GetFunctionalOption("UseProductSegments");
	MultipleWarehousesAreUsed = GetFunctionalOption("UseSeveralWarehouses");
	UseAgreementsAndContracts = GetFunctionalOption("ToUseTermsOfSales")
		Or GetFunctionalOption("UseCustomerContracts");
	ExchangeStartTime = CurrentSessionDate();
	Required2Continued = False;
	
	LanguageCode =  Common.DefaultLanguageCode();
	
	RecordTitle = NStr("vi = 'Trao đổi bạn hàng';
						|ru = 'Обмен партнерами';
						|en = 'Exchange of partners'; fa = 'Exchange of partners';
						|it = 'Scambio partner';
						|pl = 'Wymiana partnerami';
						|tr = 'İş ortaklarının değişimi'") + "." + NStr("vi = 'Bắt đầu gói kết xuất bạn hàng';
																	|ru = 'Начало пакета выгрузки партнеров';
																	|en = 'Beginning of partners export package'; fa = 'Beginning of partners export package';
																	|it = 'Inizio pacchetto scarico dei partner';
																	|pl = 'Początek pakietu eksportowania partnerów';
																	|tr = 'İş ortakları yükleme paketinin başlatılması'", LanguageCode);
	MessageText = StrTemplate(NStr("vi = 'Số lượng dòng khách hàng khi bắt đầu: %1';
									|ru = 'Количество строк клиентов на начало: %1';
									|en = 'Quantity of customer lines as of the beginning: %1'; fa = 'Quantity of customer lines as of the beginning: %1';
									|it = 'Numero di righe dei clienti all''inizio: %1';
									|pl = 'Ilość wierszy Klientów na początek: %1';
									|tr = 'Başlangıçtaki müşteri satırı sayısı:%1'", LanguageCode), Format(TableOfModified.Count(), "NG="));
	WriteLogEvent(RecordTitle, EventLogLevel.Information,,, MessageText);
	
	For Each DataString1 In TableOfModified Do
		CorrespondenceTableForIndividualPrices.Clear();
		// If you need to delete a partner, then you need to record the deletion of data.
		// For situations when the partner has ceased to be a client, or is not available to the MP user.
		DeletePartner = DataString1.DeletePartner;
		If DeletePartner Then
			If ExportedObjects.Get(DataString1.PartnerForExport) = Undefined Then
				ExportedObjects.Insert(DataString1.PartnerForExport, DataString1.PartnerForExport);
				// We get the value with the possible deletion of data.
				Data = DataString1.PartnerForExport.GetObject();
				If ValueIsFilled(DataString1.PartnerForExport) And Data = Undefined Then
					Data = New ObjectDeletion(DataString1.PartnerForExport);
					ExchangePlans.DeleteChangeRecords(ExchangeNode, DataString1.PartnerForExport);
				Else
					ExchangePlans.DeleteChangeRecords(ExchangeNode, Data);
				EndIf;
				MobileApplicationSalesOrders.DataDeletion(Data);
				If TypeOf(Data) = Type("ObjectDeletion") Then
					XDTOSerializer.WriteXML(XMLWriter, Data);
				EndIf;
				UploadClientContactPersons(XMLWriter, DataString1.PartnerForExport, True);
			EndIf;
			
			DataString1.Exported = True;
			
			PartnerUploadTime = CurrentSessionDate();
			If PartnerUploadTime - ExchangeStartTime > 30 Then
				Required2Continued = True;
				Break;
			Else
				Continue;
			EndIf;
		EndIf;
		
		// If you need to delete information about a partner, then you need to record the deletion of data.
		// For situations when the MP user cannot edit partners.
		DeletionRequired1 = DataString1.DeletionRequired1;
		If DeletionRequired1 And Not AbilityToAddPartnerChanges() Then
			If ExportedObjects.Get(DataString1.PartnerForExport) = Undefined Then
				ExportedObjects.Insert(DataString1.PartnerForExport, DataString1.PartnerForExport);
				Data = DataString1.PartnerForExport.GetObject();
				If ValueIsFilled(DataString1.PartnerForExport) And Data = Undefined Then
					Data = New ObjectDeletion(DataString1.PartnerForExport);
					ExchangePlans.DeleteChangeRecords(ExchangeNode, DataString1.PartnerForExport);
				Else
					ExchangePlans.DeleteChangeRecords(ExchangeNode, Data);
				EndIf;
				MobileApplicationSalesOrders.DataDeletion(Data);
				If TypeOf(Data) = Type("ObjectDeletion") Then
					XDTOSerializer.WriteXML(XMLWriter, Data);
				EndIf;
				UploadClientContactPersons(XMLWriter, DataString1.PartnerForExport, True);
			EndIf;
			
			DataString1.Exported = True;
			
			PartnerUploadTime = CurrentSessionDate();
			If PartnerUploadTime - ExchangeStartTime > 30 Then
				Required2Continued = True;
				Break;
			Else
				Continue;
			EndIf;
		EndIf;
		
		If ExportedObjects.Get(DataString1.PartnerForExport) = Undefined Then
			InformationOnPartner = InformationOnPartner(DataString1, UploadCompleteDossier);
			LocalObjectName = "CatalogObject.Клиенты"; //@NON-NLS-1
			WriteCatalog(XMLWriter, InformationOnPartner, LocalObjectName);
			UploadClientContactPersons(XMLWriter, DataString1.PartnerForExport, False);
			ExchangePlans.DeleteChangeRecords(ExchangeNode, DataString1.PartnerForExport.GetObject());
			ExportedObjects.Insert(DataString1.PartnerForExport, DataString1.PartnerForExport);
		EndIf;
		
		If ExportedObjects.Get(DataString1.CounterpartyRef) = Undefined Then
			Data = DataString1.CounterpartyRef.GetObject();
			If ValueIsFilled(DataString1.CounterpartyRef) And Data = Undefined Then
				Data = New ObjectDeletion(DataString1.CounterpartyRef);
			EndIf;
			If Not TypeOf(Data) = Type("CatalogObject.Counterparties") Then
				MobileApplicationSalesOrders.DataDeletion(Data);
			EndIf;
			If TypeOf(Data) = Type("ObjectDeletion") Then
				XDTOSerializer.WriteXML(XMLWriter, Data);
			Else
				If Not Data = Undefined Then
					CounterpartyInformation = CounterpartyInformation(DataString1);
					LocalObjectName = "CatalogObject.Контрагенты"; //@NON-NLS-1
					WriteCatalog(XMLWriter, CounterpartyInformation, LocalObjectName);
				EndIf;
			EndIf;
			ExportedObjects.Insert(DataString1.CounterpartyRef, DataString1.CounterpartyRef);
		EndIf;
		
		If DeletionRequired1 Then
			
			DataString1.Exported = True;
			
			PartnerUploadTime = CurrentSessionDate();
			If PartnerUploadTime - ExchangeStartTime > 30 Then
				Required2Continued = True;
				Break;
			Else
				Continue;
			EndIf;
		EndIf;
		
		If UseAgreementsAndContracts Then
			If Not ValueIsFilled(DataString1.SalesConditionID)
				Or ValueIsFilled(DataString1.SalesConditionID)
				And ExportedObjects.Get(DataString1.SalesConditionID) = Undefined Then
				
				If ValueIsFilled(DataString1.Terms) Then
					Try
						Data = DataString1.Terms.GetObject();
						DeleteSalesCondition = False;
						If Not TypeOf(Data) = Type("CatalogObject.TermsOfSale") Then
							DeleteSalesCondition = True;
						EndIf;
					Except
						DeleteSalesCondition = True;
					EndTry;
				EndIf;
				
				If ValueIsFilled(DataString1.Contract) Then
					Try
						Data = DataString1.Contract.GetObject();
						DeleteSalesCondition = False;
						If Not TypeOf(Data) = Type("CatalogObject.CounterpartyContracts") Then
							DeleteSalesCondition = True;
						EndIf;
					Except
						DeleteSalesCondition = True;
					EndTry;
				EndIf;
				
				If Not DeleteSalesCondition Then
					AgreementLine_ = AgreementWithClientOnOrganizationAndTypeOfPrices(DataString1);
					If Not AgreementLine_ = Undefined Then
							LocalObjectName = "CatalogObject.ДоговорыКлиентов"; //@NON-NLS-1
							WriteCatalog(XMLWriter, AgreementLine_, LocalObjectName);
						If DataString1.AgreementIsValid Then
							WriteDownSalesRules(XMLWriter, DataString1);
						EndIf;
						ExportedObjects.Insert(DataString1.SalesConditionID, DataString1.SalesConditionID);
					EndIf;
				EndIf;
			EndIf;
			
			If Not DataString1.AgreementIsValid = Undefined And DataString1.AgreementIsValid Then
				If DataString1.StandardAgreement 
					Or Not DataString1.ThereIsPriceSpecification Then
					
					DataString1.Exported = True;
					
					PartnerUploadTime = CurrentSessionDate();
					If PartnerUploadTime - ExchangeStartTime > 30 Then
						Required2Continued = True;
						Break;
					Else
						Continue;
					EndIf;
				EndIf;
				MapRow = CorrespondenceTableForIndividualPrices.Add();
				MapRow.Terms = DataString1.Terms;
				MapRow.IDOfSalesCondition = DataString1.SalesConditionID;
				MapRow.AgreementID_ = TrimAll(DataString1.Terms.UUID());
				MapRow.PriceKind = DataString1.PriceKind;
				If ProductSegmentsAreUsed Then
					MapRow.ProductSegment = DataString1.AgreementProductSegment;
				EndIf;
				If MultipleWarehousesAreUsed Then
					MapRow.Warehouse = DataString1.AgreementWarehouse;
				Else
					MapRow.Warehouse = Catalogs.Warehouses.DefaultWarehouse();
				EndIf;
				MapRow.UseProductSegments = ProductSegmentsAreUsed
				And ValueIsFilled(MapRow.ProductSegment);
				CorrespondenceTableForIndividualPrices.FillValues(
				MobileApplicationSalesOrdersCached.CurrencyOfOrders(), "Currency");
				CorrespondenceTableForIndividualPrices.FillValues(
					GetFunctionalOption("UseItemVariants"), "UseCharacteristics");
				RecordIndividualCustomerPrices(XMLWriter, ExchangeNode, ExportedObjects,
				CorrespondenceTableForIndividualPrices);
			EndIf;
		EndIf;
		
		DataString1.Exported = True;
		
		PartnerUploadTime = CurrentSessionDate();
		If PartnerUploadTime - ExchangeStartTime > 30 Then
			Required2Continued = True;
			Break;
		EndIf;
	EndDo;
	
	AuxProperties = New Structure("Continued", False);
	If Required2Continued Then
		UnloadedRows = TableOfModified.FindRows(New Structure("Exported", True));
		For Each RowToDelete In UnloadedRows Do
			TableOfModified.Delete(RowToDelete);
		EndDo;
		AuxProperties.Insert("Continued", True);
		AuxProperties.Insert("TableOfModified", TableOfModified);
		AuxProperties.Insert("ExportedObjects", ExportedObjects);
	Else
		ClearThoseNotIncludedInSelection(XMLWriter, ExchangeNode);
	EndIf;
	
	RecordTitle = NStr("vi = 'Trao đổi bạn hàng';
						|ru = 'Обмен партнерами';
						|en = 'Exchange of partners'; fa = 'Exchange of partners';
						|it = 'Scambio partner';
						|pl = 'Wymiana partnerami';
						|tr = 'İş ortaklarının değişimi'") + "." + NStr("vi = 'Kết thúc gói kết xuất bạn hàng';
																	|ru = 'Конец пакета выгрузки партнеров';
																	|en = 'End of partners export package'; fa = 'End of partners export package';
																	|it = 'Fine pacchetto scarico dei partner';
																	|pl = 'Koniec pakietu eksportowania partnerów';
																	|tr = 'İş ortakları yükleme paketinin sonlandırılması'", LanguageCode);
	MessageText = StrTemplate(NStr("vi = 'Số lượng dòng khách hàng khi kết thúc: %1';
									|ru = 'Количество строк клиентов на конец: %1';
									|en = 'Quantity of customer lines as of the end: %1'; fa = 'Quantity of customer lines as of the end: %1';
									|it = 'Numero di righe dei clienti alla fine: %1';
									|pl = 'Ilość wierszy Klientów na koniec: %1';
									|tr = 'Sondaki müşteri satırlarının sayısı: %1'", LanguageCode), Format(TableOfModified.Count(), "NG="));
	WriteLogEvent(RecordTitle, EventLogLevel.Information,,, MessageText);
EndProcedure

// Fills in the message for sharing information about the app settings for the mobile app.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - exchange node with a mobile app;
//  ResponseStructure - Structure - the message exchange.
//
Procedure UploadSettingsForSharing(ExchangeNode, ResponseStructure) Export
	
	NodeAttributes = MobileApplicationSalesOrders.NodeAttributes(ExchangeNode);
	
	TextSetOfConstants = "UseSalesOrders,
		|UseTermsOfSales, UseCustomerContracts,
		|UsePartnersAsCounterparties, UseSalesCommission, UseDiscountAdjustmentsInSales,
		|UseWarehousesInTabularSectionsOfSalesDocuments, UseAdvancedFeaturesOfSalesOrder,
		|UseJobsToSalesRepresentatives, ItemizeJobsForSalesRepresentatives,
		|UnitOfMeasureForWeight, UseRequestsForReturnOfGoodsFromCustomers, UseAdditionalAttributesAndInfo";
		
	ConstantsSet = Constants.CreateSet(TextSetOfConstants);
	ConstantsSet.Read();
	
	AvailableFunctions = MobileAppUserVerification();
	
	ResponseStructure.Insert("AddChangeCustomer", AvailableFunctions.ChangingClients);
	ResponseStructure.Insert("AddChangeCustomerOrders",
		ConstantsSet.UseSalesOrders And AvailableFunctions.SalesOrders);
	UseTermsOfSales = ?(ValueIsFilled(ConstantsSet.UseTermsOfSales),
		Enums.UseTermsOfSales.IndexOf(ConstantsSet.UseTermsOfSales), 0);
	ResponseStructure.Insert("UsingCustomerAgreement", UseTermsOfSales);
	ResponseStructure.Insert("UsePricesInOrderLine", True);
	ResponseStructure.Insert("UseCustomerContract", ConstantsSet.UseCustomerContracts);
	ResponseStructure.Insert("UseGoodsBalance", True);
	ResponseStructure.Insert("PartnersHowContractors", ConstantsSet.UsePartnersAsCounterparties);
	ResponseStructure.Insert("UseCommission", ConstantsSet.UseSalesCommission);
	ResponseStructure.Insert("UseManualDiscounts", ConstantsSet.UseDiscountAdjustmentsInSales);
	ResponseStructure.Insert("UseStoreInOrderLine", ConstantsSet.UseWarehousesInTabularSectionsOfSalesDocuments);
	ResponseStructure.Insert("UseOrderStatus", ConstantsSet.UseAdvancedFeaturesOfSalesOrder);
	ResponseStructure.Insert("ChangePriceInOrder", AvailableFunctions.PriceChange);
	ResponseStructure.Insert("FrequencyExchangeRates", 0);
	ResponseStructure.Insert("FrequencyExchangeBalance", 0);
	ResponseStructure.Insert("PrefixIB", NodeAttributes.PrefixForMobileDeviceData);
	ResponseStructure.Insert("MessageNumberIn", NodeAttributes.ReceivedNo);
	ResponseStructure.Insert("MessageNumberOut", NodeAttributes.SentNo);
	If AvailableFunctions.Jobs Then
		UsingTasks = ?(ValueIsFilled(ConstantsSet.UseJobsToSalesRepresentatives),
			Enums.UseJobsToSalesRepresentatives.IndexOf(
				ConstantsSet.UseJobsToSalesRepresentatives), 0);
	Else
		UsingTasks = 0;
	EndIf;
	ResponseStructure.Insert("UsingJobTargets", UsingTasks);
	ResponseStructure.Insert("DetailJobTargets", ConstantsSet.ItemizeJobsForSalesRepresentatives);
	ResponseStructure.Insert("UseCashPayment",
		(AvailableFunctions.CashAccount
			And ?(NodeAttributes.UseICOToRegisterPayment = Undefined, False,
					NodeAttributes.UseICOToRegisterPayment))
		Or (AvailableFunctions.LettersOfAuthority
			And ?(NodeAttributes.UsePowerOfAttorneyToRegisterPayment = Undefined, False,
					NodeAttributes.UsePowerOfAttorneyToRegisterPayment)));
	ResponseStructure.Insert("UseCashRegister", AvailableFunctions.CashAccount
		And ?(NodeAttributes.UseICOToRegisterPayment = Undefined, False,
			NodeAttributes.UseICOToRegisterPayment));
	ResponseStructure.Insert("UseCardPayment", AvailableFunctions.PaymentCard
		And ValueIsFilled(NodeAttributes.POSTerminal));
	ResponseStructure.Insert("CardsTypes", "");
	ResponseStructure.Insert("UsePushNotifications", ?(NodeAttributes.PushNotificationsAreSent = Undefined,
		False, NodeAttributes.PushNotificationsAreSent));
	ResponseStructure.Insert("GoogleCloudProjectNumber", NodeAttributes.GoogleCloudAppsApplicationNumber);
	ResponseStructure.Insert("UseImages", ?(NodeAttributes.TransmitProductImages = Undefined,
		False, NodeAttributes.TransmitProductImages));
	ResponseStructure.Insert("UseWeight", ?(NodeAttributes.UseWeightCharacteristics = Undefined,
		False, NodeAttributes.UseWeightCharacteristics));
	If ValueIsFilled(ConstantsSet.UnitOfMeasureForWeight) Then
		ResponseStructure.Insert("UnitWeight", TrimAll(ConstantsSet.UnitOfMeasureForWeight.UUID()));
	Else
		ResponseStructure.Insert("UnitWeight", BlankID());
	EndIf;
	ResponseStructure.Insert("UseRequestsToReturnOfGoodsByClient",
		AvailableFunctions.RequestsForReturn And ConstantsSet.UseRequestsForReturnOfGoodsFromCustomers);
	
	ResponseStructure.Insert("UseSimplifiedClientInput", PartnersAndCounterparties.SimplifiedInputAvailable());
	ResponseStructure.Insert("CheckTINRussianRules", Not PartnersAndCounterparties.SimplifiedInputAvailable());
	
	ResponseStructure.Insert("UseAdditionalProps", ConstantsSet.UseAdditionalAttributesAndInfo);
	ResponseStructure.Insert("UseCommonAdditionalValues", True);
	ResponseStructure.Insert("UseCommonAdditionalProps", True);
	
	ResponseStructure.Insert("ShowOddments", ?(NodeAttributes.DoNotDisplayBalanceWhenSelecting = Undefined,
		True, Not NodeAttributes.DoNotDisplayBalanceWhenSelecting));
		
	ResponseStructure.ResultMessage = "";
	ResponseStructure.Success = True;
EndProcedure

// Records price information in an exchange message for the exchange node with the mobile app.
//
// Parameters:
//  XMLWriter - XMLWriter - the message exchange;
//  ExchangeMessage - String - return the message exchange;
//  ExchangeNode - ExchangePlanRef - the site plan of exchange with a mobile app;
//  MessageNo - Number - number of the message exchanged with the mobile app;
//  AllPrices - Boolean - flag for uploading all prices;
//  AuxProperties - Structure - contains data for continuing the exchange.
//
Procedure UploadPriceListForExchange(XMLWriter, ExchangeMessage, ExchangeNode, MessageNo, AllPrices, AuxProperties) Export
	
	If Not AuxProperties = Undefined Then
		PriceListTable_ = AuxProperties.PriceListTable_;
		ExportedObjects = AuxProperties.ExportedObjects;
	Else
		Changes = PriceListChanges(ExchangeNode, AllPrices);
		PriceListTable_ = SalesRepresentativePriceList(ExchangeNode, Changes);
		ExportedObjects = New Map;
	EndIf;

	If PriceListTable_.Count() = 0 Then
		AuxProperties = New Structure;
		AuxProperties.Insert("Continued", False);
		ExchangeMessage = NStr("vi = 'Không có đơn giá hợp lệ.';
								|ru = 'Нет доступных цен.';
								|en = 'No available prices.'; fa = 'No available prices.';
								|it = 'Non ci sono prezzi disponibili.';
								|pl = 'Brak dostępnych cen.';
								|tr = 'Mevcut fiyat bulunmamaktadır.'", Common.DefaultLanguageCode());
		Return;
	EndIf;
	ExchangeStartTime = CurrentSessionDate();
	Required2Continued = False;
	NumberOfPriceListLines = 0;
	For Each PriceListLine In PriceListTable_ Do
		
		// Unloading objects from the price list line.
		UnloadingObjectsOfReferenceType(XMLWriter, ExportedObjects, PriceListLine, ExchangeNode);
		// We unload the price list line itself.
		WritePriceListLine(XMLWriter, PriceListLine);
		
		PriceListLine.Exported = True;
		PriceUploadTime = CurrentSessionDate();
		NumberOfPriceListLines = NumberOfPriceListLines + 1;
		If PriceUploadTime - ExchangeStartTime > 30
			Or NumberOfPriceListLines > 1000 Then
			Required2Continued = True;
			Break;
		EndIf;
	EndDo;
	
	AuxProperties = New Structure("Continued", False);
	If Required2Continued Then
		UnloadedRows = PriceListTable_.FindRows(New Structure("Exported", True));
		For Each RowToDelete In UnloadedRows Do
			PriceListTable_.Delete(RowToDelete);
		EndDo;
		AuxProperties.Insert("Continued", True);
		AuxProperties.Insert("PriceListTable_", PriceListTable_);
		AuxProperties.Insert("ExportedObjects", ExportedObjects);
	Else
		If AllPrices Then
			ClearRegistrationOfProductsAndImagesNotIncludedInExchange(ExchangeNode);
		EndIf;
	EndIf;
EndProcedure

// Writes directory data to an exchange message for the exchange node with the mobile app.
//
// Parameters:
//  XMLWriter - XMLWriter - the message exchange
//  ExchangeNode - ExchangePlanRef - exchange node with the mobile app.
//
Procedure UploadCatalogsForExchange(XMLWriter, ExchangeNode) Export
	
	CatalogTable_ = DataForUploadingCatalogs(ExchangeNode);
	
	ExportedObjects = New Array;
	For Each CatalogString In CatalogTable_ Do
		
		If ValueIsFilled(CatalogString.CurrencyRef) Then
			WriteCurrencyOfLine(XMLWriter, CatalogString);
		EndIf;
		
		If ValueIsFilled(CatalogString.CountryRef) Then
			WriteCountryOfLine(XMLWriter, CatalogString, ExportedObjects);
		EndIf;
		
		If ValueIsFilled(CatalogString.CIKindReference) Then
			WriteTypeOfKiLine(XMLWriter, CatalogString, ExportedObjects);
		EndIf;
		
		If ValueIsFilled(CatalogString.CompanyLink) Then
			RecordLineOrganization(XMLWriter, CatalogString);
		EndIf;
		
		If ValueIsFilled(CatalogString.PriceTypeReference) Then
			RecordPriceTypeOfLine(XMLWriter, CatalogString);
		EndIf;
		
		If ValueIsFilled(CatalogString.WarehouseReference) Then
			WriteFollowingLines(XMLWriter, CatalogString, ExportedObjects);
		EndIf;
		
		If ValueIsFilled(CatalogString.WeightUnitLink) Then
			WriteWeightUnitOfString(XMLWriter, CatalogString);
		EndIf;
	EndDo;
	
	If GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers") Then
		RecordRefundRequestStates(XMLWriter,
			Common.ObjectAttributeValue(ExchangeNode, "Code"));
	EndIf;
	
	//+ UP 2.2.
	If GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		RecordAdditionalItemDetails_(XMLWriter);
	EndIf;
	//- ERP 2.2.
EndProcedure

// Returns the response data on the status of customer orders.
//
// Parameters:
//  ResponseMessage - XMLWriter - response message according to the statuses of customer orders;
//  OrderIDs - Array - read array of identifiers of customer orders.
//
// Returns:
//  Array - an array containing data on the statuses of customer orders.
//
Function ResponseDataStatusOfCustomerOrders(ResponseMessage, Val OrderIDs) Export
	
	SalesOrders = New Array;
	
	For Each IDOrder In OrderIDs Do
		
		If TypeOf(IDOrder) = Type("String") Then
			SalesOrder = Documents.SalesOrder.GetRef(New UUID(IDOrder));
		Else
			SalesOrder = IDOrder;
		EndIf;
		
		OrderObject = SalesOrder.GetObject();
		
		If OrderObject = Undefined Then
			MobileApplicationSalesOrders.DataDeletion(SalesOrder);
			XDTOSerializer.WriteXML(ResponseMessage, SalesOrder);
			Continue;
		EndIf;
		
		SalesOrders.Add(SalesOrder);
		
	EndDo;
	
	Return InformationOnStatusOfCustomerOrders(SalesOrders);
EndFunction

// Returns the response data on the status of their orders for a refund.
//
// Parameters:
//  ResponseMessage - XMLWriter - response message according to the statuses of customer orders;
//  IDs - Array - read array of identifiers of applications to return.
//
// Returns:
//  Array - an array containing data on the status of refund requests.
//
Function ResponseDataRefundRequestStatus(ResponseMessage, Val IDs) Export
	
	RequestsForReturn = New Array;
	
	For Each Id In IDs Do
		
		If TypeOf(Id) = Type("String") Then
			ReturnRequest = Documents.RequestForReturnOfGoodsFromCustomer.GetRef(
				New UUID(Id));
		Else
			ReturnRequest = Id;
		EndIf;
		
		RequestObject = ReturnRequest.GetObject();
		
		If RequestObject = Undefined Then
			MobileApplicationSalesOrders.DataDeletion(ReturnRequest);
			XDTOSerializer.WriteXML(ResponseMessage, ReturnRequest);
			Continue;
		EndIf;
		
		RequestsForReturn.Add(ReturnRequest);
	EndDo;
	
	Return InformationOnStatusOfRequestsForReturns(RequestsForReturn);
EndFunction

#EndRegion

#Region CreatingData

// Records an element of the "counterparty Agreements"reference list.
//
// Parameters:
//  MobileAgreement - XDTODataObject - received exchange data;
//  Message - Array - array containing data for the response message.
//
Procedure CreateUpdateAgreementAgreement(MobileAgreement, Message) Export
	
	BlankID = BlankID();
	
	ResponseStructure = New Structure;
	ResponseStructure.Insert("ref", MobileAgreement.ref);
	ResponseStructure.Insert("ERPКодДоговора", BlankID); //@NON-NLS-1
	ResponseStructure.Insert("ERPКодСоглашения", BlankID); //@NON-NLS-1
	ResponseStructure.Insert("ТипОбъекта", "ДоговорыКлиентов"); //@NON-NLS-1 @NON-NLS-2
	ResponseStructure.Insert("Успешно", True); //@NON-NLS-1
	
	ConstantsSet = Constants.CreateSet("UseTermsOfSales, UseCustomerContracts,
	|UseSalesCommission, UseApprovalOfTermsOfSales,
	|UsePartnersSegments");
	ConstantsSet.Read();
	
	UseTermsOfSales = ConstantsSet.UseTermsOfSales;
	AgreementsAreUsed =
		Not UseTermsOfSales = Enums.UseTermsOfSales.DontUse;
	OnlyTypicalOnesAreUsed = 
		UseTermsOfSales = Enums.UseTermsOfSales.OnlyStandardTermsOfSales;
	IndividualAgreementsAreUsed = AgreementsAreUsed 
		And Not OnlyTypicalOnesAreUsed;
	//Use Agreement by clients = Setconstant.Use of Client agreementsreferences;
	PartnerSegmentsAreUsed = ConstantsSet.UsePartnersSegments;
	ContractsAreUsed_ = ConstantsSet.UseCustomerContracts;
	//There is a commission = A set of constants.Use the Sales Commission;
	
	If MobileAgreement.Комиссия Then
		BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent;
		ContractType = Catalogs.CounterpartyContracts.ContractType(BusinessOperation);
	Else
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		ContractType = Catalogs.CounterpartyContracts.ContractType(BusinessOperation);
	EndIf;
	
	PartnerLink = Catalogs.Partners.GetRef(New UUID(MobileAgreement.Клиент));
	PartnerObject_ = PartnerLink.GetObject();
	ThisIsNewPartner = PartnerObject_ = Undefined;
	
	CounterpartyRef = Catalogs.Counterparties.GetRef(New UUID(MobileAgreement.Контрагент));
	//Counterparty Object = Counterparty Link.Get an object();
	//This New Counterparty = Counterparty Object = Undefined;
	
	CompanyLink = 
		Catalogs.Companies.GetRef(New UUID(MobileAgreement.Организация));
	PriceTypeReference = Catalogs.TypesOfPrices.GetRef(New UUID(MobileAgreement.ВидЦены));
	WarehouseReference = Catalogs.Warehouses.GetRef(New UUID(MobileAgreement.Склад));
	
	ComplianceWithSalesConditions_ = New Structure;
	ComplianceWithSalesConditions_.Insert("SalesConditionID", MobileAgreement.ref);
	ComplianceWithSalesConditions_.Insert("Organization", CompanyLink);
	ComplianceWithSalesConditions_.Insert("PriceKind", PriceTypeReference);
	ComplianceWithSalesConditions_.Insert("Partner", PartnerLink);
	ComplianceWithSalesConditions_.Insert("Counterparty", CounterpartyRef);
	ComplianceWithSalesConditions_.Insert("Terms",
		PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
	ComplianceWithSalesConditions_.Insert("Contract",
		PredefinedValue("Catalog.CounterpartyContracts.EmptyRef"));
		
	RightToCreateAgreement = AgreementsAreUsed
		And AccessRight("Insert", Metadata.Catalogs.TermsOfSale);
	RightToAmendAgreement = AgreementsAreUsed
		And AccessRight("Update", Metadata.Catalogs.TermsOfSale);
	RightToCreateContract = ContractsAreUsed_
		And AccessRight("Insert", Metadata.Catalogs.CounterpartyContracts);
	RightToChangeContract = ContractsAreUsed_
		And AccessRight("Update", Metadata.Catalogs.CounterpartyContracts);
	
	ThisIsNewContract = Not ValueIsFilled(MobileAgreement.ERPКодСоглашения);
	If Not ThisIsNewContract Then
		AgreementLink = 
			Catalogs.TermsOfSale.GetRef(New UUID(MobileAgreement.ERPКодСоглашения));
		AgreementObject = AgreementLink.GetObject();
		If AgreementObject = Undefined Then
			ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
			Message.Add(ResponseStructure);
			Return;
		EndIf;
		ResponseStructure.Insert("ERPКодСоглашения", MobileAgreement.ERPКодСоглашения); //@NON-NLS-1
		HasChanges = False;
		If ValueIsFilled(MobileAgreement.Дата)
			And Not AgreementObject.Date = MobileAgreement.Дата Then
			AgreementObject.Date = MobileAgreement.Дата;
			HasChanges = True;
		EndIf;
		If ValueIsFilled(MobileAgreement.Номер)
			And Not AgreementObject.Number = MobileAgreement.Номер Then
			AgreementObject.Number = MobileAgreement.Номер;
			HasChanges = True;
		EndIf;
		If ValueIsFilled(MobileAgreement.Description)
			And Not AgreementObject.Description = MobileAgreement.Description Then
			AgreementObject.Description = MobileAgreement.Description;
			HasChanges = True;
		EndIf;
		
		If ValueIsFilled(AgreementObject.Organization)
			And Not AgreementObject.Organization = CompanyLink Then
			AgreementObject.Organization = CompanyLink;
			HasChanges = True;
		EndIf;
		If ValueIsFilled(AgreementObject.PricesKind)
			And Not AgreementObject.PricesKind = PriceTypeReference Then
			AgreementObject.PricesKind = PriceTypeReference;
			AgreementObject.PriceIncludesVAT = 
				Common.ObjectAttributeValue(AgreementObject.PricesKind, "PriceIncludesVAT");
			HasChanges = True;
		EndIf;
		If Not AgreementObject.BusinessOperation = BusinessOperation Then
			AgreementObject.BusinessOperation = BusinessOperation;
			HasChanges = True;
		EndIf;
		If Not AgreementObject.Warehouse = WarehouseReference Then
			AgreementObject.Warehouse = WarehouseReference;
			HasChanges = True;
		EndIf;
		If HasChanges Then
			If RightToAmendAgreement Then
				FillInAgreementCatalogForChanges(AgreementObject);
				Try
					AgreementObject.Write();
				Except
					ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
					Message.Add(ResponseStructure);
					Return;
				EndTry;
			Else
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				Message.Add(ResponseStructure);
				Return;
			EndIf;
		EndIf;
		ComplianceWithSalesConditions_.Insert("Terms", AgreementObject.Ref);
		If Common.ObjectAttributeValue(AgreementLink, "ContractsAreUsed") Then
			ContractLink = Catalogs.CounterpartyContracts.GetRef(
				New UUID(MobileAgreement.ERPКодДоговора));
			ObjectAgreement = ContractLink.GetObject();
			If Not ObjectAgreement = Undefined Then
				ResponseStructure.Insert("ERPКодДоговора", MobileAgreement.ERPКодДоговора); //@NON-NLS-1
				HasChanges = False;
				If ObjectAgreement.Organization = CompanyLink Then
					ObjectAgreement.Organization = CompanyLink;
					HasChanges = True;
				EndIf;
				If Not ObjectAgreement.BusinessOperation = BusinessOperation Then
					ObjectAgreement.BusinessOperation = BusinessOperation;
					ObjectAgreement.ContractType = ContractType;
					HasChanges = True;
				EndIf;
				If HasChanges Then
					If RightToChangeContract Then 
						Try
							ObjectAgreement.Write();
							Message.Add(ResponseStructure);
						Except
							ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
							Message.Add(ResponseStructure);
							Return;
						EndTry;
					Else
						ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
						Message.Add(ResponseStructure);
						Return;
					EndIf;
				EndIf;
			Else
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				Message.Add(ResponseStructure);
				Return;
			EndIf;
			ComplianceWithSalesConditions_.Insert("Contract", ObjectAgreement.Ref);
		Else
			Message.Add(ResponseStructure);
			Return;
		EndIf;
		If HasChanges Then
			Old_Set = 
				InformationRegisters.ComplianceOfSalesTermsAndConditionsOf1COrdersMobileApplication.CreateRecordSet();
			Old_Set.Filter.SalesConditionID.Set(MobileAgreement.ref);
			Old_Set.Write(True);
			NewSalesConditionExchangeNode(ComplianceWithSalesConditions_, MobileAgreement.ref);
		EndIf;
	Else
		If IndividualAgreementsAreUsed Then
			If Not RightToCreateAgreement Then
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				Message.Add(ResponseStructure);
				Return;
			EndIf;
			
			AgreementObject = Catalogs.TermsOfSale.CreateItem();
			AgreementObject.Standard_ = False;
			AgreementObject.Partner = PartnerLink;
			AgreementObject.Counterparty = CounterpartyRef;
			AgreementObject.Organization = CompanyLink;
			AgreementObject.BusinessOperation = BusinessOperation;
			AgreementObject.PricesKind = PriceTypeReference;
			AgreementObject.PriceIncludesVAT = 
				Common.ObjectAttributeValue(AgreementObject.PricesKind, "PriceIncludesVAT");
			AgreementObject.Warehouse = WarehouseReference;
			AgreementObject.Currency = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
			AgreementObject.Date = MobileAgreement.Дата;
			AgreementObject.Number = MobileAgreement.Номер;
			AgreementObject.Description = MobileAgreement.Description;
			AgreementUsesContracts = ContractsAreUsed_ And MobileAgreement.ИспользуютсяДоговорыКонтрагентов;
			AgreementObject.ContractsAreUsed = AgreementUsesContracts;
			FillInAgreementCatalogForChanges(AgreementObject);
			If GetFunctionalOption("UseJobsToManageSalesRepresentatives")
				Or GetFunctionalOption("UseJobsToSalesRepresentativesForPlanning") Then
				AgreementObject.UsedInSalesRepresentativesWork = True;
			EndIf;
			Try
				AgreementObject.Write();
				ERPAgreementCode_ = TrimAll(AgreementObject.Ref.UUID());
				ResponseStructure.Insert("ERPКодСоглашения", ERPAgreementCode_); //@NON-NLS-1
				Terms = AgreementObject.Ref;
				ComplianceWithSalesConditions_.Insert("Terms", Terms);
			Except
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				Message.Add(ResponseStructure);
				Return;
			EndTry;
		Else
			Query = New Query(MobileApplicationSalesOrders.TextOfStandardAgreementSearchRequest());
			Query.SetParameter("BusinessOperation", BusinessOperation);
			Query.SetParameter("Organization", CompanyLink);
			Query.SetParameter("PricesKind", PriceTypeReference);
			Query.SetParameter("Partner", PartnerLink);
			Query.SetParameter("Warehouse", WarehouseReference);
			Query.SetParameter("PartnerSegmentsAreUsed", PartnerSegmentsAreUsed);
			Query.SetParameter("ThisIsNewPartner", ThisIsNewPartner);
			
			Result = Query.Execute();
			If Not Result.IsEmpty() Then
				Selection = Result.Select();
				Selection.Next();
				Terms = Selection.Terms;
				ERPAgreementCode_ = TrimAll(Terms.UUID());
				AgreementUsesContracts = Terms.ContractsAreUsed;
				ResponseStructure.Insert("ERPКодСоглашения", ERPAgreementCode_); //@NON-NLS-1
				ComplianceWithSalesConditions_.Insert("Terms", Terms);
			Else
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				Message.Add(ResponseStructure);
				Return;
			EndIf;
		EndIf;
		If AgreementUsesContracts Then
			If Not RightToCreateContract Then
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				Message.Add(ResponseStructure);
				Return;
			EndIf;
			
			ObjectAgreement = Catalogs.CounterpartyContracts.CreateItem();
			ObjectAgreement.ContractType = ContractType;
			ObjectAgreement.BusinessOperation = BusinessOperation;
			ObjectAgreement.Organization = CompanyLink;
			ObjectAgreement.Partner = PartnerLink;
			ObjectAgreement.Counterparty = CounterpartyRef;
			ObjectAgreement.Manager = Users.CurrentUser();
			ObjectAgreement.ARAPCurrency = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
			ObjectAgreement.Date = MobileAgreement.Дата;
			ObjectAgreement.Number = MobileAgreement.Номер;
			ObjectAgreement.Description = MobileAgreement.Description;
			ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersStructure.Organization = ObjectAgreement.Organization;
			ParametersStructure.Currency = ObjectAgreement.ARAPCurrency;
			ObjectAgreement.BankAccount =
				Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
			ObjectAgreement.Status = Enums.CounterpartyContractStatuses.Valid;
			ObjectAgreement.ForeignCurrencyTransaction = Common.ObjectAttributeValue(Terms, "ForeignCurrencyTransaction");
			ObjectAgreement.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
			Try
				ObjectAgreement.Write();
				ERPAgreementCode = TrimAll(ObjectAgreement.Ref.UUID());
				ResponseStructure.Insert("ERPКодДоговора", ERPAgreementCode); //@NON-NLS-1
				ComplianceWithSalesConditions_.Insert("Contract", ObjectAgreement.Ref);
			Except
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				Message.Add(ResponseStructure);
				Return;
			EndTry;
		EndIf;
		Message.Add(ResponseStructure);
		NewSalesConditionExchangeNode(ComplianceWithSalesConditions_, MobileAgreement.ref);
	EndIf;
EndProcedure

// Writes the document "Task to the sales representative".
//
// Parameters:
//  MobileTask - XDTODataObject - received exchange data;
//  ExchangeNode - ExchangePlanRef - the site plan of exchange with a mobile app;
//  Message - Array - array containing data for the response message;
//  TaskSettings - XDTODataObject - JobTargetSettings (http://www.1c.ru/CustomerOrders/Exchange),
//    settings for the use of tasks by sales representatives.
//
Procedure CreateUpdateTaskForSalesRepresentative(MobileTask, ExchangeNode, Message, TaskSettings) Export
	
	NodeAttributes = MobileApplicationSalesOrders.NodeAttributes(ExchangeNode);
	
	UsingTasks = Constants.UseJobsToSalesRepresentatives.Get();
	DetailTasks = Constants.ItemizeJobsForSalesRepresentatives.Get();
	
	JobForSalesRepresentative = 
		Documents.JobForSalesRepresentative.GetRef(New UUID(MobileTask.ref));
	
	JobObject = JobForSalesRepresentative.GetObject();
	
	If JobObject = Undefined Then
		JobObject = Documents.JobForSalesRepresentative.CreateDocument();
		JobObject.SetNewObjectRef(JobForSalesRepresentative);
		JobObject.Date = MobileTask.Date;
		JobObject.Number = MobileTask.Number;
		JobObject.SalesRepresentative = Users.CurrentUser();
		JobObject.Supervisor_ = NodeAttributes.Supervisor_;
		JobObject.ItemsDetails = DetailTasks;
	Else
		Cancel = False;
		CheckIfTaskCanBeChanged(JobForSalesRepresentative, ExchangeNode, Cancel);
		If Cancel Then
			Return;
		EndIf;
	EndIf;
	
	//Completed = Mobile task.Posted;	
	JobObject.DeletionMark = MobileTask.DeletionMark;
		
	JobObject.Currency			= Catalogs.Currencies.GetRef(New UUID(MobileTask.Валюта));
	JobObject.BeginTime		= MobileTask.ВремяНачала;
	JobObject.EndTime	= MobileTask.ВремяОкончания;
	JobObject.PlannedVisitDate	= MobileTask.ДатаВизитаПлан;
	JobObject.ActualVisitDate	= MobileTask.ДатаВизитаФакт;
	
	AgreementContract				= StructureOfAgreementAgreement(MobileTask.ДоговорКлиента);
	JobObject.Contract			= AgreementContract.Contract;
	JobObject.Terms		= AgreementContract.Terms;
	JobObject.BusinessOperation	= AgreementContract.BusinessOperation;
	
	JobObject.RequestShipmentOn	= MobileTask.ЖелаемаяДатаОтгрузки;
	JobObject.Comment			= MobileTask.Комментарий;

	JobObject.Partner			= Catalogs.Partners.GetRef(New UUID(MobileTask.Клиент));
	JobObject.Counterparty		= Catalogs.Counterparties.GetRef(
		New UUID(MobileTask.Контрагент));
	JobObject.Organization		= Catalogs.Companies.GetRef(
		New UUID(MobileTask.Организация));
	JobObject.Warehouse				= Catalogs.Warehouses.GetRef(New UUID(MobileTask.Склад));
	JobObject.FillInTermsOfSalesUnderAgreement();
	
	TabularPartProducts = JobObject.Goods;
	TabularPartProducts.Clear();
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(JobObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ActionParameters);
	AddTaskToActionStructureWhenChangingNumberOfPackages(StructureOfActions, JobObject);
	RowsToProcess = New Array();
	
	For Each RowOfProduct In MobileTask.Товары Do
		DocumentLine = TabularPartProducts.Add();
		
		DocumentLine.Count 				= RowOfProduct["Количество"]; //@NON-NLS-1
		DocumentLine.NumberOfPackages 		= RowOfProduct["КоличествоУпаковок"]; //@NON-NLS-1
		DocumentLine.CountPlan 			= RowOfProduct["КоличествоПлан"]; //@NON-NLS-1
		DocumentLine.NumberOfPackages		= RowOfProduct["КоличествоУпаковок"]; //@NON-NLS-1
		DocumentLine.PercentRateOfManualDiscount		= RowOfProduct["ПроцентРучнойСкидки"]; //@NON-NLS-1
		DocumentLine.Sum					= RowOfProduct["Сумма"]; //@NON-NLS-1
		DocumentLine.VATAmount				= RowOfProduct["СуммаНДС"]; //@NON-NLS-1
		DocumentLine.ManualDiscount		= RowOfProduct["СуммаРучнойСкидки"]; //@NON-NLS-1
		DocumentLine.AmountIncludingVAT				= RowOfProduct["СуммаСНДС"]; //@NON-NLS-1
		DocumentLine.Price					= RowOfProduct["Цена"]; //@NON-NLS-1
		
		DocumentLine.PriceKind
			= Catalogs.TypesOfPrices.GetRef(New UUID(RowOfProduct["ВидЦены"])); //@NON-NLS-1
		
		ProductDescriptionPackaging		= StructureProductDescriptionPackaging(
			RowOfProduct["Номенклатура"],
			RowOfProduct["Упаковка"]); //@NON-NLS-1 @NON-NLS-2
		DocumentLine.Products			= ProductDescriptionPackaging.Products;
		If ValueIsFilled(ProductDescriptionPackaging.Characteristic) Then
			DocumentLine.Characteristic		= ProductDescriptionPackaging.Characteristic;
		EndIf;
		If ValueIsFilled(ProductDescriptionPackaging.Package) Then
			DocumentLine.Package			= ProductDescriptionPackaging.Package;
			DocumentLine.Price				= DocumentLine.Price * ProductDescriptionPackaging.PackageFactor;
		Else
			DocumentLine.NumberOfPackages	= DocumentLine.Count;
		EndIf;
		
		RowsToProcess.Add(DocumentLine);
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularPartProducts,
		CachedValues);
	
	TabularPartOfTask = JobObject.Tasks;
	TabularPartOfTask.Clear();
	
	For Each TaskLine In MobileTask.Задачи Do
		
		DocumentLine = TabularPartOfTask.Add();
		DocumentLine.Executed = TaskLine["Выполнена"]; //@NON-NLS-1
		DocumentLine.TaskDetails1 = TaskLine["ОписаниеЗадачи"]; //@NON-NLS-1
		DocumentLine.ResultDetails = TaskLine["ОписаниеРезультата"]; //@NON-NLS-1
		
	EndDo;
	
	OldCurrency = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
	NewCurrency = JobObject.Currency;
	
	If Not OldCurrency = NewCurrency Then
		
		DocumentDate               = JobObject.Date;
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(JobObject.Organization);
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, LocalAccountingCurrency);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency, DocumentDate, LocalAccountingCurrency);
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			JobObject.Goods,
			JobObject.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
		
	EndIf;
	
	MobileTaskStatus = 
		MobileApplicationSalesOrdersCached.MatchingTaskStatusesToSalesRepresentatives().Get(MobileTask.Статус);
	
	If ValueIsFilled(TrimAll(MobileTask.Статус)) Then
		If MobileTaskStatus = Enums.SalesRepresentativeTaskStatuses.NotPrepared2 
			And UsingTasks = Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning Then
			JobObject.Status = Enums.SalesRepresentativeTaskStatuses.ToProcessing;
			FillInTaskDataForMPSettings(JobObject, TaskSettings);
		Else
			JobObject.Status = MobileTaskStatus;
		EndIf;
	Else
		JobObject.Status = Enums.SalesRepresentativeTaskStatuses.EmptyRef();
	EndIf;
	
	JobObject.Write();
	RecordTaskStatusInformationForSalesRepresentative(Message, JobObject.Ref);
	
	If MobileTaskStatus = Enums.SalesRepresentativeTaskStatuses.Processed_ 
		And UsingTasks = Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning Then
		OrderObject = Documents.SalesOrder.CreateDocument();
		OrderObject.Date = CurrentSessionDate();
		OrderObject.Fill(JobObject.Ref);
		OrderObject.Write();
	EndIf;
EndProcedure

// Records the "customer Order" document.
//
// Parameters:
//  MobileData - XDTODataObject - received exchange data;
//  Message - Array - array containing data for the response message.
//
Procedure CreateUpdateCustomerOrder(MobileData, Message) Export
	
	SalesOrder = Documents.SalesOrder.GetRef(New UUID(MobileData.ref));
	
	DocumentObject = SalesOrder.GetObject();
	
	If DocumentObject = Undefined Then
		DocumentObject = Documents.SalesOrder.CreateDocument();
		DocumentObject.SetNewObjectRef(SalesOrder);
		DocumentObject.Date = MobileData.Date;
		DocumentObject.Number = MobileData.Number;
		InitializeDocument(DocumentObject);
	Else
		Cancel = False;
		CheckForChanges(SalesOrder, Cancel);
		If Cancel Then
			RecordCustomerOrderStatusInformation(Message, SalesOrder);
			Return;
		EndIf;
	EndIf;
	
	FillInDocumentHeader(DocumentObject, MobileData, 0);
	FillInDeliveryInformation(DocumentObject, MobileData, 0);
	
	DocumentObject.DateOfShipment = MobileData.ДатаОтгрузки;
	If Not ValueIsFilled(DocumentObject.DateOfShipment) Then
		DocumentObject.DateOfShipment = MobileData.ЖелаемаяДатаОтгрузки;
	EndIf;
	
	// Created by the Task of the TP.
	DocumentBasis = Documents.JobForSalesRepresentative.GetRef(
		New UUID(MobileData.ДокументОснование));
	If Not DocumentBasis.IsEmpty() Then
		DocumentBaseObject = DocumentBasis.GetObject();
		If Not DocumentBaseObject = Undefined Then
			DocumentObject.DocumentBasis = DocumentBasis;
		EndIf;
	EndIf;
	
	FillInProductPart(DocumentObject, MobileData.Товары, 0);
	
	//+ UP 2.2.
	FillInAdditionalDetailsOfObject(MobileData, DocumentObject);
	//- ERP 2.2.
	
	WritePostNewDocument(DocumentObject, Message, MobileData.Posted, 0);
EndProcedure

// Records the document "Request for return of goods from the customer".
//
// Parameters:
//  MobileData - XDTODataObject - received exchange data;
//  Message - Array - array containing data for the response message.
//
Procedure CreateUpdateRequestForReturnOfGoodsFromCustomer(MobileData, Message) Export
	
	ReturnRequest = 
		Documents.RequestForReturnOfGoodsFromCustomer.GetRef(New UUID(MobileData.ref));
	
	DocumentObject = ReturnRequest.GetObject();
	
	If DocumentObject = Undefined Then
		DocumentObject = Documents.RequestForReturnOfGoodsFromCustomer.CreateDocument();
		DocumentObject.SetNewObjectRef(ReturnRequest);
		DocumentObject.Date = MobileData.Date;
		DocumentObject.Number = MobileData.Number;
		InitializeDocument(DocumentObject);
	Else
		Cancel = False;
		CheckForChanges(ReturnRequest, Cancel);
		If Cancel Then
			RecordInformationOnStatusOfRefundRequest(Message, ReturnRequest);
			Return;
		EndIf;
	EndIf;
	
	FillInDocumentHeader(DocumentObject, MobileData, 1);
	FillInDeliveryInformation(DocumentObject, MobileData, 1);
	
	DocumentObject.DateOfReceipt = MobileData.ДатаПоступления;
	DocumentObject.RequestedDeliveryDate = MobileData.ЖелаемаяДатаПоступления;
	DocumentObject.ReasonForReturn = MobileData.ПричинаВозврата;
	If ValueIsFilled(MobileData.СпособКомпенсации) Then
		DocumentObject.CompensationMethod = 
			MobileApplicationSalesOrdersCached.MatchingTypesMethodsOfCompensationForReturnsOfGoods().Get(MobileData.СпособКомпенсации);
	Else
		DocumentObject.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment;
	EndIf;
	
	CreatedOnBasisOf = False;
	If ValueIsFilled(MobileData.ДокументОснование) Then
		// Created by the Task of the TP.
		DocumentBasis = Documents.JobForSalesRepresentative.GetRef(
		New UUID(MobileData.ДокументОснование));
		If Not DocumentBasis.IsEmpty() Then
			DocumentBaseObject = DocumentBasis.GetObject();
			If Not DocumentBaseObject = Undefined Then
				CreatedOnBasisOf = True;
			EndIf;
		EndIf;
		
		// Created by customer Order.
		If Not CreatedOnBasisOf Then
			DocumentBasis = Documents.SalesOrder.GetRef(
			New UUID(MobileData.ДокументОснование));
			If Not DocumentBasis.IsEmpty() Then
				DocumentBaseObject = DocumentBasis.GetObject();
				If Not DocumentBaseObject = Undefined Then
					CreatedOnBasisOf = True;
					DocumentObject.DocumentSalesOfGoodsAndServices = CustomImplementation(DocumentBasis);
				EndIf;
			EndIf;
		EndIf;
	EndIf;

	If CreatedOnBasisOf Then
		CommentText1 = StrTemplate(NStr("vi = '<Đã tạo mới theo chứng từ: %1/>';
										|ru = '<Создан по документу: %1/>';
										|en = '<Created from document: %1/>'; fa = '<Created from document: %1/>';
										|it = '<Creato secondo il documento: %1/>';
										|pl = '<Utworzono wg dokumentu: %1/>';
										|tr = '<Belgeye göre oluşturuldu: %1/>'",
			Common.DefaultLanguageCode()), TrimAll(DocumentBasis));
		DocumentObject.Comment = CommentText1;
	EndIf;
	
	FillInProductPart(DocumentObject, MobileData.Товары, 1);
	
	//+ UP 2.2.
	FillInAdditionalDetailsOfObject(MobileData, DocumentObject);
	//- ERP 2.2.
	
	WritePostNewDocument(DocumentObject, Message, MobileData.Posted, 1);
EndProcedure

// Writes an element of the directory "Partners".
//
// Parameters:
//  MobilePartner - XDTODataObject - received exchange data;
//  ExchangeNode - ExchangePlanRef - the site plan of exchange with a mobile app;
//  Message - Array - array containing data for the response message.
//
Procedure CreateUpdateClient(MobilePartner, ExchangeNode, Message) Export
	
	ResponseStructure = New Structure;
	ResponseStructure.Insert("ref", MobilePartner.ref);
	ResponseStructure.Insert("ERPКодДоговора", Chars.NBSp); //@NON-NLS-1
	ResponseStructure.Insert("ERPКодСоглашения", Chars.NBSp); //@NON-NLS-1
	ResponseStructure.Insert("ТипОбъекта", "Клиенты"); //@NON-NLS-1 @NON-NLS-2
	ResponseStructure.Insert("Успешно", True); //@NON-NLS-1
	
	RightOfCreation = AccessRight("Insert", Metadata.Catalogs.Partners);
	
	ThisIsNewPartner = False;
	PartnerLink = Catalogs.Partners.GetRef(New UUID(MobilePartner.ref));
	Partner = PartnerLink.GetObject();
	
	If Partner = Undefined Then
		If RightOfCreation Then
			ThisIsNewPartner = True;
			Partner = Catalogs.Partners.CreateItem();
			Partner.SetNewObjectRef(PartnerLink);
			Partner.Code = MobilePartner.Code;
			Partner.Client = True;
			Partner.MainManager = Users.CurrentUser();
			Partner.RegistrationDate = CurrentSessionDate();
			Partner.LegalEntityIndividual = Enums.IndividualCompany.Company;
			If GetFunctionalOption("UseJobsToManageSalesRepresentatives")
				Or GetFunctionalOption("UseJobsToSalesRepresentativesForPlanning") Then
				Partner.ServedBySalesRepresentatives = True;
			EndIf;
		Else
			ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
			Message.Add(ResponseStructure);
			Return;
		EndIf;
	EndIf;
	
	PartnerAccessGroupsAreUsed = Catalogs.PartnerAccessGroups.AccessGroupsAreUsed();
	If PartnerAccessGroupsAreUsed
		And Not ValueIsFilled(Partner.AccessGroup) Then
		Partner.AccessGroup = PartnerAccessGroup();
	EndIf;
	
	If Not Partner.DeletionMark = MobilePartner.DeletionMark Then
		Partner.DeletionMark = MobilePartner.DeletionMark;
	EndIf;
	If Not Partner.Description = MobilePartner.Description Then
		Partner.Description = MobilePartner.Description;
	EndIf;
	If Not Partner.DescriptionFull = MobilePartner.Description Then
		Partner.DescriptionFull = MobilePartner.Description;
	EndIf;
	
	PartnerParent_ = Catalogs.Partners.GetRef(New UUID(MobilePartner.Parent));
	If Not Partner.Parent = PartnerParent_ Then
		Partner.Parent = PartnerParent_;
	EndIf;
	
	PartnerContactInformation = Partner.ContactInformation;
	PartnerContactInformation.Clear();
	
	If Not MobilePartner.Properties().Get("ContactInformation") = Undefined Then
		For Each CIRow In MobilePartner.КонтактнаяИнформация Do
			NewRow = PartnerContactInformation.Add();
			FillPropertyValues(NewRow, CIRow, , "Type, Kind");
			NewRow.Kind = Catalogs.ContactInformationKinds.GetRef(New UUID(CIRow["Kind"]));
			NewRow.Type = Enums.ContactInformationTypes[CIRow["Type"]];
		EndDo;
	EndIf;
	
	If ValueIsFilled(MobilePartner.ДополнительнаяИнформацияПоДоставке) 
		And Not Partner.Comment = MobilePartner.ДополнительнаяИнформацияПоДоставке Then
		Partner.Comment = MobilePartner.ДополнительнаяИнформацияПоДоставке;
	EndIf;
	
	FillInAdditionalDetailsOfObject(MobilePartner, Partner);
	
	Try
		Partner.Write();
	Except
		ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
	EndTry;
	
	If ThisIsNewPartner Then
		If Not ResponseStructure["Успешно"] Then //@NON-NLS-1
			Partner.DataExchange.Load = True;
			Try
				Partner.Write();
				ResponseStructure.Insert("Успешно", True); //@NON-NLS-1
			Except
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
			EndTry;
		EndIf;
		
		If ResponseStructure["Успешно"] Then //@NON-NLS-1
			RecordPartnerSegments(PartnerLink, ExchangeNode);
		EndIf;
	EndIf;
	
	Message.Add(ResponseStructure);
EndProcedure

// Records the "contact persons of partners" directory element.
//
// Parameters:
//  MobileData - XDTODataObject
//  Message - Array of Structure - array containing data for the response message.
//
Procedure CreateUpdateClientContactPerson(MobileData, Message) Export
	
	ResponseStructure = New Structure;
	ResponseStructure.Insert("ref", MobileData.ref);
	ResponseStructure.Insert("ERPКодДоговора", Chars.NBSp); //@NON-NLS-1
	ResponseStructure.Insert("ERPКодСоглашения", Chars.NBSp); //@NON-NLS-1
	ResponseStructure.Insert("ТипОбъекта", "КонтактныеЛицаКлиентов"); //@NON-NLS-1 @NON-NLS-2
	ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
	
	ContactPersonLink =
		Catalogs.ContactPersonsForPartners.GetRef(New UUID(MobileData.ref));
	
	ContactPerson = ContactPersonLink.GetObject(); // CatalogObject.ContactPersonsForPartners -
		
	If ContactPerson = Undefined Then
		ContactPerson = Catalogs.ContactPersonsForPartners.CreateItem();
		ContactPerson.SetNewObjectRef(ContactPersonLink);
		ContactPerson.Owner = Catalogs.Partners.GetRef(New UUID(MobileData.Owner));
		ContactPerson.Author = Users.CurrentUser();
		ContactPerson.RelationRegistrationDate = CurrentSessionDate();
	EndIf;
	
	DeletionMark = MobileData.DeletionMark;
	ContactPerson.DeletionMark = DeletionMark;
	ContactPerson.Description = MobileData.Description;
	ContactPerson.BirthDate = MobileData.ДатаРождения;
	ContactPerson.JobTitleOnBusinessCard = MobileData.ДолжностьПоВизитке;
	ContactPerson.Comment = MobileData.Комментарий;
	
	KLContactInformation = ContactPerson.ContactInformation;
	KLContactInformation.Clear();
	
	If Not MobileData.Properties().Get("ContactInformation") = Undefined Then
		For Each CIRow In MobileData.КонтактнаяИнформация Do
			NewRow = KLContactInformation.Add();
			FillPropertyValues(NewRow, CIRow, , "Type, Kind");
			NewRow.Kind = Catalogs.ContactInformationKinds.GetRef(New UUID(CIRow["Kind"]));
			NewRow.Type = Enums.ContactInformationTypes[CIRow["Type"]];
		EndDo;
	EndIf;
	
	ContactPerson.DataExchange.Load = True;
	
	Try
		ContactPerson.Write();
		ResponseStructure.Insert("Успешно", True); //@NON-NLS-1
	Except
		ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
	EndTry;
	
	Message.Add(ResponseStructure);
EndProcedure

// Records an element of the "Contractors" reference list.
//
// Parameters:
//  MobileCounterparty - XDTODataObject - received exchange data;
//  Message - Array - array containing data for the response message.
//
Procedure CreateUpdateCounterparty(MobileCounterparty, Message) Export
	
	ResponseStructure = New Structure;
	ResponseStructure.Insert("ref", MobileCounterparty.ref);
	ResponseStructure.Insert("ERPКодДоговора", Chars.NBSp); //@NON-NLS-1
	ResponseStructure.Insert("ERPКодСоглашения", Chars.NBSp); //@NON-NLS-1
	ResponseStructure.Insert("ТипОбъекта", "Контрагенты"); //@NON-NLS-1 @NON-NLS-2
	ResponseStructure.Insert("Успешно", True); //@NON-NLS-1
	
	RightOfCreation = AccessRight("Insert", Metadata.Catalogs.Counterparties);
	EditRight = AccessRight("Update", Metadata.Catalogs.Counterparties);
		
	ThisIsNewCounterparty = False;
	CounterpartyRef = Catalogs.Counterparties.GetRef(New UUID(MobileCounterparty.ref));
	Counterparty = CounterpartyRef.GetObject();
	
	If Counterparty = Undefined Then
		If RightOfCreation Then
			ThisIsNewCounterparty = True;
			Counterparty = Catalogs.Counterparties.CreateItem();
			Counterparty.SetNewObjectRef(CounterpartyRef);
		Else
			ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
			Message.Add(ResponseStructure);
			Return;
		EndIf;
	EndIf;
	
	HasChanges = False;
	
	If Not Counterparty.DeletionMark = MobileCounterparty.DeletionMark Then
		Counterparty.DeletionMark = MobileCounterparty.DeletionMark;
		HasChanges = True;
	EndIf;
	
	If Not Counterparty.Description = MobileCounterparty.Description Then
		Counterparty.Description = MobileCounterparty.Description;
		HasChanges = True;
	EndIf;
	
	If Not Counterparty.TIN = MobileCounterparty.ИНН Then
		Counterparty.TIN = MobileCounterparty.ИНН;
		HasChanges = True;
	EndIf;
	
	If Not Counterparty.CRTR = MobileCounterparty.КПП Then
		Counterparty.CRTR = MobileCounterparty.КПП;
		HasChanges = True;
	EndIf;
	
	If Not Counterparty.DescriptionFull = MobileCounterparty.НаименованиеПолное Then
		Counterparty.DescriptionFull = MobileCounterparty.НаименованиеПолное;
		HasChanges = True;
	EndIf;
	
	If ValueIsFilled(MobileCounterparty.ЮрФизЛицо) Then
		LegalEntityIndividual = MobileApplicationSalesOrdersCached.ComplianceWithTypesOfLegalEntityIndividual().Get(MobileCounterparty.ЮрФизЛицо);
		If Not Counterparty.LegalEntityIndividual = LegalEntityIndividual Then
			Counterparty.LegalEntityIndividual = LegalEntityIndividual;
			HasChanges = True;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Counterparty.LegalEntityIndividual) Then
		Counterparty.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity;
		HasChanges = True;
	EndIf;
	
	If ThisIsNewCounterparty Then
		PartnerLink = Catalogs.Partners.GetRef(New UUID(MobileCounterparty.Клиент));
		Counterparty.Partner = PartnerLink;
	EndIf;
	
	If Counterparty.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur
		Or Counterparty.LegalEntityIndividual = Enums.LegalEntityIndividual.Person Then
		
		If Not Counterparty.CompanyIndividual = Enums.CompanyIndividual.Individual Then
			Counterparty.CompanyIndividual = Enums.CompanyIndividual.Individual;
			HasChanges = True;
		EndIf;
		
	ElsIf Counterparty.LegalEntityIndividual = Enums.LegalEntityIndividual.Entity
		Or LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident Then
		
		If Not Counterparty.CompanyIndividual = Enums.CompanyIndividual.BusinessEntity Then
			Counterparty.CompanyIndividual = Enums.CompanyIndividual.BusinessEntity;
			HasChanges = True;
		EndIf;
	EndIf;
	
	If HasChanges Then
		If EditRight Then
			Try
				Counterparty.Write();
			Except
				ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
			EndTry;
			
			If ThisIsNewCounterparty And Not ResponseStructure["Успешно"] Then //@NON-NLS-1
				Counterparty.DataExchange.Load = True;
				Try
					Counterparty.Write();
					ResponseStructure.Insert("Успешно", True); //@NON-NLS-1
				Except
					ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
				EndTry;
			EndIf;
		Else
			ResponseStructure.Insert("Успешно", False); //@NON-NLS-1
		EndIf;
	EndIf;
	
	Message.Add(ResponseStructure);
EndProcedure

// Records the "customer Payment" document from the mobile app.
//
// Parameters:
//  MobilePayment - XDTODataObject - received exchange data;
//  ExchangeNode - ExchangePlanRef - the site plan of exchange with a mobile app;
//  Message - Array - array containing data for the response message.
//
Procedure CreateUpdateCustomerPayment(MobilePayment, ExchangeNode, Message) Export
	
	NodeAttributes = MobileApplicationSalesOrders.NodeAttributes(ExchangeNode);
	
	ThereAreAcquiringOperations = GetFunctionalOption("UsePaymentByCards")
		And ValueIsFilled(NodeAttributes.POSTerminal);
	ThereIsCashAcceptanceAtCheckout = NodeAttributes.UseICOToRegisterPayment;
	ThereIsCashAcceptanceByProxy = GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt")
		And NodeAttributes.UsePowerOfAttorneyToRegisterPayment;
		
	PaymentMethod = MobileApplicationSalesOrdersCached.MatchingPaymentFormTypes().Get(MobilePayment.ФормаОплаты);
	PaymentStructure = New Structure;
	PaymentStructure.Insert("MobilePayment", MobilePayment);
	If PaymentMethod = Enums.PaymentForms.PaymentCard Then
		If ThereAreAcquiringOperations Then
			PaymentStructure.Insert("ArticleDDSAcquiring", NodeAttributes.ArticleDDSAcquiring);
			PaymentStructure.Insert("POSTerminal", NodeAttributes.POSTerminal);
			CreateUpdateAcquiringOperation(PaymentStructure, Message);
		EndIf;
	Else
		If ThereIsCashAcceptanceAtCheckout Then
			PaymentStructure.Insert("ArticleDDSCash", NodeAttributes.ArticleDDSCash);
			PaymentStructure.Insert("CashAccount", NodeAttributes.CashAccount);
			CreateUpdateIncomingCashOrder(PaymentStructure, Message);
		ElsIf ThereIsCashAcceptanceByProxy Then
			CreateUpdatePowerOfAttorney(PaymentStructure, Message);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region RegisteringDataForExchange

// Registers objects in the exchange nodes of the mobile app.
//
// Parameters:
//  NodesArray - Array - contains nodes for the registration of changes of an object;
//  Object - CatalogObject, InformationRegisterRecordSet - the object for which changes are registered.
//
Procedure RegisterChangesForExchangeNodes(NodesArray, Object) Export
	
	If NodesArray.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	If TypeOf(Object) = Type("InformationRegisterRecordSet.ItemsPrices") Then
		
		RegistrationStructure = TypesOfPricesForRegistration(Object);
		If RegistrationStructure.GeneralPriceList Then
			ExchangePlans.RecordChanges(NodesArray, Object);
		EndIf;
		If RegistrationStructure.PartnersForRegistration.Count()>0 Then
			For Each Partner In RegistrationStructure.PartnersForRegistration Do
				ExchangePlans.RecordChanges(NodesArray, Partner);
			EndDo;
		EndIf;
	ElsIf TypeOf(Object) = Type("InformationRegisterRecordSet.ItemsPrices25") Then
		
		RegistrationStructure = TypesOfPricesForRegistration25(Object);
		If RegistrationStructure.GeneralPriceList Then
			ExchangePlans.RecordChanges(NodesArray, Object);
		EndIf;
		If RegistrationStructure.PartnersForRegistration.Count()>0 Then
			For Each Partner In RegistrationStructure.PartnersForRegistration Do
				ExchangePlans.RecordChanges(NodesArray, Partner);
			EndDo;
		EndIf;
	ElsIf TypeOf(Object) = Type("CatalogObject.ProductsAttachedFiles") Then
		If ValueIsFilled(Object.FileOwner) Then
			For Each ExchangeNode In NodesArray Do
				NodeAttributes = MobileApplicationSalesOrders.NodeAttributes(ExchangeNode);
				TransmitProductImages = ?(NodeAttributes.TransmitProductImages = Undefined,
						False, NodeAttributes.TransmitProductImages);
				If TransmitProductImages Then
					ExchangePlans.RecordChanges(ExchangeNode, Object.Ref);
				EndIf;
			EndDo;
		EndIf;
	ElsIf TypeOf(Object) = Type("CatalogRef.ProductsAttachedFiles") Then
		FileOwnerObject = Common.ObjectAttributeValue(Object, "FileOwner");
		If ValueIsFilled(FileOwnerObject) Then
			For Each ExchangeNode In NodesArray Do
				NodeAttributes = MobileApplicationSalesOrders.NodeAttributes(ExchangeNode);
				TransmitProductImages = ?(NodeAttributes.TransmitProductImages = Undefined,
						False, NodeAttributes.TransmitProductImages);
				If TransmitProductImages Then
					ExchangePlans.RecordChanges(ExchangeNode, Object);
				EndIf;
			EndDo;
		EndIf;
	ElsIf TypeOf(Object) = Type("CatalogObject.Products") Then
		If Object.IsFolder Then
			Return;
		EndIf;
		ExchangePlans.RecordChanges(NodesArray, Object.Ref);
	Else
		RegisterAllPartners = False;
		
		PartnersForRegistration = PartnersForRegistration(Object.Ref, RegisterAllPartners);
		
		If RegisterAllPartners Then
			ExchangePlans.RecordChanges(NodesArray, Metadata.Catalogs.Partners);
		Else
			For Each Partner In PartnersForRegistration Do
				ExchangePlans.RecordChanges(NodesArray, Partner);
			EndDo;
		EndIf;
	EndIf;
EndProcedure

// Registers changes with the type "Catalog.Partners" on the node of the exchange plan according to the transmitted parameters.
// If the passed parameter "All Clients" = True, all elements of the "Partners" Catalog are registered,
// if the passed parameter "Unique identifier" is not empty,
// only one object will be registered using the passed link.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - exchange node with a mobile app;
//  AllCustomers - Boolean - flag for registering all elements of the partners directory";
//  UUID - String - string representation of the unique identifier of the "Partners" directory elements";
//  Cancel - Boolean - whether object registration is completed;
//  ExchangeMessage - String - a string that contains information about the execution error.
//
Procedure RegisterCustomerChangesForExchangePlan(ExchangeNode, AllCustomers, UUID, Cancel,
			ExchangeMessage) Export
	
	SetPrivilegedMode(True);
	
	Try
		If ValueIsFilled(UUID) Then
			Client = Catalogs.Partners.GetRef(New UUID(UUID));
			ClientObject = Client.GetObject();
			If ClientObject = Undefined Then
				ClientObject = New ObjectDeletion(Client);
			EndIf;
			ExchangePlans.RecordChanges(ExchangeNode, ClientObject);
		Else
			If AllCustomers Then
				ExchangePlans.RecordChanges(ExchangeNode, Metadata.Catalogs.Partners);
			EndIf;
		EndIf;
	Except
		Cancel = True;
		Info = ErrorInfo();
		ExchangeMessage = Info.Description;
	EndTry;
EndProcedure

#EndRegion

#Region Other

// Returns the exchange node based on the mobile app ID and the current user.
//
// Parameters:
//  ResponseStructure - Structure - response message;
//  MobileDeviceId - String - not modified code of a mobile application used as the site code of the exchange;
//  CurrentUser - CatalogRef.Users, Undefined - the current user of the session.
//
// Returns:
//  ExchangePlanRef - Exchange node "Mobile application "1C: Customer Orders"".
//
Function FindExchangeNode(ResponseStructure, MobileDeviceId, CurrentUser = Undefined) Export
	
	If CurrentUser = Undefined Then
		CurrentUser = Users.CurrentUser();
	EndIf;
	
	FoundNode = Undefined;
	
	Query = New Query(
	"SELECT ALLOWED
	|	FALSE AS NewNode,
	|	MobileApplicationSalesOrders.Ref
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	MobileApplicationSalesOrders.Code = &Code
	|	AND MobileApplicationSalesOrders.User = &CurrentUser
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE,
	|	MobileApplicationSalesOrders.Ref
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	MobileApplicationSalesOrders.Code = &NewNodeCode
	|	AND MobileApplicationSalesOrders.User = &CurrentUser
	|
	|ORDER BY
	|	NewNode");
	
	Query.SetParameter("CurrentUser", CurrentUser);
	Query.SetParameter("Code", MobileDeviceId);
	Query.SetParameter("NewNodeCode", TrimAll(CurrentUser.UUID()));
	
	Result = Query.Execute();
	
	ResponseText = "";
	If Result.IsEmpty() Then
		ResponseText = NStr("vi = 'Chưa tùy chỉnh đồng bộ với thiết bị.
									|Không tìm thấy nút trao đổi với người sử dụng: %User%';
									|ru = 'Синхронизация с устройством не настроена.
									|Не найден узел обмена для пользователя : %User%';
									|en = 'Synchronization with the device is not configured.
									|Exchange node was not found for user: %User%'; fa = 'Synchronization with the device is not configured.
									|Exchange node was not found for user: %User%';
									|it = 'Sincronizzazione con l''apparecchio non configurata.
									|Non è stato trovato un nodo di scambio per l''utente : %User%';
									|pl = 'Synchronizacja z urządzeniem nie jest ustawiona
									|Nie jest znaleziony węzeł wymiany dla użytkownika : %User%';
									|tr = 'Cihaz ile senkronizasyon ayarlanmamış.
									| Kullanıcı için değişim düğümü bulunamadı:%User%'",
									Common.DefaultLanguageCode());
		ResponseText = StrReplace(ResponseText, "%User%", TrimAll(CurrentUser));
		ResponseStructure.ResultMessage = ResponseText;
		ResponseStructure.Success = False;
		Return FoundNode;
	EndIf;
	
	SelectedNodes = Result.Select();
	SelectedNodes.Next();
	
	FoundNode = SelectedNodes.Ref;
	
	If SelectedNodes.NewNode Then
		ObjectNode = FoundNode.GetObject();
		ObjectNode.Code = MobileDeviceId;
		Try
			ObjectNode.Write();
			ResponseText = TrimAll(FoundNode.Description);
		Except
			ResponseText = NStr("vi = 'Đối với thiết bị, đã xác định người sử dụng ứng dụng khác.
			|Phiên bản cấu hình này không hỗ trợ kịch bản nhiều người sử dụng đồng thời sử dụng một thiết bị.
			|Nếu người sử dụng khác không còn sử dụng thiết bị này,
			|hãy liên hệ với người quản trị CSTT của bạn để ngắt tùy chỉnh của người sử dụng khác khỏi thiết bị này.';
			|ru = 'Для устройства уже определен другой пользователь приложения.
			|Сценарий использования одного устройства разными пользователями одновременно не поддерживается
			|текущей версией конфигурации. Если другой пользователь больше не использует это устройство,
			|обратитесь к администратору вашей ИБ для открепления настройки другого пользователя от этого устройства.';
			|en = 'Another application user is already defined for this device.
			|Concurrent usage of one device by different users is not supported
			|by the current configuration version. If that user no longer uses this device,
			|contact your infobase administrator to detach the setting of another user from this device.'; fa = 'Another application user is already defined for this device.
			|Concurrent usage of one device by different users is not supported
			|by the current configuration version. If that user no longer uses this device,
			|contact your infobase administrator to detach the setting of another user from this device.';
			|it = 'Per il dispositivo è già definito un altro utente del programma.
			|Lo scenario di utilizzo di un dispositivo da più utenti contemporaneamente non è supportato
			|dalla versione corrente della configurazione. Se un altro utente non utilizza più questo dispositivo
			|rivolgetevi all''amministratore del vostro DB per scollegare le impostazioni dell''altro utente da questo dispositivo.';
			|pl = 'Dla urządzenia już został określony inny użytkownik aplikacji.
			|Scenariusz używania jednego urządzenia przez różnych użytkowników jednocześnie nie jest obsługiwany
			|przez bieżącą wersję konfiguracji. Jeśli inny użytkownik więcej nie korzysta z tego urządzenia,
			|zwróć się do administratora Twojej BI w celu odwiązania ustawienia innego użytkownika od tego urządzenia.';
			|tr = 'Cihaz için başka bir kullanıcı zaten tanımlanmış.
			| Farklı kullanıcıların aynı cihazı aynı anda kullanması
			| mevcut yapılandırma sürümünde desteklenmemektedir. Başka bir kullanıcı artık cihazı kullanmıyorsa,
			| diğer kullanıcının yapılandırmasını cihazdan kaldırmak için IS yöneticinizle iletişime geçin.'",
			Common.DefaultLanguageCode());
			ResponseStructure.ResultMessage = ResponseText;
			ResponseStructure.Success = False;
			Return Undefined;
		EndTry;
	EndIf;
	
	ResponseStructure.ResultMessage = ResponseText;
	ResponseStructure.Success = True;
	
	Return FoundNode;
EndFunction

// Returns a new prefix for mobile device data.
//
// Returns:
//  String - new prefix.
//
Function NewPrefixForMobileDeviceData() Export
	
	SetPrivilegedMode(True);
	
	NewPrefixForMobileDeviceData = "AA";
	
	Query = New Query("SELECT
	|	CAST(MobileApplicationSalesOrders.PrefixForMobileDeviceData AS STRING(2)) AS PrefixForMobileDeviceData
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	NOT MobileApplicationSalesOrders.PrefixForMobileDeviceData = """"
	|
	|ORDER BY
	|	PrefixForMobileDeviceData DESC");
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return NewPrefixForMobileDeviceData;
	EndIf;
	
	Selection = Result.Select();
	
	Selection.Next();
	
	CurPrefix = Selection.PrefixForMobileDeviceData;
	
	FirstChar = Max(1040, CharCode(CurPrefix, 1));
	SecondCharacter = Max(1040, CharCode(CurPrefix, 2));
	
	If SecondCharacter < 1071 Then
		SecondCharacter = SecondCharacter + 1;
	Else
		SecondCharacter = 1040;
		FirstChar = FirstChar + 1;
		If FirstChar > 1071 Then
			// Numbering is over.
			FirstChar = 1071;
			SecondCharacter = 1071;
		EndIf;
	EndIf;
	
	NewPrefixForMobileDeviceData = Char(FirstChar)+Char(SecondCharacter);
	
	Return NewPrefixForMobileDeviceData;
EndFunction

// Returns the result of checking the prefix for mobile device data.
//
// Parameters:
//  Ref - ExchangePlanRef - Exchange node "Mobile app" 1C: Orders"";
//  Prefix - String - the prefix to check for mobile device data.
//
// Returns:
//  Boolean - true when the prefix is already used on another node.
//
Function CheckPrefixForMobileDeviceData(Ref, Prefix) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	|	CAST(MobileApplicationSalesOrders.PrefixForMobileDeviceData AS STRING(2)) AS PrefixForMobileDeviceData
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	NOT MobileApplicationSalesOrders.Ref = &Ref
	|	AND (CAST(MobileApplicationSalesOrders.PrefixForMobileDeviceData AS STRING(2))) = &Prefix");
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Prefix", Prefix);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
EndFunction

// Returns a structure containing the values of the mobile app functions available to the user.
//
// Parameters:
//  User - CatalogRef.Users - user of the mobile app.
//
// Returns:
//  Structure - a structure containing the values of functions available to the user.
//
Function MobileAppUserVerification(User = Undefined) Export 
	
	If User = Undefined Then
		User = Users.CurrentUser();
	EndIf;
	AvailableFunctions = New Structure;
	AvailableFunctions.Insert("CashAccount", AccessRight("Insert",
		Metadata.Documents.CashAccountReceiptNote));
	AvailableFunctions.Insert("LettersOfAuthority", AccessRight("Insert",
		Metadata.Documents.IssuedLetterOfAuthority));
	AvailableFunctions.Insert("SalesOrders", AccessRight("Insert",
		Metadata.Documents.SalesOrder));
	AvailableFunctions.Insert("PaymentCard", AccessRight("Insert",
		Metadata.Documents.PaymentCardTransaction));
	AvailableFunctions.Insert("Jobs", AccessRight("Insert",
		Metadata.Documents.JobForSalesRepresentative));
	AvailableFunctions.Insert("RequestsForReturn", AccessRight("Insert",
		Metadata.Documents.RequestForReturnOfGoodsFromCustomer));
	AvailableFunctions.Insert("MobileAppUser",
		AccessRight("Update", Metadata.ExchangePlans.MobileApplicationSalesOrders));
		
	AvailableFunctions.Insert("PriceChange",
		Users.RolesAvailable("FullAccess, VarianceFromSalesTermsAndConditions", User));
	AvailableFunctions.Insert("ChangingClients", AbilityToAddPartnerChanges());
	
	Return AvailableFunctions;
EndFunction

// Fills the collection of values with the saved details of objects to exchange.
//
// Parameters:
//  SavedExchangeDetails - ValueTable, FormDataCollection - a collection to fill in.
//
Procedure FillInTableOfSavedDetails(SavedExchangeDetails) Export
	
	SavedExchangeDetails.Clear();
	
	MasterNode = ExchangePlans.MobileApplicationSalesOrders.ThisNode();
	BankingDetailsSettings = Common.ObjectAttributeValue(MasterNode, "ExchangeAttributeSettings").Get();
	If Not BankingDetailsSettings = Undefined Then
		If TypeOf(SavedExchangeDetails) = Type("ValueTable") Then
			SavedExchangeDetails = BankingDetailsSettings.Copy();
		Else
			SavedExchangeDetails.Load(BankingDetailsSettings);
		EndIf;
	EndIf;
EndProcedure

// Post-processing of the message for exchange
//
// Parameters:
//  Message - String
//  Upload0 - Boolean - Unloading Is True, Loading Is False
//
Procedure ProcessExchangeMessage(Message, Upload0 = True) Export
	
	For Each Item In MobileApplicationSalesOrdersCached.MatchingForReplacement(Upload0) Do
		Message = StrReplace(Message, Item.Key, Item.Value);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region WritingCatalogObjectsInExchange

Procedure WriteContactInformation(MapItemInformation, Val ObjectReference, Val CatalogName, Val CatalogNameIsLocal)
	
	ThereIsPeriodicity = TMCommonUse.ThereArePropsForPartOfObject("ValidFrom",
		ObjectReference.Metadata(), "ContactInformation");
		
	Query = New Query;
	
	If ThereIsPeriodicity Then
		
		QueryText = "SELECT
		|	CatalogContactInformation.Kind AS Kind,
		|	MAX(CatalogContactInformation.ValidFrom) AS ValidFrom
		|INTO CurrentCI
		|FROM
		|	&CatalogCatalogNameContactInformation AS CatalogContactInformation
		|WHERE
		|	CatalogContactInformation.Ref = &Ref
		|	AND NOT CatalogContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.OtherInformationOfCompany)
		|	AND CatalogContactInformation.Kind = VALUE(Enum.ContactInformationTypes.Address)
		|	AND NOT CatalogContactInformation.ValidFrom > BEGINOFPERIOD(&CurrentDate, DAY)
		|
		|GROUP BY
		|	CatalogContactInformation.Kind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatalogContactInformation.Type AS Type,
		|	CatalogContactInformation.Kind AS Kind,
		|	CatalogContactInformation.Presentation AS Presentation,
		|	CatalogContactInformation.FieldValues AS FieldValues,
		|	CatalogContactInformation.Country AS Country,
		|	CatalogContactInformation.State AS State,
		|	CatalogContactInformation.City AS City,
		|	"""" AS EMAddress,
		|	"""" AS ServerDomainName,
		|	"""" AS PhoneNumber,
		|	"""" AS PhoneNumberWithoutCodes
		|INTO AddressInformation
		|FROM
		|	&CatalogCatalogNameContactInformation AS CatalogContactInformation
		|		INNER JOIN CurrentCI AS CurrentCI
		|		ON CatalogContactInformation.Kind = CurrentCI.Kind
		|			AND CatalogContactInformation.ValidFrom = CurrentCI.ValidFrom
		|WHERE
		|	CatalogContactInformation.Ref = &Ref
		|	AND CatalogContactInformation.Kind = VALUE(Enum.ContactInformationTypes.Address)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatalogContactInformation.Type AS Type,
		|	CatalogContactInformation.Kind AS Kind,
		|	CatalogContactInformation.Presentation AS Presentation,
		|	CatalogContactInformation.FieldValues AS FieldValues,
		|	CatalogContactInformation.Country AS Country,
		|	CatalogContactInformation.State AS State,
		|	CatalogContactInformation.City AS City,
		|	CatalogContactInformation.EMAddress AS EMAddress,
		|	CatalogContactInformation.ServerDomainName AS ServerDomainName,
		|	CatalogContactInformation.PhoneNumber AS PhoneNumber,
		|	CatalogContactInformation.PhoneNumberWithoutCodes AS PhoneNumberWithoutCodes
		|FROM
		|	&CatalogCatalogNameContactInformation AS CatalogContactInformation
		|WHERE
		|	CatalogContactInformation.Ref = &Ref
		|	AND NOT CatalogContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.OtherInformationOfCompany)
		|	AND NOT CatalogContactInformation.Kind = VALUE(Enum.ContactInformationTypes.Address)
		|
		|UNION ALL
		|
		|SELECT
		|	CatalogContactInformation.Type,
		|	CatalogContactInformation.Kind,
		|	CatalogContactInformation.Presentation,
		|	CatalogContactInformation.FieldValues,
		|	CatalogContactInformation.Country,
		|	CatalogContactInformation.State,
		|	CatalogContactInformation.City,
		|	"""",
		|	"""",
		|	"""",
		|	""""
		|FROM
		|	AddressInformation AS CatalogContactInformation";
		Query.SetParameter("CurrentDate", Common.CurrentUserDate());
		
	Else
		QueryText = "SELECT
		|	CatalogContactInformation.Type AS Type,
		|	CatalogContactInformation.Kind AS Kind,
		|	CatalogContactInformation.Presentation AS Presentation,
		|	CatalogContactInformation.FieldValues AS FieldValues,
		|	CatalogContactInformation.Country AS Country,
		|	CatalogContactInformation.State AS State,
		|	CatalogContactInformation.City AS City,
		|	CatalogContactInformation.EMAddress AS EMAddress,
		|	CatalogContactInformation.ServerDomainName AS ServerDomainName,
		|	CatalogContactInformation.PhoneNumber AS PhoneNumber,
		|	CatalogContactInformation.PhoneNumberWithoutCodes AS PhoneNumberWithoutCodes
		|FROM
		|	&CatalogCatalogNameContactInformation AS CatalogContactInformation
		|WHERE
		|	NOT CatalogContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.OtherInformationOfCompany)
		|	AND CatalogContactInformation.Ref = &Ref";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&CatalogCatalogNameContactInformation", CatalogName);
	Query.Text = QueryText;
	Query.SetParameter("Ref", ObjectReference);
	tabResult = Query.Execute().Unload();
	
	RecordCatalogContactInformation(MapItemInformation, tabResult, CatalogNameIsLocal);
EndProcedure

Procedure RecordCatalogContactInformation(MapItemInformation, Val CITable, Val CatalogNameIsLocal)
	
	CatalogNameIsLocal = ReplacePartnerWithClient(CatalogNameIsLocal);
	
	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(), CatalogNameIsLocal);
	ArrayOfContactInformationStrings = New Array;
	BlankID = BlankID();
	
	For Each CIRow In CITable Do
		ExchangeObject = XDTOFactory.Create(ObjectType);
		ExchangeObject.АдресЭП = CIRow.EMAddress;
		ExchangeObject.Город = CIRow.City;
		ExchangeObject.ДоменноеИмяСервера = CIRow.ServerDomainName;
		ExchangeObject.НомерТелефона = CIRow.PhoneNumber;
		ExchangeObject.НомерТелефонаБезКодов = CIRow.PhoneNumberWithoutCodes;
		ExchangeObject.Представление = CIRow.Presentation;
		ExchangeObject.Регион = CIRow.State;
		ExchangeObject.Страна = CIRow.Country;
		KiTypeByString = "";
		If ValueIsFilled(CIRow.Type) Then
			KiTypeByString = MobileApplicationSalesOrdersCached.MatchingContactInformationTypes().Get(CIRow.Type);
		EndIf;
		ExchangeObject.Тип = KiTypeByString;
		If ValueIsFilled(CIRow.Kind) Then
			IDOfCIType = TrimAll(CIRow.Kind.UUID());
		Else
			IDOfCIType = BlankID;
		EndIf;
		ExchangeObject.Вид = IDOfCIType;
		If ValueIsFilled(CIRow.Presentation) Then
			ExchangeObject.Представление = CIRow.Presentation;
		Else
			ExchangeObject.Представление = Chars.NBSp;
		EndIf;
		If ValueIsFilled(CIRow.FieldValues) Then
			ExchangeObject.ЗначенияПолей = CIRow.FieldValues;
		Else
			ExchangeObject.ЗначенияПолей = Chars.NBSp;
		EndIf;
		ArrayOfContactInformationStrings.Add(ExchangeObject);
	EndDo;
	
	MapItemInformation["КонтактнаяИнформация"] = ArrayOfContactInformationStrings; //@NON-NLS-1
EndProcedure

Procedure WriteCatalog(XMLWriter, Val StructureOfCatalog, Val CatalogName)
	
	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(), CatalogName);
	ExchangeObject = XDTOFactory.Create(ObjectType);
	
	UploadKi = False;
	ExcludedProperty = "";
	If StructureOfCatalog.Property("КонтактнаяИнформация") Then //@NON-NLS-1
		UploadKi = True;
		ExcludedProperty = ExcludedProperty + ",КонтактнаяИнформация"; //@NON-NLS-1
	EndIf;
	
	UploadAddAttributes = False;
	If StructureOfCatalog.Property("ДополнительныеРеквизиты") Then //@NON-NLS-1
		UploadAddAttributes = True;
		ExcludedProperty = ExcludedProperty + ",ДополнительныеРеквизиты"; //@NON-NLS-1
	EndIf;
	
	ExcludedProperty = TrimAll(Mid(ExcludedProperty, 2));
	Try
		FillPropertyValues(ExchangeObject, StructureOfCatalog,, ExcludedProperty);
	Except
		LongDesc = ErrorInfo();
		WriteLogEvent(
			NStr("vi = 'Trao đổi ứng dụng di động 1C:Đơn hàng';
				|ru = 'Обмен мобильное приложение 1С:Заказы';
				|en = 'Exchange mobile application 1C:Orders'; fa = 'Exchange mobile application 1C:Orders';
				|it = 'Scambio applicazione mobile 1C:Orders';
				|pl = 'Wymiana aplikacja mobilna 1С:Orders';
				|tr = '''''1C:Orders'''' Mobil uygulamanın değişimi'") + "." + NStr("vi = 'Ghi lại danh mục';
																				|ru = 'Запись справочника';
																				|en = 'Catalog record'; fa = 'Catalog record';
																				|it = 'Registrazione query';
																				|pl = 'Wpis katalogu';
																				|tr = 'Dizin kaydı'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error,,
			StructureOfCatalog.Description,
			CatalogName + ": " + DetailErrorDescription(LongDesc));
		Raise(LongDesc.Description);
	EndTry;
	
	If UploadKi Then
		For Each CIRow In StructureOfCatalog["КонтактнаяИнформация"] Do //@NON-NLS-1
			ObjectTabularSection = ExchangeObject.КонтактнаяИнформация;//XDTOList - 
			ObjectTabularSection.Add(CIRow);
		EndDo;
	EndIf;
	
	If UploadAddAttributes Then
		For Each AdditionalAttributesRow In StructureOfCatalog["ДополнительныеРеквизиты"] Do //@NON-NLS-1
			ObjectTabularSection = ExchangeObject.ДополнительныеРеквизиты;//XDTOList - 
			ObjectTabularSection.Add(AdditionalAttributesRow);
		EndDo;
	EndIf;
	
	XDTOFactory.WriteXML(XMLWriter, ExchangeObject);
EndProcedure

#EndRegion

#Region WriteBasicCatalogsInExchange

Procedure WriteCurrencyOfLine(XMLWriter, Val DataString1)
	
	CurrencyStructure = MobileApplicationSalesOrders.CurrencyStructure();
	
	CurrencyStructure.ref				= TrimAll(DataString1.CurrencyRef.UUID());
	CurrencyStructure.DeletionMark	= DataString1.CurrencyDeletionMark;
	CurrencyStructure.Description		= DataString1.CurrencyName;
	CurrencyStructure.Code			= DataString1.CurrencyCode;
	
	LocalObjectName = "CatalogObject.Валюты"; //@NON-NLS-1
	WriteCatalog(XMLWriter, CurrencyStructure, LocalObjectName);
	
EndProcedure

Procedure WriteTypeOfKiLine(XMLWriter, Val DataString1, ExportedObjects)
	
	StructureOfKiSpecies = MobileApplicationSalesOrders.StructureOfKiSpecies(False);
	
	StructureOfKiSpecies.ref = TrimAll(DataString1.CIKindReference.UUID());
	StructureOfKiSpecies.DeletionMark = DataString1.CIKindDeletionMark;
	StructureOfKiSpecies.IsFolder = DataString1.CIKindThisIsAGroup;
	StructureOfKiSpecies.Description = ReplacePartnerWithClient(DataString1.CIKindDescription);
	StructureOfKiSpecies["РеквизитДопУпорядочивания"] = DataString1.CIKindAdditionalSortingAttribute; //@NON-NLS-1
	StructureOfKiSpecies["РедактированиеТолькоВДиалоге"] = DataString1.ViewEditingOnlyInDialog; //@NON-NLS-1
	StructureOfKiSpecies["МожноИзменятьСпособРедактирования"] = DataString1.CIKindYouCanChangeEditingMethod; //@NON-NLS-1
	StructureOfKiSpecies["АдресТолькоРоссийский"] = DataString1.CIKindAddressOnlyRussia; //@NON-NLS-1
	StructureOfKiSpecies["ВключатьСтрануВПредставление"] = DataString1.CIKindIncludeCountryInPresentation; //@NON-NLS-1
	StructureOfKiSpecies["ОбязательноеЗаполнение"] = DataString1.CIKindMandatoryFilling; //@NON-NLS-1
	StructureOfKiSpecies["ПроверятьКорректность"] = DataString1.CIKindCheckAccuracy; //@NON-NLS-1
	StructureOfKiSpecies["СкрыватьНеактуальныеАдреса"] = DataString1.CIKindHideInvalidAddresses; //@NON-NLS-1
	StructureOfKiSpecies["Подсказка"] = DataString1.CIKindTooltip; //@NON-NLS-1
	StructureOfKiSpecies["РазрешитьВводНесколькихЗначений"] = DataString1.CIKindAllowToEnterSeveralValues; //@NON-NLS-1
	StructureOfKiSpecies["ERPКод"] = StructureOfKiSpecies.ref; //@NON-NLS-1
	// Mobile app support up to version 3.0.2.
	StructureOfKiSpecies["ЗапрещатьВводНекорректного"] = False; //@NON-NLS-1
	
	CIKindPredefinedDataName = "";
	If ValueIsFilled(DataString1.CIKindPredefinedDataName) Then
		CIKindPredefinedDataName = 
			MobileApplicationSalesOrdersCached.CompliancePredefinedTypesOfContactInformation().Get(
				ReplacePartnerWithClient(DataString1.CIKindPredefinedDataName));
	EndIf;
	StructureOfKiSpecies.PredefinedDataName = CIKindPredefinedDataName;
	
	KiTypeByString = "";
	If ValueIsFilled(DataString1.CIKindType) Then
		KiTypeByString = MobileApplicationSalesOrdersCached.MatchingContactInformationTypes().Get(DataString1.CIKindType);
	EndIf;
	StructureOfKiSpecies["Тип"] = KiTypeByString; //@NON-NLS-1
	
	If ValueIsFilled(DataString1.CIKindParent) Then
		ParentID = TrimAll(DataString1.CIKindParent.UUID());
		If ExportedObjects.Find(DataString1.CIKindParent) = Undefined Then
			WriteGroupOfFormKi(XMLWriter, DataString1.CIKindParent, ExportedObjects);
		EndIf;
		StructureOfKiSpecies.Parent = ParentID;
	Else
		StructureOfKiSpecies.Parent = BlankID();
	EndIf;
	
	LocalObjectName = "CatalogObject.ВидыКонтактнойИнформации"; //@NON-NLS-1
	WriteCatalog(XMLWriter, StructureOfKiSpecies, LocalObjectName);
	
EndProcedure

Procedure RecordPriceTypeOfLine(XMLWriter, Val DataString1)
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	StructureOfPriceType = MobileApplicationSalesOrders.StructureOfPriceType();
	
	StructureOfPriceType.ref				= TrimAll(DataString1.PriceTypeReference.UUID());
	StructureOfPriceType.DeletionMark		= DataString1.PriceKindDeletionMark;
	StructureOfPriceType["ERPКод"]			= StructureOfPriceType.ref; //@NON-NLS-1
	StructureOfPriceType["ЦенаВключаетНДС"]	= DataString1.PriceTypePriceIncludingVAT; //@NON-NLS-1
	
	StructureOfPriceType["ВалютаЦены"] = MobileApplicationSalesOrdersCached.OrderCurrencyID(); //@NON-NLS-1
	
	VATInformation = StrFind(DataString1.PriceTypeName, NStr("vi = 'Thuế GTGT';
															|ru = 'НДС';
															|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
															|it = 'IVA';
															|pl = 'VAT';
															|tr = 'KDV'", DefaultLanguageCode));
	Description = DataString1.PriceTypeName;
	
	If VATInformation = 0 Then
		If StructureOfPriceType["ЦенаВключаетНДС"] Then //@NON-NLS-1
			TextAboutVAT = NStr("vi = '(gồm thuế GTGT)';
								|ru = '(с НДС)';
								|en = '(including VAT)'; fa = '(including VAT)';
								|it = '(IVA inclusa)';
								|pl = '(z VAT)';
								|tr = '(KDV dahil)'", DefaultLanguageCode);
		Else
			TextAboutVAT = NStr("vi = '(không gồm thuế GTGT)';
								|ru = '(без НДС)';
								|en = '(excluding VAT)'; fa = '(excluding VAT)';
								|it = '(IVA esclusa)';
								|pl = '(bez VAT)';
								|tr = '(KDV hariç)'", DefaultLanguageCode);
		EndIf;
		Description = Description + " "+ TextAboutVAT;
	EndIf;
	StructureOfPriceType.Description = Description;
	
	LocalObjectName = "CatalogObject.ВидыЦен"; //@NON-NLS-1
	WriteCatalog(XMLWriter, StructureOfPriceType, LocalObjectName);
	
EndProcedure

Procedure WriteGroupOfFormKi(XMLWriter, Val ObjectReference, ExportedObjects)
	
	ExportedObjects.Add(ObjectReference);
	
	StructureOfKiSpecies = MobileApplicationSalesOrders.StructureOfKiSpecies(True);
	
	RequestStringForBankingDetails = "IsFolder, DeletionMark, Description, Parent, PredefinedDataName";
	DataString1 = Common.ObjectAttributesValues(ObjectReference, RequestStringForBankingDetails);
	
	StructureOfKiSpecies.ref = TrimAll(ObjectReference.UUID());
	StructureOfKiSpecies.DeletionMark = DataString1.DeletionMark;
	StructureOfKiSpecies.IsFolder = DataString1.IsFolder;
	StructureOfKiSpecies.Description = ReplacePartnerWithClient(DataString1.Description);
	StructureOfKiSpecies.PredefinedDataName = ReplacePartnerWithClient(DataString1.PredefinedDataName);
	StructureOfKiSpecies["ERPКод"] = StructureOfKiSpecies.ref; //@NON-NLS-1
	
	If ValueIsFilled(ObjectReference.Parent) Then
		ParentID = TrimAll(ObjectReference.Parent.UUID());
		If ExportedObjects.Find(ObjectReference.Parent) = Undefined Then
			WriteGroupOfFormKi(XMLWriter, ObjectReference.Parent, ExportedObjects);
		EndIf;
		StructureOfKiSpecies.Parent = ParentID;
	Else
		StructureOfKiSpecies.Parent = BlankID();
	EndIf;
	
	LocalObjectName = "CatalogObject.ВидыКонтактнойИнформации"; //@NON-NLS-1
	WriteCatalog(XMLWriter, StructureOfKiSpecies, LocalObjectName);
	
EndProcedure

Procedure WriteWeightUnitOfString(XMLWriter, Val DataString1)
	
	WeightUnitStructure = MobileApplicationSalesOrders.UnitStructure();
	
	WeightUnitStructure.ref				= TrimAll(DataString1.WeightUnitLink.UUID());
	WeightUnitStructure.DeletionMark		= DataString1.WeightUnitDeletionMark;
	WeightUnitStructure.Code				= DataString1.WeightUnitCode;
	WeightUnitStructure.Description		= DataString1.WeightUnitName;
	WeightUnitStructure.PredefinedDataName = DataString1.WeightUnitPredefinedDataName;
	WeightUnitStructure["НаименованиеПолное"] = DataString1.WeightUnitFullName; //@NON-NLS-1
	WeightUnitStructure["МеждународноеСокращение"] = DataString1.WeightUnitInternationalAbbreviation; //@NON-NLS-1
	
	LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
	WriteCatalog(XMLWriter, WeightUnitStructure, LocalObjectName);
	
EndProcedure

Procedure RecordLineOrganization(XMLWriter, Val DataString1)
	
	OrganizationStructure = MobileApplicationSalesOrders.OrganizationStructure();
	
	OrganizationStructure.ref = TrimAll(DataString1.CompanyLink.UUID());
	OrganizationStructure.DeletionMark = DataString1.OrganizationDeletionMark;
	OrganizationStructure.Description = DataString1.CompanyName;
	OrganizationStructure["ERPКод"] = OrganizationStructure.ref; //@NON-NLS-1
	OrganizationStructure["Префикс"] = DataString1.Company_Prefix; //@NON-NLS-1
	
	StringTaxationSystem = "";
	If ValueIsFilled(DataString1.CompanyTaxationSystemReference) Then
		StringTaxationSystem = 
			MobileApplicationSalesOrdersCached.ComplianceOfTypesOfTaxationSystem().Get(DataString1.CompanyTaxationSystemReference);
	EndIf;
	OrganizationStructure["СистемаНалогообложения"] = StringTaxationSystem; //@NON-NLS-1
	
	OrganizationStructure["ИНН"] = DataString1.CompanyTIN; //@NON-NLS-1
	OrganizationStructure["КПП"] = DataString1.CompanyCRTR; //@NON-NLS-1
	OrganizationStructure["СвидетельствоСерияНомер"] = DataString1.CompanyCertificateSeriesNumber; //@NON-NLS-1
	OrganizationStructure["СвидетельствоДатаВыдачи"] = DataString1.CompanyCertificateIssueDate; //@NON-NLS-1
	OrganizationStructure["НаименованиеПолное"] = DataString1.FullCompanyName; //@NON-NLS-1
	
	LegalEntityWithString = "";
	If ValueIsFilled(DataString1.CompanyLegalEntityIndividual) Then
		LegalEntityWithString = MobileApplicationSalesOrdersCached.ComplianceWithTypesOfLegalEntityIndividual().Get(DataString1.CompanyLegalEntityIndividual);
	EndIf;
	OrganizationStructure["ЮрФизЛицо"] = LegalEntityWithString; //@NON-NLS-1
	
	ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersStructure.Organization = DataString1.CompanyLink;
	ParametersStructure.Currency = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
	
	DefaultBankAccount =
		Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
	
	If Not ValueIsFilled(DefaultBankAccount) Then
		DefaultBankAccount = BankAccountFromLastOrder(DataString1.CompanyLink);
	EndIf;
	
	SetCompanySBankAccountDetails(OrganizationStructure, DefaultBankAccount);
	
	LocalObjectName = "CatalogTabularSectionRow.Организации.КонтактнаяИнформация"; //@NON-NLS-1
	WriteContactInformation(OrganizationStructure, DataString1.CompanyLink, 
		"Catalog.Companies.ContactInformation", 
		LocalObjectName);
	
	ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(DataString1.CompanyLink);
	OrganizationStructure["Руководитель"] = PersonsTM.IndividualShortName(ResponsiblePersons.Director); //@NON-NLS-1
	OrganizationStructure["ГлавныйБухгалтер"] = PersonsTM.IndividualShortName(ResponsiblePersons.ChiefAccountant); //@NON-NLS-1
	
	LocalObjectName = "CatalogTabularSectionRow.Организации.ДополнительныеРеквизиты"; //@NON-NLS-1
	RecordAdditionalDetails(OrganizationStructure, DataString1.CompanyLink, 
		"Catalog.Companies.AdditionalAttributes",
		LocalObjectName);
	
	LocalObjectName = "CatalogObject.Организации"; //@NON-NLS-1
	WriteCatalog(XMLWriter, OrganizationStructure, LocalObjectName);
	
EndProcedure

Procedure WriteFollowingLines(XMLWriter, Val DataString1, ExportedObjects)
	
	WarehouseStructure = MobileApplicationSalesOrders.WarehouseStructure(False);
	
	WarehouseStructure.ref				= TrimAll(DataString1.WarehouseReference.UUID());
	WarehouseStructure.DeletionMark	= DataString1.WarehouseDeletionMark;
	WarehouseStructure.Description		= DataString1.WarehouseName;
	WarehouseStructure.IsFolder		= DataString1.WarehouseIsGroup;
	WarehouseStructure["ERPКод"]			= WarehouseStructure.ref; //@NON-NLS-1
	
	If ValueIsFilled(DataString1.WarehouseParentReference) Then
		ParentID = TrimAll(DataString1.WarehouseParentReference.UUID());
		If ExportedObjects.Find(DataString1.WarehouseParentReference) = Undefined Then
			HierarchyInformation = GroupOfWarehousesToChooseFromOrder(WarehouseStructure.ref, DataString1.WarehouseParentReference, True);
			ParentWarehouseStructure = MobileApplicationSalesOrders.WarehouseStructure(True);
			ParentWarehouseStructure.ref				= ParentID;
			ParentWarehouseStructure.DeletionMark	= DataString1.WarehouseParentDeletionMark;
			ParentWarehouseStructure.Description		= DataString1.WarehouseParentName;
			ParentWarehouseStructure.IsFolder		= DataString1.WarehouseParentIsGroup;
			ParentWarehouseStructure["ERPКод"]			= ParentWarehouseStructure.ref; //@NON-NLS-1
			ParentWarehouseStructure.Parent			= HierarchyInformation.ParentID;
			LocalObjectName = "CatalogObject.Склады"; //@NON-NLS-1
			WriteCatalog(XMLWriter, ParentWarehouseStructure, LocalObjectName);
			ExportedObjects.Add(DataString1.WarehouseParentReference);
			For Each WarehouseData_1 In HierarchyInformation.WarehousesData Do
				WarehouseInformation = MobileApplicationSalesOrders.WarehouseStructure(True);
				FillPropertyValues(WarehouseInformation, WarehouseData_1);
				WriteCatalog(XMLWriter, WarehouseInformation, LocalObjectName);
			EndDo;
		Else
			HierarchyInformation = GroupOfWarehousesToChooseFromOrder(WarehouseStructure.ref, DataString1.WarehouseParentReference, False);
		EndIf;
		WarehouseStructure.Parent			= ParentID;
		WarehouseStructure["ГруппаСкладов"]	= HierarchyInformation.GroupID; //@NON-NLS-1
	Else
		WarehouseStructure.Parent			= BlankID();
		WarehouseStructure["ГруппаСкладов"]	= WarehouseStructure.ref; //@NON-NLS-1
	EndIf;
	
	LocalObjectName = "CatalogTabularSectionRow.Склады.КонтактнаяИнформация"; //@NON-NLS-1
	WriteContactInformation(WarehouseStructure, DataString1.WarehouseReference, 
		"Catalog.Warehouses.ContactInformation", 
		LocalObjectName);
	
	LocalObjectName = "CatalogObject.Склады"; //@NON-NLS-1
	WriteCatalog(XMLWriter, WarehouseStructure, LocalObjectName);
	
EndProcedure

Procedure WriteCountryOfLine(XMLWriter, Val DataString1, ExportedObjects)
	
	CountryStructure = MobileApplicationSalesOrders.CountryStructure();
	
	CountryStructure.ref					= TrimAll(DataString1.CountryRef.UUID());
	CountryStructure.DeletionMark		= DataString1.CountryDeletionMark;
	CountryStructure.Code				= DataString1.CountryCode_;
	CountryStructure.Description			= DataString1.CountryName;
	CountryStructure.PredefinedDataName	= DataString1.CountryPredefinedDataName;
	CountryStructure["НаименованиеПолное"]	= DataString1.CountryFullName; //@NON-NLS-1
	CountryStructure["КодАльфа2"]			= DataString1.CountryCodeAlpha2; //@NON-NLS-1
	CountryStructure["КодАльфа3"]			= DataString1.CountryCodeAlpha3; //@NON-NLS-1
	
	LocalObjectName = "CatalogObject.СтраныМира"; //@NON-NLS-1
	WriteCatalog(XMLWriter, CountryStructure, LocalObjectName);
	
EndProcedure

Procedure RecordRefundRequestStates(XMLWriter, MobileDeviceId)
	
	UnloadingStateOfApplications = True;
	RecordingAppVersion = 
		InformationRegisters.CorrespondenceOfProductsOf1COrdersMobileApplication.CreateRecordSet();
	RecordingAppVersion.Filter["ProductsID"].Value = MobileDeviceId;
	RecordingAppVersion.Filter["ProductsID"].Use = True;
	RecordingAppVersion.Read();
	If RecordingAppVersion.Count()>0 Then
		UnloadingStateOfApplications = False;
	EndIf;
	
	If UnloadingStateOfApplications Then
		StateStructure_ = New Structure;
		For Each Value In Enums.StatesOfRequestsForReturnOfGoodsFromCustomers Do
			
			IndexOf = Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IndexOf(Value);
			RequestStateObject =
				 Metadata.Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.EnumValues.Get(IndexOf);//Object Metadata Enumeration - 
			
			StateStructure_.Insert("Description", TrimAll(Value));
			StateStructure_.Insert("Порядок", IndexOf + 2); //@NON-NLS-1
			StateStructure_.Insert("ERPКод", RequestStateObject.Name); //@NON-NLS-1
			
			LocalObjectName = "CatalogObject.СостоянияЗаявокНаВозвратТоваровОтКлиентов"; //@NON-NLS-1
			WriteCatalog(XMLWriter, StateStructure_, LocalObjectName);
			
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region DataToUpload

Function DataForUploadingIndividualPriceLists(Node, AgreementLine_)
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		NameSchemeForUploadingPriceLists = "IndividualPriceListExportScheme2_5";
	Else
		NameSchemeForUploadingPriceLists = "IndividualPriceListExportScheme";
	EndIf;
	
	SettingsComposer = ComposerOfSettingsForUploadingIndividualPriceLists(Node, AgreementLine_, NameSchemeForUploadingPriceLists);
	
	IndividualPriceListExportScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(NameSchemeForUploadingPriceLists);
	
	TableOfIndividualPrices = New ValueTable;
	TemplateComposer = New DataCompositionTemplateComposer;
	Try
		DataCompositionTemplate = TemplateComposer.Execute(IndividualPriceListExportScheme,
			SettingsComposer.GetSettings(),
			,,Type("DataCompositionValueCollectionTemplateGenerator"), False);
	Except
		Return TableOfIndividualPrices;
	EndTry;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate, , , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(TableOfIndividualPrices);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor);
	OutputProcessor.EndOutput();
	
	Return TableOfIndividualPrices;
EndFunction

Function DataForUnloadingClients(Node)
	
	SettingsComposer = ClientUploadSettingsComposer(Node);
	
	PartnerExportScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(
		"PartnerExportScheme");
		
	TableOfPartners = New ValueTable;
	TemplateComposer = New DataCompositionTemplateComposer;
	Try
		DataCompositionTemplate = TemplateComposer.Execute(PartnerExportScheme, SettingsComposer.GetSettings(),
			,,Type("DataCompositionValueCollectionTemplateGenerator"), False);
	Except
		Return TableOfPartners;
	EndTry;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate, , , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(TableOfPartners);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor);
	OutputProcessor.EndOutput();
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		TableOfPartners.Columns.Add("SelfPickup", New TypeDescription("Boolean"));
		TableOfPartners.FillValues(True, "SelfPickup");
		TableOfPartners.FillValues(Date("00010101000000"), "PartnerDeliveryTimeFrom");
		TableOfPartners.FillValues(Date("00010101000000"), "PartnerDeliveryTimeTo");
	EndIf;
	If TableOfPartners.Columns.Find("PartnerWarehouseReference") = Undefined Then
		TableOfPartners.Columns.Add("PartnerWarehouseReference", New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	If TableOfPartners.Columns.Find("PartnerPaymentMethodReference") = Undefined Then
		TableOfPartners.Columns.Add("PartnerPaymentMethodReference", New TypeDescription("EnumRef.PaymentForms"));
	EndIf;
	
	Return TableOfPartners;
EndFunction

Function DataForUnloadingBalances(Node)
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		NameUploadScheme = "ItemsBalanceExportScheme2_5";
	Else
		NameUploadScheme = "ItemsBalanceExportScheme";
	EndIf;
	
	SettingsComposer = ComposerForUnloadingLeftoversSettings(Node, NameUploadScheme);
	
	BalanceUnloadingScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(NameUploadScheme);
	
	Set = BalanceUnloadingScheme.DataSets.Find("MainDataSet");
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(Set.Query, TablesNames);
	
	Fields = "WarehouseStockBalance.Products,WarehouseStockBalance.Characteristic,WarehouseStockBalance.Warehouse";
	Set.Query = InformationRegisters.ProductRestrictions.SubstituteConnection(Set.Query,
		"SubstituteGoodsRestriction", Fields);
	
	BalanceTable = New ValueTable;
	TemplateComposer = New DataCompositionTemplateComposer;
	Try
		DataCompositionTemplate = TemplateComposer.Execute(BalanceUnloadingScheme, SettingsComposer.GetSettings(),
			,,Type("DataCompositionValueCollectionTemplateGenerator"), False);
	Except
		Return BalanceTable;
	EndTry;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate, , , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(BalanceTable);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor);
	OutputProcessor.EndOutput();
	
	If BalanceTable.Columns.Find("Characteristic") = Undefined Then
		BalanceTable.Columns.Add("Characteristic",
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	
	Return BalanceTable;
EndFunction

Function DataForUploadingPriceLists(Node, PriceListFilters)
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		NameSchemeForUploadingPriceLists = "PriceExportScheme2_5";
	Else
		NameSchemeForUploadingPriceLists = "PriceExportScheme";
	EndIf;
	
	SettingsComposer = PriceListUploadSettingsComposer(Node, PriceListFilters, NameSchemeForUploadingPriceLists);
	
	PriceExportScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(NameSchemeForUploadingPriceLists);
	
	TableOfPrices = New ValueTable;
	TemplateComposer = New DataCompositionTemplateComposer;
	Try
		DataCompositionTemplate = TemplateComposer.Execute(PriceExportScheme, SettingsComposer.GetSettings(),
			,,Type("DataCompositionValueCollectionTemplateGenerator"), False);
	Except
		Return TableOfPrices;
	EndTry;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate, , , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(TableOfPrices);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor);
	OutputProcessor.EndOutput();
	
	Return TableOfPrices;
EndFunction

Function DataForUploadingCatalogs(Node)
	
	SettingsComposer = ComposerForCatalogUploadSettings(Node);
	
	CatalogUploadScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(
		"MainCatalogExportScheme");
		
	CatalogTable_ = New ValueTable;
	TemplateComposer = New DataCompositionTemplateComposer;
	Try
		DataCompositionTemplate = TemplateComposer.Execute(CatalogUploadScheme,
			SettingsComposer.GetSettings(),
			,,Type("DataCompositionValueCollectionTemplateGenerator"), False);
	Except
		Return CatalogTable_;
	EndTry;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate, , , True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(CatalogTable_);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor);
	OutputProcessor.EndOutput();
	
	Return CatalogTable_;
EndFunction

Function ComposerOfSettingsForUploadingIndividualPriceLists(Node, AgreementLine_, NameSchemeForUploadingPriceLists)
	
	CatalogUploadScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(NameSchemeForUploadingPriceLists);
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CatalogUploadScheme));
	SettingsComposer.LoadSettings(CatalogUploadScheme.DefaultSettings);
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Node");
	DSCParameter.Value = Node;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Currency");
	DSCParameter.Value = AgreementLine_.Currency;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Period");
	DSCParameter.Value = CurrentSessionDate();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("UseCharacteristics");
	DSCParameter.Value = GetFunctionalOption("UseItemVariants");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("CustomerTermsOfSales");
	DSCParameter.Value = AgreementLine_.Terms;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ManagementCompanyNotUsed");
	DSCParameter.Value = Not GetFunctionalOption("UseManagementCompany");
	DSCParameter.Use = True;
	
	Filter = SettingsComposer.Settings.Filter;
	
	ComposerSettingsFromExchangeSettings = MobileApplicationSalesOrdersCached.ExchangeSettings(Node);//DataCompositionSettings - 
	
	FilterByProductSegmentIsUsed = False;
	UseWeightCharacteristics = False;
	TransmitProductImages = False;
	
	WarehouseField = New DataCompositionField("Warehouse");
	ProductSegmentField = New DataCompositionField("ProductSegment");
	PartnerSegmentField = New DataCompositionField("PartnersSegment");
	AgreementField_ = New DataCompositionField("Terms");
	FieldUseWeightCharacteristics = New DataCompositionField("UseWeightCharacteristics");
	SendProductImagesField = New DataCompositionField("TransmitProductImages");
	
	If Not ComposerSettingsFromExchangeSettings = Undefined Then
		ArrayDeletition = New Array;
		For Each FilterElement In ComposerSettingsFromExchangeSettings.Filter.Items Do
			If FilterElement.Use Then
				If FilterElement.LeftValue = PartnerSegmentField
					Or FilterElement.LeftValue = AgreementField_
					Or FilterElement.LeftValue = WarehouseField Then
					Continue;
				EndIf;
				NewItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewItem, FilterElement,
					"UserSettingID, LeftValue, ComparisonType, RightValue, Use");
				If FilterElement.LeftValue = ProductSegmentField Then
					FilterByProductSegmentIsUsed = True;
				EndIf;
				If FilterElement.LeftValue = FieldUseWeightCharacteristics Then
					UseWeightCharacteristics = FilterElement.RightValue;
				EndIf;
				If FilterElement.LeftValue = SendProductImagesField Then
					TransmitProductImages = FilterElement.RightValue;
				EndIf;
				If FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
					ArrayDeletition.Add(NewItem);
				EndIf;
			EndIf;
		EndDo;
		For Each ForDeletion In ArrayDeletition Do
			Filter.Items.Delete(ForDeletion);
		EndDo;
	EndIf;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("FilterByProductSegmentIsUsed");
	DSCParameter.Value = FilterByProductSegmentIsUsed;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("UseWeightCharacteristics");
	DSCParameter.Value = UseWeightCharacteristics;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("TransmitProductImages");
	DSCParameter.Value = TransmitProductImages;
	DSCParameter.Use = True;
	
	Return SettingsComposer;
EndFunction

Function ClientUploadSettingsComposer(Node)
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	PartnerExportScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate("PartnerExportScheme");
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(PartnerExportScheme)); 
	SettingsComposer.LoadSettings(PartnerExportScheme.DefaultSettings);
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Period");
	DSCParameter.Value = CurrentSessionDate();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Node");
	DSCParameter.Value = Node;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("IsBlankString");
	DSCParameter.Value = "";
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ManagementCompanyNotUsed");
	DSCParameter.Value = Not GetFunctionalOption("UseManagementCompany");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("AgreementUsage");
	DSCParameter.Value = Constants.UseTermsOfSales.Get();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Currency");
	DSCParameter.Value = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("UseShipmentProhibition");
	DSCParameter.Value = GetFunctionalOption("UseShipmentProhibition");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("TextSegmentShipmentProhibited");
	DSCParameter.Value = NStr("vi = 'Khách hàng nằm trong phân khúc bạn hàng bị cấm giao hàng.';
								|ru = 'Клиент входит в сегмент партнеров, которым отгрузка запрещена.';
								|en = 'Customer is on delivery black list.'; fa = 'Customer is on delivery black list.';
								|it = 'Il cliente fa parte del segmento di partner a cui è vietata la spedizione.';
								|pl = 'Klient wchodzi do segmentów partnerów, dla których wysyłka jest zabronionа.';
								|tr = 'Müşteri, sevkiyat yapmasına izin verilmeyen iş ortakları segmentindedir.'",
		DefaultLanguageCode);
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("TextPartnerDeletionMark");
	DSCParameter.Value = NStr("vi = 'Khách hàng đã bị đặt dấu xóa.';
								|ru = 'Клиент помечен на удаление.';
								|en = 'The customer is marked for deletion.'; fa = 'The customer is marked for deletion.';
								|it = 'Il cliente è contrassegnato per la cancellazione.';
								|pl = 'Klient jest zaznaczony do usunięcia.';
								|tr = 'Müşteri silinmek üzere işaretlenmiştir.'",
		DefaultLanguageCode);
	DSCParameter.Use = True;
	
	UseAgreementsAndContracts = GetFunctionalOption("ToUseTermsOfSales")
		Or GetFunctionalOption("UseCustomerContracts");
		
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("UseAgreementsAndContracts");
	DSCParameter.Value = UseAgreementsAndContracts;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ContractsAreUsed");
	DSCParameter.Value = GetFunctionalOption("UseCustomerContracts");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("StandardContractName");
	DSCParameter.Value = NStr("vi = 'Hợp đồng mẫu';
								|ru = 'Типовой договор';
								|en = 'Standard contract'; fa = 'Standard contract';
								|it = 'Contratto tipo';
								|pl = 'Kontrakt typowy';
								|tr = 'Örnek sözleşme'",
		DefaultLanguageCode);
	DSCParameter.Use = True;
	
	Filter = SettingsComposer.Settings.Filter;
	
	ComposerSettingsFromExchangeSettings = MobileApplicationSalesOrdersCached.ExchangeSettings(Node);//DataCompositionSettings - 
	
	WarehouseField = New DataCompositionField("Warehouse");
	ProductSegmentField =  New DataCompositionField("ProductSegment");
	PartnerSegmentField = New DataCompositionField("PartnersSegment");
	OrganizationField_ = New DataCompositionField("Organization");
	PriceTypeField = New DataCompositionField("PriceKind");
	
	FilterByPartnerSegmentIsUsed = False;
	If Not ComposerSettingsFromExchangeSettings = Undefined Then
		For Each FilterElement In ComposerSettingsFromExchangeSettings.Filter.Items Do
			If FilterElement.Use Then
				// Filters do not participate in the selection of customers: "Warehouse", "Segment Nomenclature".
				If FilterElement.LeftValue = WarehouseField
					Or FilterElement.LeftValue = ProductSegmentField Then
					Continue;
				EndIf;
				// The filter: "Organization" does not participate in the selection of clients, if agreements and contracts are not used.
				If FilterElement.LeftValue = OrganizationField_
					And Not UseAgreementsAndContracts Then
					Continue;
				EndIf;
				// The filter: "View Prices" does not participate in the selection of clients, if agreements and contracts are not used.
				If FilterElement.LeftValue = PriceTypeField
					And Not UseAgreementsAndContracts Then
					Continue;
				EndIf;
				// The filters of the exchange node header do not participate in the selection.
				If FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
					Continue;
				EndIf;
				
				NewItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewItem, FilterElement,
					"UserSettingID, LeftValue, ComparisonType, RightValue, Use");
				If FilterElement.LeftValue = PartnerSegmentField Then
					FilterByPartnerSegmentIsUsed = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("PartnerSegmentsAreUsed");
	DSCParameter.Value = GetFunctionalOption("UsePartnersSegments");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("FilterByPartnerSegmentIsUsed");
	DSCParameter.Value = FilterByPartnerSegmentIsUsed;
	DSCParameter.Use = True;
	
	Return SettingsComposer;
EndFunction

Function ComposerForUnloadingLeftoversSettings(Node, NameUploadScheme)
	
	BalanceUnloadingScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(NameUploadScheme);

	Set = BalanceUnloadingScheme.DataSets.Find("MainDataSet");
	Fields = "WarehouseStockBalance.Products,WarehouseStockBalance.Characteristic,WarehouseStockBalance.Warehouse";
	Set.Query = InformationRegisters.ProductRestrictions.SubstituteConnection(Set.Query,
		"SubstituteGoodsRestriction", Fields);

	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(BalanceUnloadingScheme));
	SettingsComposer.LoadSettings(BalanceUnloadingScheme.DefaultSettings);
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Period");
	DSCParameter.Value = CurrentSessionDate();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("UseCharacteristics");
	DSCParameter.Value = GetFunctionalOption("UseItemVariants");
	DSCParameter.Use = True;
	
	Filter = SettingsComposer.Settings.Filter;
	
	ComposerSettingsFromExchangeSettings = MobileApplicationSalesOrdersCached.ExchangeSettings(Node);//DataCompositionSettings - 
	
	ProductSegmentField =  New DataCompositionField("ProductSegment");
	PartnerSegmentField = New DataCompositionField("PartnersSegment");
	AgreementField_ =  New DataCompositionField("Terms");
	OrganizationField_ =  New DataCompositionField("Organization");
	
	FilterByProductSegmentIsUsed = False;
	If Not ComposerSettingsFromExchangeSettings = Undefined Then
		ArrayDeletition = New Array;
		For Each FilterElement In ComposerSettingsFromExchangeSettings.Filter.Items Do
			If FilterElement.Use Then
				If FilterElement.LeftValue = PartnerSegmentField
					Or FilterElement.LeftValue = AgreementField_
					Or FilterElement.LeftValue = OrganizationField_ Then
					Continue;
				EndIf;
				NewItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewItem, FilterElement,
					"UserSettingID, LeftValue, ComparisonType, RightValue, Use");
				UserSetting = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
				If Not UserSetting = Undefined Then
					UserSetting.ComparisonType = FilterElement.ComparisonType;
					UserSetting.RightValue = FilterElement.RightValue;
				EndIf;
				If FilterElement.LeftValue = ProductSegmentField Then
					FilterByProductSegmentIsUsed = True;
				EndIf;
				If FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
					ArrayDeletition.Add(NewItem);
				EndIf;
			EndIf;
		EndDo;
		For Each ForDeletion In ArrayDeletition Do
			Filter.Items.Delete(ForDeletion);
		EndDo;
	EndIf;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("FilterByProductSegmentIsUsed");
	DSCParameter.Value = FilterByProductSegmentIsUsed;
	DSCParameter.Use = True;
	
	Return SettingsComposer;
EndFunction

Function PriceListUploadSettingsComposer(Node, PriceListFilters, NameSchemeForUploadingPriceLists)
	
	CatalogUploadScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(NameSchemeForUploadingPriceLists);
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CatalogUploadScheme));
	SettingsComposer.LoadSettings(CatalogUploadScheme.DefaultSettings);
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Node");
	DSCParameter.Value = Node;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Currency");
	DSCParameter.Value = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Period");
	DSCParameter.Value = CurrentSessionDate();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("UseCharacteristics");
	DSCParameter.Value = GetFunctionalOption("UseItemVariants");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ManagementCompanyNotUsed");
	DSCParameter.Value = Not GetFunctionalOption("UseManagementCompany");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("HasChanges");
	DSCParameter.Value = PriceListFilters.HasChanges;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ProductsArray");
	DSCParameter.Value = PriceListFilters.Products;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ArrayOfCharacteristics");
	DSCParameter.Value = PriceListFilters.Characteristic;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ArrayOfPriceTypes");
	DSCParameter.Value = PriceListFilters.PriceKind;
	DSCParameter.Use = True;
	
	UseTermsOfSales = Constants.UseTermsOfSales.Get();
	OnlySpecialTermsOfSales = 
		UseTermsOfSales = Enums.UseTermsOfSales.OnlySpecialTermsOfSales;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("NotAgreementsAreUsed");
	DSCParameter.Value = OnlySpecialTermsOfSales
		Or Not GetFunctionalOption("ToUseTermsOfSales");
	DSCParameter.Use = True;
	
	Filter = SettingsComposer.Settings.Filter;
	
	ComposerSettingsFromExchangeSettings = MobileApplicationSalesOrdersCached.ExchangeSettings(Node);//DataCompositionSettings - 
	
	FilterByProductSegmentIsUsed = False;
	UseWeightCharacteristics = False;
	TransmitProductImages = False;
	
	WarehouseField = New DataCompositionField("Warehouse");
	ProductSegmentField =  New DataCompositionField("ProductSegment");
	PartnerSegmentField = New DataCompositionField("PartnersSegment");
	FieldUseWeightCharacteristics = New DataCompositionField("UseWeightCharacteristics");
	SendProductImagesField = New DataCompositionField("TransmitProductImages");
	
	If Not ComposerSettingsFromExchangeSettings = Undefined Then
		ArrayDeletition = New Array;
		For Each FilterElement In ComposerSettingsFromExchangeSettings.Filter.Items Do
			If FilterElement.Use Then
				If FilterElement.LeftValue = PartnerSegmentField Then
					Continue;
				EndIf;
				If FilterElement.LeftValue = WarehouseField Then
					Continue;
				EndIf;
				NewItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewItem, FilterElement,
					"UserSettingID, LeftValue, ComparisonType, RightValue, Use");
				If FilterElement.LeftValue = ProductSegmentField Then
					FilterByProductSegmentIsUsed = True;
				EndIf;
				If FilterElement.LeftValue = FieldUseWeightCharacteristics Then
					UseWeightCharacteristics = FilterElement.RightValue;
				EndIf;
				If FilterElement.LeftValue = SendProductImagesField Then
					TransmitProductImages = FilterElement.RightValue;
				EndIf;
				If FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
					ArrayDeletition.Add(NewItem);
				EndIf;
			EndIf;
		EndDo;
		For Each ForDeletion In ArrayDeletition Do
			Filter.Items.Delete(ForDeletion);
		EndDo;
	EndIf;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("FilterByProductSegmentIsUsed");
	DSCParameter.Value = FilterByProductSegmentIsUsed;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("UseWeightCharacteristics");
	DSCParameter.Value = UseWeightCharacteristics;
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("TransmitProductImages");
	DSCParameter.Value = TransmitProductImages;
	DSCParameter.Use = True;
	
	Return SettingsComposer;
EndFunction

Function ComposerForCatalogUploadSettings(Node)
	
	CatalogUploadScheme = ExchangePlans.MobileApplicationSalesOrders.GetTemplate(
		"MainCatalogExportScheme");
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CatalogUploadScheme));
	SettingsComposer.LoadSettings(CatalogUploadScheme.DefaultSettings);
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Currency");
	DSCParameter.Value = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("Period");
	DSCParameter.Value = CurrentSessionDate();
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("IsBlankString");
	DSCParameter.Value = "";
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("ManagementCompanyNotUsed");
	DSCParameter.Value = Not GetFunctionalOption("UseManagementCompany");
	DSCParameter.Use = True;
	
	DSCParameter = SettingsComposer.Settings.DataParameters.Items.Find("WeightUnit");
	DSCParameter.Value = Constants.UnitOfMeasureForWeight.Get();
	DSCParameter.Use = True;
	
	Filter = SettingsComposer.Settings.Filter;
	
	ComposerSettingsFromExchangeSettings = MobileApplicationSalesOrdersCached.ExchangeSettings(Node);//DataCompositionSettings - 
	
	ProductSegmentField =  New DataCompositionField("ProductSegment");
	PartnerSegmentField = New DataCompositionField("PartnersSegment");
	AgreementField_ =  New DataCompositionField("Terms");
	
	If Not ComposerSettingsFromExchangeSettings = Undefined Then
		For Each FilterElement In ComposerSettingsFromExchangeSettings.Filter.Items Do
			If FilterElement.Use Then
				If FilterElement.LeftValue = PartnerSegmentField
					Or FilterElement.LeftValue = AgreementField_
					Or FilterElement.LeftValue = ProductSegmentField Then
					Continue;
				EndIf;
				// The filters of the exchange node header do not participate in the selection.
				If FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
					Continue;
				EndIf;
				NewItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
				FillPropertyValues(NewItem, FilterElement,
					"UserSettingID, LeftValue, ComparisonType, RightValue, Use");
			EndIf;
		EndDo;
	EndIf;
	
	Return SettingsComposer;
EndFunction

#EndRegion

#Region DataForRegistration

Function TypesOfPricesForRegistration(RecordSet)
	
	SetPrivilegedMode(True);
	
	RegistrationStructure = New Structure("GeneralPriceList, PartnersForRegistration");
	
	TypesOfPrices_ = RecordSet.UnloadColumn("PriceKind");
	
	Query = New Query(
	"SELECT TOP 1
	|	TypesOfPrices.Ref
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	NOT &TermsAreUsed
	|	AND TypesOfPrices.UseWhileSellingToCustomers
	|	AND TypesOfPrices.Ref IN(&TypesOfPrices_)
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerAgreementsSales.PricesKind
	|FROM
	|	Catalog.TermsOfSale AS CustomerAgreementsSales
	|WHERE
	|	CustomerAgreementsSales.Standard_
	|	AND CustomerAgreementsSales.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CustomerAgreementsSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Approved
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind.UseWhileSellingToCustomers
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind IN (&TypesOfPrices_)
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAgreementsSales.Partner AS Partner
	|FROM
	|	Catalog.TermsOfSale AS CustomerAgreementsSales
	|WHERE
	|	NOT CustomerAgreementsSales.Standard_
	|	AND CustomerAgreementsSales.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CustomerAgreementsSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Approved
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind.UseWhileSellingToCustomers
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind IN (&TypesOfPrices_)
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerAgreementsSales.Ref.Partner
	|FROM
	|	Catalog.TermsOfSale.Goods AS CustomerAgreementsSales
	|WHERE
	|	NOT CustomerAgreementsSales.Ref.Standard_
	|	AND CustomerAgreementsSales.Ref.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Ref.Approved
	|			ELSE TRUE
	|		END
	|	AND CustomerAgreementsSales.Ref.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.Ref.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.Ref.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.Ref.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.Ref.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CustomerAgreementsSales.PriceKind.UseWhileSellingToCustomers
	|	AND CustomerAgreementsSales.PriceKind IN(&TypesOfPrices_)
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerAgreementsSales.Ref.Partner
	|FROM
	|	Catalog.TermsOfSale.PriceGroups AS CustomerAgreementsSales
	|WHERE
	|	NOT CustomerAgreementsSales.Ref.Standard_
	|	AND CustomerAgreementsSales.Ref.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Ref.Approved
	|			ELSE TRUE
	|		END
	|	AND CustomerAgreementsSales.Ref.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.Ref.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.Ref.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.Ref.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.Ref.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CustomerAgreementsSales.PricesKind.UseWhileSellingToCustomers
	|	AND CustomerAgreementsSales.PricesKind IN(&TypesOfPrices_)");
	
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("TypesOfPrices_", TypesOfPrices_);
	Query.SetParameter("TermsAreUsed", GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("MatchingIsUsed",
		GetFunctionalOption("UseApprovalOfTermsOfSales"));
		
	Available_BusinessTransactions = New Array;
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.SaleToCustomer);
	Query.SetParameter("Available_BusinessTransactions", Available_BusinessTransactions);
	
	ResultsArray = Query.ExecuteBatch();
	
	RegistrationStructure.GeneralPriceList = Not ResultsArray[0].IsEmpty();
	
	RegistrationStructure.PartnersForRegistration = ResultsArray[1].Unload().UnloadColumn("Partner");
	
	Return RegistrationStructure;
EndFunction

Function TypesOfPricesForRegistration25(RecordSet)
	
	SetPrivilegedMode(True);
	
	RegistrationStructure = New Structure("GeneralPriceList, PartnersForRegistration");
	
	TypesOfPrices_ = RecordSet.UnloadColumn("PriceKind");
	
	Query = New Query(
	"SELECT TOP 1
	|	TypesOfPrices.Ref
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	NOT &TermsAreUsed
	|	AND TypesOfPrices.UseWhileSellingToCustomers
	|	AND TypesOfPrices.Ref IN(&TypesOfPrices_)
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerAgreementsSales.PricesKind
	|FROM
	|	Catalog.TermsOfSale AS CustomerAgreementsSales
	|WHERE
	|	CustomerAgreementsSales.Standard_
	|	AND CustomerAgreementsSales.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CustomerAgreementsSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Approved
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind.UseWhileSellingToCustomers
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind IN (&TypesOfPrices_)
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerAgreementsSales.SpecialPriceType
	|FROM
	|	Catalog.TermsOfSale AS CustomerAgreementsSales
	|WHERE
	|	CustomerAgreementsSales.Standard_
	|	AND CustomerAgreementsSales.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CustomerAgreementsSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Approved
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.SpecialPriceType = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.SpecialPriceType.UseWhileSellingToCustomers
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.SpecialPriceType = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.SpecialPriceType IN (&TypesOfPrices_)
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerAgreementsSales.Partner AS Partner
	|FROM
	|	Catalog.TermsOfSale AS CustomerAgreementsSales
	|WHERE
	|	NOT CustomerAgreementsSales.Standard_
	|	AND CustomerAgreementsSales.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CustomerAgreementsSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Approved
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind.UseWhileSellingToCustomers
	|		END
	|	AND CASE
	|			WHEN CustomerAgreementsSales.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				THEN TRUE
	|			ELSE CustomerAgreementsSales.PricesKind IN (&TypesOfPrices_)
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerAgreementsSales.Partner AS Partner
	|FROM
	|	Catalog.TermsOfSale AS CustomerAgreementsSales
	|WHERE
	|	NOT CustomerAgreementsSales.Standard_
	|	AND CustomerAgreementsSales.BusinessOperation IN (&Available_BusinessTransactions)
	|	AND CustomerAgreementsSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND CASE
	|			WHEN &MatchingIsUsed
	|				THEN CustomerAgreementsSales.Approved
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityStartDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityStartDate > &Period
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN NOT CustomerAgreementsSales.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN NOT CustomerAgreementsSales.ValidityEndDate < &Period
	|			ELSE TRUE
	|		END
	|	AND CustomerAgreementsSales.SpecialPriceType <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	AND CustomerAgreementsSales.SpecialPriceType.UseWhileSellingToCustomers
	|	AND CustomerAgreementsSales.SpecialPriceType IN (&TypesOfPrices_)");
	
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("TypesOfPrices_", TypesOfPrices_);
	Query.SetParameter("TermsAreUsed", GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("MatchingIsUsed",
		GetFunctionalOption("UseApprovalOfTermsOfSales"));
		
	Available_BusinessTransactions = New Array;
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.SaleToCustomer);
	Query.SetParameter("Available_BusinessTransactions", Available_BusinessTransactions);
	
	ResultsArray = Query.ExecuteBatch();
	
	RegistrationStructure.GeneralPriceList = Not ResultsArray[0].IsEmpty();
	
	RegistrationStructure.PartnersForRegistration = ResultsArray[1].Unload().UnloadColumn("Partner");
	
	Return RegistrationStructure;
EndFunction

Procedure CounterpartiesForRegistration(PartnersForRegistration, Counterparty)
	
	SetPrivilegedMode(True);
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInPartnerListWithAllHierarchy(
			Common.ObjectAttributeValue(Counterparty, "Partner"), PartnerList);
		For Each Item In PartnerList Do
			PartnersForRegistration.Add(Item.Value);
		EndDo;
		Return;
	EndIf;
	
	Query = New Query;
	
	Query.Text = "SELECT DISTINCT
	|	PartnerHierarchy.Parent AS Partner
	|FROM
	|	InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON PartnerHierarchy.Parent = Counterparties.Partner
	|WHERE
	|	Counterparties.Ref = &Counterparty";
	
	Query.SetParameter("Counterparty", Counterparty);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ArrayOfPartners = QueryResult.Unload().UnloadColumn("Partner");
	
	For Each ArrayElement In ArrayOfPartners Do
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInPartnerListWithAllHierarchy(ArrayElement, PartnerList);
		For Each Item In PartnerList Do
			PartnersForRegistration.Add(Item.Value);
		EndDo;
	EndDo;
EndProcedure

Function PartnersForRegistration(Ref, RegisterAllPartners)
	
	SetPrivilegedMode(True);
	
	PartnersForRegistration = New Array;
	
	If TypeOf(Ref) = Type("CatalogRef.Partners") Then
		PartnersForRegistration.Add(Ref);
	ElsIf TypeOf(Ref) = Type("CatalogRef.ContactPersonsForPartners") Then
		PartnersForRegistration.Add(Common.ObjectAttributeValue(Ref, "Owner"));
	ElsIf TypeOf(Ref) = Type("CatalogRef.Counterparties") Then
		CounterpartiesForRegistration(PartnersForRegistration, Ref);
	ElsIf TypeOf(Ref) = Type("CatalogRef.CounterpartyContracts") Then
		CounterpartiesForRegistration(PartnersForRegistration, Common.ObjectAttributeValue(Ref, "Counterparty"));
	ElsIf TypeOf(Ref) = Type("CatalogRef.TermsOfSale") Then
		CustomerAgreementsForRegistration(PartnersForRegistration, RegisterAllPartners, Ref);
	EndIf;
	
	Return PartnersForRegistration;
EndFunction

Procedure CustomerAgreementsForRegistration(PartnersForRegistration, RegisterAllPartners, Terms)
	
	SetPrivilegedMode(True);
	
	If Not Common.ObjectAttributeValue(Terms, "Standard_") Then
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInPartnerListWithAllHierarchy(
			Common.ObjectAttributeValue(Terms, "Partner"), PartnerList);
		For Each Item In PartnerList Do
			PartnersForRegistration.Add(Item.Value);
		EndDo;
		Return;
	EndIf;
	
	PartnerSegment = Common.ObjectAttributeValue(Terms, "PartnersSegment");
	
	If Not ValueIsFilled(PartnerSegment) Then
		RegisterAllPartners = True;
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	SegmentPartners.Partner AS Partner
	|FROM
	|	InformationRegister.SegmentPartners AS SegmentPartners
	|WHERE
	|	SegmentPartners.Segment = &PartnerSegment");
	
	Query.SetParameter("PartnerSegment", PartnerSegment);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ArrayOfPartners = QueryResult.Unload().UnloadColumn("Partner");
	
	For Each ArrayElement In ArrayOfPartners Do
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInPartnerListWithAllHierarchy(ArrayElement, PartnerList);
		For Each Item In PartnerList Do
			PartnersForRegistration.Add(Item.Value);
		EndDo;
	EndDo;
EndProcedure

Procedure ClearRegistrationOfProductsAndImagesNotIncludedInExchange(ExchangeNode)
	
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Metadata.Catalogs.Products);
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Metadata.Catalogs.ProductsAttachedFiles);
EndProcedure

#EndRegion

#Region CreatingNewDocuments

Procedure WritePostNewDocument(DocumentObject, Message, Posted, DocumentType);
	
	Try
		DocumentObject.DataExchange.Load = True;
		DocumentObject.Write(DocumentWriteMode.Write);
	Except
		If DocumentType = 0 Then
			RecordCustomerOrderStatusInformation(Message, DocumentObject.Ref, True, True);
		Else
			RecordInformationOnStatusOfRefundRequest(Message, DocumentObject.Ref, True, True);
		EndIf;
		Return;
	EndTry;
	
	DocumentVerified = DocumentObject.CheckFilling();
	
	WriteMode = ?(Posted And DocumentVerified, DocumentWriteMode.Posting, ?(DocumentObject.Posted,
	DocumentWriteMode.UndoPosting, DocumentWriteMode.Write));
	
	Try
		DocumentObject.DataExchange.Load = False;
		DocumentObject.Write(WriteMode, DocumentPostingMode.Regular);
		If DocumentType = 0 Then
			RecordCustomerOrderStatusInformation(Message, DocumentObject.Ref, True);
		Else
			RecordInformationOnStatusOfRefundRequest(Message, DocumentObject.Ref, True);
		EndIf;
	Except
		If DocumentType = 0 Then
			RecordCustomerOrderStatusInformation(Message, DocumentObject.Ref, True, True);
		Else
			RecordInformationOnStatusOfRefundRequest(Message, DocumentObject.Ref, True, True);
		EndIf;
	EndTry;
EndProcedure

Procedure FillInProductPart(DocumentObject, MobileDataProducts, DocumentType)
	
	If DocumentType = 0 Then
		TabularPartProducts = DocumentObject.Goods;
	ElsIf DocumentType = 1 Then
		TabularPartProducts = DocumentObject.ReturnedGoods;
	EndIf;
	TabularPartProducts.Clear();
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(DocumentObject);
	
	// We perform the necessary operations for refilling/checking for the PM line.
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	
	If DocumentType = 0 Then
		
		StructureOfActions.Insert("FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(
			New Structure("BusinessOperation", DocumentObject.BusinessOperation), False));
		
		DocumentParameters = Documents.SalesOrder.DocumentParametersForSoftwareActions(DocumentObject);
		StringFields_ = "SupplyOption";
		ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
		
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, DocumentObject, DocumentType);
	
	RowsToProcess = New Array;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	For Each RowOfProduct In MobileDataProducts Do
		DocumentLine = TabularPartProducts.Add();
		
		If DocumentType = 0 Then
			DocumentLine.Count = RowOfProduct["Количество"]; //@NON-NLS-1
			DocumentLine.NumberOfPackages = RowOfProduct["КоличествоУпаковок"]; //@NON-NLS-1
			DocumentLine.Canceled = RowOfProduct["Отменено"]; //@NON-NLS-1
			DocumentLine.Price = RowOfProduct["Цена"]; //@NON-NLS-1
			DocumentLine.PercentRateOfManualDiscount = RowOfProduct["ПроцентРучнойСкидки"]; //@NON-NLS-1
			DocumentLine.ManualDiscount = RowOfProduct["СуммаРучнойСкидки"]; //@NON-NLS-1
		ElsIf DocumentType = 1 Then
			DocumentLine.Count = RowOfProduct["Количество"]; //@NON-NLS-1
			DocumentLine.NumberOfPackages = RowOfProduct["КоличествоУпаковок"]; //@NON-NLS-1
			DocumentLine.Canceled = RowOfProduct["Отменено"]; //@NON-NLS-1
			DocumentLine.Price = RowOfProduct["Цена"]; //@NON-NLS-1
		EndIf;
		
		DocumentLine.PriceKind = Catalogs.TypesOfPrices.GetRef(New UUID(RowOfProduct["ВидЦены"])); //@NON-NLS-1
		
		ProductDescriptionPackaging = StructureProductDescriptionPackaging(
			RowOfProduct["Номенклатура"],
			RowOfProduct["Упаковка"]); //@NON-NLS-1 @NON-NLS-2
		DocumentLine.Products = ProductDescriptionPackaging.Products;
		If ValueIsFilled(ProductDescriptionPackaging.Characteristic) Then
			DocumentLine.Characteristic = ProductDescriptionPackaging.Characteristic;
		EndIf;
		If ValueIsFilled(ProductDescriptionPackaging.Package) Then
			DocumentLine.Package = ProductDescriptionPackaging.Package;
			DocumentLine.Price = DocumentLine.Price * ProductDescriptionPackaging.PackageFactor;
		Else
			DocumentLine.NumberOfPackages = DocumentLine.Count;
		EndIf;
		
		If DocumentType = 0 Then
			DocumentLine.DateOfShipment = DocumentObject.DateOfShipment;
			DocumentLine.Warehouse = Catalogs.Warehouses.GetRef(New UUID(RowOfProduct["Склад"])); //@NON-NLS-1
		ElsIf DocumentType = 1 Then
			DocumentLine.DateOfReceipt = DocumentObject.DateOfReceipt;
			DocumentLine.DocumentSalesOfGoodsAndServices = DocumentObject.DocumentSalesOfGoodsAndServices;
		EndIf;
		
		RowsToProcess.Add(DocumentLine);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularPartProducts,
		CachedValues);
	
	OldCurrency = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
	NewCurrency = DocumentObject.Currency;
	
	If Not OldCurrency = NewCurrency Then
		
		DocumentDate               = DocumentObject.Date;
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, LocalAccountingCurrency);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency, DocumentDate, LocalAccountingCurrency);
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			TabularPartProducts,
			DocumentObject.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
		
	EndIf;
	
	If DocumentType = 0 Then
		DocumentsManager = Documents.SalesOrder;
	ElsIf DocumentType = 1 Then
		DocumentsManager = Documents.RequestForReturnOfGoodsFromCustomer;
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(DocumentObject,
		DocumentsManager));
	
	If DocumentType = 0 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	ElsIf DocumentType = 1 Then
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Returned_);
	EndIf;
	
EndProcedure

Procedure FillInDocumentHeader(DocumentObject, MobileData, DocumentType)
	
	DocumentObject.DeletionMark = MobileData.DeletionMark;
	DocumentObject.Comment = MobileData.Комментарий;
	
	DocumentCurrency = Catalogs.Currencies.GetRef(New UUID(MobileData.Валюта));
	DocumentObject.Currency = DocumentCurrency;
	DocumentObject.Partner = Catalogs.Partners.GetRef(New UUID(MobileData.Клиент));
	DocumentObject.Counterparty = Catalogs.Counterparties.GetRef(
		New UUID(MobileData.Контрагент));
	OrganizationOfOrder = Catalogs.Companies.GetRef(
		New UUID(MobileData.Организация));
	DocumentObject.Organization = ?(ValueIsFilled(OrganizationOfOrder), OrganizationOfOrder, DocumentObject.Organization);
	
	OrderWarehouse = Catalogs.Warehouses.GetRef(New UUID(MobileData.Склад));
	DocumentObject.Warehouse = ?(ValueIsFilled(OrderWarehouse), OrderWarehouse, DocumentObject.Warehouse);
	
	If GetFunctionalOption("ToUseTermsOfSales")
		Or GetFunctionalOption("UseCustomerContracts") Then
		
		AgreementContract = StructureOfAgreementAgreement(MobileData.ДоговорКлиента);
		DocumentObject.Contract = AgreementContract.Contract;
		DocumentObject.Terms = AgreementContract.Terms;
		DocumentObject.BusinessOperation = AgreementContract.BusinessOperation;
		
		If ValueIsFilled(DocumentObject.Terms) Then
			DocumentObject.FillInTermsOfSalesUnderAgreement();
		Else
			DocumentObject.FillInDefaultSalesConditions();
			If MobileData.Товары.Count() > 0 Then
				PriceKind = Catalogs.TypesOfPrices.GetRef(New UUID(MobileData.Товары[0].ВидЦены));
				DocumentObject.PriceIncludesVAT = Common.ObjectAttributeValue(PriceKind, "PriceIncludesVAT");
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(DocumentObject.Currency) Then
			DocumentObject.Currency = DocumentCurrency;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(DocumentObject.VATTaxation) Then
		If DocumentType = 0 Then
			FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(DocumentObject);
			VATAccountingERP.FillInSalesVATTaxation(
				DocumentObject.VATTaxation,
				FillParameters);
		ElsIf  DocumentType = 1 Then
			FillParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(DocumentObject);
			VATAccountingERP.FillInSalesVATTaxation(
				DocumentObject.VATTaxation,
				FillParameters);
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(DocumentObject.BusinessOperation) Then
		If DocumentType = 0 Then
			DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		ElsIf DocumentType = 1 Then
			DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
		EndIf;
	EndIf;
	
	DocumentObject.Priority = SettingsValueCached.GetDefaultPriority(DocumentObject.Priority);
	
	DocumentObject.ARAPObjectSettings = ARAPAccountingServer.ARAPObjectSettings(True,,DocumentObject.Terms, DocumentObject.Contract);
	
	If DocumentObject.ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments Then
		DocumentObject.PaymentID = TMCommonUse.GetUniquePaymentID(DocumentObject);
	Else
		DocumentObject.PaymentID = Undefined;
	EndIf;
	
	If GetFunctionalOption("UseDiscountsMarkupsInSales") Then
		DocumentObject.DiscountsAreCalculated = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Function BankAccountFromLastOrder(Organization)
	
	Query = New Query("SELECT ALLOWED TOP 1
	|	SalesOrder.BankAccount AS BankAccount
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.Posted
	|	AND SalesOrder.Organization = &Organization
	|
	|ORDER BY
	|	SalesOrder.Date DESC");
	
	Query.SetParameter("Organization", Organization);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.BankAccount;
EndFunction

Function AbilityToAddPartnerChanges()
	
	ConstantsSet = Constants.CreateSet("UseTermsOfSales, UseCustomerContracts");
	ConstantsSet.Read();
	AbilityToAddPartnerChanges = AccessRight("Insert", Metadata.Catalogs.Partners);
	AbilityToAddContractChanges = AccessRight("Insert", Metadata.Catalogs.CounterpartyContracts);
	AbilityToAddChangeAgreements = AccessRight("Insert", Metadata.Catalogs.TermsOfSale);
		
	If ValueIsFilled(ConstantsSet.UseTermsOfSales) And Not ConstantsSet.UseTermsOfSales =
		Enums.UseTermsOfSales.DontUse Then
			AbilityToAddPartnerChanges = AbilityToAddPartnerChanges
				And AbilityToAddChangeAgreements;
	EndIf;
	If ConstantsSet.UseCustomerContracts Then
		AbilityToAddPartnerChanges = AbilityToAddPartnerChanges
			And AbilityToAddContractChanges;
	EndIf;
		
	Return AbilityToAddPartnerChanges;
EndFunction

Procedure UploadClientContactPersons(XMLWriter, Client, DataDeletion)
	
	Query = New Query;
	Query.Text = MobileApplicationSalesOrders.RequestTextOfClientSContactPersons();
	Query.SetParameter("Partner", Client);
	Query.SetParameter("OwnerCode", TrimAll(Client.UUID()));
	Result = Query.Execute().Unload();
	For Each DataString1 In Result Do
		Data = DataString1.ContactPerson.GetObject();
		If DataDeletion Then
			MobileApplicationSalesOrders.DataDeletion(Data);
			If ValueIsFilled(DataString1.ContactPerson) And Data = Undefined Then
				Data = New ObjectDeletion(DataString1.ContactPerson);
			EndIf;
		EndIf;
		If TypeOf(Data) = Type("ObjectDeletion") Then
			XDTOSerializer.WriteXML(XMLWriter, Data);
			Continue;
		EndIf;
		ContactPersonStructure = MobileApplicationSalesOrders.ContactPersonStructure();
		FillPropertyValues(ContactPersonStructure, DataString1);
		ContactPersonStructure.ref = TrimAll(DataString1.ContactPerson.UUID());
		ContactPersonStructure["ERPКод"] = ContactPersonStructure.ref; //@NON-NLS-1
		
		LocalObjectName = "CatalogTabularSectionRow.КонтактныеЛицаПартнеров.КонтактнаяИнформация"; //@NON-NLS-1
		WriteContactInformation(ContactPersonStructure, DataString1.ContactPerson, 
			"Catalog.ContactPersonsForPartners.ContactInformation",
			LocalObjectName);
		
		LocalObjectName = "CatalogObject.КонтактныеЛицаКлиентов"; //@NON-NLS-1
		WriteCatalog(XMLWriter, ContactPersonStructure, LocalObjectName);
	EndDo;
EndProcedure

Procedure UnloadingObjectsOfReferenceType(XMLWriter, ExportedObjects, PriceListLine, ExchangeNode)
	
	BlankID = BlankID();
	
	// Let's write down the type of price of the uploaded price line.
	If ValueIsFilled(PriceListLine.PriceTypeReference)
		And ExportedObjects.Get(PriceListLine.PriceTypeReference) = Undefined Then
		RecordPriceTypeOfLine(XMLWriter, PriceListLine);
		ExportedObjects.Insert(PriceListLine.PriceTypeReference, PriceListLine.PriceTypeReference);
	EndIf;
	
	// Let's write down the parent of the item of the uploaded price line.
	If ValueIsFilled(PriceListLine.ParentProduct)
		And ExportedObjects.Get(PriceListLine.ParentProduct) = Undefined Then
		
		StructureOfParentProduct = MobileApplicationSalesOrders.StructureOfParentProduct();
		
		StructureOfParentProduct.Ref = TrimAll(PriceListLine.ParentProduct.UUID());
		StructureOfParentProduct.DeletionMark = PriceListLine.ParentProductDeletionMark;
		StructureOfParentProduct.Description = TrimAll(PriceListLine.ParentProduct);
		StructureOfParentProduct.IsFolder = True;
		StructureOfParentProduct.Code = PriceListLine.ProductParentCode;
		StructureOfParentProduct["ERPКодНоменклатура"] = StructureOfParentProduct.Ref; //@NON-NLS-1
		StructureOfParentProduct["СтрокаПоиска"] = TrimAll(StructureOfParentProduct.Code)
			+TrimAll(StructureOfParentProduct.Description); //@NON-NLS-1
		
		LocalObjectName = "CatalogObject.Номенклатура"; //@NON-NLS-1
		If Not ValueIsFilled(PriceListLine.ParentParentProduct) Then
			StructureOfParentProduct.Parent = BlankID;
			WriteCatalog(XMLWriter, StructureOfParentProduct, LocalObjectName);
		Else
			StructureOfParentProduct.Parent = 
				TrimAll(PriceListLine.ParentParentProduct.UUID());
			WriteCatalog(XMLWriter, StructureOfParentProduct, LocalObjectName);
			Parent = PriceListLine.ParentParentProduct;
			While ValueIsFilled(Parent) Do
				If ExportedObjects.Get(Parent) = Undefined Then
					WriteParentOfProductItem(XMLWriter, Parent);
					ExportedObjects.Insert(Parent, Parent);
				EndIf;
				Parent = Parent.Parent;
			EndDo;
		EndIf;
		ExportedObjects.Insert(PriceListLine.ParentProduct, PriceListLine.ParentProduct);
	EndIf;
	
	// Let's write down the type of nomenclature of the unloaded price line.
	If ValueIsFilled(PriceListLine.ProductsTypeOfProducts_)
			And ExportedObjects.Get(PriceListLine.ProductsTypeOfProducts_) = Undefined Then
		StructureOfProductType				= MobileApplicationSalesOrders.StructureOfProductType();
		StructureOfProductType.Ref			= TrimAll(PriceListLine.ProductsTypeOfProducts_.UUID());
		StructureOfProductType.DeletionMark	= PriceListLine.ProductsTypeOfProducts_DeletionMark;
		StructureOfProductType.Description	= TrimAll(PriceListLine.ProductsTypeOfProducts_);
		StructureOfProductType.IsFolder		= False;
		StructureOfProductType["ERPКод"]		= StructureOfProductType.Ref; //@NON-NLS-1
		
		LocalObjectName = "CatalogObject.ВидыНоменклатуры"; //@NON-NLS-1
		If Not ValueIsFilled(PriceListLine.ProductsTypeOfProductsParent) Then
			StructureOfProductType.Parent = BlankID;
			WriteCatalog(XMLWriter, StructureOfProductType, LocalObjectName);
		Else
			StructureOfProductType.Parent = 
				TrimAll(PriceListLine.ProductsTypeOfProductsParent.UUID());
			WriteCatalog(XMLWriter, StructureOfProductType, LocalObjectName);
			Parent = PriceListLine.ProductsTypeOfProductsParent;
			While ValueIsFilled(Parent) Do
				If ExportedObjects.Get(Parent) = Undefined Then
					WriteDownTypeOfProductItem(XMLWriter, Parent);
					ExportedObjects.Insert(Parent, Parent);
					Parent = Parent.Parent;
				Else
					Break;
				EndIf;
			EndDo;
		EndIf;
		ExportedObjects.Insert(PriceListLine.ProductsTypeOfProducts_,
			PriceListLine.ProductsTypeOfProducts_);
	EndIf;
	
	// Let's write down the price group of the item of the uploaded price line.
	If ValueIsFilled(PriceListLine.ProductsPriceGroup)
			And ExportedObjects.Get(PriceListLine.ProductsPriceGroup) = Undefined Then
		StructurePriceGroup				= MobileApplicationSalesOrders.PriceGroupStructure();
		StructurePriceGroup.Ref			= TrimAll(PriceListLine.ProductsPriceGroup.UUID());
		StructurePriceGroup.DeletionMark	= PriceListLine.ProductsPriceGroupDeletionMark;
		StructurePriceGroup.Description	= TrimAll(PriceListLine.ProductsPriceGroup);
		StructurePriceGroup["Описание"]		= PriceListLine.ProductsPriceGroupDescription; //@NON-NLS-1
		
		LocalObjectName = "CatalogObject.ЦеновыеГруппы"; //@NON-NLS-1
		WriteCatalog(XMLWriter, StructurePriceGroup, LocalObjectName);
		
		ExportedObjects.Insert(PriceListLine.ProductsPriceGroup, PriceListLine.ProductsPriceGroup);
	EndIf;
	
	// Let's write down the unit of measurement of the nomenclature of the uploaded price line.
	If ValueIsFilled(PriceListLine.ProductsUnitOfMeasure)
			And ExportedObjects.Get(PriceListLine.ProductsUnitOfMeasure) = Undefined Then
		UnitStructure = MobileApplicationSalesOrders.UnitStructure();
		UnitStructure.Ref = TrimAll(PriceListLine.ProductsUnitOfMeasure.UUID());
		UnitStructure.DeletionMark = PriceListLine.ProductsUnitOfMeasureDeletionMark;
		UnitStructure.Description = TrimAll(PriceListLine.ProductsUnitOfMeasure);
		UnitStructure.Code = PriceListLine.ProductsUnitOfMeasurementCode;
		UnitStructure.PredefinedDataName = "";
		UnitStructure["МеждународноеСокращение"] =
			PriceListLine.ProductUnitOfMeasurementInternationalAbbreviation;  //@NON-NLS-1
		UnitStructure["НаименованиеПолное"] =
			PriceListLine.ProductsUnitOfMeasurementFullName;  //@NON-NLS-1
		
		LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
		WriteCatalog(XMLWriter, UnitStructure, LocalObjectName);
		
		ExportedObjects.Insert(PriceListLine.ProductsUnitOfMeasure,
		PriceListLine.ProductsUnitOfMeasure);
	EndIf;
	
	// Let's write down the packaging of the uploaded price list line.
	If ValueIsFilled(PriceListLine.PackagingRef)
		And ExportedObjects.Get(PriceListLine.Package) = Undefined Then
		PackingStructure		= MobileApplicationSalesOrders.PackingStructure();
		PackingStructure.Ref	= PriceListLine.Package;
		PackingStructure.Owner = PriceListLine.Products;
		PackingStructure.Description	= TrimAll(PriceListLine.PackagingRef);
		
		PackingStructure.DeletionMark = PriceListLine.ProductPackagesDeletionMark;
		PackingStructure["ERPКод"] = TrimAll(PriceListLine.PackagingRef.UUID()); //@NON-NLS-1
		PackingStructure["Коэффициент"] = PriceListLine.PackagingNomenclatureCoefficient; //@NON-NLS-1
		PackingStructure["НаименованиеПолное"] = PriceListLine.PackagingProductsName; //@NON-NLS-1
		
		If Not ValueIsFilled(PriceListLine.PackagingProductsParent) Then
			PackingStructure.Parent = BlankID;
		Else
			PackingRecordStructure = New Structure;
			PackingRecordStructure.Insert("PackagingRef", PriceListLine.PackagingProductsParent);
			PackingRecordStructure.Insert("ProductsID", PriceListLine.ProductsID);
			PackingRecordStructure.Insert("VariantID", PriceListLine.VariantID);
			PackingRecordStructure.Insert("MPProducts", PriceListLine.Products);
			PackingRecordStructure.Insert("Products", PriceListLine.ProductsLink);
			PackingRecordStructure.Insert("CharacteristicReference", PriceListLine.CharacteristicReference);
			
			PackingStructure.Parent = IDOfMPPackage(XMLWriter, ExportedObjects, PackingRecordStructure);
		EndIf;
		
		If ValueIsFilled(PriceListLine.PackagingProductsUnitOfMeasurement) Then
			PackingStructure["ЕдиницаИзмерения"] =
			TrimAll(PriceListLine.PackagingProductsUnitOfMeasurement.UUID());  //@NON-NLS-1
			If ExportedObjects.Get(PriceListLine.PackagingProductsUnitOfMeasurement) = Undefined Then
				
				UnitStructure = MobileApplicationSalesOrders.UnitStructure();
				UnitStructure.Ref = 
				TrimAll(PriceListLine.PackagingProductsUnitOfMeasurement.UUID());
				UnitStructure.DeletionMark = PriceListLine.PackagingProductsUnitOfMeasurementDeletionMark;
				UnitStructure.Description = TrimAll(PriceListLine.PackagingProductsUnitOfMeasurement);
				UnitStructure.Code = PriceListLine.PackagingProductsUnitCode;
				UnitStructure.PredefinedDataName = 
				PriceListLine.PackagingProductsUnitOfMeasurementNameOfPredefinedData;
				UnitStructure["МеждународноеСокращение"] = 
				PriceListLine.PackagingProductsUnitOfMeasureInternationalAbbreviation; //@NON-NLS-1
				UnitStructure["НаименованиеПолное"] =
				PriceListLine.PackagingProductsUnitOfMeasurementFullName; //@NON-NLS-1
				
				LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
				WriteCatalog(XMLWriter, UnitStructure, LocalObjectName);
				
				ExportedObjects.Insert(PriceListLine.PackagingProductsUnitOfMeasurement,
				PriceListLine.PackagingProductsUnitOfMeasurement);
			EndIf;
		Else
			PackingStructure["ЕдиницаИзмерения"] = TrimAll(PriceListLine.PackagingRef.UUID()); //@NON-NLS-1
		EndIf;
		
		If ValueIsFilled(PriceListLine.PackagingProductsWeightUnit) 
			And PriceListLine.UseWeight Then
			
			PackingStructure["Вес"] = PriceListLine.PackagingProductsWeight; //@NON-NLS-1
			PackingStructure["ВесЕдиницаИзмерения"] =
				TrimAll(PriceListLine.PackagingProductsWeightUnit.UUID());  //@NON-NLS-1
			If ExportedObjects.Get(PriceListLine.PackagingProductsWeightUnit) = Undefined Then
				
				UnitStructure = MobileApplicationSalesOrders.UnitStructure();
				UnitStructure.Ref = 
				TrimAll(PriceListLine.PackagingProductsWeightUnit.UUID());
				UnitStructure.DeletionMark = PriceListLine.PackagingProductsWeightUnitDeletionMark;
				UnitStructure.Description = TrimAll(PriceListLine.PackagingProductsWeightUnit);
				UnitStructure.Code = PriceListLine.PackagingProductsWeightUnitCode;
				UnitStructure.PredefinedDataName = 
				PriceListLine.PackagingProductsWeightUnitPredefinedDataName;
				UnitStructure["МеждународноеСокращение"] =
				PriceListLine.PackagingProductsWeightUnitOfMeasurementInternationalAbbreviation; //@NON-NLS-1
				UnitStructure["НаименованиеПолное"] =
				PriceListLine.PackagingProductsWeightUnitOfMeasurementFullName; //@NON-NLS-1
				
				LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
				WriteCatalog(XMLWriter, UnitStructure, LocalObjectName);
				
				ExportedObjects.Insert(PriceListLine.PackagingProductsWeightUnit,
				PriceListLine.PackagingProductsWeightUnit);
			EndIf;
		Else
			PackingStructure["ВесЕдиницаИзмерения"] = BlankID; //@NON-NLS-1
			PackingStructure["Вес"] = 0; //@NON-NLS-1
		EndIf;
		
		PackingStructure["Штрихкод"] = ItemsBarcode(PriceListLine.ProductsLink,
			PriceListLine.CharacteristicReference, PriceListLine.PackagingRef); //@NON-NLS-1
		
		LocalObjectName = "CatalogObject.УпаковкиНоменклатуры"; //@NON-NLS-1
		WriteCatalog(XMLWriter, PackingStructure, LocalObjectName);
		
		// Let's write down the hierarchy of packages of the package of the unloaded price line,
		// if packages for the nomenclature are used.
		PackingRecordStructure = New Structure;
		PackingRecordStructure.Insert("PackagingRef", PriceListLine.PackagingRef);
		PackingRecordStructure.Insert("ProductsID", PriceListLine.ProductsID);
		PackingRecordStructure.Insert("VariantID", PriceListLine.VariantID);
		PackingRecordStructure.Insert("MPProducts", PriceListLine.Products);
		PackingRecordStructure.Insert("Products", PriceListLine.ProductsLink);
		PackingRecordStructure.Insert("CharacteristicReference", PriceListLine.CharacteristicReference);
		PackingRecordStructure.Insert("ItemVariantsAreUsed", PriceListLine.ItemVariantsAreUsed);
		
		WritePackingHierarchy(XMLWriter, ExportedObjects, PackingRecordStructure);
		
		ExportedObjects.Insert(PriceListLine.Package, PriceListLine.Package);
	EndIf;
	
	// Let's write down the nomenclature of the uploaded price list line.
	If ValueIsFilled(PriceListLine.Products) And (PriceListLine.GoodsShipmentIsRequired)
			And ExportedObjects.Get(PriceListLine.Products) = Undefined Then
		
		NameOfMPProducts = TrimAll(PriceListLine.ProductsLink)
									+ ?(PriceListLine.ItemVariantsAreUsed,
									" (" + TrimAll(PriceListLine.CharacteristicReference) + ")", "");
		
		FullNameOfMPProducts = TrimAll(PriceListLine.ProductFullName)
									+ ?(PriceListLine.ItemVariantsAreUsed,
									" (" + TrimAll(PriceListLine.CharacteristicFullName) + ")", "");
		
		ProductStructure_ = MobileApplicationSalesOrders.ProductStructure_();
		
		ProductStructure_.Ref			= PriceListLine.Products;
		ProductStructure_.DeletionMark	= PriceListLine.ProductsDeletionMark;
		ProductStructure_.Description	= NameOfMPProducts;
		
		ProductStructure_.IsFolder	= False;
		ProductStructure_.Parent	= TrimAll(PriceListLine.ParentProduct.UUID());
		ProductStructure_.Code		= PriceListLine.ProductsCode;
		
		ProductStructure_["ERPКодНоменклатура"]	= PriceListLine.ProductsID; //@NON-NLS-1
		ProductStructure_["ERPКодХарактеристика"]	= PriceListLine.VariantID; //@NON-NLS-1
		ProductStructure_["Артикул"]				= PriceListLine.ProductsSKU; //@NON-NLS-1
		ProductStructure_["ВидНоменклатуры"]		=
			TrimAll(PriceListLine.ProductsTypeOfProducts_.UUID()); //@NON-NLS-1
		ProductStructure_["ЕдиницаИзмерения"]		=
			TrimAll(PriceListLine.ProductsUnitOfMeasure.UUID()); //@NON-NLS-1
		ProductStructure_["НаименованиеПолное"]	= FullNameOfMPProducts; //@NON-NLS-1
		
		ProductStructure_["СтавкаНДСЧислом"]		=
			PriceManagementSystemClientServer.GetVATRateAsNumber(PriceListLine.VATRateLink)/100; //@NON-NLS-1
		
		ProductStructure_["Услуга"]				= PriceListLine.OperationService; //@NON-NLS-1
		ProductStructure_["ЦеноваяГруппа"]			= TrimAll(PriceListLine.ProductsPriceGroup.UUID()); //@NON-NLS-1
		ProductStructure_["СтрокаПоиска"]			= TrimAll(ProductStructure_.Code)
			+ TrimAll(ProductStructure_.Description) + TrimAll(ProductStructure_["Артикул"]); //@NON-NLS-1 @NON-NLS-2
		ProductStructure_["Описание"]				= PriceListLine.ProductItemDescription; //@NON-NLS-1
			
		// Let's write down the unit of measurement of the item of the unloaded price line as a package,
		// if Tasks are used and Tasks are detailed by nomenclature.
		ProductUnitOfMeasurementSuchAsPackaging = BlankID;
		If ValueIsFilled(PriceListLine.ProductsUnitOfMeasure)
			And PriceListLine.UnloadingUnitOfMeasureAsPacking Then
			
			PackingRecordStructure = New Structure;
			PackingRecordStructure.Insert("PackagingRef", PriceListLine.ProductsUnitOfMeasure);
			PackingRecordStructure.Insert("ProductsID", PriceListLine.ProductsID);
			PackingRecordStructure.Insert("VariantID", PriceListLine.VariantID);
			PackingRecordStructure.Insert("MPProducts", PriceListLine.Products);
			PackingRecordStructure.Insert("Products", PriceListLine.ProductsLink);
			PackingRecordStructure.Insert("CharacteristicReference", PriceListLine.CharacteristicReference);
			PackingRecordStructure.Insert("ItIsUnitOfWeight", False);
			ProductUnitOfMeasurementSuchAsPackaging = 
				IDOfMPPackage(XMLWriter, ExportedObjects, PackingRecordStructure);
			ExportedObjects.Insert(ProductUnitOfMeasurementSuchAsPackaging, ProductUnitOfMeasurementSuchAsPackaging);
		EndIf;
		
		ProductStructure_["ЕдиницаЗаказа"] = ?(ValueIsFilled(PriceListLine.Package), PriceListLine.Package,
			ProductUnitOfMeasurementSuchAsPackaging); //@NON-NLS-1
			
		ProductStructure_["Штрихкод"] = ItemsBarcode(PriceListLine.ProductsLink,
			PriceListLine.CharacteristicReference, ProductStructure_["ЕдиницаЗаказа"]); //@NON-NLS-1 @NON-NLS-2
		
		// Let's write down the unit of measurement of the weight of the item of the unloaded price line.
		// She can also participate in the selection in the order.
		If ValueIsFilled(PriceListLine.WeightPackingLink)
			And PriceListLine.UseWeight Then
			
			PackingRecordStructure = New Structure;
			PackingRecordStructure.Insert("PackagingRef", PriceListLine.WeightPackingLink);
			PackingRecordStructure.Insert("ProductsID", PriceListLine.ProductsID);
			PackingRecordStructure.Insert("VariantID", PriceListLine.VariantID);
			PackingRecordStructure.Insert("MPProducts", PriceListLine.Products);
			PackingRecordStructure.Insert("Products", PriceListLine.ProductsLink);
			PackingRecordStructure.Insert("CharacteristicReference", PriceListLine.CharacteristicReference);
			PackingRecordStructure.Insert("ItIsUnitOfWeight", True);
			ProductStructure_["ВесЕдиницаИзмерения"] =
				IDOfMPPackage(XMLWriter, ExportedObjects, PackingRecordStructure); //@NON-NLS-1 
			ProductStructure_["ВесЗнаменатель"] = PriceListLine.WeightDenominator; //@NON-NLS-1
			ProductStructure_["ВесИспользовать"] = PriceListLine.WeightUse; //@NON-NLS-1
			ProductStructure_["ВесМожноУказыватьВДокументах"] = PriceListLine.YouCanSpecifyWeightInDocuments; //@NON-NLS-1
			ProductStructure_["ВесЧислитель"] = PriceListLine.WeightNumerator; //@NON-NLS-1
			ExportedObjects.Insert(ProductStructure_["ВесЕдиницаИзмерения"], ProductStructure_["ВесЕдиницаИзмерения"]); //@NON-NLS-1 @NON-NLS-2
		Else
			ProductStructure_["ВесЕдиницаИзмерения"] = BlankID; //@NON-NLS-1
			ProductStructure_["ВесЗнаменатель"] = 1; //@NON-NLS-1
			ProductStructure_["ВесИспользовать"] = False; //@NON-NLS-1
			ProductStructure_["ВесМожноУказыватьВДокументах"] = False; //@NON-NLS-1
			ProductStructure_["ВесЧислитель"] = 0; //@NON-NLS-1
		EndIf;
		
		// Let's write down a picture of the nomenclature of the uploaded price line.
		If ValueIsFilled(PriceListLine.ImageFileLink) Then
			ProductStructure_["ФайлКартинки"] =
				IDOfImageFile(XMLWriter, ExportedObjects, PriceListLine, ExchangeNode); //@NON-NLS-1 
		Else
			ProductStructure_["ФайлКартинки"] = BlankID; //@NON-NLS-1
		EndIf;
		
		LocalObjectName = "CatalogTabularSectionRow.Номенклатура.ДополнительныеРеквизиты"; //@NON-NLS-1
		RecordAdditionalDetails(ProductStructure_, PriceListLine.ProductsLink, 
			"Catalog.Products.AdditionalAttributes",
			LocalObjectName);
		
		LocalObjectName = "CatalogObject.Номенклатура"; //@NON-NLS-1
		WriteCatalog(XMLWriter, ProductStructure_, LocalObjectName);
		ExportedObjects.Insert(PriceListLine.Products, NameOfMPProducts);
		ExchangePlans.DeleteChangeRecords(ExchangeNode, PriceListLine.ProductsLink);
	EndIf;
EndProcedure

Function PartnerAccessGroup()
	
	Query = New Query("SELECT ALLOWED TOP 1
	|	Partners.Ref,
	|	Partners.AccessGroup
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	NOT Partners.DeletionMark
	|	AND NOT Partners.AccessGroup = VALUE(Catalog.PartnerAccessGroups.EmptyRef)");
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Catalogs.PartnerAccessGroups.EmptyRef();
	EndIf;
	Selection = Result.Select();
	Selection.Next();
	Return Selection.AccessGroup;
EndFunction

Function GroupOfWarehousesToChooseFromOrder(WarehouseID_1, WarehouseParent, ToExport)
	
	WarehousesGroupOfToChooseFrom = New Structure("ParentID, GroupID, WarehousesData",,, New Array);
	VHFWarehouses = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");
	BlankID = BlankID();
	
	Query = New Query("SELECT ALLOWED
	|	Warehouses.Ref AS WarehouseReference,
	|	Warehouses.IsFolder AS IsFolder,
	|	Warehouses.DeletionMark AS DeletionMark,
	|	Warehouses.Description AS Description,
	|	Warehouses.Parent AS WarehouseParent,
	|	Warehouses.SelectGroup
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref = &Warehouse
	|TOTALS BY
	|	WarehouseReference ONLY HIERARCHY");
	Query.SetParameter("Warehouse", WarehouseParent);
	WarehouseHierarchy = Query.Execute().Unload();
	If WarehouseHierarchy.Count() = 0 Then
		WarehousesGroupOfToChooseFrom.ParentID = BlankID;
		WarehousesGroupOfToChooseFrom.GroupID = WarehouseID_1;
		Return WarehousesGroupOfToChooseFrom;
	EndIf;
	
	WarehousesForUnloading = New Array ;
	GroupOfWarehouses = PredefinedValue("Catalog.Warehouses.EmptyRef");
	For Each String In WarehouseHierarchy Do
		If Not ValueIsFilled(String.WarehouseReference) Then
			Continue;
		EndIf;
		If VHFWarehouses Then
			If Not ValueIsFilled(GroupOfWarehouses)
				And Not String.SelectGroup = PredefinedValue("Enum.SelectWarehouseGroup.Disable") Then
				GroupOfWarehouses = String.WarehouseReference;
			EndIf;
			If ValueIsFilled(GroupOfWarehouses)
				And String.SelectGroup = PredefinedValue("Enum.SelectWarehouseGroup.Disable") Then
				GroupOfWarehouses = PredefinedValue("Catalog.Warehouses.EmptyRef");
			EndIf;
		EndIf;
		If String.WarehouseReference = WarehouseParent Then
			If Not ValueIsFilled(String.WarehouseParent) Then
				WarehousesGroupOfToChooseFrom.ParentID = BlankID;
			Else
				WarehousesGroupOfToChooseFrom.ParentID = TrimAll(String.WarehouseParent.UUID());
			EndIf;
		EndIf;
		If ToExport And (Not String.WarehouseReference = WarehouseParent) Then
			WarehouseStructure = MobileApplicationSalesOrders.WarehouseStructure(True);
			FillPropertyValues(WarehouseStructure, String);
			WarehouseStructure.ref = TrimAll(String.WarehouseReference.UUID());
			WarehouseStructure["ERPКод"] = WarehouseStructure.ref; //@NON-NLS-1
			If Not ValueIsFilled(String.WarehouseParent) Then
				WarehouseStructure.Parent = BlankID;
			Else
				WarehouseStructure.Parent = TrimAll(String.WarehouseParent.UUID());
			EndIf;
			WarehousesForUnloading.Add(WarehouseStructure);
		EndIf;
	EndDo;
	WarehousesGroupOfToChooseFrom.WarehousesData = WarehousesForUnloading;
	
	If VHFWarehouses Then
		If Not ValueIsFilled(GroupOfWarehouses) Then
			WarehousesGroupOfToChooseFrom.GroupID = WarehouseID_1;
		Else
			WarehousesGroupOfToChooseFrom.GroupID = TrimAll(GroupOfWarehouses.UUID());
		EndIf;
	Else
		WarehousesGroupOfToChooseFrom.GroupID = WarehouseID_1;
	EndIf;
	
	Return WarehousesGroupOfToChooseFrom;
EndFunction

Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object, DocumentType)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	If DocumentType = 0 Then
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	EndIf;
EndProcedure

Procedure AddTaskToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
EndProcedure

Function PartnerProfile(Val Partner, UploadCompleteDossier)
	
	InformationOnPartner = New Structure("Досье, КонтактныеТелефоны"); //@NON-NLS-1
	Report = Reports.PartnerProfile.Create();
	Report.Contacts = True;
	Report.ClientData = UploadCompleteDossier;
	Report.VendorData = False;
	SpreadsheetDocument = New SpreadsheetDocument;
	Report.GenerateReport(SpreadsheetDocument, Partner);
	
	InformationOnPartner["Досье"] = SpreadsheetDocument; //@NON-NLS-1
	
	ContactList = New ValueList;
	InformationOnPartner["КонтактныеТелефоны"] = ContactList; //@NON-NLS-1
	
	Return New ValueStorage(InformationOnPartner, New Deflation(9));
EndFunction

Procedure WriteDownTypeOfProductItem(XMLWriter, ProductKind)
	
	StructureOfProductType = MobileApplicationSalesOrders.StructureOfProductType();
	
	RequestStringForBankingDetails = "IsFolder, DeletionMark, Description, Parent";
	ObjectAttributes = Common.ObjectAttributesValues(ProductKind, RequestStringForBankingDetails);
	
	FillPropertyValues(StructureOfProductType, ObjectAttributes);
	StructureOfProductType.Ref = TrimAll(ProductKind.UUID());
	StructureOfProductType.Parent = BlankID();
	
	If ValueIsFilled(ObjectAttributes.Parent) Then
		StructureOfProductType.Parent = TrimAll(ObjectAttributes.Parent.UUID());
	EndIf;
	
	StructureOfProductType["ERPКод"] = StructureOfProductType.Ref; //@NON-NLS-1
	
	LocalObjectName = "CatalogObject.ВидыНоменклатуры"; //@NON-NLS-1
	WriteCatalog(XMLWriter, StructureOfProductType, LocalObjectName);
	
EndProcedure

Procedure RecordAvailablePartnerSegments(Partner, ArrayOfSegments)
	
	SetPrivilegedMode(True);
	
	For Each Segment In ArrayOfSegments Do
		
		SegmentPartners = InformationRegisters.SegmentPartners.CreateRecordManager();
		SegmentPartners.Partner = Partner;
		SegmentPartners.Segment = Segment;
		SegmentPartners.Write(True);
	EndDo;
	
	SetPrivilegedMode(False);
EndProcedure

Procedure WriteTaskToExchangePackage(XMLWriter, Data, UseAgreementsAndContracts)
	
	NameUris = MobileApplicationSalesOrders.NamespaceURI();
	
	ObjectType = XDTOFactory.Type(NameUris, "DocumentObject.ЗаданиеТорговомуПредставителю");
	ItemTypeProducts = XDTOFactory.Type(NameUris, "DocumentTabularSectionRow.ЗаданиеТорговомуПредставителю.Товары");
	TaskObjectType = XDTOFactory.Type(NameUris, "DocumentTabularSectionRow.ЗаданиеТорговомуПредставителю.Задачи");
	ItemTypeOrderDebts = XDTOFactory.Type(NameUris,
		"DocumentTabularSectionRow.ЗаданиеТорговомуПредставителю.ДолгиПоЗаказам");
	ItemTypeDecryption = XDTOFactory.Type(NameUris,
		"DocumentTabularSectionRow.ЗаданиеТорговомуПредставителю.РасшифровкаДебиторскойЗадолженности");
		
	Serializer = New XDTOSerializer(XDTOFactory);
	
	MobileTask = XDTOFactory.Create(ObjectType);
	
	MobileTask.Ref = Serializer.XMLString(Data.Ref);
	MobileTask.DeletionMark = Data.DeletionMark;
	MobileTask.Date = Data.Date;
	MobileTask.Number = Data.Number;
	MobileTask.Posted = Data.Posted;
	MobileTask.Валюта = Serializer.XMLString(Data.Currency);
	MobileTask.ВремяНачала = Data.BeginTime;
	MobileTask.ВремяОкончания = Data.EndTime;
	MobileTask.ДатаВизитаПлан = Data.PlannedVisitDate;
	MobileTask.ДатаВизитаФакт = Data.ActualVisitDate;
	MobileTask.ДетализацияПоНоменклатуре = Data.ItemsDetails;
	MobileTask.ДоговорКлиента = Serializer.XMLString(Data.Contract);
	MobileTask.ЖелаемаяДатаОтгрузки = Data.RequestShipmentOn;
	MobileTask.Клиент = Serializer.XMLString(Data.Partner);
	MobileTask.Комментарий = Data.Comment;
	MobileTask.Контрагент = Serializer.XMLString(Data.Counterparty);
	MobileTask.Организация = Serializer.XMLString(Data.Organization);
	MobileTask.Склад = Serializer.XMLString(Data.Warehouse);
	MobileTask.Статус = MobileApplicationSalesOrdersCached.MatchingTaskStatusesToSalesRepresentatives().Get(Data.Status);
	MobileTask.СуммаПлан = Data.SumPlan;
	
	If UseAgreementsAndContracts Then
		
		PriceKind = Common.ObjectAttributeValue(Data.Terms, "PricesKind");
		
		ThereIsContract = ValueIsFilled(Data.Contract);
		StructureAndTermsOfSales = New Structure;
		StructureAndTermsOfSales.Insert("Organization", Data.Organization);
		StructureAndTermsOfSales.Insert("PriceKind", PriceKind);
		StructureAndTermsOfSales.Insert("Partner", Data.Partner);
		StructureAndTermsOfSales.Insert("Terms", Data.Terms);
		StructureAndTermsOfSales.Insert("Counterparty", Data.Counterparty);
		StructureAndTermsOfSales.Insert("Contract", ?(ThereIsContract, Data.Contract,
			Catalogs.CounterpartyContracts.EmptyRef()));
		MobileTask.ДоговорКлиента = IDOfSalesCondition(StructureAndTermsOfSales);
	Else
		MobileTask.ДоговорКлиента = BlankID();
	EndIf;
	
	// PM data "Goods".
	If Data.Goods.Count() > 0 Then
		For Each TSRow In Data.Goods Do
			MobileTaskProducts = XDTOFactory.Create(ItemTypeProducts);
			MobileTaskProducts.Количество = TSRow.Count;
			MobileTaskProducts.КоличествоУпаковок = TSRow.NumberOfPackages;
			MobileTaskProducts.КоличествоПлан = TSRow.CountPlan;
			MobileTaskProducts.КоличествоУпаковокПлан = TSRow.NumberOfPackagesPlan;
			MobileTaskProducts.Номенклатура = Serializer.XMLString(TSRow.Products);
			MobileTaskProducts.ПроцентРучнойСкидки = TSRow.PercentRateOfManualDiscount;
			MobileTaskProducts.Сумма = TSRow.Sum;
			MobileTaskProducts.СуммаРучнойСкидки = TSRow.ManualDiscount;
			MobileTaskProducts.СуммаНДС = TSRow.VATAmount;
			MobileTaskProducts.Упаковка = Serializer.XMLString(TSRow.Package);
			MobileTaskProducts.Цена = TSRow.Price;
			MobileTaskProducts.ВидЦены = Serializer.XMLString(TSRow.PriceKind);
			MobileTaskProducts.СуммаСНДС = TSRow.AmountIncludingVAT;

			RefSearchStructure = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			TSRow.Products, TSRow.Characteristic, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			If RefSearchStructure.ItemVariantsAreUsed
				And Not ValueIsFilled(RefSearchStructure.Characteristic) Then
				Continue;
			EndIf;
			ProductsIdentifier = TrimAll(TSRow.Products.UUID());
			ItemVariantID = ?(ValueIsFilled(TSRow.Characteristic),
			TrimAll(TSRow.Characteristic.UUID()), "");
			If RefSearchStructure.ItemVariantsAreUsed Then
				MobileTaskProducts.Номенклатура = IDOfMPObject(ProductsIdentifier,
					ItemVariantID, "");
			Else
				MobileTaskProducts.Номенклатура = ProductsIdentifier;
			EndIf;
			If ValueIsFilled(TSRow.Package) Then
				PackagingsID = Serializer.XMLString(TSRow.Package);
				If TypeOf(Common.ObjectAttributeValue(TSRow.Package, "Owner")) = Type("CatalogRef.Products") 
					And Not RefSearchStructure.ItemVariantsAreUsed Then
					PackagingConformity = PackagingsID;
				Else
					PackagingConformity = IDOfMPObject(ProductsIdentifier, ItemVariantID, PackagingsID);
				EndIf;
			Else
				PackagingsID =
					Serializer.XMLString(Common.ObjectAttributeValue(TSRow.Products, "UnitOfMeasure"));
				PackagingConformity = IDOfMPObject(ProductsIdentifier, ItemVariantID, PackagingsID);
			EndIf;
			MobileTaskProducts.Упаковка = PackagingConformity;
			ObjectTabularSection = MobileTask.Товары;//XDTOList - 
			ObjectTabularSection.Add(MobileTaskProducts);
		EndDo;
	EndIf;
	
	// PM data "Tasks".
	If Data.Tasks.Count() > 0 Then
		For Each ListItem In Data.Tasks Do
			MobileTask_ = XDTOFactory.Create(TaskObjectType);
			MobileTask_["Выполнена"] = ListItem.Executed; //@NON-NLS-1
			MobileTask_["ОписаниеЗадачи"] = ListItem.TaskDetails1; //@NON-NLS-1
			MobileTask_["ОписаниеРезультата"] = ListItem.ResultDetails; //@NON-NLS-1
			ObjectTabularSection = MobileTask.Задачи;//XDTOList - 
			ObjectTabularSection.Add(MobileTask_);
		EndDo;
	EndIf;

	// PM data "DolgiPoZakazam".
	If Data.ARAPByOrders.Count() > 0 Then
		For Each TSRow In Data.ARAPByOrders Do
			MobileTaskOrderDebts = XDTOFactory.Create(ItemTypeOrderDebts);
			For Each Property In MobileTaskOrderDebts.Properties() Do
				If Common.RefTypeValue(TSRow[TrimAll(Property)]) Then
					MobileTaskOrderDebts[TrimAll(Property)] = Serializer.XMLString(TSRow[TrimAll(Property)]);
				Else
					MobileTaskOrderDebts[TrimAll(Property)] = TSRow[TrimAll(Property)];
				EndIf;
			EndDo;
			ObjectTabularSection = MobileTask.ДолгиПоЗаказам;//XDTOList - 
			ObjectTabularSection.Add(MobileTaskOrderDebts);
		EndDo;
	EndIf;
	
	// PM data "Decryption of the debitor's debt".
	If Data.ReceivablesDrillDownReport.Count() > 0 Then
		For Each TSRow In Data.ReceivablesDrillDownReport Do
			MobileTaskDecryption = XDTOFactory.Create(ItemTypeDecryption);
			For Each Property In MobileTaskDecryption.Properties() Do
				If Common.RefTypeValue(TSRow[TrimAll(Property)]) Then
					MobileTaskDecryption[TrimAll(Property)] = Serializer.XMLString(TSRow[TrimAll(Property)]);
				Else
					MobileTaskDecryption[TrimAll(Property)] = TSRow[TrimAll(Property)];
				EndIf;
			EndDo;
			ObjectTabularSection = MobileTask.РасшифровкаДебиторскойЗадолженности;//XDTOList - 
			ObjectTabularSection.Add(MobileTaskDecryption);
		EndDo;
	EndIf;
	
	XDTOFactory.WriteXML(XMLWriter, MobileTask);
EndProcedure

Procedure WritePackingHierarchy(XMLWriter, ExportedObjects, PackingRecordStructure)
	
	If Not GetFunctionalOption("UseItemPackages") Then
		Return;
	EndIf;
	
	ProductPackages = ProductPackages(PackingRecordStructure.Products,
		PackingRecordStructure.PackagingRef);
	
	If ProductPackages = Undefined Then
		Return;
	EndIf;
	
	BlankID = BlankID();
	
	While ProductPackages.Next() Do
		
		PackagingsID = TrimAll(ProductPackages.PackagingRef.UUID());
		If TypeOf(ProductPackages.PackagingOwner) = Type("CatalogRef.Products")
			And Not PackingRecordStructure.ItemVariantsAreUsed Then
			PackagingConformity = TrimAll(ProductPackages.PackagingRef.UUID());
		Else
			PackagingConformity = IDOfMPObject(PackingRecordStructure.ProductsID,
					PackingRecordStructure.VariantID, PackagingsID);
		EndIf;
		If ExportedObjects.Get(PackagingConformity) = Undefined Then
			
			PackingStructure = MobileApplicationSalesOrders.PackingStructure();
			PackingStructure.Ref = PackagingConformity;
			PackingStructure.Owner = PackingRecordStructure.MPProducts;
			PackingStructure.Description = TrimAll(ProductPackages.PackagingRef);
			PackingStructure["ERPКод"] = PackagingsID; //@NON-NLS-1
			PackingStructure["НаименованиеПолное"] = PackingStructure.Description; //@NON-NLS-1
			
			PackingStructure.DeletionMark = ProductPackages.DeletionMark;
			PackingStructure["Коэффициент"] = ProductPackages.ZoomRatio; //@NON-NLS-1
			PackingStructure["Вес"] = ProductPackages.Weight; //@NON-NLS-1
			
			If Not ValueIsFilled(ProductPackages.Parent) Then
				PackingStructure.Parent = BlankID;
			Else
				PackingStructure.Parent = TrimAll(ProductPackages.Parent.UUID());
			EndIf;
			
			If ValueIsFilled(ProductPackages.UnitOfMeasure) Then
				PackingStructure["ЕдиницаИзмерения"] =
					TrimAll(ProductPackages.UnitOfMeasure.UUID()); //@NON-NLS-1
				If ExportedObjects.Get(ProductPackages.UnitOfMeasure) = Undefined Then
					
					UnitStructure = MobileApplicationSalesOrders.UnitStructure();
					UnitStructure.Ref = TrimAll(ProductPackages.UnitOfMeasure.UUID());
					UnitStructure.DeletionMark = ProductPackages.UnitOfMeasureDeletionMark;
					UnitStructure.Description = ProductPackages.UnitOfMeasurementName;
					UnitStructure.Code = ProductPackages.UnitOfMeasureCode;
					UnitStructure.PredefinedDataName = ProductPackages.UnitNameOfPredefinedData;
					UnitStructure["МеждународноеСокращение"] = ProductPackages.UnitOfMeasureInternationalAbbreviation; //@NON-NLS-1
					UnitStructure["НаименованиеПолное"] = ProductPackages.UnitOfMeasurementFullName; //@NON-NLS-1
					
					LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
					WriteCatalog(XMLWriter, UnitStructure, LocalObjectName);
					
					ExportedObjects.Insert(ProductPackages.UnitOfMeasure, ProductPackages.UnitOfMeasure);
				EndIf;
			Else
				PackingStructure["ЕдиницаИзмерения"] = BlankID; //@NON-NLS-1
			EndIf;
			
			If ValueIsFilled(ProductPackages.WeightUnitOfMeasure) Then
				PackingStructure["ВесЕдиницаИзмерения"] =
					TrimAll(ProductPackages.WeightUnitOfMeasure.UUID()); //@NON-NLS-1
				If ExportedObjects.Get(ProductPackages.WeightUnitOfMeasure) = Undefined Then
					
					UnitStructure = MobileApplicationSalesOrders.UnitStructure();
					UnitStructure.Ref = TrimAll(ProductPackages.WeightUnitOfMeasure.UUID());
					UnitStructure.DeletionMark = ProductPackages.WeightUnitOfMeasureDeletionMark;
					UnitStructure.Description = ProductPackages.WeightUnitName_;
					UnitStructure.Code = ProductPackages.WeightUnitCode_;
					UnitStructure.PredefinedDataName = ProductPackages.WeightUnitNameOfPredefinedData;
					UnitStructure["МеждународноеСокращение"] =
						ProductPackages.WeightUnitOfMeasurementInternationalAbbreviation; //@NON-NLS-1
					UnitStructure["НаименованиеПолное"] = ProductPackages.WeightUnitFullName_; //@NON-NLS-1
					
					LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
					WriteCatalog(XMLWriter, UnitStructure, LocalObjectName);
					
					ExportedObjects.Insert(ProductPackages.WeightUnitOfMeasure, ProductPackages.WeightUnitOfMeasure);
				EndIf;
			Else
				PackingStructure["ВесЕдиницаИзмерения"] = BlankID; //@NON-NLS-1
			EndIf;
			
			PackingStructure["Штрихкод"] = ItemsBarcode(PackingRecordStructure.Products,
				PackingRecordStructure.CharacteristicReference, PackingRecordStructure.PackagingRef); //@NON-NLS-1
			
			LocalObjectName = "CatalogObject.УпаковкиНоменклатуры"; //@NON-NLS-1
			WriteCatalog(XMLWriter, PackingStructure, LocalObjectName);
			
		EndIf;
	EndDo;
EndProcedure

Procedure RecordIndividualCustomerPrices(XMLWriter, ExchangeNode, ExportedObjects,
	CorrespondenceTableForIndividualPrices)
	
	For Each AgreementLine_ In CorrespondenceTableForIndividualPrices Do
		TableOfIndividualPrices_ = IndividualPriceList(ExchangeNode, AgreementLine_);
		For Each PriceListLine In TableOfIndividualPrices_ Do
			UnloadingObjectsOfReferenceType(XMLWriter, ExportedObjects, PriceListLine, ExchangeNode);
			RecordStringOfIndividualCustomerPrices(XMLWriter, PriceListLine);
		EndDo;
	EndDo;
EndProcedure

Procedure RecordTaskStatusInformationForSalesRepresentative(Message, Val JobForSalesRepresentative)
	
	Structure = MobileApplicationSalesOrders.StructureOfTaskStatusToSalesRepresentative();
	Structure.ref = TrimAll(Common.ObjectAttributeValue(JobForSalesRepresentative, "Ref").UUID());
	Structure["Статус"] = "Закрыт"; //@NON-NLS-1 @NON-NLS-2
	Structure["ПечатнаяФормаЗаказа"] = Chars.NBSp; //@NON-NLS-1
	
	Message.Add(Structure);
EndProcedure

Procedure RecordCustomerOrderStatusInformation(Message, Val SalesOrder, Val Changed = False, Error = False)
	
	OrderStatusInformation = MobileApplicationSalesOrders.StructureOfCustomerSOrderStatus();
	If Not Error Then
		SalesOrders = New Array;
		SalesOrders.Add(SalesOrder);
		StatusInformation = InformationOnStatusOfCustomerOrders(SalesOrders);
		If StatusInformation.Count()> 0 Then
			FillPropertyValues(OrderStatusInformation, StatusInformation[0]);
		EndIf;
	EndIf;
	
	Message.Add(OrderStatusInformation);
EndProcedure

Procedure RecordInformationOnStatusOfRefundRequest(Message, Val RequestForReturnOfGoods, Val Changed = False, Error = False)
	
	StatusInformation = MobileApplicationSalesOrders.StructureOfRefundRequestStatus();
	
	If Not Error Then
		RequestsForReturnOfGoods = New Array;
		RequestsForReturnOfGoods.Add(RequestForReturnOfGoods);
		ApplicationStatusInformation = InformationOnStatusOfRequestsForReturns(RequestsForReturnOfGoods);
		If StatusInformation.Count()> 0 Then
			FillPropertyValues(StatusInformation, ApplicationStatusInformation[0]);
		EndIf;
	EndIf;
	
	Message.Add(StatusInformation);
EndProcedure

Procedure WritePrintedOrderFormForTask(XMLWriter, JobForSalesRepresentative)

	Query = New Query(
	"SELECT
	|	SalesOrder.Ref AS LinkToOrder
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.DocumentBasis = &JobForSalesRepresentative");

	Query.SetParameter("JobForSalesRepresentative", JobForSalesRepresentative.Ref);
		
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	Selection.Next();
	
	Structure = New Structure;
	Structure.Insert("ref", TrimAll(JobForSalesRepresentative.Ref.UUID()));
	Structure.Insert("Статус", "Closed"); //@NON-NLS-1
	
	PrintObjects = New ValueList;
	PrintObjects.Add(Selection.LinkToOrder);
	
	CurStructureOfTypes = New Map;
	CurStructureOfTypes.Insert("Document.SalesOrder", PrintObjects.UnloadValues());
	
	SpreadsheetDocument = DataProcessors.PrintOrderForGoodsServices.GeneratePrintedCustomerOrderForm(
		CurStructureOfTypes, PrintObjects, Undefined);
		
	For Each Drawing In SpreadsheetDocument.Drawings Do
		If Drawing.Name = "BarcodeIcon" Then
			Drawing.PictureSize = PictureSize.Stretch;
			Break;
		EndIf;
	EndDo;
	
	Structure.Insert("ПечатнаяФормаЗаказа", New ValueStorage(SpreadsheetDocument, New Deflation(9))); //@NON-NLS-1
	
	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(), "JobTargetStatus");
	ExchangeObject = XDTOFactory.Create(ObjectType);
	FillPropertyValues(ExchangeObject, Structure);
	
	XDTOFactory.WriteXML(XMLWriter, ExchangeObject);
EndProcedure

Procedure WriteDownSalesRules(XMLWriter, TableRow)
	
	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(),
		"InformationRegisterRecord.ПравилаПродаж");
	ExchangeObject = XDTOFactory.Create(ObjectType);
	ExchangeObject.Клиент = TrimAll(TableRow.PartnerForExport.UUID());
	ExchangeObject.ДоговорКлиента = TableRow.SalesConditionID;
	
	XDTOFactory.WriteXML(XMLWriter, ExchangeObject);
EndProcedure

Procedure WriteParentOfProductItem(XMLWriter, ProductsParent)
	
	StructureOfParentProduct = MobileApplicationSalesOrders.StructureOfParentProduct();
	
	RequestStringForBankingDetails = "IsFolder, DeletionMark, Description, Parent, Code";
	ObjectAttributes = Common.ObjectAttributesValues(ProductsParent, RequestStringForBankingDetails);
	
	StructureOfParentProduct.IsFolder = ObjectAttributes.IsFolder;
	StructureOfParentProduct.Ref = TrimAll(ProductsParent.UUID());
	StructureOfParentProduct.DeletionMark = ObjectAttributes.DeletionMark;
	StructureOfParentProduct.Parent = BlankID();
	If ValueIsFilled(ObjectAttributes.Parent) Then
		StructureOfParentProduct.Parent = TrimAll(ObjectAttributes.Parent.UUID());
	EndIf;
	StructureOfParentProduct.Code = ObjectAttributes.Code;
	StructureOfParentProduct.Description = ObjectAttributes.Description;
	StructureOfParentProduct["ERPКодНоменклатура"] = StructureOfParentProduct.Ref; //@NON-NLS-1
	StructureOfParentProduct["СтрокаПоиска"] = TrimAll(ObjectAttributes.Code)+TrimAll(ObjectAttributes.Description); //@NON-NLS-1
	
	LocalObjectName = "CatalogObject.Номенклатура"; //@NON-NLS-1
	WriteCatalog(XMLWriter, StructureOfParentProduct, LocalObjectName);
	
EndProcedure

Procedure RecordPartnerSegments(Partner, ExchangeNode)
	
	PartnerSegmentsAreUsed = Constants.UsePartnersSegments.Get();
	
	If Not PartnerSegmentsAreUsed Then
		Return;
	EndIf;
	
	SegmentDiagram = ExchangePlans.MobileApplicationSalesOrders.GetTemplate("AvailablePartnerSegments");
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SegmentDiagram)); 
	SettingsComposer.LoadSettings(SegmentDiagram.DefaultSettings);
	
	Filter = SettingsComposer.Settings.Filter;
	
	ComposerSettingsFromExchangeSettings = MobileApplicationSalesOrdersCached.ExchangeSettings(ExchangeNode);//DataCompositionSettings - 
	
	PartnerSegmentField = New DataCompositionField("PartnersSegment");
	
	SegmentSelectionIsUsed = False;
	If Not ComposerSettingsFromExchangeSettings = Undefined Then
		ArrayDeletition = New Array;
		For Each FilterElement In ComposerSettingsFromExchangeSettings.Filter.Items Do
			If FilterElement.Use Then
				If FilterElement.LeftValue = PartnerSegmentField Then
					NewItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
					FillPropertyValues(NewItem, FilterElement,
					"UserSettingID, LeftValue, ComparisonType, RightValue, Use");
					SegmentSelectionIsUsed = True;
				EndIf;
				If FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
					ArrayDeletition.Add(FilterElement);
				EndIf;
			EndIf;
		EndDo;
		For Each ForDeletion In ArrayDeletition Do
			Filter.Items.Delete(ForDeletion);
		EndDo;
	EndIf;
	
	If Not SegmentSelectionIsUsed Then
		Return;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = TemplateComposer.Execute(SegmentDiagram, SettingsComposer.GetSettings(),
		,,Type("DataCompositionValueCollectionTemplateGenerator"), False);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(DataCompositionTemplate);
	
	SegmentTable = New ValueTable;
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(SegmentTable);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor);
	OutputProcessor.EndOutput();
	
	If SegmentTable.Count()>0 Then
		RecordAvailablePartnerSegments(Partner, SegmentTable.UnloadColumn("PartnersSegment"));
	EndIf;
EndProcedure

Procedure RecordStringOfIndividualCustomerPrices(XMLWriter, Val PriceListLine)
	
	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(),
		"InformationRegisterRecord.ЦеныНоменклатурыПоДоговорамКлиентов");
	ExchangeObject = XDTOFactory.Create(ObjectType);

	ExchangeObject.ДоговорКлиента = PriceListLine.CustomerContract;
	ExchangeObject.ВидНоменклатуры = PriceListLine.ProductKind;
	ExchangeObject.ВидЦены = PriceListLine.PriceKind;
	ExchangeObject.Номенклатура = PriceListLine.Products;
	ExchangeObject.РодительНоменклатуры = PriceListLine.ProductsParent;
	ExchangeObject.СтрокаПоиска = PriceListLine.SearchString;
	ExchangeObject.Упаковка = PriceListLine.Package;
	ExchangeObject.Цена = PriceListLine.Price;
	ExchangeObject.ЦеноваяГруппа = PriceListLine.PriceGroup;
	
	XDTOFactory.WriteXML(XMLWriter, ExchangeObject);
EndProcedure

Procedure WriteStringOfXMLResidues(XMLWriter, RemainderLine_)

	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(),
		"InformationRegisterRecord.ТоварыНаСкладах");
	ExchangeObject = XDTOFactory.Create(ObjectType);
	ExchangeObject.Номенклатура = RemainderLine_.ref;
	ExchangeObject.Склад = RemainderLine_.WarehouseRef;
	ExchangeObject.ВНаличии = RemainderLine_.AvailableBalance;
	ExchangeObject.СостояниеОстаткаИндекс = RemainderLine_.BalanceStatusIndex;
	
	XDTOFactory.WriteXML(XMLWriter, ExchangeObject);
EndProcedure

Procedure WritePriceListLine(XMLWriter, PriceListLine)
	
	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(),
		"InformationRegisterRecord.ЦеныНоменклатуры");
	ExchangeObject = XDTOFactory.Create(ObjectType);
	
	ExchangeObject.ВидНоменклатуры = PriceListLine.ProductKind;
	ExchangeObject.ВидЦены = PriceListLine.PriceKind;
	ExchangeObject.Номенклатура = PriceListLine.Products;
	ExchangeObject.РодительНоменклатуры = PriceListLine.ProductsParent;
	ExchangeObject.СтрокаПоиска = PriceListLine.SearchString;
	ExchangeObject.Упаковка = PriceListLine.Package;
	ExchangeObject.Цена = PriceListLine.Price;
	ExchangeObject.ЦеноваяГруппа = PriceListLine.PriceGroup;
	
	XDTOFactory.WriteXML(XMLWriter, ExchangeObject);
EndProcedure

Procedure FillInTaskDataForMPSettings(JobForSalesRepresentative, TaskSettings)
	
	UseVariants = Constants.UseItemVariants.Get();
	DetailTasks = Constants.ItemizeJobsForSalesRepresentatives.Get();
	
	FillInTasksBasedOnSalesHistoryData = TaskSettings.ЗаполнятьЗаданияПоДаннымИсторииПродаж;
	ReceiveInformationAboutSettlementsWithClients = TaskSettings.ПолучатьИнформациюОРасчетахСКлиентами;
	
	If FillInTasksBasedOnSalesHistoryData And DetailTasks Then
		
		PeriodDetails = New Structure;
		PeriodDetails.Insert("Period", "day");
		PeriodDetails.Insert("BeginOfPeriod", TaskSettings.НачалоПериодаАнализаИсторииПродаж);
		PeriodDetails.Insert("EndOfPeriod", TaskSettings.КонецПериодаАнализаИсторииПродаж);
		
		JobForSalesRepresentative.FillInSalesHistory(PeriodDetails, UseVariants);
	EndIf;
	
	If ReceiveInformationAboutSettlementsWithClients Then	
		JobForSalesRepresentative.FillInDataOnAccountsReceivable();
	EndIf;
EndProcedure

Procedure FillInDeliveryInformation(DocumentObject, MobileData, DocumentType)
	
	DeliveryAddress = MobileData.АдресДоставки;
	If Not ValueIsFilled(DeliveryAddress) And ValueIsFilled(DocumentObject.Partner) Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(DocumentObject.Partner);
	EndIf;
	
	If ValueIsFilled(DeliveryAddress) Then
		DocumentObject.DeliveryAddress = DeliveryAddress;
		GeneralPurposeTMServerCall.FillInValuesOfCIFieldsOnPresentation(DeliveryAddress,
			DocumentObject.DeliveryAddressFieldValues);
	Else
		DocumentObject.DeliveryAddress = NStr("vi = '<chưa chỉ ra địa chỉ/>';
												|ru = '<адрес не указан/>';
												|en = '<address is not specified/>'; fa = '<address is not specified/>';
												|it = '<indirizzo non indicato/>';
												|pl = '<adres nie jest wskazany/>';
												|tr = '<adres belirtilmemiş/>.'", Common.DefaultLanguageCode());
	EndIf;
	
	DocumentObject.DeliveryTimeFrom = MobileData.ВремяДоставкиС;
	DocumentObject.DeliveryTimeTo = MobileData.ВремяДоставкиПо;
	DocumentObject.AdditionalDeliveryInformation = MobileData.ДополнительнаяИнформацияПоДоставке;
	
	If DocumentType = 0 Then
		DeliveryMethod = Enums.TransportMethods.ToCustomer;
	ElsIf DocumentType = 1 Then
		DeliveryMethod = Enums.TransportMethods.ToCustomerIsDefinedByTransportationCompany;
	EndIf;
	DocumentObject.DeliveryMethod = ?(MobileData.Самовывоз, Enums.TransportMethods.SelfPickup,
		DeliveryMethod);
EndProcedure

Procedure FillInAgreementCatalogForChanges(AgreementObject)

	AgreementObject.Manager = Users.CurrentUser();
	If Not GetFunctionalOption("UseApprovalOfTermsOfSales")
		Or Users.RolesAvailable("FullAccess, VarianceFromSalesTermsAndConditions") Then
		AgreementObject.Status = Enums.StatusesOfTermsOfSales.Valid;
	Else
		AgreementObject.Status = Enums.StatusesOfTermsOfSales.NotApproved;
	EndIf;
	
	AgreementObject.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
	AgreementObject.FinancialAccountingGroup = 
		Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(AgreementObject.Organization,
								AgreementObject.BusinessOperation);
	
	If Not AgreementObject.ContractsAreUsed Then
		If GetFunctionalOption("UseSalesOrders")
			Or AgreementObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
			AgreementObject.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
		Else
			AgreementObject.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
		EndIf;
	EndIf;
EndProcedure

Function ReplacePartnerWithClient(Val String)
	
	ReplacementString = String;
	
	MatchingPartnerAndCustomerNames = MobileApplicationSalesOrdersCached.MatchingPartnerAndCustomerNames();
	MatchingOfString = MatchingPartnerAndCustomerNames.Get(String);
	If Not MatchingOfString = Undefined Then
		ReplacementString = MatchingOfString;
	EndIf;

	Return ReplacementString;
	
EndFunction

Function IDOfMPObject(Val ProductsID, Val VariantID, Val PackagingsID)
	
	MPObject = ComplianceOfMPObject(ProductsID, VariantID, PackagingsID);
	
	If MPObject = Undefined Then
		MPObject = NewComplianceOfMPObject(ProductsID, VariantID, PackagingsID);
	EndIf;
	
	Return MPObject;
EndFunction

Function IDOfMPPackage(XMLWriter, ExportedObjects, PackingRecordStructure)
	
	PackagingsID = TrimAll(PackingRecordStructure.PackagingRef.UUID());
	PackagingConformity = IDOfMPObject(PackingRecordStructure.ProductsID,
		PackingRecordStructure.VariantID, PackagingsID);
	ItIsUnitOfWeight = PackingRecordStructure.Property("ItIsUnitOfWeight");
	
	BlankID = BlankID();
	
	If ExportedObjects.Get(PackagingConformity) = Undefined Then
		
		PackingStructure = MobileApplicationSalesOrders.PackingStructure();
		PackingStructure.Ref = PackagingConformity;
		PackingStructure.Owner = PackingRecordStructure.MPProducts;
		PackingStructure.Description = TrimAll(PackingRecordStructure.PackagingRef);
		PackingStructure["ERPКод"] = PackagingsID; //@NON-NLS-1
		PackingStructure["НаименованиеПолное"]	= PackingStructure.Description; //@NON-NLS-1
		
		RequestResultForPackaging = RequestResultForPackaging(PackingRecordStructure.PackagingRef,
			PackingRecordStructure.Products);
		
		If RequestResultForPackaging = Undefined Then
			Return PackagingConformity;
		EndIf;
		
		PackingStructure.DeletionMark = RequestResultForPackaging.DeletionMark;
		PackingStructure["Коэффициент"] = RequestResultForPackaging.ZoomRatio; //@NON-NLS-1
		If PackingRecordStructure.PackagingRef = RequestResultForPackaging.WeightUnit Then
			PackingStructure["Вес"] = 1; //@NON-NLS-1
		ElsIf PackingRecordStructure.PackagingRef = RequestResultForPackaging.UnitOfProductMeasurement_ Then
			PackingStructure["Вес"] = RequestResultForPackaging.UnitWeight_; //@NON-NLS-1
		Else
			PackingStructure["Вес"] = RequestResultForPackaging.Weight; //@NON-NLS-1
		EndIf;
		
		If Not ValueIsFilled(RequestResultForPackaging.Parent) Then
			PackingStructure.Parent = BlankID;
		Else
			MPPackingRecordStructure = New Structure;
			MPPackingRecordStructure.Insert("PackagingRef", RequestResultForPackaging.Parent);
			MPPackingRecordStructure.Insert("ProductsID", PackingRecordStructure.ProductsID);
			MPPackingRecordStructure.Insert("VariantID", PackingRecordStructure.VariantID);
			MPPackingRecordStructure.Insert("MPProducts", PackingRecordStructure.MPProducts);
			MPPackingRecordStructure.Insert("Products", PackingRecordStructure.Products);
			MPPackingRecordStructure.Insert("CharacteristicReference", PackingRecordStructure.CharacteristicReference);
			
			PackingStructure.Parent =
				IDOfMPPackage(XMLWriter, ExportedObjects, MPPackingRecordStructure);
		EndIf;
		
		If ValueIsFilled(RequestResultForPackaging.UnitOfMeasure) Then
			PackingStructure["ЕдиницаИзмерения"] = TrimAll(RequestResultForPackaging.UnitOfMeasure.UUID()); //@NON-NLS-1
			
			If ExportedObjects.Get(RequestResultForPackaging.UnitOfMeasure) = Undefined Then
				
				UnitStructure = MobileApplicationSalesOrders.UnitStructure();
				UnitStructure.Ref = TrimAll(RequestResultForPackaging.UnitOfMeasure.UUID());
				UnitStructure.DeletionMark = RequestResultForPackaging.UnitOfMeasureDeletionMark;
				UnitStructure.Description = RequestResultForPackaging.UnitOfMeasurementName;
				UnitStructure.Code = RequestResultForPackaging.UnitOfMeasureCode;
				UnitStructure.PredefinedDataName =
					RequestResultForPackaging.UnitNameOfPredefinedData;
				UnitStructure["МеждународноеСокращение"] = 
					RequestResultForPackaging.UnitOfMeasureInternationalAbbreviation; //@NON-NLS-1
				UnitStructure["НаименованиеПолное"] = RequestResultForPackaging.UnitOfMeasurementFullName; //@NON-NLS-1
				
				LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
				WriteCatalog(XMLWriter, UnitStructure, LocalObjectName);
				
				ExportedObjects.Insert(RequestResultForPackaging.UnitOfMeasure,
				RequestResultForPackaging.UnitOfMeasure);
			EndIf;
		Else
			PackingStructure["ЕдиницаИзмерения"] = TrimAll(PackingRecordStructure.PackagingRef.UUID()); //@NON-NLS-1
		EndIf;
		
		If ValueIsFilled(RequestResultForPackaging.WeightUnitOfMeasure) Then
			PackingStructure.ВесЕдиницаИзмерения =
				TrimAll(RequestResultForPackaging.WeightUnitOfMeasure.UUID());
			If ExportedObjects.Get(RequestResultForPackaging.WeightUnitOfMeasure) = Undefined Then
				
				UnitStructure = MobileApplicationSalesOrders.UnitStructure();
				UnitStructure.Ref = TrimAll(RequestResultForPackaging.WeightUnitOfMeasure.UUID());
				UnitStructure.DeletionMark = RequestResultForPackaging.WeightUnitOfMeasureDeletionMark;
				UnitStructure.Description = RequestResultForPackaging.WeightUnitName_;
				UnitStructure.Code = RequestResultForPackaging.WeightUnitCode_;
				UnitStructure.PredefinedDataName =
					RequestResultForPackaging.WeightUnitNameOfPredefinedData;
				UnitStructure["МеждународноеСокращение"] =
					RequestResultForPackaging.WeightUnitOfMeasurementInternationalAbbreviation; //@NON-NLS-1
				UnitStructure["НаименованиеПолное"] = RequestResultForPackaging.WeightUnitFullName_; //@NON-NLS-1
				
				LocalObjectName = "CatalogObject.ЕдиницыИзмерения"; //@NON-NLS-1
				WriteCatalog(XMLWriter, UnitStructure, LocalObjectName);
				
				ExportedObjects.Insert(RequestResultForPackaging.UnitOfMeasure,
				RequestResultForPackaging.UnitOfMeasure);
			EndIf;
		Else
			If ItIsUnitOfWeight Then
				PackingStructure["ВесЕдиницаИзмерения"] = TrimAll(PackingRecordStructure.PackagingRef.UUID()); //@NON-NLS-1
			Else
				PackingStructure["ВесЕдиницаИзмерения"] = BlankID; //@NON-NLS-1
			EndIf;
		EndIf;
		
		PackingStructure["Штрихкод"] = ItemsBarcode(PackingRecordStructure.Products,
			PackingRecordStructure.CharacteristicReference, PackingRecordStructure.PackagingRef); //@NON-NLS-1
		
		LocalObjectName = "CatalogObject.УпаковкиНоменклатуры"; //@NON-NLS-1
		WriteCatalog(XMLWriter, PackingStructure, LocalObjectName);
		ExportedObjects.Insert(PackagingConformity, TrimAll(PackingRecordStructure.PackagingRef));
	EndIf;
	
	Return PackagingConformity;
EndFunction

Function IDOfImageFile(XMLWriter, ExportedObjects, PriceListRow, ExchangeNode)
	
	IDOfImageFile = TrimAll(PriceListRow.ImageFileLink.UUID());
	
	If ExportedObjects.Get(IDOfImageFile) = Undefined 
		And (PriceListRow.ImageSubmissionIsRequired) Then
		
		XdtoImageFileDetails = MobileApplicationSalesOrders.ProductStructure_AttachedFiles();
		
		XdtoImageFileDetails.ref = IDOfImageFile;
		XdtoImageFileDetails.DeletionMark = PriceListRow.PicturesFileDeletionMark;
		XdtoImageFileDetails.Description = PriceListRow.ImageFileName;
		XdtoImageFileDetails["ВладелецФайла"] =
			TrimAll(PriceListRow.ImageFileFILEOwner.UUID()); //@NON-NLS-1
		XdtoImageFileDetails["ДатаСоздания"] = PriceListRow.ImageFileCreationDate; //@NON-NLS-1
		XdtoImageFileDetails["Описание"] = PriceListRow.ImageFileDescription; //@NON-NLS-1
		XdtoImageFileDetails["Размер"] = PriceListRow.ImageFileSize; //@NON-NLS-1
		XdtoImageFileDetails["Расширение"] = PriceListRow.ImageFileExtension; //@NON-NLS-1
		
		Try
			FileData = FilesOperations.FileBinaryData(PriceListRow.ImageFileLink);
		Except
			FileData = "";
		EndTry;
		XdtoImageFileDetails["ХранимыйФайл"] = New ValueStorage(FileData, New Deflation(9)); //@NON-NLS-1
		
		LocalObjectName = "CatalogObject.НоменклатураПрисоединенныеФайлы"; //@NON-NLS-1
		WriteCatalog(XMLWriter, XdtoImageFileDetails, LocalObjectName);
		ExportedObjects.Insert(IDOfImageFile, IDOfImageFile);
		ExchangePlans.DeleteChangeRecords(ExchangeNode, PriceListRow.ImageFileLink);
	EndIf;
	
	Return IDOfImageFile;
EndFunction

Function IDOfSalesCondition(StructureAndTermsOfSales)
	
	SalesCondition = AgreementCompliance(StructureAndTermsOfSales);
	
	If SalesCondition = Undefined Then
		SalesCondition = NewSalesConditionExchangeNode(StructureAndTermsOfSales);
	EndIf;
	
	Return SalesCondition;
EndFunction

Function PriceListChanges(Val ExchangeNode, Val AllPrices)
	
	// The data may already be unavailable by rights.
	SetPrivilegedMode(True);
	
	Changes = New Structure;
	Changes.Insert("Products", Undefined);
	Changes.Insert("Characteristic", Undefined);
	Changes.Insert("PriceKind", Undefined);
	
	If AllPrices Then
		Changes.Insert("HasChanges", False);
		ExchangePlans.RecordChanges(ExchangeNode, Metadata.Catalogs.Products);
		NodeAttributes = MobileApplicationSalesOrders.NodeAttributes(ExchangeNode);
		TransmitProductImages = ?(NodeAttributes.TransmitProductImages = Undefined,
				False, NodeAttributes.TransmitProductImages);
		If TransmitProductImages Then
			ExchangePlans.RecordChanges(ExchangeNode, Metadata.Catalogs.ProductsAttachedFiles);
		EndIf;
	Else
		Changes.Insert("HasChanges", True);
	EndIf;
	
	Query = New Query;
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		QueryText = "SELECT
		|	ItemsPrices.Products AS Products,
		|	ItemsPrices.PricingVariant AS PricingVariant,
		|	ItemsPrices.PriceKind,
		|	CASE
		|		WHEN
		|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|			THEN CatProducts_.Ref
		|		WHEN
		|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
		|			THEN CatProducts_.ProductKind
		|		WHEN
		|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|			THEN CatProducts_.ItemVariantsOwner
		|		ELSE NULL
		|	END AS ItemVariantsOwner
		|INTO PricesOfNomenclaturePrev
		|FROM
		|	InformationRegister.ItemsPrices25 AS ItemsPrices
		|		INNER JOIN InformationRegister.ItemsPrices25.Changes AS PricesOfChanges
		|		ON (PricesOfChanges.Recorder = ItemsPrices.Recorder)
		|		AND (VALUETYPE(PricesOfChanges.Node) = TYPE(ExchangePlan.MobileApplicationSalesOrders))
		|		AND (PricesOfChanges.Node = &Node)
		|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|			LEFT JOIN Catalog.Products AS CatProducts_
		|			ON ItemsCharacteristics.Owner = CatProducts_.Ref
		|		ON (ItemsPrices.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))
		|		AND (ItemsPrices.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing)
		|
		|INDEX BY
		|	PricingVariant,
		|	ItemVariantsOwner
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	PricesOfNomenclaturePrev.Products,
		|	ISNULL(ItemsCharacteristics.Ref, ISNULL(ItemsCharacteristics1.Ref,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS Characteristic,
		|	PricesOfNomenclaturePrev.PriceKind
		|FROM
		|	PricesOfNomenclaturePrev AS PricesOfNomenclaturePrev
		|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		ON (PricesOfNomenclaturePrev.ItemVariantsOwner <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))
		|		AND PricesOfNomenclaturePrev.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing
		|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
		|		ON (PricesOfNomenclaturePrev.ItemVariantsOwner = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))
		|		AND PricesOfNomenclaturePrev.ItemVariantsOwner = ItemsCharacteristics1.Owner";
	Else
		QueryText = "SELECT DISTINCT
		|	ItemsPrices.Products AS Products,
		|	ItemsPrices.PriceKind,
		|	ItemsPrices.Characteristic
		|FROM
		|	InformationRegister.ItemsPrices AS ItemsPrices
		|		INNER JOIN InformationRegister.ItemsPrices.Changes AS PricesOfChanges
		|		ON (PricesOfChanges.Recorder = ItemsPrices.Recorder)
		|			AND (VALUETYPE(PricesOfChanges.Node) = TYPE(ExchangePlan.MobileApplicationSalesOrders))
		|			AND (PricesOfChanges.Node = &Node)";
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("Node", ExchangeNode);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Changes;
	EndIf;
	
	ChangesTable = Result.Unload();
	Changes.Insert("Products", ChangesTable.UnloadColumn("Products"));
	Changes.Insert("Characteristic", ChangesTable.UnloadColumn("Characteristic"));
	Changes.Insert("PriceKind", ChangesTable.UnloadColumn("PriceKind"));
	
	Return Changes;
EndFunction

Function IndividualPriceList(ExchangeNode, AgreementLine_)
	
	PriceTable_ = DataForUploadingIndividualPriceLists(ExchangeNode, AgreementLine_);
	
	If PriceTable_.Count() = 0 Then
		Return PriceTable_;
	EndIf;
	
	UsePriceGroups = GetFunctionalOption("UsePriceGroups");
	UseCharacteristics = GetFunctionalOption("UseItemVariants");
	UsePackages = GetFunctionalOption("UseItemPackages");
	If PriceTable_.Columns.Find("PriceGroup") = Undefined Then
		PriceTable_.Columns.Add("PriceGroup", New TypeDescription("CatalogRef.PriceGroups"));
	EndIf;
	If PriceTable_.Columns.Find("CharacteristicReference") = Undefined Then
		PriceTable_.Columns.Add("CharacteristicReference",
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	If PriceTable_.Columns.Find("ItemVariantsAreUsed") = Undefined Then
		PriceTable_.Columns.Add("ItemVariantsAreUsed", New TypeDescription("Boolean"));
		PriceTable_.FillValues(UseCharacteristics, "ItemVariantsAreUsed");
	EndIf;
	
	If PriceTable_.Columns.Find("UsePackages") = Undefined Then
		PriceTable_.Columns.Add("UsePackages",  New TypeDescription("Boolean"));
		PriceTable_.FillValues(UsePackages, "UsePackages");
	EndIf;
	
	BlankID = BlankID();
	
	For Each PriceListRow In PriceTable_ Do
		PriceListRow.CustomerContract = AgreementLine_.IDOfSalesCondition;
		PriceListRow.ProductsID = TrimAll(PriceListRow.ProductsLink.UUID());
		PriceListRow.VariantID = ?(ValueIsFilled(PriceListRow.CharacteristicReference),
			TrimAll(PriceListRow.CharacteristicReference.UUID()), "");
		PriceListRow.PackagingsID = TrimAll(PriceListRow.PackagingRef.UUID());
		PriceListRow.PriceKind = TrimAll(PriceListRow.PriceTypeReference.UUID());
		PriceListRow.ProductKind = TrimAll(PriceListRow.ProductKindReference.UUID());
		PriceListRow.PriceGroup = ?(
			UsePriceGroups,
			TrimAll(PriceListRow.PriceGroupReference.UUID()),
			BlankID);
		PriceListRow.ProductsParent = TrimAll(PriceListRow.ProductsParentReference.UUID());
	EndDo;
	
	QueryText = MobileApplicationSalesOrders.RequestTextForDetailsOfPriceListObjects(True);
	Query = New Query(QueryText);
	Query.SetParameter("PriceTable_", PriceTable_);
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("RegistrationCountry", Constants.MainCountry.Get());
	IndividualPriceList = Query.Execute().Unload();
	
	MatchesOfProducts = IndividualPriceList.FindRows(New Structure("RecordProductCompliance", True));
	For Each PriceListRow In MatchesOfProducts Do
		PriceListRow.Products = IDOfMPObject(PriceListRow.ProductsID, PriceListRow.VariantID, "");
	EndDo;
	ConformityOfPackages_ = IndividualPriceList.FindRows(New Structure("RecordPackagingCompliance", True));
	For Each PriceListRow In ConformityOfPackages_ Do
		PriceListRow.Package =
			IDOfMPObject(PriceListRow.ProductsID, PriceListRow.VariantID, PriceListRow.PackagingsID);
	EndDo;
	
	UnloadingUnitOfMeasureAsPacking =
		GetFunctionalOption("UseJobsToManageSalesRepresentatives")
		And GetFunctionalOption("ItemizeJobsForSalesRepresentatives");
	
	If IndividualPriceList.Columns.Find("UnloadingUnitOfMeasureAsPacking") = Undefined Then
		IndividualPriceList.Columns.Add("UnloadingUnitOfMeasureAsPacking",  New TypeDescription("Boolean"));
		IndividualPriceList.FillValues(UnloadingUnitOfMeasureAsPacking, "UnloadingUnitOfMeasureAsPacking");
	EndIf;
	
	Return IndividualPriceList;
EndFunction

Procedure InitializeDocument(DocumentObject)
	
	DocumentObject.Manager = Users.CurrentUser();
	DocumentObject.Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(DocumentObject.Currency);
	DocumentObject.Organization = SettingsValueCached.GetDefaultOrganization(DocumentObject.Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(DocumentObject.Organization);
	DocumentObject.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, DocumentObject.BankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(DocumentObject.Counterparty);
	DocumentObject.CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
		ParametersOfAccount, DocumentObject.CounterpartyBankAccount);
		
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = DocumentObject.Organization;
	ParametersStructure.PaymentMethod = DocumentObject.PaymentMethod;
	ParametersStructure.CashAccount 		= DocumentObject.CashAccount;
	DocumentObject.CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	DocumentObject.Department = SettingsValueCached.UserDivision(
		DocumentObject.Manager, DocumentObject.Department);
	DocumentObject.Warehouse = SettingsValueCached.GetDefaultWarehouse(
		DocumentObject.Warehouse, GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments"));
		
	FillInSeparately = Common.ObjectAttributeValue(DocumentObject.Terms,
	"EnableAssigmentSupplyForOrders");
	
	If TypeOf(DocumentObject) = Type("DocumentObject.SalesOrder") Then
		If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
			DocumentObject.Status = Enums.SalesOrderStatuses.ToSupply;
			If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
				DocumentObject.DateOfShipment = CurrentSessionDate();
			EndIf;
		Else
			DocumentObject.Status = Enums.SalesOrderStatuses.NotApproved;
		EndIf;
		ProvisionInDocumentsServer.FillInDefaultSecurityOption(DocumentObject.Goods,
			FillInSeparately, DocumentObject.Status);
	ElsIf TypeOf(DocumentObject) = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer") Then
		If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
			DocumentObject.Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn;
			If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
				DocumentObject.DateOfShipment = CurrentSessionDate();
			EndIf;
		Else
			DocumentObject.Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
		EndIf;
		ProvisionInDocumentsServer.FillInDefaultSecurityOption(DocumentObject.SubstituteGoods,
			FillInSeparately, DocumentObject.Status);
		DocumentObject.OneDateReceipt = True;
	EndIf;
	
	DocumentObject.Priority = SettingsValueCached.GetDefaultPriority(DocumentObject.Priority);
	DocumentObject.ARAPObjectSettings = ARAPAccountingServer.ARAPObjectSettings(True,,DocumentObject.Terms, DocumentObject.Contract);
	DocumentObject.NotShipInInstallments = True;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(DocumentObject);
EndProcedure

Function CounterpartyInformation(Val TableRow)
	
	CounterpartyStructure = MobileApplicationSalesOrders.CounterpartyStructure();
	
	CounterpartyStructure.Ref			= TrimAll(TableRow.CounterpartyRef.UUID());
	CounterpartyStructure.DeletionMark	= TableRow.CounterpartyDeletionMark;
	CounterpartyStructure.Description	= TableRow.CounterpartyDescription;
	CounterpartyStructure["ERPКод"]			= CounterpartyStructure.Ref; //@NON-NLS-1
	
	LegalEntityIndividual = "";
	If ValueIsFilled(TableRow.CounterpartyLegEntInd) Then
		LegalEntityIndividual = MobileApplicationSalesOrdersCached.ComplianceWithTypesOfLegalEntityIndividual().Get(TableRow.CounterpartyLegEntInd);
	EndIf;
	
	CounterpartyStructure["ЮрФизЛицо"] = LegalEntityIndividual;//@NON-NLS-1
	CounterpartyStructure["ИНН"] = TableRow.CounterpartyTIN;//@NON-NLS-1
	CounterpartyStructure["ИННКПП"] = TrimAll(TableRow.CounterpartyTIN)
		+ ?(ValueIsFilled(TableRow.CounterpartyCRTR),"/" + TrimAll(TableRow.CounterpartyCRTR), ""); //@NON-NLS-1
	CounterpartyStructure["НаименованиеПолное"] = TableRow.CounterpartyFullName;//@NON-NLS-1
	CounterpartyStructure["ПредставлениеКонтрагента"] = TableRow.CounterpartyFullName
		+ " (" +CounterpartyStructure["ИННКПП"] + ")";//@NON-NLS-1 @NON-NLS-3
	CounterpartyStructure["Клиент"] = TrimAll(TableRow.CounterpartyPartner.UUID());//@NON-NLS-1
	CounterpartyStructure["КПП"] = TableRow.CounterpartyCRTR;//@NON-NLS-1
	
	Return CounterpartyStructure;
EndFunction

Function InformationOnPartner(Val TableRow, UploadCompleteDossier)
	
	BlankID = BlankID();
	
	PartnerStructure = MobileApplicationSalesOrders.PartnerStructure();
	
	PartnerStructure.Ref							= TrimAll(TableRow.PartnerForExport.UUID());
	PartnerStructure.DeletionMark					= TableRow.PartnerDeletionMark;
	PartnerStructure.Description					= TableRow.PartnerDescription;
	PartnerStructure.Parent						= ?(ValueIsFilled(TableRow.PartnerParentReference),
															TrimAll(TableRow.PartnerParentReference.UUID()),
																BlankID);
	PartnerStructure.Code							= TableRow.PartnerCode;
	PartnerStructure["ERPКод"]						= PartnerStructure.Ref;//@NON-NLS-1
	
	PartnerStructure["ВидЦены"]						= BlankID;//@NON-NLS-1
	PartnerStructure["ВремяДоставкиПо"]				= TableRow.PartnerDeliveryTimeTo;//@NON-NLS-1
	PartnerStructure["ВремяДоставкиС"]				= TableRow.PartnerDeliveryTimeFrom;//@NON-NLS-1
	PartnerStructure["ОтгрузкаЗапрещена"]				= TableRow.PartnerShipmentProhibited;//@NON-NLS-1
	PartnerStructure["ПричинаДобавленияВСтопЛист"]	= TableRow.PartnerReasonForAddingToStopList;//@NON-NLS-1
	PartnerStructure["Самовывоз"]						= TableRow.PartnerPickup;//@NON-NLS-1
	PartnerStructure["Склад"]							= ?(ValueIsFilled(TableRow.PartnerWarehouseReference),
															TrimAll(TableRow.PartnerWarehouseReference.UUID()),
																BlankID);//@NON-NLS-1
	PartnerStructure["СтрокаПоиска"] 					= TrimAll(PartnerStructure.Description);//@NON-NLS-1
	PartnerStructure["ДополнительнаяИнформация"] 		= PartnerProfile(TableRow.PartnerForExport, UploadCompleteDossier);//@NON-NLS-1
	
	PartnerStructure["ДополнительнаяИнформацияПоДоставке"]	= TableRow.PartnerAdditionalInformationAboutDelivery;//@NON-NLS-1
	
	LinePaymentMethod = "";
	If ValueIsFilled(TableRow.PartnerPaymentMethodReference) Then
		FormOfPaymentIndex = Enums.PaymentForms.IndexOf(TableRow.PartnerPaymentMethodReference);
		FormOfPaymentObject = Metadata.Enums.PaymentForms.EnumValues.Get(FormOfPaymentIndex);//MetadataObjectEnum - 
		LinePaymentMethod = FormOfPaymentObject.Name;
	EndIf;
	PartnerStructure["ФормаОплаты"] = LinePaymentMethod;//@NON-NLS-1
	
	LocalObjectName = "CatalogTabularSectionRow.Партнеры.КонтактнаяИнформация"; //@NON-NLS-1
	WriteContactInformation(PartnerStructure, TableRow.PartnerForExport, 
		"Catalog.Partners.ContactInformation", 
		LocalObjectName);
	
	//+ ERP 2.2.
	//
	// These are the Attributes of the XDTO package ERP 2.1.
	//  The structure of the partner.Delete Address = "";
	//  Partner structure.Delete delivery addresss = "";
	//  Partner structure.Delete Contact Person = "";
	//  Partner structure.Delete Phone = "";
	//  Partner structure.Delete E-mail = "";
	//
	LocalObjectName = "CatalogTabularSectionRow.Партнеры.ДополнительныеРеквизиты"; //@NON-NLS-1
	RecordAdditionalDetails(PartnerStructure, TableRow.PartnerForExport,
			"Catalog.Partners.AdditionalAttributes",
			LocalObjectName);
	//- ERP 2.2.
	
	Return PartnerStructure;
EndFunction

Function InformationOnStatusOfCustomerOrders(SalesOrders)
	
	ResponseData_ = New Array;
	
	IBCustomerOrders = RequestResultForDocumentsCustomerOrder(SalesOrders);
	
	If IBCustomerOrders.IsEmpty() Then
		Return ResponseData_;
	EndIf;
	
	SelectionOfDocuments = IBCustomerOrders.Select();
	
	While SelectionOfDocuments.Next()Do
		
		IBClientOrder = SelectionOfDocuments;
		
		StatusString = Chars.NBSp;
		If ValueIsFilled(IBClientOrder.Status) Then
			StatusString = 
				MobileApplicationSalesOrdersCached.MatchingTypesCustomerOrderStatuses().Get(IBClientOrder.Status);
		EndIf;
		
		OrderState = New Structure;
		OrderState.Insert("State", Enums.SalesOrderStates.EmptyRef());
		OrderState.Insert("StateOverdue", False);
		OrderState.Insert("AmountOfDebt", 0);
		OrderState.Insert("AmountToPay", 0);
		
		StringState = Chars.NBSp;
		StateLink = Enums.SalesOrderStates.EmptyRef();
		
		If IBClientOrder.ThisIsOrderAsInvoice Then
			StateLink = Enums.SalesOrderStates.Closed;
		Else
			Documents.SalesOrder.CalculateStatus(IBClientOrder.Ref, IBClientOrder.Contract, OrderState);
			If ValueIsFilled(OrderState.State) Then
				StateLink = OrderState.State; 
			EndIf;
		EndIf;
		
		If ValueIsFilled(StateLink) Then
			StringState = 
				MobileApplicationSalesOrdersCached.MatchingStatusTypesOfCustomerOrders().Get(StateLink);
		EndIf;
		
		Structure = New Structure;
		Structure.Insert("ref", TrimAll(IBClientOrder.Ref.UUID()));
		Structure.Insert("Статус", TrimAll(StatusString)); //@NON-NLS-1
		Structure.Insert("Проведен", IBClientOrder.Posted); //@NON-NLS-1
		Structure.Insert("ПометкаУдаления", IBClientOrder.DeletionMark); //@NON-NLS-1
		Structure.Insert("Состояние", TrimAll(StringState)); //@NON-NLS-1
		Structure.Insert("Просрочен", OrderState.StateOverdue); //@NON-NLS-1
		Structure.Insert("ДатаОтгрузки", IBClientOrder.DateOfShipment); //@NON-NLS-1
		Structure.Insert("Изменен", False); //@NON-NLS-1
		
		PrintObjects = New ValueList;
		PrintObjects.Add(IBClientOrder.Ref);
		CurStructureOfTypes = New Map;
		CurStructureOfTypes.Insert("Document.SalesOrder", PrintObjects.UnloadValues());
		SpreadsheetDocument = DataProcessors.PrintOrderForGoodsServices.GeneratePrintedCustomerOrderForm(
			CurStructureOfTypes, PrintObjects, Undefined);
			
		For Each Drawing In SpreadsheetDocument.Drawings Do
			If Drawing.Name = "BarcodeIcon" Then
				Drawing.PictureSize = PictureSize.Stretch;
				Break;
			EndIf;
		EndDo;
		
		Structure.Insert("ПечатнаяФормаДокумента", New ValueStorage(SpreadsheetDocument, New Deflation(9))); //@NON-NLS-1
		
		Structure.Insert("СуммаДокументаУП", IBClientOrder.DocumentAmount); //@NON-NLS-1
		Structure.Insert("СуммаНДСДокументаУП", IBClientOrder.VATAmount); //@NON-NLS-1
		
		If IBClientOrder.SettlementProcedureContract Then
			AmountOfDebtUnderUPDocument = Min(IBClientOrder.DocumentAmount, OrderState.AmountToPay);
			If IBClientOrder.PaymentDueDateIsSet Then
				Structure.Insert("ДатаСледующегоПлатежа", IBClientOrder.PaymentDueDate); //@NON-NLS-1
			EndIf;
		Else
			AmountOfDebtUnderUPDocument = OrderState.AmountOfDebt;
			Structure.Insert("ДатаСледующегоПлатежа", NextPaymentDateForOrder(IBClientOrder.Ref)); //@NON-NLS-1
		EndIf;
		
		Structure.Insert("СуммаДолгаПоДокументуУП", AmountOfDebtUnderUPDocument); //@NON-NLS-1
		
		If IBClientOrder.PrepaymentAmountMan > 0 Then
			Structure.Insert("ДатаПредоплатыПоДокументу", OrderPrepaymentDate(IBClientOrder.Ref)); //@NON-NLS-1
			Structure.Insert("СуммаПредоплатыПоДокументу", IBClientOrder.PrepaymentAmountMan); //@NON-NLS-1
		EndIf;
		
		//+ UP 2.2.
		Structure.Insert("ДополнительныеРеквизиты"); //@NON-NLS-1
		LocalObjectName = "DocumentTabularSectionRow.SalesOrder.AdditionalAttributes";
		RecordAdditionalDetails(Structure, IBClientOrder.Ref,
			"Document.SalesOrder.AdditionalAttributes",
			LocalObjectName);
		//- ERP 2.2.
		
		ResponseData_.Add(Structure);
	EndDo;
	
	Return ResponseData_;
EndFunction

Function InformationOnStatusOfRequestsForReturns(RequestsForReturn)
	
	ResponseData_ = New Array;
	
	RequestsForInformationSecurityRefund = RequestResultForDocumentsRequestForRefund(RequestsForReturn);
	
	If RequestsForInformationSecurityRefund.IsEmpty() Then
		Return ResponseData_;
	EndIf;
	
	SelectionOfDocuments = RequestsForInformationSecurityRefund.Select();
	
	While SelectionOfDocuments.Next()Do
		
		RequestForInformationSecurityRefund = SelectionOfDocuments;
		
		StatusString = Chars.NBSp;
		If ValueIsFilled(RequestForInformationSecurityRefund.Status) Then
			StatusString = 
				MobileApplicationSalesOrdersCached.MatchingTypesStatusesOfRequestsForReturnOfGoodsFromCustomers().Get(RequestForInformationSecurityRefund.Status);
		EndIf;
		
		StateOfApplication = New Structure;
		StateOfApplication.Insert("State", Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.EmptyRef());
		StateOfApplication.Insert("AmountOfDebt", 0);
		StateOfApplication.Insert("AmountToPay", 0);
		
		Documents.RequestForReturnOfGoodsFromCustomer.CalculateStatus(RequestForInformationSecurityRefund.Ref,
			RequestForInformationSecurityRefund.Contract, StateOfApplication);
		
		StringState = Chars.NBSp;
		If ValueIsFilled(StateOfApplication.State) Then
			StringState = 
				MobileApplicationSalesOrdersCached.MatchingStatusTypesOfRefundRequests().Get(StateOfApplication.State);
		EndIf;
		
		Structure = New Structure;
		Structure.Insert("ref", TrimAll(RequestForInformationSecurityRefund.Ref.UUID()));
		Structure.Insert("Статус", TrimAll(StatusString)); //@NON-NLS-1
		Structure.Insert("Проведен", RequestForInformationSecurityRefund.Posted); //@NON-NLS-1
		Structure.Insert("ПометкаУдаления", RequestForInformationSecurityRefund.DeletionMark); //@NON-NLS-1
		Structure.Insert("Состояние", TrimAll(StringState)); //@NON-NLS-1
		Structure.Insert("ДатаПоступления", RequestForInformationSecurityRefund.DateOfReceipt); //@NON-NLS-1
		Structure.Insert("ДатаОтгрузки", RequestForInformationSecurityRefund.DateOfShipment); //@NON-NLS-1
		Structure.Insert("Изменен", False); //@NON-NLS-1
		
		PrintObjects = New ValueList;
		PrintObjects.Add(RequestForInformationSecurityRefund.Ref);
		CurStructureOfTypes = New Map;
		CurStructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintObjects.UnloadValues());
		SpreadsheetDocument =
			DataProcessors.PrintApplicationForReturnOfGoodsFromCustomer.GeneratePrintedApplicationFormForReturnOfGoodsFromClient(
				CurStructureOfTypes, PrintObjects, Undefined);
				
		For Each Drawing In SpreadsheetDocument.Drawings Do
			If Drawing.Name = "BarcodeIcon" Then
				Drawing.PictureSize = PictureSize.Stretch;
				Break;
			EndIf;
		EndDo;
		
		Structure.Insert("ПечатнаяФормаДокумента", New ValueStorage(SpreadsheetDocument, New Deflation(9))); //@NON-NLS-1
		
		Structure.Insert("СуммаДокументаУП", RequestForInformationSecurityRefund.DocumentAmount); //@NON-NLS-1
		Structure.Insert("СуммаНДСДокументаУП", RequestForInformationSecurityRefund.DocumentVATAmount); //@NON-NLS-1
		
		If RequestForInformationSecurityRefund.SettlementProcedureContract Then
			AmountOfDebtUnderUPDocument = Min(RequestForInformationSecurityRefund.DocumentAmount, StateOfApplication.AmountToPay);
		Else
			AmountOfDebtUnderUPDocument = StateOfApplication.AmountOfDebt;
		EndIf;
		Structure.Insert("СуммаДолгаПоДокументуУП", AmountOfDebtUnderUPDocument); //@NON-NLS-1
		
		//+ UP 2.2.
		Structure.Insert("ДополнительныеРеквизиты"); //@NON-NLS-1
		LocalObjectName = "DocumentTabularSectionRow.RequestForReturnOfGoodsFromCustomer.AdditionalAttributes";
		RecordAdditionalDetails(Structure, RequestForInformationSecurityRefund.Ref,
			"Document.RequestForReturnOfGoodsFromCustomer.AdditionalAttributes",
			LocalObjectName);
		//- ERP 2.2.
		
		ResponseData_.Add(Structure);
	EndDo;
	
	Return ResponseData_;
EndFunction

Function ArrayOfChanges(ExchangeNode, MessageNo, FilterChanges)
	
	// The data may already be unavailable by rights.
	SetPrivilegedMode(True);
	
	ArrayOfChanges = New Array;
	For Each Filter In FilterChanges Do
		ChangesSelection = ExchangePlans.SelectChanges(ExchangeNode, MessageNo, Filter);
		While ChangesSelection.Next() Do
			ArrayOfChanges.Add(ChangesSelection.Get());
		EndDo;
	EndDo;
	
	Return ArrayOfChanges;
EndFunction

Function NewComplianceOfMPObject(Val ProductsID, Val VariantID, Val PackagingsID)
	
	SetPrivilegedMode(True);
	
	ComplianceOfMPObject =
		InformationRegisters.CorrespondenceOfProductsOf1COrdersMobileApplication.CreateRecordManager();
	ComplianceOfMPObject.ProductsID	= ProductsID;
	ComplianceOfMPObject.VariantID	= VariantID;
	ComplianceOfMPObject.PackagingsID		= PackagingsID;
	ComplianceOfMPObject.MobileAppObjectID		= TrimAll(New UUID());
	
	ComplianceOfMPObject.Write(True);
	
	Return ComplianceOfMPObject.MobileAppObjectID;
EndFunction

Function NewSalesConditionExchangeNode(StructureAndTermsOfSales, SalesConditionID = Undefined)
	
	SetPrivilegedMode(True);
	
	MapRow = 
		InformationRegisters.ComplianceOfSalesTermsAndConditionsOf1COrdersMobileApplication.CreateRecordManager();
	MapRow.Organization	= StructureAndTermsOfSales.Organization;
	MapRow.PriceKind		= StructureAndTermsOfSales.PriceKind;
	MapRow.Partner		= StructureAndTermsOfSales.Partner;
	MapRow.Terms	= StructureAndTermsOfSales.Terms;
	MapRow.Counterparty	= StructureAndTermsOfSales.Counterparty;
	MapRow.Contract		= StructureAndTermsOfSales.Contract;
	If SalesConditionID = Undefined Then
		MapRow.SalesConditionID	= TrimAll(New UUID());
	Else
		MapRow.SalesConditionID	= SalesConditionID;
	EndIf;
	
	Try
		MapRow.Write(True);
		IDOfSalesCondition = MapRow.SalesConditionID;
	Except
		IDOfSalesCondition = BlankID();
	EndTry;
	
	Return IDOfSalesCondition;
EndFunction

Procedure ProcessObjectBeforeWritingToExchangePacket(Object)
	
	UsingTasks = Constants.UseJobsToSalesRepresentatives.Get();
	
	If UsingTasks =
		Enums.UseJobsToSalesRepresentatives.UsedForManagementBySalesRepresentatives Then
		Object.FillInDataOnAccountsReceivable();
		Object.AdditionalProperties.Insert("NotRegisterChanges", True);
		Object.Write();
	EndIf;
EndProcedure

Procedure ClearThoseNotIncludedInSelection(XMLWriter, ExchangeNode)
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	|	PartnersChanges.Ref AS PartnerToDelete
	|FROM
	|	Catalog.Partners.Changes AS PartnersChanges
	|WHERE
	|	VALUETYPE(PartnersChanges.Node) = TYPE(ExchangePlan.MobileApplicationSalesOrders)
	|	AND PartnersChanges.Node = &Node");
	
	Query.SetParameter("Node", ExchangeNode);
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	NotIncludedInSelection = Result.Select();
	
	While NotIncludedInSelection.Next() Do
		Data = NotIncludedInSelection.PartnerToDelete.GetObject();
		If ValueIsFilled(NotIncludedInSelection.PartnerToDelete) And Data = Undefined Then
			Data = New ObjectDeletion(NotIncludedInSelection.PartnerToDelete);
		EndIf;
		ExchangePlans.DeleteChangeRecords(ExchangeNode, Data);
		MobileApplicationSalesOrders.DataDeletion(Data);
		If TypeOf(Data) = Type("ObjectDeletion") Then
			XDTOSerializer.WriteXML(XMLWriter, Data);
		EndIf;
	EndDo;
EndProcedure

Function SalesRepresentativePriceList(ExchangeNode, PriceListFilters)
	
	PriceTable_ = DataForUploadingPriceLists(ExchangeNode, PriceListFilters);
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Metadata.InformationRegisters.ItemsPrices);
	ExchangePlans.DeleteChangeRecords(ExchangeNode, Metadata.InformationRegisters.ItemsPrices25);
	If PriceTable_.Count() = 0 Then
		Return PriceTable_;
	EndIf;
	UsePriceGroups = GetFunctionalOption("UsePriceGroups");
	UseCharacteristics = GetFunctionalOption("UseItemVariants");
	UsePackages = GetFunctionalOption("UseItemPackages");
	If PriceTable_.Columns.Find("PriceGroup") = Undefined Then
		PriceTable_.Columns.Add("PriceGroup", New TypeDescription("CatalogRef.PriceGroups"));
	EndIf;
	If PriceTable_.Columns.Find("CharacteristicReference") = Undefined Then
		PriceTable_.Columns.Add("CharacteristicReference",
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	If PriceTable_.Columns.Find("ItemVariantsAreUsed") = Undefined Then
		PriceTable_.Columns.Add("ItemVariantsAreUsed", New TypeDescription("Boolean"));
		PriceTable_.FillValues(UseCharacteristics, "ItemVariantsAreUsed");
	EndIf;
	
	If PriceTable_.Columns.Find("UsePackages") = Undefined Then
		PriceTable_.Columns.Add("UsePackages", New TypeDescription("Boolean"));
		PriceTable_.FillValues(UsePackages, "UsePackages");
	EndIf;
	
	BlankID = BlankID();
	
	For Each PriceListRow In PriceTable_ Do
		PriceListRow.ProductsID = TrimAll(PriceListRow.ProductsLink.UUID());
		PriceListRow.VariantID = ?(ValueIsFilled(PriceListRow.CharacteristicReference),
			TrimAll(PriceListRow.CharacteristicReference.UUID()), "");
		PriceListRow.PackagingsID = TrimAll(PriceListRow.PackagingRef.UUID());
		PriceListRow.PriceKind = TrimAll(PriceListRow.PriceTypeReference.UUID());
		PriceListRow.ProductKind = TrimAll(PriceListRow.ProductKindReference.UUID());
		PriceListRow.PriceGroup = ?(
			UsePriceGroups,
			TrimAll(PriceListRow.PriceGroupReference.UUID()),
			BlankID);
		PriceListRow.ProductsParent = TrimAll(PriceListRow.ProductsParentReference.UUID());
	EndDo;
	
	QueryText = MobileApplicationSalesOrders.RequestTextForDetailsOfPriceListObjects(False);
	Query = New Query(QueryText);
	Query.SetParameter("PriceTable_", PriceTable_);
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("RegistrationCountry", Constants.MainCountry.Get());
	GeneralPriceList = Query.Execute().Unload();
	
	MatchesOfProducts = GeneralPriceList.FindRows(New Structure("RecordProductCompliance", True));
	For Each PriceListRow In MatchesOfProducts Do
		PriceListRow.Products = IDOfMPObject(PriceListRow.ProductsID, PriceListRow.VariantID, "");
	EndDo;
	ConformityOfPackages_ = GeneralPriceList.FindRows(New Structure("RecordPackagingCompliance", True));
	For Each PriceListRow In ConformityOfPackages_ Do
		PriceListRow.Package =
			IDOfMPObject(PriceListRow.ProductsID, PriceListRow.VariantID, PriceListRow.PackagingsID);
	EndDo;
		
	UnloadingUnitOfMeasureAsPacking =
		GetFunctionalOption("UseJobsToManageSalesRepresentatives")
		And GetFunctionalOption("ItemizeJobsForSalesRepresentatives");
	
	If GeneralPriceList.Columns.Find("UnloadingUnitOfMeasureAsPacking") = Undefined Then
		GeneralPriceList.Columns.Add("UnloadingUnitOfMeasureAsPacking",  New TypeDescription("Boolean"));
		GeneralPriceList.FillValues(UnloadingUnitOfMeasureAsPacking, "UnloadingUnitOfMeasureAsPacking");
	EndIf;
	
	Return GeneralPriceList;
EndFunction

Procedure CheckForChanges(DocumentRef, Cancel)
	
	If TypeOf(DocumentRef) = Type("DocumentRef.SalesOrder") Then
		DocumentRefStatus = Common.ObjectAttributeValue(DocumentRef, "Status");
		
		If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
			If DocumentRefStatus = Enums.SalesOrderStatuses.ToSupply
				Or DocumentRefStatus = Enums.SalesOrderStatuses.ToShip
				Or DocumentRefStatus = Enums.SalesOrderStatuses.Closed Then
				Cancel = True;
			EndIf;
		Else
			If DocumentRefStatus = Enums.SalesOrderStatuses.Closed Then
				Cancel = True;
			EndIf;
		EndIf;
	ElsIf TypeOf(DocumentRef) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		DocumentRefStatus = Common.ObjectAttributeValue(DocumentRef, "Status");
		
		If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
			If DocumentRefStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply
				Or DocumentRefStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip
				Or DocumentRefStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed Then
				Cancel = True;
			EndIf;
		Else
			If DocumentRefStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed Then
				Cancel = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

Procedure CheckIfTaskCanBeChanged(JobForSalesRepresentative, ExchangeNode, Cancel)
	
	If ExchangePlans.IsChangeRecorded(ExchangeNode, JobForSalesRepresentative) Then
		Cancel = True;
	EndIf;
EndProcedure

Function BlankID()
	
	Return "00000000-0000-0000-0000-000000000000";
EndFunction

Function CustomImplementation(Val SalesOrder)
	
	CustomerInvoice = Documents.CustomerInvoice.EmptyRef();
	
	Query = New Query("SELECT DISTINCT TOP 2
	|	CustomerInvoice.Ref
	|INTO MOUTH
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.SalesOrder = &SalesOrder
	|	AND CustomerInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT TOP 2
	|	SalesOfGoodsServicesGoods.Ref
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|WHERE
	|	SalesOfGoodsServicesGoods.SalesOrder = &SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MOUTH.Ref
	|FROM
	|	MOUTH AS MOUTH
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP MOUTH");
	
	Query.SetParameter("SalesOrder", SalesOrder);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return CustomerInvoice;
	EndIf;
	
	Selection = Result.Unload().UnloadColumn("Ref");
	
	If Selection.Count() = 1 Then
		CustomerInvoice = Selection[0];
	EndIf;
	
	Return CustomerInvoice;
EndFunction

Function RequestResultForDocumentsCustomerOrder(Val SalesOrders)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	Goods.Ref AS OrderDocument,
	|	SUM(CASE
	|			WHEN Goods.Canceled
	|				THEN 0
	|			ELSE Goods.VATAmount
	|		END) AS DocumentVATAmount
	|INTO GoodsFromOrder
	|FROM
	|	Document.SalesOrder.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&SalesOrders)
	|
	|GROUP BY
	|	Goods.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentSalesOrder.Ref AS Ref,
	|	DocumentSalesOrder.Contract AS Contract,
	|	DocumentSalesOrder.DeletionMark AS DeletionMark,
	|	DocumentSalesOrder.Posted AS Posted,
	|	DocumentSalesOrder.Status AS Status,
	|	DocumentSalesOrder.DateOfShipment AS DateOfShipment,
	|	DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue + DocumentSalesOrder.AmountOfPrepaymentBeforeShipment AS PrepaymentAmountMan,
	|	CASE
	|		WHEN DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SettlementProcedureContract,
	|	DocumentSalesOrder.DocumentAmount,
	|	DocumentSalesOrder.Contract.PaymentDueDateIsSet AS PaymentDueDateIsSet,
	|	DocumentSalesOrder.Contract.PaymentDueDate AS PaymentDueDate,
	|	DocumentSalesOrder.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
	|	ISNULL(GoodsFromOrder.DocumentVATAmount, 0) AS VATAmount
	|FROM
	|	Document.SalesOrder AS DocumentSalesOrder
	|		LEFT JOIN GoodsFromOrder AS GoodsFromOrder
	|		ON (GoodsFromOrder.OrderDocument = DocumentSalesOrder.Ref)
	|WHERE
	|	DocumentSalesOrder.Ref IN(&SalesOrders)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsFromOrder");
	
	Query.SetParameter("SalesOrders", SalesOrders);
	
	Return Query.Execute();
EndFunction

Function RequestResultForDocumentsRequestForRefund(Val RequestsForReturn)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	Goods.Ref AS Request,
	|	SUM(CASE
	|			WHEN Goods.Canceled
	|				THEN 0
	|			ELSE Goods.VATAmount
	|		END) AS DocumentVATAmount
	|INTO ApplicationProducts_
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Goods
	|WHERE
	|	Goods.Ref IN(&RequestsForReturn)
	|
	|GROUP BY
	|	Goods.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentReturnRequest.Ref AS Ref,
	|	DocumentReturnRequest.Contract AS Contract,
	|	DocumentReturnRequest.DeletionMark AS DeletionMark,
	|	DocumentReturnRequest.Posted AS Posted,
	|	DocumentReturnRequest.Status AS Status,
	|	DocumentReturnRequest.DateOfReceipt AS DateOfReceipt,
	|	DocumentReturnRequest.DateOfShipment AS DateOfShipment,
	|	CASE
	|		WHEN DocumentReturnRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SettlementProcedureContract,
	|	DocumentReturnRequest.DocumentAmount,
	|	ISNULL(ApplicationProducts_.DocumentVATAmount, 0) AS DocumentVATAmount
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentReturnRequest
	|		LEFT JOIN ApplicationProducts_ AS ApplicationProducts_
	|		ON (ApplicationProducts_.Request = DocumentReturnRequest.Ref)
	|WHERE
	|	DocumentReturnRequest.Ref IN(&RequestsForReturn)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ApplicationProducts_");
	
	Query.SetParameter("RequestsForReturn", RequestsForReturn);
	
	Return Query.Execute();
EndFunction

Function RequestResultForPackaging(Val PackagingUnitOfMeasure, Val Products)
	
	Query = New Query(
	"SELECT ALLOWED
	|	ProductPackages.DeletionMark AS DeletionMark,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
	|	ProductPackages.Parent AS Parent,
	|	ProductPackages.UnitOfMeasure AS UnitOfMeasure,
	|	ProductPackages.UnitOfMeasure.DeletionMark AS UnitOfMeasureDeletionMark,
	|	ProductPackages.UnitOfMeasure.Code AS UnitOfMeasureCode,
	|	ProductPackages.UnitOfMeasure.Description AS UnitOfMeasurementName,
	|	ProductPackages.UnitOfMeasure.PredefinedDataName AS UnitNameOfPredefinedData,
	|	ProductPackages.UnitOfMeasure.DescriptionFull AS UnitOfMeasurementFullName,
	|	ProductPackages.UnitOfMeasure.InternationalAbbreviation AS UnitOfMeasureInternationalAbbreviation,
	|	&QueryTextPackageWeight AS Weight,
	|	ProductPackages.WeightUnitOfMeasure AS WeightUnitOfMeasure,
	|	ProductPackages.WeightUnitOfMeasure.DeletionMark AS WeightUnitOfMeasureDeletionMark,
	|	ProductPackages.WeightUnitOfMeasure.Code AS WeightUnitCode_,
	|	ProductPackages.WeightUnitOfMeasure.Description AS WeightUnitName_,
	|	ProductPackages.WeightUnitOfMeasure.PredefinedDataName AS WeightUnitNameOfPredefinedData,
	|	ProductPackages.WeightUnitOfMeasure.DescriptionFull AS WeightUnitFullName_,
	|	ProductPackages.WeightUnitOfMeasure.InternationalAbbreviation AS WeightUnitOfMeasurementInternationalAbbreviation,
	|	Products.UnitOfMeasure AS UnitOfProductMeasurement_,
	|	Products.WeightUnitOfMeasure AS WeightUnit,
	|	CASE
	|		WHEN Products.WeightDenominator = 0
	|			THEN 0
	|		ELSE Products.WeightNumerator / Products.WeightDenominator
	|	END AS UnitWeight_
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		INNER JOIN Catalog.Products AS Products
	|		ON (Products.Ref = &Products)
	|			AND (ProductPackages.Ref = &PackagingUnitOfMeasure)");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages", "Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackageWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"ProductPackages", "Products"));
		
	Query.SetParameter("PackagingUnitOfMeasure", PackagingUnitOfMeasure);
	Query.SetParameter("Products", Products);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection;
EndFunction

Function NextPaymentDateForOrder(Val Ref)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(BEGINOFPERIOD(SalesOrder.DateOfShipment, DAY)) AS DateOfShipment,
	|	MAX(ISNULL(SalesOrderPaymentScheduleSteps.PaymentDate, DATETIME(1, 1, 1))) AS PastPaymentDate,
	|	MAX(ISNULL(CustomerOrderStagesOfThePaymentSchedule1.PaymentDate, DATETIME(1, 1, 1))) AS NextPaymentDate_
	|INTO DocumentDates
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		LEFT JOIN Document.SalesOrder.PaymentScheduleSteps AS SalesOrderPaymentScheduleSteps
	|		ON (SalesOrderPaymentScheduleSteps.Ref = SalesOrder.Ref)
	|			AND (SalesOrderPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned))
	|			AND (SalesOrderPaymentScheduleSteps.PaymentDate <= BEGINOFPERIOD(&CurrentDate, DAY))
	|		LEFT JOIN Document.SalesOrder.PaymentScheduleSteps AS CustomerOrderStagesOfThePaymentSchedule1
	|		ON (CustomerOrderStagesOfThePaymentSchedule1.Ref = SalesOrder.Ref)
	|			AND (CustomerOrderStagesOfThePaymentSchedule1.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned))
	|			AND (CustomerOrderStagesOfThePaymentSchedule1.PaymentDate > BEGINOFPERIOD(&CurrentDate, DAY))
	|WHERE
	|	SalesOrder.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NOT DocumentDates.NextPaymentDate_ = DATETIME(1, 1, 1)
	|			THEN DocumentDates.NextPaymentDate_
	|		ELSE CASE
	|				WHEN NOT DocumentDates.PastPaymentDate = DATETIME(1, 1, 1)
	|					THEN DocumentDates.PastPaymentDate
	|				ELSE DocumentDates.DateOfShipment
	|			END
	|	END AS NextPaymentDate_
	|FROM
	|	DocumentDates AS DocumentDates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DocumentDates";
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Selection.Next();
	
	Return Selection.NextPaymentDate_;
EndFunction

Function OrderPrepaymentDate(Val Ref)
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	MAX(BEGINOFPERIOD(SalesOrder.Date, DAY)) AS DocumentDate,
	|	MAX(ISNULL(SalesOrderPaymentScheduleSteps.PaymentDate, DATETIME(1, 1, 1))) AS PrepaymentDate
	|INTO DocumentDates
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		LEFT JOIN Document.SalesOrder.PaymentScheduleSteps AS SalesOrderPaymentScheduleSteps
	|		ON (SalesOrderPaymentScheduleSteps.Ref = SalesOrder.Ref)
	|			AND (SalesOrderPaymentScheduleSteps.PaymentOption IN (&PaymentOptions))
	|WHERE
	|	SalesOrder.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NOT DocumentDates.PrepaymentDate = DATETIME(1, 1, 1)
	|			THEN DocumentDates.PrepaymentDate
	|		ELSE DocumentDates.DocumentDate
	|	END AS PrepaymentDate
	|FROM
	|	DocumentDates AS DocumentDates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DocumentDates";
	
	PaymentOptions = New Array;
	PaymentOptions.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision);
	PaymentOptions.Add(Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment);
	Query.SetParameter("PaymentOptions", PaymentOptions);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Selection.Next();
	
	Return Selection.PrepaymentDate;
EndFunction

Function AgreementWithClientOnOrganizationAndTypeOfPrices(TableRow)
	
	AgreementLine_ = Undefined;
	
	ARAPCurrency = MobileApplicationSalesOrdersCached.CurrencyOfOrders();
	
	If GetFunctionalOption("UseCustomerContracts")
			And TableRow.ContractsAreUsed Then
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			ContractIsObligatory = True;
		Else
			ContractIsObligatory = False;
		EndIf;
	Else
		ContractIsObligatory = False;
	EndIf;
	
	If ContractIsObligatory And Not ValueIsFilled(TableRow.Contract) Then
		Return AgreementLine_;
	EndIf;
	
	AgreementLine_ = MobileApplicationSalesOrders.StructureOfContract();
	
	ThereIsContract = ValueIsFilled(TableRow.Contract);
	
	Terms = TableRow.Terms;
	
	If Not ValueIsFilled(TableRow.SalesConditionID) Then
		StructureAndTermsOfSales = New Structure;
		StructureAndTermsOfSales.Insert("Organization",	TableRow.Organization);
		StructureAndTermsOfSales.Insert("PriceKind",		TableRow.PriceKind);
		StructureAndTermsOfSales.Insert("Partner",		TableRow.PartnerForExport);
		StructureAndTermsOfSales.Insert("Terms",		TableRow.Terms);
		StructureAndTermsOfSales.Insert("Counterparty",		TableRow.CounterpartyRef);
		StructureAndTermsOfSales.Insert("Contract",		?(ThereIsContract, TableRow.Contract,
			Catalogs.CounterpartyContracts.EmptyRef()));
		AgreementLine_.ref = IDOfSalesCondition(StructureAndTermsOfSales);
		TableRow.SalesConditionID = AgreementLine_.ref;
	Else
		AgreementLine_.ref = TableRow.SalesConditionID;
	EndIf;
	
	AgreementLine_.DeletionMark = ?(ThereIsContract, TableRow.ContractDeletionMark
		Or TableRow.TermsDeletionMark Or TableRow.ContractDeletionRequired, TableRow.TermsDeletionMark);
		
	PresentationOfContract = ?(ThereIsContract And ValueIsFilled(TableRow.ContractName_),
		TableRow.ContractName_, TableRow.AgreementName);
	
	AgreementLine_.Description = StrTemplate(NStr("vi = '%1 (%2)';
													|ru = '%1 (%2)';
													|en = '%1 (%2)'; fa = '%1 (%2)';
													|it = '%1 (%2)';
													|pl = '%1 (%2)';
													|tr = '%1 (%2)'"),
		PresentationOfContract, TrimAll(TableRow.CounterpartyRef));
	AgreementLine_["ERPКодДоговора"] = TrimAll(?(ThereIsContract, TableRow.Contract.UUID(),
		BlankID())); //@NON-NLS-1
	AgreementLine_["ERPКодСоглашения"] = TrimAll(Terms.UUID()); //@NON-NLS-1
	AgreementLine_["ВалютаВзаиморасчетов"] = TrimAll(ARAPCurrency.UUID()); //@NON-NLS-1
	AgreementLine_["ВидЦены"] = TrimAll(TableRow.PriceKind.UUID()); //@NON-NLS-1
	AgreementLine_["Дата"] = ?(ThereIsContract And ValueIsFilled(TableRow.ContractDate), TableRow.ContractDate,
		TableRow.AgreementDate); //@NON-NLS-1
	AgreementLine_["Действует"] = TableRow.AgreementIsValid; //@NON-NLS-1
	AgreementLine_["Клиент"] = TrimAll(TableRow.PartnerForExport.UUID()); //@NON-NLS-1
	AgreementLine_["Комиссия"] = TableRow.AgreementCommission; //@NON-NLS-1
	AgreementLine_["Контрагент"] = TrimAll(TableRow.CounterpartyRef.UUID()); //@NON-NLS-1
	AgreementLine_["Номер"] = ?(ThereIsContract And ValueIsFilled(TableRow.ContractNumber_), TableRow.ContractNumber_,
		TableRow.AgreementNumber); //@NON-NLS-1
	AgreementLine_["Организация"] = TrimAll(TableRow.Organization.UUID()); //@NON-NLS-1
	AgreementLine_["Пояснение"] =
		StrTemplate(NStr("vi = '%1 (%2, %3, %4)';
						|ru = '%1 (%2, %3, %4)';
						|en = '%1 (%2, %3, %4)'; fa = '%1 (%2, %3, %4)';
						|it = '%1 (%2, %3, %4)';
						|pl = '%1 (%2, %3, %4)';
						|tr = '%1 (%2, %3, %4)'"),
		PresentationOfContract, TrimAll(TableRow.CounterpartyRef),
			TrimAll(TableRow.Organization), TrimAll(TableRow.PriceKind)); //@NON-NLS-1
	MultipleWarehousesAreUsed = GetFunctionalOption("UseSeveralWarehouses");
	If MultipleWarehousesAreUsed Then
		AgreementLine_["Склад"] = TrimAll(TableRow.AgreementWarehouse.UUID()); //@NON-NLS-1
	Else
		AgreementWarehouse = Catalogs.Warehouses.DefaultWarehouse();
		AgreementLine_["Склад"] = TrimAll(AgreementWarehouse.UUID()); //@NON-NLS-1
	EndIf;
	AgreementLine_["Типовое"] = TableRow.StandardAgreement; //@NON-NLS-1
	AgreementLine_["ЕстьУточнениеЦен"] = TableRow.ThereIsPriceSpecification; //@NON-NLS-1
	If GetFunctionalOption("UseCustomerContracts") Then
		AgreementLine_["ИспользуютсяДоговорыКонтрагентов"] = TableRow.ContractsAreUsed; //@NON-NLS-1
	Else
		AgreementLine_["ИспользуютсяДоговорыКонтрагентов"] = False; //@NON-NLS-1
	EndIf;
	UniqueKey_ = AgreementLine_["Организация"] + "/"
		+ AgreementLine_["Контрагент"] + "/"
		+ AgreementLine_["ВалютаВзаиморасчетов"] + "/"
		+ AgreementLine_["ВидЦены"] + "/"
		+ AgreementLine_["Склад"] + "/"
		+ Format(AgreementLine_["Комиссия"], "BF=0; BT=1"); //@NON-NLS-1 @NON-NLS-3 @NON-NLS-5 @NON-NLS-7 @NON-NLS-9 @NON-NLS-11
		
	AgreementLine_["УникальныйКлюч"] = UniqueKey_; //@NON-NLS-1
	LinePaymentMethod = "";
	If ValueIsFilled(TableRow.PartnerPaymentMethodReference) Then
		LinePaymentMethod = MobileApplicationSalesOrdersCached.MatchingPaymentFormTypes().Get(TableRow.PartnerPaymentMethodReference);
	EndIf;
	AgreementLine_["ФормаОплаты"] = LinePaymentMethod; //@NON-NLS-1
	
	AgreementLine_["РасчетыПоДоговору"] = TableRow.SettlementsUnderContract; //@NON-NLS-1
	AgreementLine_["СуммаДолгаПоДоговору"] = TableRow.DebtAmountUnderTheContract; //@NON-NLS-1
	
	Return AgreementLine_;
EndFunction

Function ProductCompliance(ProductsID)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ProductCompliance.ProductsID,
	|	ProductCompliance.VariantID,
	|	ProductCompliance.PackagingsID
	|FROM
	|	InformationRegister.CorrespondenceOfProductsOf1COrdersMobileApplication AS ProductCompliance
	|WHERE
	|	ProductCompliance.MobileAppObjectID = &ProductsID";
	
	Query.SetParameter("ProductsID", ProductsID);
	
	Result = Query.Execute();
	
	MPObject = Undefined;
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		MPObject = Selection;
	Else
		ProductYouAreLookingFor = Catalogs.Products.GetRef(New UUID(ProductsID));
		If Not ProductYouAreLookingFor.GetObject() = Undefined Then
			MPObject = New Structure("ProductsID, VariantID, PackagingsID", ProductsID, "", "");
		EndIf;
	EndIf;
	
	Return MPObject;
EndFunction

Function ComplianceOfMPObject(Val ProductsID, Val VariantID, Val PackagingsID)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ProductCompliance.MobileAppObjectID AS MPObject
	|FROM
	|	InformationRegister.CorrespondenceOfProductsOf1COrdersMobileApplication AS ProductCompliance
	|WHERE
	|	ProductCompliance.ProductsID = &ProductsID
	|	AND ProductCompliance.VariantID = &VariantID
	|	AND ProductCompliance.PackagingsID = &PackagingsID";
	
	Query.SetParameter("ProductsID", ProductsID);
	Query.SetParameter("VariantID", VariantID);
	Query.SetParameter("PackagingsID", PackagingsID);
	
	Result = Query.Execute();
	
	MPObject = Undefined;
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		MPObject = Selection.MPObject;
	EndIf;
	
	Return MPObject;
EndFunction

Function AgreementCompliance(StructureAndTermsOfSales)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ComplianceWithSalesConditions_.SalesConditionID AS SalesConditionID
	|FROM
	|	InformationRegister.ComplianceOfSalesTermsAndConditionsOf1COrdersMobileApplication AS ComplianceWithSalesConditions_
	|WHERE
	|	ComplianceWithSalesConditions_.Organization = &Organization
	|	AND CASE
	|			WHEN &PriceTypeSpecified
	|				THEN ComplianceWithSalesConditions_.PriceKind = &PriceKind
	|			ELSE TRUE
	|		END
	|	AND ComplianceWithSalesConditions_.Partner = &Partner
	|	AND ComplianceWithSalesConditions_.Terms = &Terms
	|	AND ComplianceWithSalesConditions_.Counterparty = &Counterparty
	|	AND ComplianceWithSalesConditions_.Contract = &Contract";
	
	
	Query.SetParameter("Organization", StructureAndTermsOfSales.Organization);
	Query.SetParameter("PriceTypeSpecified", ValueIsFilled(StructureAndTermsOfSales.PriceKind));
	Query.SetParameter("PriceKind", StructureAndTermsOfSales.PriceKind);
	Query.SetParameter("Partner", StructureAndTermsOfSales.Partner);
	Query.SetParameter("Terms", StructureAndTermsOfSales.Terms);
	Query.SetParameter("Counterparty", StructureAndTermsOfSales.Counterparty);
	Query.SetParameter("Contract", StructureAndTermsOfSales.Contract);
	
	Result = Query.Execute();
	
	SalesConditionID = Undefined;
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		SalesConditionID = Selection.SalesConditionID;
	EndIf;
	
	Return SalesConditionID;
EndFunction

Function ComplianceWithSalesConditions_1(SalesConditionID)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ComplianceWithSalesConditions_.Organization,
	|	ComplianceWithSalesConditions_.PriceKind,
	|	ComplianceWithSalesConditions_.Partner,
	|	ComplianceWithSalesConditions_.Terms,
	|	ComplianceWithSalesConditions_.Counterparty,
	|	ComplianceWithSalesConditions_.Contract
	|FROM
	|	InformationRegister.ComplianceOfSalesTermsAndConditionsOf1COrdersMobileApplication AS ComplianceWithSalesConditions_
	|WHERE
	|	ComplianceWithSalesConditions_.SalesConditionID = &SalesConditionID";
	
	
	Query.SetParameter("SalesConditionID", SalesConditionID);
	
	Result = Query.Execute();
	
	SalesConditionID = Undefined;
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		SalesConditionID = Selection;
	EndIf;
	
	Return SalesConditionID;
EndFunction

Function StructureOfAgreementAgreement(Val SalesConditionID)
	
	Structure = New Structure("Contract, Terms, BusinessOperation");
	ConditionString_ = ComplianceWithSalesConditions_1(SalesConditionID);
	
	If ConditionString_ = Undefined Then
		Return Structure;
	EndIf;
	
	Structure.Contract		= ConditionString_.Contract;
	Structure.Terms	= ConditionString_.Terms;
	
	If ValueIsFilled(Structure.Contract) Then
		BusinessOperation = Common.ObjectAttributeValue(Structure.Contract, "BusinessOperation");
	Else
		Structure.Contract = Catalogs.CounterpartyContracts.EmptyRef();
		If ValueIsFilled(Structure.Terms) Then
			BusinessOperation = Common.ObjectAttributeValue(Structure.Terms, "BusinessOperation");
		Else
			Structure.Terms = Catalogs.TermsOfSale.EmptyRef();
			BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		EndIf;
	EndIf;
	
	Structure.BusinessOperation = BusinessOperation;
	
	Return Structure;
EndFunction

Function StructureProductDescriptionPackaging(Val IDProducts, Val PackagingID)
	
	Structure = New Structure;
	Structure.Insert("Products", Catalogs.Products.EmptyRef());
	Structure.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	Structure.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	Structure.Insert("PackageFactor", 0);
	Structure.Insert("OperationService", False);
	
	ProductsRow = ProductCompliance(IDProducts);
	
	If ProductsRow = Undefined Then
		Return Structure;
	EndIf;
	
	Products = Catalogs.Products.GetRef(
		New UUID(ProductsRow.ProductsID));
	
	If Products.GetObject() = Undefined Then
		Structure.Insert("Products", Catalogs.Products.EmptyRef());
		Return Structure;
	EndIf;
	
	Structure.Insert("Products", Products);
	
	ProductAttributes = 
		Common.ObjectAttributesValues(Products, "ItemsType, UsePackages, PackagingGroup");
	
	ItemsType = ProductAttributes.ItemsType;
	
	If Not ItemsType = Enums.ItemsTypes.OwnGoods
		And Not ItemsType = Enums.ItemsTypes.ReusablePackage
		And Not ItemsType = Enums.ItemsTypes.Set Then
		Structure.Insert("OperationService", True);
	EndIf;
	
	Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
	
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Products);
	
	If GetFunctionalOption("UseItemVariants") Then
		If ItemVariantsAreUsed Then
			If Not ProductsRow = Undefined Then
				Characteristic = Catalogs.ItemsCharacteristics.GetRef(
					New UUID(ProductsRow.VariantID));
			EndIf;
		Else
			Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
		EndIf;
	EndIf;
	
	If ValueIsFilled(Characteristic) Then
		If Not Characteristic.GetObject() = Undefined Then
			Structure.Insert("Characteristic", Characteristic);
		EndIf;
	Else
		Structure.Insert("Characteristic", Characteristic);
	EndIf;
	
	If Not GetFunctionalOption("UseItemPackages") 
		Or Not ProductAttributes.UsePackages
		Or Not ValueIsFilled(ProductAttributes.PackagingGroup) Then
		Return Structure;
	EndIf;
	
	Package = Undefined;
	
	If ProductAttributes.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem
		And Not ItemVariantsAreUsed Then
		Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(New UUID(PackagingID));
	Else
		PackingString = ProductCompliance(PackagingID);
		If Not PackingString = Undefined Then
			Package = Catalogs.PackagesAndUnitsOfMeasure.GetRef(
				New UUID(PackingString.PackagingsID));
		EndIf;
	EndIf;
	
	If Not Package = Undefined And Not Package.GetObject() = Undefined Then
		Structure.Insert("Package", Package);
		Structure.Insert("PackageFactor",
			Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package.Ref, Products));
	EndIf;
	
	Return Structure;
EndFunction

Function GivenDocumentNumber(Number, InformationSecurityNumber)
	
	NewInformationSecurityNumber = "";
	
	NumberLength = StrLen(InformationSecurityNumber);
	EmptyNumber = StringFunctionsClientServer.GenerateCharacterString("0", NumberLength);
	NumberWithoutPrefix = ObjectsPrefixesClientServer.NumberForPrinting(InformationSecurityNumber);
	
	EmptyInformationSecurityNumber = Left(Left(InformationSecurityNumber, NumberLength - StrLen(NumberWithoutPrefix))
		+ EmptyNumber, NumberLength);
	
	NewInformationSecurityNumber = Left(EmptyInformationSecurityNumber, NumberLength - StrLen(Number)) + Number;
	
	Return NewInformationSecurityNumber;
EndFunction

Function FoundPowerOfAttorney(TheStructureOfTheSearch)
	
	Query = New Query();
	Query.Text = "SELECT
	|	IssuedLetterOfAuthority.Ref
	|FROM
	|	Document.IssuedLetterOfAuthority AS IssuedLetterOfAuthority
	|WHERE
	|	IssuedLetterOfAuthority.AuthorizationLetterType = VALUE(Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash)
	|	AND IssuedLetterOfAuthority.Number = &Number
	|	AND YEAR(IssuedLetterOfAuthority.Date) = YEAR(&Date)
	|	AND IssuedLetterOfAuthority.Partner = &Partner
	|	AND IssuedLetterOfAuthority.Person = &Person";
	
	Query.SetParameter("Number", TheStructureOfTheSearch.Number);
	Query.SetParameter("Partner", TheStructureOfTheSearch.Partner);
	Query.SetParameter("Date", TheStructureOfTheSearch.Date);
	Query.SetParameter("Person", TheStructureOfTheSearch.Person);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Documents.IssuedLetterOfAuthority.EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Ref;
EndFunction

Procedure CreateUpdatePowerOfAttorney(PaymentStructure, Message)
	
	CreatePowerOfAttorney = False;
	
	MobilePayment = PaymentStructure.MobilePayment;
	
	PowerOfAttorneyOrganization = Catalogs.Companies.GetRef(
		New UUID(MobilePayment.Организация));
	PowerOfAttorneyPartner = Catalogs.Partners.GetRef(
		New UUID(MobilePayment.Клиент));
	PowerOfAttorneyIndividual = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	
	PowerOfAttorneyNumber = ObjectsPrefixesClientServer.NumberForPrinting(MobilePayment.НомерВходящегоДокумента);
	PowerOfAttorneyDate = MobilePayment.ДатаВходящегоДокумента;
	
	LetterOfAuthority = Documents.IssuedLetterOfAuthority.GetRef(New UUID(MobilePayment.ref));
	IssuedLetterOfAuthority = LetterOfAuthority.GetObject();
	
	If IssuedLetterOfAuthority = Undefined Then
		PowerOfAttorneyForOrganization = Documents.IssuedLetterOfAuthority.FindByAttribute("Organization", PowerOfAttorneyOrganization);
		If PowerOfAttorneyForOrganization.IsEmpty() Then
			CreatePowerOfAttorney = True;
		Else
			OrganizationNumber = Common.ObjectAttributeValue(PowerOfAttorneyForOrganization, "Number");
			PowerOfAttorneyNumber_ = GivenDocumentNumber(PowerOfAttorneyNumber, OrganizationNumber);
			TheStructureOfTheSearch = New Structure("Number, Date, Partner, Person");
			TheStructureOfTheSearch.Number = PowerOfAttorneyNumber_;
			TheStructureOfTheSearch.Date = PowerOfAttorneyDate;
			TheStructureOfTheSearch.Person = PowerOfAttorneyIndividual;
			TheStructureOfTheSearch.Partner = PowerOfAttorneyPartner;
			PowerOfAttorneyLink = FoundPowerOfAttorney(TheStructureOfTheSearch);
			If PowerOfAttorneyLink.IsEmpty() Then
				CreatePowerOfAttorney = True;
			Else
				IssuedLetterOfAuthority = PowerOfAttorneyLink.GetObject();
			EndIf;
		EndIf;
	EndIf;
	
	If CreatePowerOfAttorney Then
		IssuedLetterOfAuthority = Documents.IssuedLetterOfAuthority.CreateDocument();
		IssuedLetterOfAuthority.SetNewObjectRef(LetterOfAuthority);
		IssuedLetterOfAuthority.Date = PowerOfAttorneyDate;
		IssuedLetterOfAuthority.Organization = PowerOfAttorneyOrganization;
		IssuedLetterOfAuthority.Status = Enums.StatusesOfAuthorizationLetters.NotIssued;
		IssuedLetterOfAuthority.SetNewNumber();
		PowerOfAttorneyNumber_ = GivenDocumentNumber(PowerOfAttorneyNumber, IssuedLetterOfAuthority.Number);
		// Let's check if it is possible to create a power of attorney with a number from the application.
		// If there is a power of attorney with such a number, then we do not set the number of the new power of attorney, we leave it created automatically.
		PowerOfAttorneyLink = Documents.IssuedLetterOfAuthority.FindByNumber(PowerOfAttorneyNumber_, PowerOfAttorneyDate);
		If PowerOfAttorneyLink.IsEmpty() Then
			IssuedLetterOfAuthority.Number = PowerOfAttorneyNumber_;
		EndIf;
	EndIf;
	
	SalesOrder = 
		Documents.SalesOrder.GetRef(New UUID(MobilePayment.ДокументОснование));
	Try
		OrderObject = SalesOrder.GetObject();
	Except
		OrderObject = Undefined;
	EndTry;
	FillInFromOrder = True;
	If OrderObject = Undefined Then
		// There is no order in the IB, we fill in the payment details.
		FillInFromOrder = False;
	EndIf;
	If FillInFromOrder Then
		IssuedLetterOfAuthority.Fill(SalesOrder);
	Else
		IssuedLetterOfAuthority.Partner = PowerOfAttorneyPartner;
		IssuedLetterOfAuthority.Person = PowerOfAttorneyIndividual;
		IssuedLetterOfAuthority.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash;
		IssuedLetterOfAuthority.Currency = Catalogs.Currencies.GetRef(
			New UUID(MobilePayment.Валюта));
		IssuedLetterOfAuthority.Counterparty = Catalogs.Counterparties.GetRef(
			New UUID(MobilePayment.Контрагент));
	EndIf;
	
	IssuedLetterOfAuthority.DocumentAmount = MobilePayment.СуммаДокумента;
	
	PowerOfAttorneyComment = StrTemplate(NStr("vi = 'Thanh toán theo giấy đề nghị số %1 ngày %2';
												|ru = 'Оплата по доверенности №%1 от %2';
												|en = 'Payment under the authorization letter No. %1 of %2'; fa = 'Payment under the authorization letter No. %1 of %2';
												|it = 'Pagamento secondo gli accordi №%1 da %2';
												|pl = 'Płatność na podstawie pełnomocnictwa nr%1 z dn. %2';
												|tr = '%1 sayılı %2 tarihli yetkilendirilmiş ödeme'"),
		PowerOfAttorneyNumber, PowerOfAttorneyDate);
	IssuedLetterOfAuthority.Comment = PowerOfAttorneyComment;
	
	If Not ValueIsFilled(IssuedLetterOfAuthority.Counterparty) Then
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(IssuedLetterOfAuthority.Partner,
			IssuedLetterOfAuthority.Counterparty);
	EndIf;
	
	Posted = True;
	Try
		IssuedLetterOfAuthority.DataExchange.Load = True;
		IssuedLetterOfAuthority.Write(DocumentWriteMode.Write);
	Except
		Posted = False;
	EndTry;
	
	WriteMode = ?(Posted, DocumentWriteMode.Posting,
		?(IssuedLetterOfAuthority.Posted,
			DocumentWriteMode.UndoPosting, DocumentWriteMode.Write));
	Try
		IssuedLetterOfAuthority.DataExchange.Load = False;
		IssuedLetterOfAuthority.Write(WriteMode, DocumentPostingMode.Regular);
	Except
		Posted = False;
	EndTry;
	
	Structure = New Structure;
	Structure.Insert("ref", MobilePayment.ref);
	Structure.Insert("Posted", Posted);
	Message.Add(Structure);
EndProcedure

Procedure CreateUpdateIncomingCashOrder(PaymentStructure, Message)
	
	MobilePayment = PaymentStructure.MobilePayment;
	ArticleDDSCash = PaymentStructure.ArticleDDSCash;
	CashAccount = PaymentStructure.CashAccount;
	
	OCR = Documents.CashAccountReceiptNote.GetRef(New UUID(MobilePayment.ref));
	CashAccountReceiptNote = OCR.GetObject();
	If CashAccountReceiptNote = Undefined Then
		CashAccountReceiptNote = Documents.CashAccountReceiptNote.CreateDocument();
		CashAccountReceiptNote.SetNewObjectRef(OCR);
		CashAccountReceiptNote.Date = MobilePayment.Date;
	Else
		CashAccountReceiptNote.ARAPDetails.Clear();
	EndIf;
	
	SalesOrder =
		Documents.SalesOrder.GetRef(New UUID(MobilePayment.ДокументОснование));
	Try
		OrderObject = SalesOrder.GetObject();
	Except
		OrderObject = Undefined;
	EndTry;
	FillInFromOrder = True;
	If OrderObject = Undefined Then
		// There is no order in the IB, we fill in the payment details.
		FillInFromOrder = False;
	EndIf;
	If FillInFromOrder Then
		OrderDetails = Common.ObjectAttributesValues(SalesOrder, "BusinessOperation, ARAPObjectSettings");
		If OrderDetails.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			Or OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			FillInFromOrder = False;
		EndIf;
	EndIf;
	
	IncomingCashOrderPartner = Catalogs.Partners.GetRef(
		New UUID(MobilePayment.Клиент));
	If FillInFromOrder Then
		CashAccountReceiptNote.Fill(SalesOrder);
	Else
		CashAccountReceiptNote.Organization = Catalogs.Companies.GetRef(
			New UUID(MobilePayment.Организация));
		CashAccountReceiptNote.Currency = Catalogs.Currencies.GetRef(
			New UUID(MobilePayment.Валюта));
		CashAccountReceiptNote.Counterparty = Catalogs.Counterparties.GetRef(
			New UUID(MobilePayment.Контрагент));
		AgreementContract = StructureOfAgreementAgreement(MobilePayment.ДоговорКлиента);
		CashReceiptOrderAgreement = AgreementContract.Contract;
		
		If ValueIsFilled(CashReceiptOrderAgreement) Then
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = SalesOrder;
			ParametersForFillingInDecryption.Contract          = CashReceiptOrderAgreement;
			ParametersForFillingInDecryption.DocumentCurrency  = CashAccountReceiptNote.Currency;
			ParametersForFillingInDecryption.Partner          = IncomingCashOrderPartner;
			ParametersForFillingInDecryption.PaymentPurpose = SalesOrder;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				CashAccountReceiptNote.ARAPDetails);
		EndIf;
	EndIf;
	
	CashAccountReceiptNote.DocumentAmount = MobilePayment.СуммаДокумента;
	CashAccountReceiptNote.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer;
	CashAccountReceiptNote.Cashier = Users.CurrentUser();
	CashAccountReceiptNote.Comment = TrimAll(MobilePayment.ПредставлениеДокумента);
	
	If Not ValueIsFilled(CashAccountReceiptNote.Counterparty) Then
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(IncomingCashOrderPartner,
			CashAccountReceiptNote.Counterparty);
	EndIf;
	If ValueIsFilled(CashAccount) Then
		If Not ValueIsFilled(CashAccountReceiptNote.CashAccount) Then
			CashAccountReceiptNote.CashAccount = CashAccount;
		EndIf;
		If Not ValueIsFilled(CashAccountReceiptNote.Organization) Then
			CashAccountReceiptNote.Organization = Common.ObjectAttributeValue(CashAccount, "Owner");
		EndIf;
	Else
		If Not ValueIsFilled(CashAccountReceiptNote.CashAccount) Then
			CashAccountReceiptNote.CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(CashAccountReceiptNote.Organization);
		EndIf;
	EndIf;
	
	If CashAccountReceiptNote.ARAPDetails.Count() = 1 Then
		If CashAccountReceiptNote.DocumentAmount <> 0 Then
			TableRow = CashAccountReceiptNote.ARAPDetails[0];
			TableRow.Sum = CashAccountReceiptNote.DocumentAmount;
			TableRow.AmountARAP = 0;
			If ValueIsFilled(ArticleDDSCash) Then
				TableRow.CashFlowItem = ArticleDDSCash;
			EndIf;
		Else
			CashAccountReceiptNote.ARAPDetails.Delete(0);
		EndIf;
	ElsIf CashAccountReceiptNote.ARAPDetails.Count() = 0
		And CashAccountReceiptNote.DocumentAmount > 0 Then
		TableRow = CashAccountReceiptNote.ARAPDetails.Add();
		TableRow.ARAPCurrency = CashAccountReceiptNote.Currency;
		TableRow.Partner = IncomingCashOrderPartner;
		TableRow.Sum = CashAccountReceiptNote.DocumentAmount;
		If ValueIsFilled(ArticleDDSCash) Then
			TableRow.CashFlowItem = ArticleDDSCash;
		EndIf;
		If ValueIsFilled(SalesOrder) Then
			TableRow.ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(SalesOrder, CashAccountReceiptNote.Organization);
			TableRow.PaymentPurpose = SalesOrder;
		EndIf;
	ElsIf CashAccountReceiptNote.DocumentAmount = 0 Then
		CashAccountReceiptNote.ARAPDetails.Clear();
	EndIf;
	
	CashAccountReceiptNote.Posted = True;
	Posted = True;
	Try
		CashAccountReceiptNote.DataExchange.Load = True;
		CashAccountReceiptNote.Write(DocumentWriteMode.Write);
	Except
		Posted = False;
	EndTry;
	
	WriteMode = ?(Posted, DocumentWriteMode.Posting,
		?(CashAccountReceiptNote.Posted,
			DocumentWriteMode.UndoPosting, DocumentWriteMode.Write));
	Try
		CashAccountReceiptNote.DataExchange.Load = False;
		CashAccountReceiptNote.Write(WriteMode, DocumentPostingMode.Regular);
	Except
		Posted = False;
	EndTry;
	
	Structure = New Structure;
	Structure.Insert("ref", MobilePayment.ref);
	Structure.Insert("Posted", Posted);
	Message.Add(Structure);
EndProcedure

Procedure CreateUpdateAcquiringOperation(PaymentStructure, Message)
	
	MobilePayment = PaymentStructure.MobilePayment;
	ArticleDDSAcquiring = PaymentStructure.ArticleDDSAcquiring;
	POSTerminal = PaymentStructure.POSTerminal;
	AcquiringTransaction =
		Documents.PaymentCardTransaction.GetRef(New UUID(MobilePayment.ref));
		
	PaymentCardTransaction = AcquiringTransaction.GetObject();
	If PaymentCardTransaction = Undefined Then
		PaymentCardTransaction = Documents.PaymentCardTransaction.CreateDocument();
		PaymentCardTransaction.SetNewObjectRef(AcquiringTransaction);
		PaymentCardTransaction.Date = MobilePayment.Date;
	Else
		If PaymentCardTransaction.PaymentCompleted Then
			Structure = New Structure;
			Structure.Insert("ref", TrimAll(PaymentCardTransaction.Ref.UUID()));
			Structure.Insert("Posted", PaymentCardTransaction.Posted);
			Message.Add(Structure);
			Return;
		EndIf;
	EndIf;
	
	SalesOrder =
		Documents.SalesOrder.GetRef(New UUID(MobilePayment.ДокументОснование));
	Try
		OrderObject = SalesOrder.GetObject();
	Except
		OrderObject = Undefined;
	EndTry;
	FillInFromOrder = True;
	If OrderObject = Undefined Then
		// There is no order in the IB, we fill in the payment details.
		FillInFromOrder = False;
	EndIf;
	If FillInFromOrder Then
		OrderDetails = Common.ObjectAttributesValues(SalesOrder, "BusinessOperation, ARAPObjectSettings");
		If OrderDetails.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			Or OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			FillInFromOrder = False;
		EndIf;
	EndIf;
	PartnerPaymentCardOperation = Catalogs.Partners.GetRef(
			New UUID(MobilePayment.Клиент));
	If FillInFromOrder Then
		PaymentCardTransaction.Fill(SalesOrder);
	Else
		PaymentCardTransaction.Organization = Catalogs.Companies.GetRef(
			New UUID(MobilePayment.Организация));
		PaymentCardTransaction.Currency = Catalogs.Currencies.GetRef(
			New UUID(MobilePayment.Валюта));
		PaymentCardTransaction.Counterparty = Catalogs.Counterparties.GetRef(
			New UUID(MobilePayment.Контрагент));
		AgreementContract = StructureOfAgreementAgreement(MobilePayment.ДоговорКлиента);
		PaymentCardOperationAgreement = AgreementContract.Contract;
		
		If ValueIsFilled(PaymentCardOperationAgreement) Then
			ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
			ParametersForFillingInDecryption.SalesOrder     = SalesOrder;
			ParametersForFillingInDecryption.Contract          = PaymentCardOperationAgreement;
			ParametersForFillingInDecryption.DocumentCurrency  = PaymentCardTransaction.Currency;
			ParametersForFillingInDecryption.Partner          = PartnerPaymentCardOperation;
			ParametersForFillingInDecryption.PaymentPurpose = SalesOrder;
			
			ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
				ParametersForFillingInDecryption,
				PaymentCardTransaction.ARAPDetails);
		EndIf;
	EndIf;
	
	PaymentCardTransaction.DocumentAmount = MobilePayment.СуммаДокумента;
	PaymentCardTransaction.DoNotControlRequestFilling = True;
	PaymentCardTransaction.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer;
	PaymentCardTransaction.POSTerminal = POSTerminal;
	PaymentCardTransaction.PaymentCardNumber = TrimAll(MobilePayment.НомерПлатежнойКарты);
	PaymentCardTransaction.PaymentCompleted = True;
	PaymentCardTransaction.EmployeeResponsible = Users.CurrentUser();
	PaymentCardTransaction.Comment = TrimAll(MobilePayment.ПредставлениеДокумента);
	
	If Not ValueIsFilled(PaymentCardTransaction.Counterparty) Then
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(PartnerPaymentCardOperation,
			PaymentCardTransaction.Counterparty);
	EndIf;
	If Not ValueIsFilled(PaymentCardTransaction.Organization) Then
		Attributes = Catalogs.POSTerminals.GetDetailsOfAcquiringTerminal(POSTerminal);
		PaymentCardTransaction.Organization = Attributes.Organization;
	EndIf;
	If ValueIsFilled(ArticleDDSAcquiring)
		And Not ValueIsFilled(PaymentCardTransaction.CashFlowItem) Then
		PaymentCardTransaction.CashFlowItem = ArticleDDSAcquiring;
	EndIf;
	
	If PaymentCardTransaction.ARAPDetails.Count() = 1 Then
		If PaymentCardTransaction.DocumentAmount <> 0 Then
			TableRow = PaymentCardTransaction.ARAPDetails[0];
			TableRow.Sum = PaymentCardTransaction.DocumentAmount;
			TableRow.AmountARAP = 0;
			If ValueIsFilled(ArticleDDSAcquiring)
				And Not ValueIsFilled(TableRow.CashFlowItem) Then
				TableRow.CashFlowItem = ArticleDDSAcquiring;
			EndIf;
		Else
			PaymentCardTransaction.ARAPDetails.Delete(0);
		EndIf;
	ElsIf PaymentCardTransaction.ARAPDetails.Count() = 0
			And PaymentCardTransaction.DocumentAmount > 0 Then
		TableRow = PaymentCardTransaction.ARAPDetails.Add();
		TableRow.ARAPCurrency = PaymentCardTransaction.Currency;
		TableRow.Partner = PartnerPaymentCardOperation;
		TableRow.Sum = PaymentCardTransaction.DocumentAmount;
		If ValueIsFilled(ArticleDDSAcquiring) Then
			TableRow.CashFlowItem = ArticleDDSAcquiring;
		EndIf;
		If ValueIsFilled(SalesOrder) Then
			TableRow.OrderDocument = SalesOrder;
			TableRow.PaymentPurpose = SalesOrder;
		EndIf;
	ElsIf PaymentCardTransaction.DocumentAmount = 0 Then
		PaymentCardTransaction.ARAPDetails.Clear();
	EndIf;
	
	PaymentCardTransaction.Posted = True;
	Posted = True;
	Try
		PaymentCardTransaction.DataExchange.Load = True;
		PaymentCardTransaction.Write(DocumentWriteMode.Write);
	Except
		Posted = False;
	EndTry;
	
	WriteMode = ?(Posted, DocumentWriteMode.Posting,
		?(PaymentCardTransaction.Posted,
			DocumentWriteMode.UndoPosting, DocumentWriteMode.Write));
	Try
		PaymentCardTransaction.DataExchange.Load = False;
		PaymentCardTransaction.Write(WriteMode, DocumentPostingMode.Regular);
	Except
		Posted = False;
	EndTry;
	
	Structure = New Structure;
	Structure.Insert("ref", MobilePayment.ref);
	Structure.Insert("Posted", Posted);
	Message.Add(Structure);
EndProcedure

Function ProductPackages(Products, Package)
	
	QueryText =
	"SELECT ALLOWED
	|	ProductPackages.Owner AS PackagingOwner,
	|	ProductPackages.Ref AS PackagingRef,
	|	ProductPackages.DeletionMark AS DeletionMark,
	|	&QueryTextPackagingFactor AS ZoomRatio,
	|	ProductPackages.Parent AS Parent,
	|	ProductPackages.UnitOfMeasure AS UnitOfMeasure,
	|	ProductPackages.UnitOfMeasure.DeletionMark AS UnitOfMeasureDeletionMark,
	|	ProductPackages.UnitOfMeasure.Code AS UnitOfMeasureCode,
	|	ProductPackages.UnitOfMeasure.Description AS UnitOfMeasurementName,
	|	ProductPackages.UnitOfMeasure.PredefinedDataName AS UnitNameOfPredefinedData,
	|	ProductPackages.UnitOfMeasure.DescriptionFull AS UnitOfMeasurementFullName,
	|	ProductPackages.UnitOfMeasure.InternationalAbbreviation AS UnitOfMeasureInternationalAbbreviation,
	|	&QueryTextPackageWeight AS Weight,
	|	ProductPackages.WeightUnitOfMeasure AS WeightUnitOfMeasure,
	|	ProductPackages.WeightUnitOfMeasure.DeletionMark AS WeightUnitOfMeasureDeletionMark,
	|	ProductPackages.WeightUnitOfMeasure.Code AS WeightUnitCode_,
	|	ProductPackages.WeightUnitOfMeasure.Description AS WeightUnitName_,
	|	ProductPackages.WeightUnitOfMeasure.PredefinedDataName AS WeightUnitNameOfPredefinedData,
	|	ProductPackages.WeightUnitOfMeasure.DescriptionFull AS WeightUnitFullName_,
	|	ProductPackages.WeightUnitOfMeasure.InternationalAbbreviation AS WeightUnitOfMeasurementInternationalAbbreviation
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (ProductPackages.Owner = CASE
	|				WHEN Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN Products.Ref
	|				WHEN NOT Products.PackagingGroup = VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN Products.PackagingGroup
	|				ELSE FALSE
	|			END)
	|			AND (Products.Ref = &Products)
	|			AND (NOT ProductPackages.Ref = &Package)
	|			AND (Products.UsePackages)";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages", "Products"));
	QueryText = StrReplace(QueryText,
		"&QueryTextPackageWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"ProductPackages", "Products"));
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Package", Package);
	Query.SetParameter("Products", Products);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	
	Return Selection;
EndFunction

Procedure SetCompanySBankAccountDetails(AttributesStructure1, BankAccount)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BankAccounts.AccountNumber AS AccountNumber,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankDescription
	|		ELSE ISNULL(Banks.Description, """")
	|	END AS Bank,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankBIC
	|		ELSE ISNULL(Banks.Code, """")
	|	END AS BIC,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankCorrAccount
	|		ELSE ISNULL(Banks.CorrAccount, """")
	|	END AS CorrAccount,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankCity
	|		ELSE ISNULL(Banks.City, """")
	|	END AS BankCity
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|		LEFT JOIN Catalog.BankClassifier AS Banks
	|		ON BankAccounts.Bank = Banks.Ref
	|WHERE
	|	BankAccounts.Ref = &BankAccount";
	
	Query.SetParameter("BankAccount", BankAccount);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		AttributesStructure1.Insert("НомерСчета", Selection.AccountNumber); //@NON-NLS-1
		AttributesStructure1.Insert("Банк", Selection.Bank); //@NON-NLS-1
		AttributesStructure1.Insert("БИК", Selection.BIC); //@NON-NLS-1
		AttributesStructure1.Insert("ГородБанка", Selection.BankCity); //@NON-NLS-1
		AttributesStructure1.Insert("КоррСчет", Selection.CorrAccount); //@NON-NLS-1
	Else
		AttributesStructure1.Insert("НомерСчета", ""); //@NON-NLS-1
		AttributesStructure1.Insert("Банк", ""); //@NON-NLS-1
		AttributesStructure1.Insert("БИК", ""); //@NON-NLS-1
		AttributesStructure1.Insert("ГородБанка", ""); //@NON-NLS-1
		AttributesStructure1.Insert("КоррСчет", ""); //@NON-NLS-1
	EndIf;
	
EndProcedure

Function ItemsBarcode(Products, Characteristic, Package)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ItemsBarcodes.Barcode AS Barcode,
	|	0 AS Priority
	|INTO Barcodes
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|WHERE
	|	ItemsBarcodes.Products = &Products
	|	AND ItemsBarcodes.Characteristic = &Characteristic
	|	AND ItemsBarcodes.Package = &Package
	|
	|UNION ALL
	|
	|SELECT
	|	ItemsBarcodes.Barcode,
	|	1
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|WHERE
	|	ItemsBarcodes.Products = &Products
	|	AND ItemsBarcodes.Characteristic = &Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	Barcodes.Barcode AS Barcode
	|FROM
	|	Barcodes AS Barcodes
	|
	|ORDER BY
	|	Barcodes.Priority
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Barcodes";

	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Package", Package);

	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return "";
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Barcode;
EndFunction

#EndRegion

#Region Additional_requisits

Procedure RecordAdditionalDetails(MapItemInformation, Val ObjectReference, Val ObjectName, Val ObjectNameLocal)
	
	NamesArray = StrSplit(ObjectName, ".");
	LocalName = Left(ObjectName, StrLen((NamesArray[NamesArray.UBound()]))-2);
	
	Query = New Query(
	"SELECT
	|	ItemAdditionalDetails.Property AS Property,
	|	ItemAdditionalDetails.Value AS Value,
	|	ItemAdditionalDetails.TextString AS TextString
	|FROM
	|	&ObjectTable AS ItemAdditionalDetails
	|WHERE
	|	ItemAdditionalDetails.Ref = &Ref");
	
	Query.Text = StrReplace(Query.Text, "&ObjectTable", ObjectName);
	Query.SetParameter("Ref", ObjectReference);
	Result = Query.Execute().Unload();
	
	DetailsOfExchange = New ValueTable;
	FillInTableOfSavedDetails(DetailsOfExchange);
	DetailsOfExchange.Columns.Add("TextString", New TypeDescription("String"));
	DescriptionOfValueTypesAndProps = MobileApplicationSalesOrders.DescriptionOfValueTypesAndProps();
	DetailsOfExchange.Columns.Add("Value", DescriptionOfValueTypesAndProps);
	DetailsOfExchange.Columns.Add("ForDeletion", New TypeDescription("Boolean"));
	
	For Each StringAttribute In DetailsOfExchange Do
		If StringAttribute.ObjectName = LocalName Then
			If StringAttribute.Participates Then
				If TypeOf(StringAttribute.Attribute) = Type("String") Then
					StringAttribute.Value = Common.ObjectAttributeValue(ObjectReference, StringAttribute.Attribute);
				Else
					AdditionalPropsLine = Result.Find(StringAttribute.Attribute);
					If AdditionalPropsLine = Undefined Then
						StringAttribute.ForDeletion = True;
					Else
						StringAttribute.Value = AdditionalPropsLine.Value;
						StringAttribute.TextString = AdditionalPropsLine.TextString;
					EndIf;
				EndIf;
			Else
				StringAttribute.ForDeletion = True;
			EndIf;
		Else
			StringAttribute.ForDeletion = True;
		EndIf;
	EndDo;
	LinesToDelete = DetailsOfExchange.FindRows(New Structure("ForDeletion", True));
	
	For Each RowToDelete In LinesToDelete Do
		DetailsOfExchange.Delete(RowToDelete);
	EndDo;
	
	RecordAdditionalItemDetails(MapItemInformation, DetailsOfExchange, ObjectNameLocal);
EndProcedure

Procedure RecordAdditionalItemDetails(MapItemInformation, Val AddAttributes, Val LocalObjectName)
	
	LocalObjectName = StrReplace(LocalObjectName, NStr("vi = 'Bạn hàng';
														|ru = 'Партнер';
														|en = 'Partner'; fa = 'شریک تجاری';
														|it = 'Partner';
														|pl = 'Partner';
														|tr = 'İş ortağı'"), NStr("vi = 'Khách hàng';
																				|ru = 'Клиент';
																				|en = 'Customer'; fa = 'مشتری';
																				|it = 'Cliente';
																				|pl = 'Klient';
																				|tr = 'Müşteri'"));
	
	ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(), LocalObjectName);
	
	ArrayOfStringsAndBankingDetails = New Array;
	For Each StringAttribute In AddAttributes Do
		
		ExchangeObject = XDTOFactory.Create(ObjectType);
		ExchangeObject.Свойство = StringAttribute.UniquePropertyID;
		If TypeOf(StringAttribute.Value) = Type("CatalogRef.ObjectsPropertiesValues")
			Or TypeOf(StringAttribute.Value) = Type("CatalogRef.ObjectPropertyValueHierarchy") Then
			Value = TrimAll(StringAttribute.Value.UUID());
		Else
			Value = StringAttribute.Value;
		EndIf;
		ExchangeObject.Значение = Value;
		If ValueIsFilled(StringAttribute.TextString) Then
			ExchangeObject.ТекстоваяСтрока = StringAttribute.TextString;
		Else
			ExchangeObject.ТекстоваяСтрока = "";
		EndIf;
		
		ArrayOfStringsAndBankingDetails.Add(ExchangeObject);
	EndDo;
	
	MapItemInformation["ДополнительныеРеквизиты"] = ArrayOfStringsAndBankingDetails; //@NON-NLS-1
EndProcedure

Procedure RecordAdditionalItemDetails_(XMLWriter)
	
	DetailsOfExchange = New ValueTable;
	FillInTableOfSavedDetails(DetailsOfExchange);
	
	For Each StringAttribute In DetailsOfExchange Do
		RecordAdditionalProps(XMLWriter, StringAttribute);
	EndDo;
EndProcedure

Procedure RecordAdditionalProps(XMLWriter, Val DataString1)
	
	IncludeObjectPropertyValuesInExchange = False;
	If DataString1.ValueType.ContainsType(Type("Boolean")) Then
		MPValueType = "Boolean";
	ElsIf DataString1.ValueType.ContainsType(Type("Date")) Then
		MPValueType = "Date";
	ElsIf DataString1.ValueType.ContainsType(Type("String")) Then
		MPValueType = "String";
	ElsIf DataString1.ValueType.ContainsType(Type("Number")) Then
		MPValueType = "Number";
	ElsIf DataString1.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
		MPValueType = "CatalogReferenceObjectPropertyValues";
		IncludeObjectPropertyValuesInExchange = True;
	ElsIf DataString1.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
		MPValueType = "CatalogReferenceObjectPropertyValuesHierarchy";
		IncludeObjectPropertyValuesInExchange = True;
	Else
		MPValueType = "";
	EndIf;
	
	// If the object's details or additional details of the object are no longer involved in the exchange,
	// we pass a sign of deleting the object.
	// Also, if the type of the props value is directories "Value of object properties" or "Value of object properties (Hierarchy)",
	// we pass the deletion sign for subordinate objects.
	If Not DataString1.Participates Then
		If Not TypeOf(DataString1.Attribute) = Type("String") Then
			Data = DataString1.Attribute.GetObject();
			If ValueIsFilled(DataString1.Attribute) And Data = Undefined Then
				Data = New ObjectDeletion(DataString1.Attribute);
			EndIf;
		Else
			Data = ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.GetRef(
			New UUID(DataString1.UniquePropertyID));
		EndIf;
		MobileApplicationSalesOrders.DataDeletion(Data);
		If TypeOf(Data) = Type("ObjectDeletion") Then
			XDTOSerializer.WriteXML(XMLWriter, Data);
		EndIf;
		If IncludeObjectPropertyValuesInExchange Then
			WriteObjectPropertyValues(XMLWriter, DataString1.Attribute, True);
		EndIf;
		Return;
	EndIf;
	
	StructureOfAdditionalProps = MobileApplicationSalesOrders.StructureOfAdditionalProps();
	
	If TypeOf(DataString1.Attribute) = Type("String") Then
		StructureOfAdditionalProps.DeletionMark = False;
		StructureOfAdditionalProps.Description = DataString1.Attribute;
		StructureOfAdditionalProps.PredefinedDataName = "";
		
		StructureOfAdditionalProps.Виден = True;
		StructureOfAdditionalProps.ВладелецДополнительныхЗначений = BlankID();
		StructureOfAdditionalProps.ДополнительныеЗначенияИспользуются = False;
		StructureOfAdditionalProps.ДополнительныеЗначенияСВесом = False;
		StructureOfAdditionalProps.Доступен = True;
		StructureOfAdditionalProps.Заголовок = DataString1.Presentation;
		StructureOfAdditionalProps.ЗаголовокФормыВыбораЗначения = DataString1.Presentation;
		StructureOfAdditionalProps.ЗаголовокФормыЗначения = DataString1.Presentation;
		StructureOfAdditionalProps.ЗаполнятьОбязательно = False;
		StructureOfAdditionalProps.МногострочноеПолеВвода = 0;
		StructureOfAdditionalProps.НаборСвойств = DataString1.ObjectName;
		StructureOfAdditionalProps.ФорматСвойства = "";
		
	Else
		ValuesOfPropsAdditionalProps = Common.ObjectAttributesValues(DataString1.Attribute,
		"DeletionMark, Description, PredefinedDataName, isVisible, AdditionalValuesOwner, PropertiesSet,""
		|""AdditionalValuesUsed, AdditionalValuesWithWeight, Available, Title, FormatProperties,""
		|""ValueChoiceFormTitle, ValueFormTitle, RequiredToFill, MultilineInputField");
		StructureOfAdditionalProps.DeletionMark = ValuesOfPropsAdditionalProps.DeletionMark;
		StructureOfAdditionalProps.Description = ValuesOfPropsAdditionalProps.Description;
		StructureOfAdditionalProps.PredefinedDataName = ValuesOfPropsAdditionalProps.PredefinedDataName;
		StructureOfAdditionalProps.ПометкаУдаления = ValuesOfPropsAdditionalProps.DeletionMark;
		StructureOfAdditionalProps.Виден = ValuesOfPropsAdditionalProps.isVisible;
		StructureOfAdditionalProps.ДополнительныеЗначенияИспользуются = ValuesOfPropsAdditionalProps.AdditionalValuesUsed;
		StructureOfAdditionalProps.ДополнительныеЗначенияСВесом = ValuesOfPropsAdditionalProps.AdditionalValuesWithWeight;
		StructureOfAdditionalProps.Доступен = ValuesOfPropsAdditionalProps.Available;
		StructureOfAdditionalProps.Заголовок = ValuesOfPropsAdditionalProps.Title;
		StructureOfAdditionalProps.ФорматСвойства = ValuesOfPropsAdditionalProps.FormatProperties;
		StructureOfAdditionalProps.ЗаголовокФормыВыбораЗначения = ValuesOfPropsAdditionalProps.ValueChoiceFormTitle;
		StructureOfAdditionalProps.ЗаполнятьОбязательно = ValuesOfPropsAdditionalProps.RequiredToFill;
		StructureOfAdditionalProps.МногострочноеПолеВвода = ValuesOfPropsAdditionalProps.MultilineInputField;
		
		If Not ValueIsFilled(ValuesOfPropsAdditionalProps.AdditionalValuesOwner) Then
			StructureOfAdditionalProps.ВладелецДополнительныхЗначений = BlankID();
		Else
			StructureOfAdditionalProps.ВладелецДополнительныхЗначений =
				TrimAll(ValuesOfPropsAdditionalProps.AdditionalValuesOwner.UUID());
		EndIf;
		If Not ValueIsFilled(ValuesOfPropsAdditionalProps.PropertiesSet) Then
			StructureOfAdditionalProps.НаборСвойств = Chars.NBSp;
		Else
			StructureOfAdditionalProps.НаборСвойств = DataString1.ObjectName;
		EndIf;
	EndIf;
	
	StructureOfAdditionalProps.ref = DataString1.UniquePropertyID;
	StructureOfAdditionalProps.ЭтоДополнительноеСведение = False;
	StructureOfAdditionalProps.НаборСвойств = DataString1.ObjectName;
	StructureOfAdditionalProps.ТипЗначения = MPValueType;
	
	FillInDependenciesOfPropertiesAndProps(DataString1.Attribute, StructureOfAdditionalProps);
	
	LocalObjectName = "CatalogObject.ДополнительныеРеквизитыИСведения"; //@NON-NLS-1
	WriteCatalog(XMLWriter, StructureOfAdditionalProps, LocalObjectName);
	
	If IncludeObjectPropertyValuesInExchange Then
		WriteObjectPropertyValues(XMLWriter, DataString1.Attribute);
	EndIf;
EndProcedure

Procedure WriteObjectPropertyValues(XMLWriter, Owner, Delete = False)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ObjectsPropertiesValues.Ref,
	|	ObjectsPropertiesValues.DeletionMark AS DeletionMark,
	|	ObjectsPropertiesValues.Owner,
	|	ObjectsPropertiesValues.Parent,
	|	ObjectsPropertiesValues.IsFolder AS IsFolder,
	|	ObjectsPropertiesValues.Description AS Description,
	|	ObjectsPropertiesValues.Weight AS Weight,
	|	ObjectsPropertiesValues.PredefinedDataName AS PredefinedDataName
	|FROM
	|	Catalog.ObjectsPropertiesValues AS ObjectsPropertiesValues
	|WHERE
	|	ObjectsPropertiesValues.Owner = &Owner
	|
	|UNION ALL
	|
	|SELECT
	|	ObjectsPropertiesValues.Ref,
	|	ObjectsPropertiesValues.DeletionMark,
	|	ObjectsPropertiesValues.Owner,
	|	ObjectsPropertiesValues.Parent,
	|	FALSE,
	|	ObjectsPropertiesValues.Description,
	|	ObjectsPropertiesValues.Weight,
	|	ObjectsPropertiesValues.PredefinedDataName
	|FROM
	|	Catalog.ObjectPropertyValueHierarchy AS ObjectsPropertiesValues
	|WHERE
	|	ObjectsPropertiesValues.Owner = &Owner";
	
	Query.SetParameter("Owner", Owner);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		If Delete Then
			Data = Selection.Ref.GetObject();
			If ValueIsFilled(Selection.Ref) And Data = Undefined Then
				Data = New ObjectDeletion(Selection.Ref);
			EndIf;
			MobileApplicationSalesOrders.DataDeletion(Data);
			If TypeOf(Data) = Type("ObjectDeletion") Then
				XDTOSerializer.WriteXML(XMLWriter, Data);
			EndIf;
		Else
			Hierarchy = TypeOf(Selection.Ref) = Type("CatalogRef.ObjectPropertyValueHierarchy");
			ObjectPropertyValueStructure =
			MobileApplicationSalesOrders.ObjectPropertyValueStructure(Hierarchy, Selection.IsFolder);
			FillPropertyValues(ObjectPropertyValueStructure, Selection);
			
			ObjectPropertyValueStructure.ref = TrimAll(Selection.Ref.UUID());
			ObjectPropertyValueStructure.Owner = TrimAll(Selection.Owner.UUID());
			ObjectPropertyValueStructure.Parent = TrimAll(Selection.Parent.UUID());
			
			LocalObjectName = "CatalogObject.ЗначенияСвойствОбъектов"; //@NON-NLS-1
			LocalObjectNameHierarchy = "CatalogObject.ЗначенияСвойствОбъектовИерархия"; //@NON-NLS-1
			WriteCatalog(XMLWriter, ObjectPropertyValueStructure,
			?(Hierarchy, LocalObjectNameHierarchy, LocalObjectName));
		EndIf;
	EndDo;
EndProcedure

Procedure FillInAdditionalDetailsOfObject(MobileData, Object)
	
	If Not MobileData.Properties().Get("ДополнительныеРеквизиты") = Undefined Then //@NON-NLS-1
		AdditionalObjectAttributes = Object.AdditionalAttributes;
		
		SavedExchangeDetails = New ValueTable;
		FillInTableOfSavedDetails(SavedExchangeDetails);
		
		For Each LineAdd In MobileData.ДополнительныеРеквизиты Do
			
			MatchingProps = SavedExchangeDetails.Find(TrimAll(LineAdd.Property),
				"UniquePropertyID");
			If MatchingProps = Undefined Then
				Continue;
			EndIf;
			
			IsAddlAttribute = Not TypeOf(MatchingProps.Attribute) = Type("String");
			
			If IsAddlAttribute Then
				AdditionalAttributeRow = AdditionalObjectAttributes.Find(MatchingProps.Attribute);
				If Not AdditionalAttributeRow = Undefined Then
					AdditionalAttributeRow.TextString = LineAdd.TextString;
					If MatchingProps.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
						Value = Catalogs.ObjectsPropertiesValues.GetRef(
							New UUID(TrimAll(LineAdd.Value)));
					ElsIf MatchingProps.ValueType.ContainsType(
								Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
								
						Value = Catalogs.ObjectPropertyValueHierarchy.GetRef(
							New UUID(TrimAll(LineAdd.Value)));
					Else
						Value = LineAdd.Value;
					EndIf;
					AdditionalAttributeRow.Value = Value;
				Else
					If MatchingProps.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
						Value = Catalogs.ObjectsPropertiesValues.GetRef(
						New UUID(TrimAll(LineAdd.Value)));
					ElsIf MatchingProps.ValueType.ContainsType(
								Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
								
						Value = Catalogs.ObjectPropertyValueHierarchy.GetRef(
						New UUID(TrimAll(LineAdd.Value)));
					Else
						Value = LineAdd.Value;
					EndIf;
					If Not ValueIsFilled(Object.Ref) Then
						AdditionalAttributeRow = AdditionalObjectAttributes.Add();
						AdditionalAttributeRow.Property = MatchingProps.Attribute;
						AdditionalAttributeRow.TextString = LineAdd.TextString;
						AdditionalAttributeRow.Value = Value;
					Else
						If ValueIsFilled(Value) Then
							AdditionalAttributeRow = AdditionalObjectAttributes.Add();
							AdditionalAttributeRow.Property = MatchingProps.Attribute;
							AdditionalAttributeRow.TextString = LineAdd.TextString;
							AdditionalAttributeRow.Value = Value;
						EndIf;
					EndIf;
				EndIf;
			Else
				ObjectAttribute = New Structure(TrimAll(MatchingProps.Attribute), LineAdd.Value);
				FillPropertyValues(Object, ObjectAttribute);
			EndIf;
		EndDo;
	EndIf;
EndProcedure

Procedure FillInDependenciesOfPropertiesAndProps(AdditionalAttribute5, StructureOfAdditionalProps)
	
	ArrayOfAdditionalBankingDetails = New Array;
	
	If Not TypeOf(AdditionalAttribute5) = Type("String") Then
		
		Query = New Query("SELECT
		|	AdditionalAttributesDependencies.DependentProperty,
		|	AdditionalAttributesDependencies.Attribute,
		|	AdditionalAttributesDependencies.Condition,
		|	AdditionalAttributesDependencies.Value
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.AdditionalAttributesDependencies AS AdditionalAttributesDependencies
		|WHERE AdditionalAttributesDependencies.Ref = &Ref");
		
		Query.SetParameter("Ref", AdditionalAttribute5);
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			
			LocalObjectName = "CatalogTabularSectionRow.ДополнительныеРеквизитыИСведения.ЗависимостиДополнительныхРеквизитов"; //@NON-NLS-1
			ObjectType = XDTOFactory.Type(MobileApplicationSalesOrders.NamespaceURI(),
				LocalObjectName);
			
			Selection = Result.Select();
			While Selection.Next() Do
				ExchangeObject = XDTOFactory.Create(ObjectType);
				FillPropertyValues(ExchangeObject, Selection);
				ArrayOfAdditionalBankingDetails.Add(ExchangeObject);
			EndDo;
		EndIf;
	EndIf;
	StructureOfAdditionalProps.ЗависимостиДополнительныхРеквизитов = ArrayOfAdditionalBankingDetails;
EndProcedure

#EndRegion

#EndRegion
