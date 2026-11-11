////////////////////////////////////////////////////////////////////////////////
// Client procedures for working with security mechanisms
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Adds the "Transferred earlier" action to the options for selecting collateral in the order.
// Parameters:
//  Item - TextBox - the form element associated with the details of the tabular part of the support option
//  CurrentData - FormDataCollectionItem - Current data of the table part.
Procedure AddPreviouslyPassedActionToOptionsForSelectingSoftwareOption(Item, CurrentData) Export
	
	NewArray = New Array();
	
	If CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
			Or CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
		
		ActionsArray = ProvisionInDocumentsClientServer.AvailableActionsForSelectingCollateralInDefaultRow();
		ActionsArray.Add(PredefinedValue("Enum.SupplyOptions.TransferedEarlier"));
		
		AllowedActions = New FixedArray(ActionsArray);
		NewParameter1 = New ChoiceParameter("AllowedActions", AllowedActions);
		NewArray.Add(NewParameter1);
		
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(NewArray);
	
EndProcedure

// It is used to check whether fields are filled in before executing a command to fill in security in documents.
//
// Parameters:
//  Object - FormDataStructure - the main details of the document form associated with the object being edited-the document in
//                                  which you want to perform field filling checks.
//  GoodsTable - FormDataCollection - list where you need to perform field completion checks
//  Id - Number - id of the line.
//  CheckParameters - See SupplyClientServer.InitializeFillVerificationParameters
//  Warehouse - CatalogRef.Warehouses - value of the warehouse (warehouse - shipments) field from the document header.
//  Mode - String  - command execution mode.
//
// Returns:
//  Boolean - true if the fill check is successful, false otherwise.
//
Function CheckFilling(Object, GoodsTable, Id, CheckParameters, Warehouse, Mode) Export
	
	IssueMessages = Mode <> ProvisionInDocumentsClientServer.WarehouseSelectionMode();
	Paths = "LineNumber,
	       |Canceled,
	       |Products, Characteristic, SupplyOption,
	       |ItemsType, ItemVariantsAreUsed,
	       |Count, NumberOfPackages";

	RowData = New Structure(Paths);
	Errors = New Array();

	Storage = New Structure(Paths);

	FillPropertyValues(Storage, Object);

	ThereAreErrorsWarehouse         = False;
	
	LineProducts_ = GoodsTable.FindByID(Id);
	FillPropertyValues(Storage, LineProducts_);
	FillPropertyValues(RowData, Storage);
	
	If Mode = ProvisionInDocumentsClientServer.ViewAvailabilityMode()
			And RowData.SupplyOption <> PredefinedValue("Enum.SupplyOptions.ReserveAsReceived")
			And RowData.SupplyOption <> PredefinedValue("Enum.SupplyOptions.ToSupply")
			And RowData.SupplyOption <> PredefinedValue("Enum.SupplyOptions.NotRequired") Then
			Return False;
	EndIf;

	If RowData.ItemsType <> PredefinedValue("Enum.ItemsTypes.OwnGoods")
			And RowData.ItemsType <> PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			
		Return False;
		
	EndIf;
	
	If RowData.Canceled = True Then
		
		ShowMessageBox(, NStr("vi = 'Đối với dòng đã đánh dấu, không thể đảm bảo và giao hàng.';
								|ru = 'Для отмененной строки обеспечение и отгрузка невозможны.';
								|en = 'Supply and shipment are not available for a canceled line.'; fa = 'Supply and shipment are not available for a canceled line.';
								|it = 'Per una riga annullata, il software e la spedizione non sono disponibili.';
								|pl = 'Dla anulowanego wiersza zapewnienie i wysyłka są niemożliwe.';
								|tr = 'İptal edilen satır için sipariş karşılama ve sevkiyat yapılamaz.'"));
		Return False;
		
	EndIf;
	
	If RowData.Count = 0 And RowData.NumberOfPackages = 0 Then
		
		Error = New Structure("Field, LineNumber", "Count", RowData.LineNumber);
		Errors.Add(Error);
		
	EndIf;
	
	If RowData.Count = 0 And RowData.NumberOfPackages <> 0 Then
		
		Error = New Structure("Field, LineNumber", "NumberOfPackages", RowData.LineNumber);
		Errors.Add(Error);
		
	EndIf;
	
	If Not ValueIsFilled(RowData.Products) Then
		
		Error = New Structure("Field, LineNumber", "Products", RowData.LineNumber);
		Errors.Add(Error);
		
	EndIf;
	
	If Not ValueIsFilled(RowData.Characteristic) And RowData.ItemVariantsAreUsed = True Then
		
		Error = New Structure("Field, LineNumber", "Characteristic", RowData.LineNumber);
		Errors.Add(Error);
		
	EndIf;

	If CheckParameters.Fields.Property("Warehouse") And Not ValueIsFilled(Warehouse) Then
		
		If Not ThereAreErrorsWarehouse Then
			Error = New Structure("Field, LineNumber", "Warehouse", RowData.LineNumber);
			Errors.Add(Error);
			ThereAreErrorsWarehouse = True;
		EndIf;
		
	EndIf;
	
	UserErrors = Undefined;
	
	For Each Error In Errors Do
		
		Field  = StrReplace(CheckParameters.Fields[Error.Field], "%1", Error.LineNumber - 1);
		Text = StrReplace(CheckParameters.Texts[Error.Field], "%1", Error.LineNumber);
		CommonClientServer.AddUserError(UserErrors, Field, Text, "");
		
	EndDo;
	
	If IssueMessages Then
		ClearMessages();
		CommonClientServer.ReportErrorsToUser(UserErrors);
	EndIf;
	
	Return Errors.Count() = 0;
	
EndFunction

// Returns the parameter structure used when opening the "security Needs" processing form.
//  Returns:
//   Structure: 
//    * PurposeUseKey - String, Undefined - See the Forms parameter of the same name.
//    * FilterBySupplyType - EnumRef.SupplyTypes, Undefined - selection by type of collateral. 
//    * FilterByBusinessUnit - CatalogRef.BusinessStructure, Undefined - selection by division.
//    * ThereIsInventoryStep - Boolean - if False, the inventory maintenance step is ignored.
//
Function ParametersForOpeningProcessingFormProvidingNeeds() Export
	
	Result = New Structure();
	Result.Insert("PurposeUseKey", Undefined);
	Result.Insert("FilterBySupplyType", Undefined);
	Result.Insert("FilterBySupplySource", Undefined);
	Result.Insert("FilterByBusinessUnit", Undefined);
	Result.Insert("ThereIsInventoryStep", True);
	Result.Insert("SelectionByWorkshopStorerooms", False);
	
	Return Result;
	
EndFunction

// Notifies that the order does not contain a single product with the "Provide separately" action for its own purpose.
//
Procedure ReportAbsenceOfGoodsForSeparateProvision() Export
	
	ErrorText = NStr("vi = 'Trong đơn hàng không có hàng hóa để đảm bảo đặt riêng.';
					|ru = 'В заказе нет товаров для обособленного обеспечения.';
					|en = 'No goods for assigned fulfillment in the order.'; fa = 'No goods for assigned fulfillment in the order.';
					|it = 'L''ordine non contiene merci di approvvigionamento separato.';
					|pl = 'W zamówieniu nie ma towarów dla oddzielnego zabezpieczenia.';
					|tr = 'Siparişte ayrıştırılmış tedarik için ürün mevcut değil.'");
	
	ShowMessageBox(, ErrorText);
	
EndProcedure

// Notifies that there are no reserves in stock for the purpose of the order.
Procedure ReportAbsenceOfGoodsForWithdrawalOfReserve() Export
	
	ErrorText = NStr("vi = 'Theo đơn hàng không có số dư đặt riêng. Không thể thực hiện lệnh.';
					|ru = 'По заказу нет обособленных остатков. Выполнение команды не предусмотрено.';
					|en = 'No assigned balance in the order. The command is not available.'; fa = 'No assigned balance in the order. The command is not available.';
					|it = 'Non ci sono rimanenze separate dell''ordine. Non è prevista l''esecuzione del comando.';
					|pl = 'Wg zamówienia nie ma oddzielnych sald. Wykonanie polecenia nie jest przewidziane.';
					|tr = 'Sipariş üzerine ayrıştırılmış bakiyeler mevcut değil. Komutun yürütülmesi öngörülmüyor.'");
	
	ShowMessageBox(, ErrorText);
	
EndProcedure

// Notifies that all products present in the document with the "Provide separately" action are for a third-party purpose.
//
// Parameters:
//  ThisIsReservation	 - Boolean - This is a reservation or withdrawal of a reserve.
//
Procedure ReportAbsenceOfGoodsForSeparateSecurityForCurOrder(ThisIsReservation) Export
	
	If ThisIsReservation Then
		
		ErrorText = NStr("vi = 'Các nhu cầu được ghi nhận cho mục đích không liên quan đến đơn đặt hàng này. Cho phép dự phòng cho mục đích này từ đơn hàng đã chỉ ra trong mục đích hoặc thông qua chứng từ ""Điều chỉnh mục đích hàng hóa"" được tạo thủ công từ danh sách chứng từ.';
						|ru = 'Потребности зафиксированы по назначению, не связанному с данным заказом. Резервирование для такого назначения доступно из заказа, указанного в назначении, или с помощью документа ""Корректировка назначения товаров"", создаваемого вручную из списка документов.';
						|en = 'The demands are recorded by the assignment that is not related to this order. You can reserve such assignment from the order specified in the assignment, or using the ""Inventory assignment adjustment"" document created manually from the document list.'; fa = 'The demands are recorded by the assignment that is not related to this order. You can reserve such assignment from the order specified in the assignment, or using the ""Inventory assignment adjustment"" document created manually from the document list.';
						|it = 'Il fabbisogno è bloccato per un''assegnazione non correlata a questo ordine. La prenotazione per tale assegnazione è disponibile dall''ordine indicato nell''assegnazione oppure con l''aiuto del documento ""Rettifica dell''assegnazione della merce"", da creare manualmente dall''elenco di documenti.';
						|pl = 'Zapotrzebowania są ustalone według przeznaczenia, niezwiązanego z danym zamówieniem. Rezerwa dla tego przeznaczenia jest dostępna z zamówienia, podanego w przeznaczeniu, lub za pomocą dokumentu ""Korekta przeznaczenia towarów"", tworzonego ręcznie z listy dokumentów.';
						|tr = 'Talepler, bu siparişle ilgili olmayan bir atama için sabitlendi. Böyle bir atama için rezervasyon, görevde belirtilen siparişten veya belge listesinden manuel olarak oluşturulan ""Ürün atamasının ayarlanması"" belgesi ile mevcuttur.'");
		
	Else
		
		ErrorText = NStr("vi = 'Theo mục đích liên quan đến đơn hàng này không có số dư trong kho để bỏ dự phòng. Cho phép bỏ dự phòng đối với mục đích không liên quan đến đơn hàng này từ đơn hàng đã chỉ ra trong mục đích hoặc thông qua chứng từ ""Điều chỉnh mục đích hàng hóa"" được tạo thủ công từ danh sách chứng từ.';
						|ru = 'По назначению связанному с данным заказом на складе нет остатков для снятия. Снятие резерва для назначения, не связанного с данным заказом, доступно из заказа, указанного в назначении или с помощью документа ""Корректировка назначения товаров"", создаваемого вручную из списка документов.';
						|en = 'There is no inventory for removing by the assignment related to this order in the warehouse. You can remove reserve for an assignment that is not related to this order from the order specified in the assignment or using the ""Inventory assignment adjustment"" document created manually from the document list.'; fa = 'There is no inventory for removing by the assignment related to this order in the warehouse. You can remove reserve for an assignment that is not related to this order from the order specified in the assignment or using the ""Inventory assignment adjustment"" document created manually from the document list.';
						|it = 'Non ci sono rimanenze da prelevare nel magazzino per l''assegnazione correlata a questo ordine. L''annullamento della prenotazione per l''assegnazione non correlata a questo ordine è disponibile dall''ordine indicato nell''assegnazione oppure con l''aiuto del documento ""Rettifica dell''assegnazione delle merci"", da creare manualmente dall''elenco di documenti.';
						|pl = 'Dla przeznaczenia, związanego z danym zamówieniem w magazynie nie ma sald do usunięcia. Usunięcie rezerwy dla przeznaczenia, nie związanego z danym zamówieniem, jest dostępne z określonego w przeznaczeniu lub za pomocą dokumentu ""Korekta przeznaczenia towarów"", tworzonego ręcznie z listy dokumentów.';
						|tr = 'Bu siparişle ilgili atamaya göre ambardan çıkış için bakiye bulunmamaktadır. Bu siparişle ilgili olmayan bir görev için rezervin kaldırılması, görevde belirtilen siparişten veya belge listesinden manuel olarak oluşturulan ""Stok atama düzeltmesi"" belgesi mevcuttur.'");
		
	EndIf;
	
	ShowMessageBox(, ErrorText);
	
EndProcedure

// Notifies that it is not possible to start processing a reservation or removing a reserve from a document with 
// an unsuitable status.
//
// Parameters:
//  ThisIsReservation	 - Boolean - This is a reservation or withdrawal of a reserve
//  MinimumStatus	 - String - The minimum status from which you can start processing reservations/withdrawals.
//
Procedure ReportRequiredMinimumDocumentStatus(ThisIsReservation, MinimumStatus) Export
	
	ErrorText = ?(ThisIsReservation,
		NStr("vi = 'Trạng thái chứng từ tối thiểu để đặt chỗ cho một nhiệm vụ là ""%1"".';
			|ru = 'Минимальный статус документа для резервирования под назначение - ""%1"".';
			|en = 'Minimum document status to reserve for assignment: ""%1"".'; fa = 'Minimum document status to reserve for assignment: ""%1"".';
			|it = 'Lo stato minimo del documento per la prenotazione sotto assegnazione è ""%1"".';
			|pl = 'Minimalny status dokumentu do rezerwowania pod przeznaczenie - ""%1"".';
			|tr = 'Atama için rezerv edilmesi gereken minimum belge durumu ""%1"".'"),
		NStr("vi = 'Trạng thái tối thiểu của chứng từ để loại bỏ dự phòng cho mục đích là ""%1"".';
			|ru = 'Минимальный статус документа для снятия резерва под назначение - ""%1"".';
			|en = 'Minimum document status to remove from reserve for assignment: ""%1"".'; fa = 'Minimum document status to remove from reserve for assignment: ""%1"".';
			|it = 'Lo stato minimo del documento per la rimozione della riserva sotto l''assegnazione è ""%1"".';
			|pl = 'Minimalny status dokumentu do zdjęcia rezerwy pod przeznaczenie - ""%1"".';
			|tr = 'Rezervin çıkarılması için minimum belge durumu ""%1"".'"));
	
	ErrorText = StrTemplate(ErrorText, MinimumStatus);
	
	ShowMessageBox(, ErrorText);
	
EndProcedure

// Constructor of the parameters of the form for filling in the assignment correction.
// Returns:
//  Structure - structure with fields:
//   * Master_2 - Boolean - true, when the form is closed, a document will be created,
//              False - as a result, the goods to be filled in will be placed in temporary storage.
//   * OperationKind - EnumRef.KindsOfAssignmentAdjustmentOperations - type of operation.
//   * Purpose - CatalogRef.Assignments - the purpose for which you need to fill out the document.
//   * OrderDocument - DocumentRef - the order in the context of which the filling is called.
//   * Organization - CatalogRef.BusinessStructure - it is used to select balances for assigning orders to a given organization.
//   * AddressOfGoods - String - the address of the warehouse with the goods selection table.
//   * AssignmentAdjustment - DocumentRef.InventoryAssignmentAdjustment - a link to a refillable document that could have already been held earlier.
//   * Count - Number - used in the counter adjustment operation.
Function ParametersOfFormForFillingInItemAssignmentAdjustment() Export
	
	FormParameters = New Structure();
	FormParameters.Insert("Master_2", False);
	FormParameters.Insert("OperationKind", Undefined);
	FormParameters.Insert("Purpose", Undefined);
	FormParameters.Insert("OrderDocument", Undefined);
	FormParameters.Insert("Organization", Undefined);
	FormParameters.Insert("AddressOfGoods", Undefined);
	FormParameters.Insert("AssignmentAdjustment", Undefined);
	FormParameters.Insert("QuantityToPassForAssignment", Undefined);
	FormParameters.Insert("Assignments", Undefined);
	FormParameters.Insert("MultipleAppointments", False);

	Return FormParameters;
		
EndFunction

#EndRegion
