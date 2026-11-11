#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var RecordingWithRestrictedRights;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	RecordingWithRestrictedRights = Not AccessRight("Insert", ThisObject.Metadata());

	If RecordingWithRestrictedRights Then

		// Checking the program record of the object.
		TMAccessManagement.CheckWhetherCatalogDetailsCanBeChanged(ThisObject, "Description", Cancel);

		// There is access only to change individual details of the warehouse (the role of "Changing the configuration of the warehouse")
		// additional processing of warehouse data is not required.
		Return;

	EndIf;

	If Not IsFolder Then

		FillInCurWarehouseGroupSelection();
		UpdateUsageFlag();
		UpdateOperationalBalanceControlFlag();
		
		WarehousesClientServer.AgreeOnFeatureValues(ThisObject);

	EndIf;
	
	If Not IsNew() Then
		If Not IsFolder Then
			ObjectAttributes = Common.ObjectAttributesValues(Ref, "DeletionMark,UseBinLocationWarehousing,UseBinLocationWarehousingForInformation");
				If CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings Then
				UseBinLocationWarehousing          = ObjectAttributes.UseBinLocationWarehousing;
				UseBinLocationWarehousingForInformation = ObjectAttributes.UseBinLocationWarehousingForInformation;
			EndIf;
		EndIf;
	EndIf;

	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		SetPrivilegedMode(True);
 		Query = New Query(
		"SELECT TOP 1
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref <> &Ref");
		Query.SetParameter("Ref", Ref);
		If Not Query.Execute().IsEmpty() Then
			Constants.UseSeveralWarehouses.Set(True);
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
	If Not IsFolder Then
		
		CheckShipmentProcessingProcedure(Cancel);
		UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
		
		If UsedDelivery25 Then
			
			FirstRecord = GoodsDelivery.FirstCreationOfDeliveryPoints(ThisObject);
			DataOfMainAddresses = DataOfMainAddressesFromContactInformation();
			
			If FirstRecord
				And DataOfMainAddresses.Count() > 0 Then
				
				UpdateDeliveryPoints = True;
				
			Else
				
				AddressDataBeforeChange = DataOfMainAddressesBeforeChange(FirstRecord);
				UpdateDeliveryPoints = GoodsDelivery.AddressesChanged(AddressDataBeforeChange, DataOfMainAddresses);
				
			EndIf;
			
			If UpdateDeliveryPoints Then
				
				DataForCreatingTD = New Structure;
				DataForCreatingTD.Insert("UpdateDeliveryPoints", UpdateDeliveryPoints);
				DataForCreatingTD.Insert("FirstRecord", FirstRecord);
				DataForCreatingTD.Insert("DataOfMainAddresses", DataOfMainAddresses);
				
				AdditionalProperties.Insert("DataForCreatingTD", DataForCreatingTD);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If RecordingWithRestrictedRights Then
		// There is access only to change individual details of the warehouse (the role of "Changing the configuration of the warehouse")
		// additional processing of warehouse data is performed partially.
		SetSoftwareSetting(ThisObject);
		Return;
	EndIf;
	
	If IsFolder Then
		
		FillInSelectionOfSubordinateWarehouseGroup(Cancel);
		
	Else
		
		SetSoftwareSetting(ThisObject);
		AddVHFWarehousePoliciesForAccountingForSeriesTypesOfProducts();
		InformationRegisters.SettingsOfBinLocationWarehouses.ApplyDefaultSettings(Ref,
																				Catalogs.Warerooms.EmptyRef(),
																				UseBinLocationWarehousing,
																				StartDateOfUsingWarehouseBinSystem,
																				UseBinLocationWarehousingForInformation,
																				WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.Use);
		
	EndIf;
	
	RefreshReusableValues();
	
	SetFOValueUseResponsibleStorage();
	
	TMCommonUse.SyncKeys(ThisObject);	
	
	DataForCreatingTD = CommonClientServer.StructureProperty(
		AdditionalProperties,
		"DataForCreatingTD",
		Undefined);
	
	If DataForCreatingTD <> Undefined Then
		
		MeasurementStartTime = PerformanceMonitor.StartTimeMeasurement();
		
		Try
			
			Block = New DataLock();
			LockItem = Block.Add("Catalog.DeliveryPoints");
			LockItem.SetValue("Owner", Ref);
			Block.Lock();
			
		Except
			
			Information = ErrorInfo();
			
			MessageTemplate = NStr("vi = 'Không thể ghi lại ""%1"": dữ liệu của các điểm giao hàng trực thuộc đang được chỉnh sửa';
									|ru = 'Не удалось записать ""%1"": данные подчиненных точек доставки редактируются';
									|en = 'Cannot save %1: data of subordinate delivery points is being edited'; fa = 'Cannot save %1: data of subordinate delivery points is being edited';
									|it = 'Cannot save %1: data of subordinate delivery points is being edited';
									|pl = 'Cannot save %1: data of subordinate delivery points is being edited';
									|tr = '""%1"" kaydedilemedi: Alt teslimat noktalarının verileri düzenleniyor'");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				Description);
			
			Refinement = CommonClientServer.ExceptionClarification(Information, MessageText);
			ErrorPresentation = ErrorProcessing.DetailErrorDescription(Information);
			
			PerformanceMonitor.EndTimeMeasurement(
				"Catalog.Warehouses.ObjectModule.UpdateDeliveryPointsWhenRecording", MeasurementStartTime,,, True);
			
			Raise(Refinement.Text, Refinement.Category,, ErrorPresentation, Information);
			
		EndTry;
		
		SetPrivilegedMode(True);
		
		FillingData = GoodsDelivery.DataOfDeliveryPointsForProcessing(
			Ref,
			DataForCreatingTD.FirstRecord,
			DataForCreatingTD.DataOfMainAddresses);
		
		For Each PointData_ In FillingData Do
			
			GoodsDelivery.UpdateCreateDeliveryPoint(Ref, PointData_);
			
		EndDo;
		
		PerformanceMonitor.EndTimeMeasurement(
			"Catalog.Warehouses.ObjectModule.UpdateDeliveryPointsWhenRecording",
			MeasurementStartTime);
		
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	ModifiedObjects = CommonClientServer.ValueInArray(Ref);
	Catalogs.ItemKinds.DeleteObjectsFromSeriesAccountingPolicies(ModifiedObjects);
	SetPrivilegedMode(False);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		If Not GetFunctionalOption("UseSeveralPriceTypes") Then
			RetailPriceType = PriceManagementSystem.PriceTypePriceList_();
			AccountingPriceType = RetailPriceType;
			SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost;
		EndIf;
		If FillingData <> Undefined And FillingData.Property("WarehouseStore") Then
			WarehouseStore = FillingData.WarehouseStore;
		Else
			If GetFunctionalOption("UseRetailSales") Then
				WarehouseStore = Enums.TypesOfWarehouses.RetailStore;
			Else
				WarehouseStore = Enums.TypesOfWarehouses.WholesaleWarehouse;
			EndIf;
		EndIf;
		If FillingData <> Undefined And FillingData.Property("Group") Then
			Parent = FillingData.Group;
		EndIf;
		
		If ProductsServer.ThereIsTypeOfProductRequiringObligationOfOrderSchemeForSurplusesShortages(Ref) Then
			UseWarehouseManagemantSystemForGoodsSurplusesShortages = True;
		Else
			UseWarehouseManagemantSystemForGoodsSurplusesShortages = GetFunctionalOption("UseWarehouseManagementSystem");
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;

	If Not IsFolder Then
		
		If (WarehouseStore <> Enums.TypesOfWarehouses.RetailStore
			Or ValueIsFilled(RetailPriceType) ) Then
			
			NotCheckedAttributeArray.Add("RetailPriceType");
		EndIf;
		
		NotCheckedAttributeArray.Add("Department");
		NotCheckedAttributeArray.Add("SelectGroup");
		
		If Not UseWarehouseManagemantSystemForGoodsSurplusesShortages
			And GetFunctionalOption("UseItemsBatch")
			And ProductsServer.ThereIsTypeOfProductRequiringObligationOfOrderSchemeForSurplusesShortages(Ref) Then
			
			MessageText = NStr("vi = 'Không thể vô hiệu hóa việc sử dụng sơ đồ hai pha khi phản ánh hàng thừa, hàng thiếu và hàng hỏng, bởi vì đã có dạng mặt hàng có tùy chỉnh chỉ ra sê-ri khi phản ánh hàng thừa, hàng thiếu và/hoặc hàng hỏng.';
								|ru = 'Нельзя отключить использование ордерной схемы при отражении излишков, недостач и порчи, т.к. есть вид номенклатуры, для которого настроено указание серий при отражении недостач и/или излишков.';
								|en = 'Cannot disable usage of warehouse management upon recording surpluses, shortages, and damage, as there is a item kind for which the batch specification upon recording shortage or surplus is set.'; fa = 'Cannot disable usage of warehouse management upon recording surpluses, shortages, and damage, as there is a item kind for which the batch specification upon recording shortage or surplus is set.';
								|it = 'Impossibile disattivare l''utilizzo dello schema all''ordine durante la visualizzazione degli avanzi, degli ammanchi e dei danni poiché vi è un tipo di articolo, per il quale è impostata un indicazione delle serie su visualizzazione degli ammanchi e/o degli avanzi.';
								|pl = 'Nie można włączyć używanie schematu zleceniowego przy odzwierciedleniu nadwyżek, niedoborów i uszkodzeń, ponieważ jest rodzaj pozycji, dla którego jest ustawiono wskazywanie serii przy odzwierciedlaniu niedoborów i/lub nadwyżek.';
								|tr = 'Fazlalıklar, eksiklikler ve stok kalite değişiklikleri yansıtılırken emir şemasının kullanımını devre dışı bırakamazsınız çünkü eksiklikler ve/veya fazlalıklar yansıtılırken parti belirtmenin ayarlandığı ürün türü mevcuttur.'");
			CommonClientServer.MessageToUser(MessageText, Ref, "UseWarehouseManagemantSystemForGoodsSurplusesShortages","Object",Cancel);
		EndIf;
		
		CheckShipmentProcessingProcedure(Cancel);
		
	Else
		
		CheckWhetherParentGroupIsSelectedCorrectly(Cancel);
		
	EndIf;
	
	If Not IsFolder And Not CustodyWarehouse Then
		NotCheckedAttributeArray.Add("DepositoryKind");
		NotCheckedAttributeArray.Add("Depository");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	WarehousesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure OnCopy(ObjectToCopy)
	
	If Not ObjectToCopy.IsFolder Then
		UseItemsBatch = False;
		SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure FillInSelectionOfSubordinateWarehouseGroup(Cancel)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Parent = &Ref
		|	AND NOT Warehouses.IsFolder
		|	AND Warehouses.SelectGroup <> &SelectWarehouseGroup";
		
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("SelectWarehouseGroup", SelectGroup);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		Try
			LockDataForEdit(Selection.Ref);
		Except
			
			ErrorText = NStr("vi = 'Không thể phong tỏa %Item%. %ErrorDescription%';
							|ru = 'Не удалось заблокировать %Item%. %ErrorDescription%';
							|en = 'Cannot lock %Item%.%ErrorDescription%'; fa = 'Cannot lock %Item%.%ErrorDescription%';
							|it = 'Non è stato possibile bloccare %Item%. %ErrorDescription%';
							|pl = 'Blokowanie %Item% nie powiodło się. %ErrorDescription%';
							|tr = '%Item% bloke edilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Item%",        Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			CommonClientServer.MessageToUser(ErrorText,,,,Cancel);
			
		EndTry;
			
		Object = Selection.Ref.GetObject(); // CatalogObject.Warehouses
		
		Try
			
			Object.Write();
			
		Except
			
			ErrorText = NStr("vi = 'Không thể ghi lại %Item%. %ErrorDescription%';
							|ru = 'Не удалось записать %Item%. %ErrorDescription%';
							|en = 'Cannot save %Item%. %ErrorDescription%'; fa = 'Cannot save %Item%. %ErrorDescription%';
							|it = 'Non è stato possibile scrivere %Item%. %ErrorDescription%';
							|pl = 'Zapisywanie %Item% nie powiodło się. %ErrorDescription%';
							|tr = '%Item% kaydedilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Item%",        Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			CommonClientServer.MessageToUser(ErrorText,,,,Cancel);
			
		EndTry
		
	EndDo;
	
EndProcedure

Procedure FillInCurWarehouseGroupSelection()
	
	If Not ValueIsFilled(Parent) Or
		(Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments")
		And Not GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments")) Then
		
		SelectGroup = Enums.SelectWarehouseGroup.Disable;
		
	Else
		
		SelectGroup = Common.ObjectAttributeValue(Parent, "SelectGroup");
		
	EndIf;
	
EndProcedure

Procedure CheckWhetherParentGroupIsSelectedCorrectly(Cancel)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &Parent
		|	AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)
		|	AND &SelectWarehouseGroup =  VALUE(Enum.SelectWarehouseGroup.AllowInOrders)";
		
	Query.SetParameter("Parent", Parent);
	Query.SetParameter("SelectWarehouseGroup", SelectGroup);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
			ErrorText = NStr("vi = 'Cấm chỉ ra giá trị ""Cho phép trong các đơn hàng"", nếu trong nhóm kho lớp trên đã chỉ ra giá trị ""Cho phép trong các đơn hàng và hóa đơn""';
							|ru = 'Запрещено указывать значение ""Разрешить в заказах"", если в вышестоящей группе складов указано значение ""Разрешить в заказах и накладных""';
							|en = 'You cannot specify value ""Allow in orders"" if there is value ""Allow in orders and notes"" specified in the superior group'; fa = 'You cannot specify value ""Allow in orders"" if there is value ""Allow in orders and notes"" specified in the superior group';
							|it = 'È vietato specificare il valore ""Consenti negli ordini"" se il gruppo di magazzini di livello superiore ha il valore ""Consenti negli ordini e nelle fatture""';
							|pl = 'Wskazywanie wartości ""Zezwól w zamówieniach"" jest zabronione, jeśli w nadrzędnej grupie magazynów wskazano wartość ""Zezwól w zamówieniach i fakturach""';
							|tr = 'Ana ambar grubunda ""Siparişlerde ve faturalarda izin ver"" değeri belirtilmiş ise ""Siparişlerde izin ver"" değerinin belirtilmesi yasaktır.'");
			
			CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"SelectGroup",
			,
			Cancel);
			
	EndIf;
	
EndProcedure

Procedure UpdateUsageFlag()
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("SkipUpdatingSeriesUsageFlag") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Table.UseItemsBatch) AS UseItemsBatch,
	|	MAX(Table.UseCostAccountingByBatches) AS UseCostAccountingByBatches
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN NOT BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|					AND BatchAccountingPolicies.BatchAccountingPolicy <> VALUE(Catalog.BatchAccountingPolicies.SeriesAreNotUsed)
	|					THEN TRUE
	|				ELSE FALSE
	|			END AS UseItemsBatch,
	|		ISNULL(BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE) AS UseCostAccountingByBatches
	|	FROM
	|		Catalog.Warehouses AS Warehouses
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			ON Warehouses.Ref = BatchAccountingPolicies.Warehouse
	|	WHERE
	|		NOT &IsNew
	|		AND Warehouses.Ref = &Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN ISNULL(ProductKind.BatchAccountingPolicy, VALUE(Catalog.BatchAccountingPolicies.SeriesAreNotUsed))
	|				<> VALUE(Catalog.BatchAccountingPolicies.SeriesAreNotUsed)
	|					THEN TRUE
	|				ELSE FALSE
	|			END,
	|		ISNULL(ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)
	|	FROM
	|		Catalog.ItemKinds AS ProductKind
	|	WHERE
	|		&IsNew
	|		AND NOT ProductKind.DeletionMark) AS Table";
	
	Query.SetParameter("Warehouse", Ref);
	Query.SetParameter("IsNew", Not ValueIsFilled(Ref));
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	UseItemsBatch  = Selection.UseItemsBatch;
	UseCostAccountingByBatches = Selection.UseCostAccountingByBatches;
	
EndProcedure

Procedure UpdateOperationalBalanceControlFlag()
	If AdditionalProperties.Property("SkipUpdatingOperationalBalancesControlFlag") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Table.RealTimeStockControl) AS RealTimeStockControl
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|				THEN FALSE
	|			ELSE BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|		END AS RealTimeStockControl
	|	FROM
	|		Catalog.Warehouses AS Warehouses
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			ON Warehouses.Ref = BatchAccountingPolicies.Warehouse
	|	WHERE
	|		NOT &IsNew
	|		AND Warehouses.Ref = &Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN ProductKind.BatchAccountingPolicy IS NULL 
	|				THEN FALSE
	|			ELSE ProductKind.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|		END AS RealTimeStockControl
	|	FROM
	|		Catalog.ItemKinds AS ProductKind
	|	WHERE
	|		&IsNew) AS Table";
	
	Query.SetParameter("Warehouse", Ref);
	Query.SetParameter("IsNew", Not ValueIsFilled(Ref));
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Selection.RealTimeStockControl Then
		RealTimeStockControl = True;
	EndIf;

EndProcedure

Procedure AddVHFWarehousePoliciesForAccountingForSeriesTypesOfProducts()
	
	If AdditionalProperties.IsNew
		And GetFunctionalOption("UseItemsBatch") Then
		
		SetPrivilegedMode(True);
		ModifiedObjects = CommonClientServer.ValueInArray(Ref);
		Catalogs.ItemKinds.AddObjectsToBatchAccountingPolicies(ModifiedObjects);
		
	EndIf;
	
EndProcedure

Procedure SetSoftwareSetting(Object)

	If AccessRight("Update", Metadata.InformationRegisters.SetUpSupplyControl) Then
		InformationRegisters.SetUpSupplyControl.SetSetting(
			Object.Ref,
			Object.AvailableStockControl);
	EndIf;

EndProcedure

Procedure SetFOValueUseResponsibleStorage()
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Warehouses.DepositoryKind = VALUE(Enum.DepositaryKinds.OwnCompany)) AS TransferOfItemToYourOwnOrganization
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.CustodyWarehouse";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		VMIIsUsedForFollowingPurposes = True;
		VMIIsUsedByItsOwnOrganizations = Selection.TransferOfItemToYourOwnOrganization;
		
	Else
		
		VMIIsUsedForFollowingPurposes = False;
		VMIIsUsedByItsOwnOrganizations = False;
		
	EndIf;
	
	OptionValue = Constants.UseCustody.Get();
	If VMIIsUsedForFollowingPurposes <> OptionValue Then
		Constants.UseCustody.Set(Not OptionValue);
	EndIf;
	
	OptionValue = Constants.UseVMIByOwnCompanies.Get();
	If VMIIsUsedByItsOwnOrganizations <> OptionValue Then
		Constants.UseVMIByOwnCompanies.Set(Not OptionValue);
	EndIf;

EndProcedure

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	Result.Insert("Catalog.DocumentRegistryKeys", "DeletionMark,Description");
	
	Return Result;
	
EndFunction

#EndRegion

#Region Delivery

Procedure CheckShipmentProcessingProcedure(Cancel)
	
	If StartShipmentOnceDeliveryOrderIsCreated
		And GoodsDeliveryClientServer.UsedDelivery25() Then
		
		OrderInSystem = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
		If OrderInSystem = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst Then
			
			MessageText = NStr("vi = 'Không thể làm việc với kho hai pha ""Đóng gói được thực hiện sau khi lập kế hoạch giao hàng"" vì thứ tự lập vận đơn và phiếu là ""Đơn hàng và vận đơn trước, phiếu sau"".';
								|ru = 'Недоступна работа с ордерным складом ""Сборка осуществляется после планирования доставки"", так как порядок оформления накладных и ордеров ""Сначала заказы и накладные, затем ордера"".';
								|en = 'Cannot select the ""Picking after delivery planning"" option as the procedure of sales invoice and goods issue registration is ""Orders and invoices first, then goods issues"".'; fa = 'Cannot select the ""Picking after delivery planning"" option as the procedure of sales invoice and goods issue registration is ""Orders and invoices first, then goods issues"".';
								|it = 'Cannot select the ""Picking after delivery planning"" option as the procedure of sales invoice and goods issue registration is ""Orders and invoices first, then goods issues"".';
								|pl = 'Cannot select the ""Picking after delivery planning"" option as the procedure of sales invoice and goods issue registration is ""Orders and invoices first, then goods issues"".';
								|tr = 'İrsaliye ve emir düzenleme sırası ""Önce siparişler ve irsaliyeler, sonra emirler"" olduğu için, ""Montaj işlemi teslimat planlamasından sonra gerçekleştirilir"" ayarına sahip emre dayalı depo ile işlem yapılamaz.'");
			Common.MessageToUser(MessageText,, "ProcedureOfTransportationJobIndication",, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function DataOfMainAddressesFromContactInformation()
	
	DataOfAddresses = GoodsDelivery.NewAddressesData();
	
	Filter = New Structure;
	Filter.Insert("Kind", Catalogs.ContactInformationKinds.WarehouseAddress);
	AddressLines = ContactInformation.FindRows(Filter);
	
	DataOfAddresses = GoodsDelivery.AddressDataAccordingToContactInformation(AddressLines);
	
	Return DataOfAddresses;
	
EndFunction

Function DataOfMainAddressesBeforeChange(FirstRecord)
	
	Result = GoodsDelivery.NewAddressesData();
	
	If Not FirstRecord Then
		
		QueryText =
		"SELECT
		|	ContactInformation.Presentation AS Address,
		|	ContactInformation.Value AS AddressValue,
		|	ContactInformation.FieldValues AS FieldValueAddress,
		|	TRUE AS Main
		|FROM
		|	Catalog.Warehouses.ContactInformation AS ContactInformation
		|WHERE
		|	ContactInformation.Ref = &Ref
		|	AND ContactInformation.Kind = &Kind";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Kind", Catalogs.ContactInformationKinds.WarehouseAddress);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			AddressIsEmpty = GoodsDelivery.AddressIsEmpty(Selection);
			
			If Not AddressIsEmpty Then
				
				AddressLine = Result.Add();
				FillPropertyValues(AddressLine, Selection);
				
				AddressLine.Id =
					GoodsDeliveryLocalization.IdOfDeliveryPointAddress(AddressLine.AddressValue);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf