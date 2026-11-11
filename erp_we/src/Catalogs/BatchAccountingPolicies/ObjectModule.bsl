#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not SpecifyOnShipment
		And Not SpecifyOnReceiving
		And Not SpecifyUponTransferBetweenWarerooms
		And Not SpecifyWhenRecordingSurpluses
		And Not SpecifyWhenRecordingShortages
		And Not SpecifyWhenMovingMaterials
		And Not SpecifyWhenMovingProducts
		And Not SpecifyWhenRepairingProducts
		And Not SeriesAccountingInventoryInOperation Then
		
		MessageText = NStr("vi = 'Cần chỉ ra ít nhất một giao dịch cần chỉ định sê-ri.';
							|ru = 'Необходимо указать хотя бы одну операцию, требующую указания серий.';
							|en = 'Specify at least one transaction that requires batch.'; fa = 'Specify at least one transaction that requires batch.';
							|it = 'È necessario specificare almeno un''operazione che richiede l''indicazione delle serie.';
							|pl = 'Należy wskazać chociaż jedną operację, wymagającą określenia serii.';
							|tr = 'Parti belirtmeyi gerektiren en az bir işlem belirtilmeli.'");
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
		
	EndIf;
	
	If SpecifyOnShipment
		And Not SpecifyOnShipmentByTransfer
		And Not SpecifyOnShipmentByReturnToVendor
		And Not SpecifyOnShipmentToCustomer
		And Not SpecifyOnRetailShipment
		And Not SpecifyWhenShippingComponentsForAssembly
		And Not SpecifyOnShipmentForInternalNeeds 
		And Not SpecifyWhenShippingKitsForDisassembly Then
		
		MessageText = NStr("vi = 'Đã bật sử dụng chính sách chỉ định sê-ri khi giao hàng, nhưng chưa chọn giao dịch giao hàng nào cần chỉ định sê-ri';
							|ru = 'Включена политика указания серий при отгрузке, но не выбрано ни одной операции отгрузки, когда необходимо указывать серии';
							|en = 'Outbound delivery batch tracking is enabled, but no shipment operation is selected when it is required to specify batch'; fa = 'Outbound delivery batch tracking is enabled, but no shipment operation is selected when it is required to specify batch';
							|it = 'È attiva la politica di indicazione delle serie durante lo scarico, ma non è stata scelta nessuna operazione di scarico che richiede l''indicazione delle serie';
							|pl = 'Jest włączona polityka określania serii przy wysyłce, ale nie wybrano żadnej operacji wysyłki, w której wymagane jest określenie serii';
							|tr = 'Sevkiyat sırasında partileri belirtme politikası etkinleştirildi, ancak partilerin belirtilmesi gerektiğinde sevkiyat işlemi seçilmedi'");
		
		CommonClientServer.MessageToUser(MessageText,,"SpecifyOnShipment","Object",Cancel);
		
	EndIf;
	
	If SpecifyOnReceiving
		And Not SpecifyOnReceivingFromVendor 
		And Not SpecifyOnReceivingByReturnFromCustomer 
		And Not SpecifyWhenReceivingAssembledKits 
		And Not SpecifyOnReceivingByTransfer 
		And Not SpecifyOnReceivingByOtherRecordingAsReceived 
		And Not SpecifyWhenReceivingComponentsAfterDisassembly
		And Not SpecifyOnReturnOfGoodsNotAcceptedByRecipient
		And Not SpecifyWhenReceivingProductsFromManufacturing Then
		
		MessageText = NStr("vi = 'Đã bật sử dụng chính sách chỉ định sê-ri khi nhập hàng, nhưng chưa chọn giao dịch nhập hàng nào cần chỉ định sê-ri';
							|ru = 'Включена политика указания серий при приемке, но не выбрано ни одной операции приемки, когда необходимо указывать серии';
							|en = 'Batch specification policy on receipt is enabled, but no receiving operation is selected when it is required to specify batch'; fa = 'Batch specification policy on receipt is enabled, but no receiving operation is selected when it is required to specify batch';
							|it = 'È attiva la politica di indicazione delle serie durante la ricezione, ma non è stata scelta nessuna operazione di ricezione che richiede l''indicazione delle serie';
							|pl = 'Jest włączona polityka określania serii przy odbiorze, ale nie wybrano żadnej operacji odbioru, w której wymagane jest określenie serii';
							|tr = 'Partinin kabul sırasında belirtilmesi politikası etkinleştirildi, ancak partinin belirtilmesi gerektiğinde hiçbir kabul işlemi seçilmedi'");
		
		CommonClientServer.MessageToUser(MessageText,,"SpecifyOnReceiving","Object",Cancel);
		
	EndIf;
	
	If SpecifyOnShipment
		And Not SpecifyWhenPlanningShipment
		And Not SpecifyByPickingResult 
		And Not SpecifyWhenPlanningPicking Then
		
		MessageText = NStr("vi = 'Chưa chọn phương án chỉ định sê-ri khi xuất hàng';
							|ru = 'Не выбран вариант указания серий при отгрузке';
							|en = 'Option for outbound delivery batch tracking is not selected'; fa = 'Option for outbound delivery batch tracking is not selected';
							|it = 'La variante di specificare la serie allo scarico non è selezionata';
							|pl = 'Nie wybrano wariantu określania serii przy wysyłce';
							|tr = 'Sevkiyat sırasında parti belirtme seçeneği seçilmedi'");
		
		CommonClientServer.MessageToUser(MessageText,,"SpecifyOnShipment","Object",Cancel);
		
	EndIf;
	If SpecifyWhenMovingMaterials
		And Not SpecifyWhenReceivingMaterials 
		And Not SpecifyOnReturnToWarehouse 
		And Not SpecifyOnMaterialConsumption 
		And Not SpecifyUponAllocatingCostsToProductionLots Then
		
		MessageText = NStr("vi = 'Đã bật sử dụng chính sách chỉ định sê-ri khi điều chuyển nguyên vật liệu, nhưng chưa chọn giao dịch nào cần chỉ định sê-ri';
							|ru = 'Включена политика указания серий при движении материалов, но не выбрано ни одной операции, когда необходимо указывать серии';
							|en = 'Batch specification policy on material movements is enabled, but no operation is selected when it is required to specify batch'; fa = 'Batch specification policy on material movements is enabled, but no operation is selected when it is required to specify batch';
							|it = 'È attiva la politica di indicazione delle serie durante lo spostamento dei materiali, ma non è stata scelta nessuna operazione che richiede l''indicazione delle serie';
							|pl = 'Jest włączona polityka określania serii przy ruchu materiałów, ale nie wybrano żadnej operacji, w której wymagane jest określenie serii';
							|tr = 'Malzeme hareketlerinde parti belirtilmesi politikası etkin, ancak parti belirtilmesi gerektiğinde işlem seçilmedi'");
		
		CommonClientServer.MessageToUser(MessageText,, "SpecifyWhenMovingMaterials", "Object", Cancel);
	EndIf; 
	
	If SpecifyWhenMovingProducts
		And Not SpecifyDuringProduction 
		And Not SpecifyOnProductionIssueToBusinessUnit Then
		
		MessageText = NStr("vi = 'Đã bật sử dụng chính sách chỉ định sê-ri khi điều chuyển sản phẩm, nhưng chưa chọn giao dịch nào cần chỉ định sê-ri';
							|ru = 'Включена политика указания серий при движении продукции, но не выбрано ни одной операции, когда необходимо указывать серии';
							|en = 'Batch specification policy on product movements is enabled, but no operation is selected when it is required to specify batch'; fa = 'Batch specification policy on product movements is enabled, but no operation is selected when it is required to specify batch';
							|it = 'È attiva la politica di indicazione delle serie durante lo spostamento della produzione, ma non è stata scelta nessuna operazione che richiede l''indicazione delle serie';
							|pl = 'Jest włączona polityka określania serii przy ruchu produkcji, ale nie wybrano żadnej operacji, w której wymagane jest określenie serii';
							|tr = 'İmal edilen ürün transferinde parti belirtme politikası etkin, ancak parti belirtmek gerektiğinde hiçbir işlem seçilmedi'");
		
		CommonClientServer.MessageToUser(MessageText,, "SpecifyWhenMovingProducts", "Object", Cancel);
	EndIf; 
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not SpecifyOnShipment Then
		SpecifyByPickingResult           = False;
		SpecifyWhenPlanningPicking   = False;
		SpecifyWhenPlanningShipment = False;
	EndIf;
	
	ForWarehouse = SpecifyOnReceiving
				Or SpecifyWhenRecountingInventory
				Or SpecifyOnShipment
				Or SpecifyWhenRecordingSurpluses
				Or SpecifyWhenRecordingShortages
				Or SpecifyUponTransferBetweenWarerooms;
				
	ForProduction = SpecifyWhenMovingMaterials
		Or SpecifyWhenMovingProducts
		Or SpecifyWhenRepairingProducts;
		
	
	If Predefined Then
		// The blank policy type is used to output the predefined
		// "Seriesuse" policy in the selection and line-by-line selection form.
		PolicyType = Enums.TypesOfBatchSpecificationPolicies.EmptyRef();
	EndIf;
	
	ProductsLocalization.BeforeRecordingSeriesAccountingPolicy(ThisObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	ProductionManagement.ConfigureUseOfSeriesInProduction22();
	Return // in UT and KA the handler is empty
	
EndProcedure

#EndRegion

#EndIf
#EndIf