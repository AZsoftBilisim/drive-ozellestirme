
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DiscrepanciesServer.PageManagementSelectAction(ThisObject, Parameters);
	
	UseReturnRequests = GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	UseSalesOrders = GetFunctionalOption("UseSalesOrders");
	UseTransferOrders = GetFunctionalOption("UseTransferOrders");
	UseShipmentWithDeferredTransferOfTitle2_5 = GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
	NumberOfDiscrepancyPackaging = Parameters.NumberOfDiscrepancyPackaging;
	GroupUpdate = Parameters.GroupUpdate;
	ThisIsTransferOfOwnership = (Parameters.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
	ThisIsImplementationOfLocalAccounting = (Parameters.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
	TypeOfAct = Parameters.TypeOfAct;
	ShipmentToPrincipal = Parameters.ShipmentToPrincipal;
	DiscrepanciesPostingMethod = Parameters.DiscrepanciesPostingMethod;
	TheLineToOrder = Parameters.TheLineToOrder;
	Contract = Parameters.Contract;
	ThereIsPackage = Parameters.ThereIsPackage;
	
	If ShipmentToPrincipal
		Or Not GroupUpdate
			And NumberOfDiscrepancyPackaging >= 0
			And (Parameters.ItemsType = Enums.ItemsTypes.Work_5
				Or Parameters.ItemsType = Enums.ItemsTypes.OperationService) Then
		If ActionWithSurplusDocument = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered Then
			ActionWithSurplusDocument = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef();
		EndIf;
		Items.ReturnOverdelivered.Enabled = False;
	EndIf;
	
	If Not GroupUpdate Then
		If NumberOfDiscrepancyPackaging >= 0 Then
			
			Items.Pages.CurrentPage = Items.Surpluses;
			
			ActionWithSurplusGoods = ?(
				ValueIsFilled(Parameters.SelectedActionWithGoods),
				Parameters.SelectedActionWithGoods,
				Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
			
			ActionWithSurplusDocument = ?(
				ValueIsFilled(Parameters.SelectedDocumentAction),
				Parameters.SelectedDocumentAction,
				Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
			
		Else
			
			Items.Pages.CurrentPage = Items.Shortages;
			
			ActionWithShortageGoods = ?(
				ValueIsFilled(Parameters.SelectedActionWithGoods),
				Parameters.SelectedActionWithGoods,
				Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
			
			ActionWithShortageDocument = ?(
				ValueIsFilled(Parameters.SelectedDocumentAction),
				Parameters.SelectedDocumentAction,
				Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
			
		EndIf;
	Else
		
		If Parameters.ThereAreSurpluses Then
			
			If Not ValueIsFilled(ActionWithSurplusGoods) Then
				ActionWithSurplusGoods = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
			EndIf;
			
			If Not ValueIsFilled(ActionWithSurplusDocument) Then
				ActionWithSurplusDocument = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery;
			EndIf;
			
		EndIf;
		
		If Parameters.ThereIsShortages Then
			
			If Not ValueIsFilled(ActionWithShortageGoods) Then
				ActionWithShortageGoods = Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount;
			EndIf;
			
			If Not ValueIsFilled(ActionWithShortageDocument) Then
				ActionWithShortageDocument = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If GroupUpdate Then
		Title = NStr("vi = 'Cách xử lý chênh lệch';
					|ru = 'Как отработать расхождения';
					|en = 'Discrepancy treatment'; fa = 'رسیدگی به مغایرت';
					|it = 'Come elaborare le differenze';
					|pl = 'Jak przetworzyć odchylenie';
					|tr = 'Tutarsızlıkların giderilme biçimi'");
	Else
		If NumberOfDiscrepancyPackaging >= 0 Then
			Items.Shortages.Visible = False;
			Title = NStr("vi = 'Làm thế nào để xử lý thừa';
						|ru = 'Как отработать излишек';
						|en = 'Surplus treatment'; fa = 'Surplus treatment';
						|it = 'Come elaborare le eccedenze';
						|pl = 'Jak przetworzyć nadmiar';
						|tr = 'Fazlalıkların giderilme biçimi'");
		Else
			Items.Surpluses.Visible = False;
			Title = NStr("vi = 'Làm thế nào để xử lý thiếu hụt';
						|ru = 'Как отработать недостачу';
						|en = 'Shortage treatment'; fa = 'Shortage treatment';
						|it = 'Come elaborare gli ammanchi';
						|pl = 'Jak przetworzyć niedobór';
						|tr = 'Eksikliklerin giderilme biçimi'");
		EndIf;
	EndIf;
	
	Items.NotesPicture.Visible = Parameters.ShowExplanation;
	Items.Explanation.Visible = Parameters.ShowExplanation;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingInProgress And Modified And Not Exit Then
		
		Cancel = True;
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(
			Notification,
			NStr("vi = 'Những thay đổi được thực hiện sẽ bị mất. Vẫn đóng?';
				|ru = 'Выполненные изменения будут утеряны. Все равно закрыть?';
				|en = 'Made changes will be lost. Close anyway?'; fa = 'Made changes will be lost. Close anyway?';
				|it = 'Le modifiche apportate andanno perse. Chiudere ugualmente?';
				|pl = 'Wprowadzone zmiany zostaną utracone. Zamknąć mimo wszystko?';
				|tr = 'Yapılan değişiklikler kaybolacaktır. Yine de kapatılsın mı?'"),
			QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GenerateHeadings();
	SetAvailabilityOfActions();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WriteOFFActionWithShortageGoodsOnChange(Item)
	
	If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		GenerateHeadings();
	EndIf;
	
	SetAvailabilityOfActions();
	
EndProcedure

&AtClient
Procedure WriteOffActionWithShortageGoodsOutOfWayOnChange(Item)
	
	If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		GenerateHeadings();
	EndIf;
	
	SetAvailabilityOfActions();
	
EndProcedure

&AtClient
Procedure TakeIntoAccountShortageActionWithGoodsDuringInventoryOnChange(Item)
	
	If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		GenerateHeadings();
	EndIf;
	
	SetAvailabilityOfActions();
	
EndProcedure

&AtClient
Procedure ReturnActionWithShortageGoodsOnChange(Item)
	
	If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		GenerateHeadings();
	EndIf;
	
	SetAvailabilityOfActions();
	
EndProcedure

&AtClient
Procedure ExpectActionWithShortageGoodsOnChange(Item)
	
	If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		GenerateHeadings();
	EndIf;
	
	SetAvailabilityOfActions();
	
EndProcedure

&AtClient
Procedure EnterIntoWayOfActionWithSurplusGoodsOnChange(Item)
	
	If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		GenerateHeadings();
	EndIf;
	
	SetAvailabilityOfActions();
	
EndProcedure

&AtClient
Procedure TakeIntoAccountInventoryActionWithGoodsSurplusOnChange(Item)
	SetAvailabilityOfActions();
	
	If DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		GenerateHeadings();
	EndIf;
	
	SetAvailabilityOfActions();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClosingInProgress = True;
	
	If GroupUpdate Then
		ClosingParameters = New Structure();
		ClosingParameters.Insert("ActionWithSurplusDocument", ActionWithSurplusDocument);
		ClosingParameters.Insert("ActionWithShortageDocument", ActionWithShortageDocument);
		ClosingParameters.Insert("ActionWithSurplusGoods", ActionWithSurplusGoods);
		ClosingParameters.Insert("ActionWithShortageGoods", ActionWithShortageGoods);
		Close(ClosingParameters);
	ElsIf NumberOfDiscrepancyPackaging > 0 Then
		ClosingParameters = New Structure();
		ClosingParameters.Insert("ActionWithDocument", ActionWithSurplusDocument);
		ClosingParameters.Insert("DiscrepancyTreatment", ActionWithSurplusGoods);
		Close(ClosingParameters);
	ElsIf NumberOfDiscrepancyPackaging < 0 Then
		ClosingParameters = New Structure();
		ClosingParameters.Insert("ActionWithDocument", ActionWithShortageDocument);
		ClosingParameters.Insert("DiscrepancyTreatment", ActionWithShortageGoods);
		Close(ClosingParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ClosingInProgress = True;
	Close(Undefined);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateHeadings()
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfAct) Then
		
		GenerateHeadingsOfImplementationReport();
	
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfAct) Then
		
		GenerateHeadingsActOfShipmentOfItemsToCustomer();
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfAct) Then
		
		GenerateReturnReportHeaders();
		
	ElsIf TypeOfAct = "Move" Then
		
		GenerateHeadingsOfActOfMoving();
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfAct)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfAct) Then
		
		GenerateTransferReportHeaders();
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfAct) Then
		
		GenerateVMIActHeadings();
	ElsIf TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider") Then
		
		GenerateHeadingsOfTransferActToGiver();
	
	ElsIf TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider") Then	
		
		GenerateHeadersOfReturnCertificateToGiver();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateHeadingsOfImplementationReport()
	
	// 1. Shortages
	Items.DecorationShortfallsAgreed.Title   = NStr("vi = 'Hàng thiếu khi bán đã thống nhất với khách hàng';
													|ru = 'Недостачи при реализации согласованы с клиентом';
													|en = 'Shortages on sales are approved with the customer'; fa = 'Shortages on sales are approved with the customer';
													|it = 'Ammanchi alla vendita concordati con il cliente';
													|pl = 'Niedobory podczas realizacji są uzgodnione z klientem';
													|tr = 'Satışlardaki eksiklikler müşteri ile kararlaştırılır'");
	Items.DecorationShortfallsNotAgreedUpon.Title = NStr("vi = 'Hàng thiếu khi bán chưa thống nhất với khách hàng';
														|ru = 'Недостачи при реализации не согласованы с клиентом';
														|en = 'Shortages on sales are not approved with the customer'; fa = 'Shortages on sales are not approved with the customer';
														|it = 'Ammanchi alla vendita non concordati con il cliente';
														|pl = 'Niedobory podczas realizacji nie są uzgodnione z klientem';
														|tr = 'Satışlardaki eksiklikler müşteri ile kararlaştırılmaz'");
	
	// 1.1. Correction (correction)
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		
		// Action With The Product
		Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
		Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
		
		Items.ReturnActionWithShortageGoods.Visible =
			UseShipmentWithDeferredTransferOfTitle2_5 And ValueIsFilled(Contract) And Not ThereIsPackage;
		Items.ReturnActionWithShortageGoodsDecoration.Visible =
			UseShipmentWithDeferredTransferOfTitle2_5 And ValueIsFilled(Contract) And Not ThereIsPackage;
		
		Items.ExpectActionWithShortageGoods.Visible = False;
		Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
		
		Items.TakeIntoAccountInventoryActionWithGoodsShortagesDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																						|ru = 'Расхождения учитываются при инвентаризации';
																						|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																						|it = 'Discrepancies are recognized upon physical inventory count';
																						|pl = 'Discrepancies are recognized upon physical inventory count';
																						|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		
		Items.ReturnActionWithShortageGoodsDecoration.Title = NStr("vi = 'Tạo điều chỉnh bán hàng để trả lại hàng ""đi đường""';
																	|ru = 'Оформляется корректировка реализации для возврата товаров ""в путь""';
																	|en = 'Register sales adjustment to return goods ""in transit""'; fa = 'ثبت تعدیل فروش برای بازگرداندن کالای ""در راه""';
																	|it = 'Register sales adjustment to return goods ""in transit""';
																	|pl = 'Register sales adjustment to return goods ""in transit""';
																	|tr = 'Yoldaki” ürünlerin iadesi için satış düzeltmesi düzenlenir'");
		
		// Action With A Document
		
		// ApplyAppearance
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Đối với mặt hàng chưa giao đủ, cần lập chứng từ điều chỉnh bán hàng (chỉnh sửa)';
																	|ru = 'На недопоставленный товар оформляется корректировка реализации (исправление)';
																	|en = 'For underdelivered goods, sales adjustment (correction) is registered'; fa = 'For underdelivered goods, sales adjustment (correction) is registered';
																	|it = 'For underdelivered goods, sales adjustment (correction) is registered';
																	|pl = 'For underdelivered goods, sales adjustment (correction) is registered';
																	|tr = 'Eksik tedarik edilen mal için satış düzeltmesi (düzeltme) düzenlenir'");
		
		// Issue and add
		If ThisIsTransferOfOwnership Then
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Đối với hàng hóa chưa giao đủ, cần lập chứng từ điều chỉnh bán hàng (chỉnh sửa) và sau đó lập chứng từ giao hàng mới cho khách đối với hàng hóa chưa giao đủ';
																		|ru = 'На недопоставленный товар оформляется корректировка реализации (исправление) с последующим оформлением новой отгрузки товаров клиенту недопоставленного товара';
																		|en = 'Sales adjustment is registered for underdelivered goods (correction), and a new shipment of underdelivered goods to customer is registered'; fa = 'Sales adjustment is registered for underdelivered goods (correction), and a new shipment of underdelivered goods to customer is registered';
																		|it = 'Sales adjustment is registered for underdelivered goods (correction), and a new shipment of underdelivered goods to customer is registered';
																		|pl = 'Sales adjustment is registered for underdelivered goods (correction), and a new shipment of underdelivered goods to customer is registered';
																		|tr = 'Eksik tedarik edilen mal için satış düzeltmesi (düzeltme) düzenlenir ve ardından müşteriye eksik teslim edilen malın yeni sevkiyatı düzenlenir'");
		Else
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Đối với mặt hàng chưa giao đủ, cần lập chứng từ điều chỉnh bán hàng (chỉnh sửa), sau đó lập chứng từ bán đối với mặt hàng chưa giao đủ';
																		|ru = 'На недопоставленный товар оформляется корректировка реализации (исправление) с последующим оформлением реализации недопоставленного товара';
																		|en = 'For underdelivered goods, sales adjustment (correction) is registered, and a new underdelivered goods sale is registered'; fa = 'For underdelivered goods, sales adjustment (correction) is registered, and a new underdelivered goods sale is registered';
																		|it = 'For underdelivered goods, sales adjustment (correction) is registered, and a new underdelivered goods sale is registered';
																		|pl = 'For underdelivered goods, sales adjustment (correction) is registered, and a new underdelivered goods sale is registered';
																		|tr = 'Eksik tedarik edilen mal için satış düzeltmesi (düzeltme) düzenlenir ve ardından eksik teslim edilen malın satışı düzenlenir'");
		EndIf;
		
	// 1.2. Adjustment (by agreement of the parties)
	ElsIf DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties") Then
	
		// Action With The Product
		Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
		Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
		
		Items.ReturnActionWithShortageGoods.Visible =
			UseShipmentWithDeferredTransferOfTitle2_5 And ValueIsFilled(Contract) And Not ThereIsPackage;
		Items.ReturnActionWithShortageGoodsDecoration.Visible =
			UseShipmentWithDeferredTransferOfTitle2_5 And ValueIsFilled(Contract) And Not ThereIsPackage;
		
		Items.ExpectActionWithShortageGoods.Visible = False;
		Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
		
		Items.TakeIntoAccountInventoryActionWithGoodsShortagesDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																						|ru = 'Расхождения учитываются при инвентаризации';
																						|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																						|it = 'Discrepancies are recognized upon physical inventory count';
																						|pl = 'Discrepancies are recognized upon physical inventory count';
																						|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		
		Items.ReturnActionWithShortageGoodsDecoration.Title = NStr("vi = 'Tạo điều chỉnh bán hàng để trả lại hàng ""đi đường""';
																	|ru = 'Оформляется корректировка реализации для возврата товаров ""в путь""';
																	|en = 'Register sales adjustment to return goods ""in transit""'; fa = 'ثبت تعدیل فروش برای بازگرداندن کالای ""در راه""';
																	|it = 'Register sales adjustment to return goods ""in transit""';
																	|pl = 'Register sales adjustment to return goods ""in transit""';
																	|tr = 'Yoldaki” ürünlerin iadesi için satış düzeltmesi düzenlenir'");
		
		// Action With A Document
		
		// ApplyAppearance
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Đã lập chứng từ điều chỉnh giao hàng đối với hàng hóa chưa giao đủ (theo thỏa thuận giữa các bên)';
																	|ru = 'На недопоставленный товар оформляется корректировка реализации (по согласованию сторон)';
																	|en = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties)'; fa = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties)';
																	|it = 'Per un prodotto non consegnato viene emesso un adeguamento di vendita (mediante accordo delle parti)';
																	|pl = 'Dla niedostarczonych towarów sporządza się korekcja realizacji (według uzgodnienia stron)';
																	|tr = 'Eksik teslim edilen mal için satış düzeltmesi (tarafların mutabakatıyla) düzenlenir'");
		
		// Issue and add
		If ThisIsTransferOfOwnership Then
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Đã lập chứng từ điều chỉnh giao hàng đối với hàng hóa chưa giao (theo thỏa thuận giữa các bên) và sau đó lập chứng từ giao hàng đối với hàng hóa chưa giao đủ';
																		|ru = 'На недопоставленный товар оформляется корректировка реализации (по согласованию сторон) с последующим оформлением отгрузки товаров клиенту недопоставленного товара';
																		|en = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties), and a new shipment of underdelivered goods to customer is registered'; fa = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties), and a new shipment of underdelivered goods to customer is registered';
																		|it = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties), and a new shipment of underdelivered goods to customer is registered';
																		|pl = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties), and a new shipment of underdelivered goods to customer is registered';
																		|tr = 'Eksik tedarik edilen mal için satış düzeltmesi (tarafların mutabakatıyla) düzenlenir ve ardından müşteriye eksik teslim edilen malın sevkiyatı düzenlenir'");
		Else
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Đã lập chứng từ điều chỉnh giao hàng đối với hàng hóa chưa giao đủ (theo thỏa thuận giữa các bên) và sau đó lập chứng từ giao hàng đối với hàng hóa chưa giao đủ';
																		|ru = 'На недопоставленный товар оформляется корректировка реализации (по согласованию сторон) с последующим оформлением реализации недопоставленного товара';
																		|en = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties) and a new underdelivered goods sale is registered'; fa = 'Sales adjustment is registered for underdelivered goods (as agreed by the parties) and a new underdelivered goods sale is registered';
																		|it = 'Per un prodotto non consegnato è emesso un adeguamento di vendita (mediante accordo delle parti) con la successiva realizzazione di vendita dei beni non consegnati';
																		|pl = 'Dla niedostarczonych towarów sporządza się korekcja realizacji (według uzgodnienia stron) z późniejszym sporządzeniem realizacji niedostarczonych towarów';
																		|tr = 'Teslim edilmeyen mallar için bir satış düzeltmesi (mutabık kalındığı üzere) yapılır ve teslim edilmeyen mallar daha sonra satılır.'");
		EndIf;
		
	// 1.3.
	ElsIf DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments") Then
		
		// Action With The Product
		Items.WriteOFFActionWithShortageGoods.Visible = False;
		Items.WriteOFFActionWithShortageGoodsDecoration.Visible = False;
		
		Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
		Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
		
		Items.ReturnActionWithShortageGoods.Visible = False;
		Items.ReturnActionWithShortageGoodsDecoration.Visible = False;
		
		Items.ExpectActionWithShortageGoods.Visible = False;
		Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
		
		Items.TakeIntoAccountInventoryActionWithGoodsShortagesDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																						|ru = 'Расхождения учитываются при инвентаризации';
																						|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																						|it = 'Discrepancies are recognized upon physical inventory count';
																						|pl = 'Discrepancies are recognized upon physical inventory count';
																						|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		
		// Actions with the document
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Đối với hàng hóa chưa giao đủ, sẽ tạo điều chỉnh bán hàng (trả lại hàng hóa chưa giao đủ)';
																	|ru = 'На недопоставленный товар оформляется корректировка реализации (возврат недопоставленного товара)';
																	|en = 'Sales adjustment (return of underdelivered goods) is registered for underdelivered goods'; fa = 'Sales adjustment (return of underdelivered goods) is registered for underdelivered goods';
																	|it = 'Per un prodotto non consegnato viene emesso un adeguamento di vendita (resa del prodotto non consegnato)';
																	|pl = 'Dla niedostarczonych towarów sporządza się korekcja realizacji (zwrot niedostarczonych towarów)';
																	|tr = 'Eksik teslim edilen mal için satış düzeltmesi (eksik teslim edilen malın iadesi) düzenlenir'");
		Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Đối với hàng hóa chưa giao đủ, sẽ tạo điều chỉnh bán hàng (trả lại hàng hóa chưa giao đủ) và sau đó, tạo giao hàng đối với việc giao thêm';
																	|ru = 'На недопоставленный товар оформляется корректировка реализации (возврат недопоставленного товара) с последующим оформлением реализации на допоставку';
																	|en = 'Sales adjustment (return of underdelivered goods) is registered for underdelivered goods and subsequent delivery sale is registered'; fa = 'Sales adjustment (return of underdelivered goods) is registered for underdelivered goods and subsequent delivery sale is registered';
																	|it = 'Per un prodotto non consegnato viene emesso un adeguamento di vendita (resa del prodotto non consegnato) con la successiva realizzazione di vendita e consegna';
																	|pl = 'Dla niedostarczonych towarów sporządza się korekcja realizacji (zwrot niedostarczonych towarów) z późniejszym sporządzeniem realizacji niedostarczonych towarów';
																	|tr = 'Eksik teslim edilen mal için satış düzeltmesi (eksik teslim edilen malın iadesi) düzenlenir ve ardından tamamlama teslimatı için satış düzenlenir'");
		
	// 1.4. Document modification
	Else // Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments
		
		// Action With The Product
		Items.WriteOFFActionWithShortageGoods.Visible = Not ThisIsTransferOfOwnership And Not ThisIsImplementationOfLocalAccounting;
		Items.WriteOFFActionWithShortageGoodsDecoration.Visible = Not ThisIsTransferOfOwnership And Not ThisIsImplementationOfLocalAccounting;
		
		Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = ThisIsTransferOfOwnership;
		Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = ThisIsTransferOfOwnership;
		
		Items.ReturnActionWithShortageGoods.Visible = ThisIsTransferOfOwnership;
		Items.ReturnActionWithShortageGoodsDecoration.Visible = ThisIsTransferOfOwnership;
		
		Items.ExpectActionWithShortageGoods.Visible = ThisIsTransferOfOwnership;
		Items.ExpectActionWithShortageGoodsDecoration.Visible = ThisIsTransferOfOwnership;
		
		If ThisIsTransferOfOwnership Then
			Items.TakeIntoAccountInventoryActionWithGoodsShortagesDecoration.Title = NStr("vi = 'Việc giao hàng cho khách sẽ được giảm tương ứng với phần hàng chưa giao đủ. Các chênh lệch được ghi nhận khi kiểm kê';
																							|ru = 'Отгрузка товаров клиенту уменьшается на недопоставленный товар. Расхождения учитываются при инвентаризации';
																							|en = 'Goods shipment to customer is reduced for underdelivered goods. Discrepancies are recognized upon physical inventory count'; fa = 'Goods shipment to customer is reduced for underdelivered goods. Discrepancies are recognized upon physical inventory count';
																							|it = 'Goods shipment to customer is reduced for underdelivered goods. Discrepancies are recognized upon physical inventory count';
																							|pl = 'Goods shipment to customer is reduced for underdelivered goods. Discrepancies are recognized upon physical inventory count';
																							|tr = 'Müşteriye ürün sevkiyatı, eksik teslim edilen mal kadar azaltılır. Tutarsızlıklar stok sayımında dikkate alınır'");
		Else
			Items.TakeIntoAccountInventoryActionWithGoodsShortagesDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																							|ru = 'Расхождения учитываются при инвентаризации';
																							|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																							|it = 'Discrepancies are recognized upon physical inventory count';
																							|pl = 'Discrepancies are recognized upon physical inventory count';
																							|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		EndIf;
		
		Items.ReturnActionWithShortageGoodsDecoration.Title = NStr("vi = 'Tạo tiếp nhận hàng hóa từ khách';
																	|ru = 'Оформляется поступление товаров от клиента';
																	|en = 'Goods receipt from customer is registered'; fa = 'Goods receipt from customer is registered';
																	|it = 'Goods receipt from customer is registered';
																	|pl = 'Goods receipt from customer is registered';
																	|tr = 'Müşteriden ürün alımı düzenlenir'");
		
		// Action With A Document
		
		// ApplyAppearance
		If (TheLineToOrder Or GroupUpdate And UseSalesOrders) And Not ThisIsTransferOfOwnership Then
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Giao hàng bị giảm đối với hàng hóa chưa giao đủ và sau đó, hủy bỏ các dòng chưa giao đủ của đơn hàng';
																		|ru = 'Реализация уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
																		|en = 'Sale is reduced for underdelivered goods, and underdelivered order lines are cancelled'; fa = 'Sale is reduced for underdelivered goods, and underdelivered order lines are cancelled';
																		|it = 'La vendita viene ridotta dai beni non consegnati con la conseguente cancellazione delle righe dell''ordine non consegnate.';
																		|pl = 'Realizacja zmniejsza się o niedostarczone towary z późniejszym anulowaniem niedostarczonych wierszy zamówienia';
																		|tr = 'Satış, eksik teslim edilen mal kadar azaltılır ve ardından eksik teslim edilen sipariş satırları iptal edilir'");
		Else
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Bán hàng bị giảm đối với hàng hóa chưa giao đủ';
																		|ru = 'Реализация уменьшается на недопоставленный товар';
																		|en = 'Sale is reduced for underdelivered goods'; fa = 'Sale is reduced for underdelivered goods';
																		|it = 'La vendita viene ridotta dai beni non consegnati';
																		|pl = 'Realizacja zmniejsza się o niedostarczone towary';
																		|tr = 'Satış, eksik teslim edilen mal kadar azaltılır'");
		EndIf;
		
		// Issue and add
		If ThisIsTransferOfOwnership Then
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Giao hàng bị giảm đối với mặt hàng giao thiếu, sau đó lập chứng từ mới để giao hàng còn thiếu cho khách';
																		|ru = 'Реализация уменьшается на недопоставленный товар с последующим оформлением новой отгрузки товаров клиенту недопоставленного товара';
																		|en = 'Sale is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered'; fa = 'Sale is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered';
																		|it = 'Sale is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered';
																		|pl = 'Sale is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered';
																		|tr = 'Satış, eksik teslim edilen mal kadar azaltılır ve ardından müşteriye eksik teslim edilen malın yeni sevkiyatı düzenlenir'");
		Else
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Giao hàng bị giảm đối với hàng hóa chưa giao đủ và sau đó tạo giao hàng mới cho hàng hóa chưa giao đủ';
																		|ru = 'Реализация уменьшается на недопоставленный товар с последующим оформлением новой реализации недопоставленного товара';
																		|en = 'Sale is reduced by underdelivered goods, new sale of underdelivered goods is registered'; fa = 'Sale is reduced by underdelivered goods, new sale of underdelivered goods is registered';
																		|it = 'La vendita viene ridotta dai beni non consegnati con la successiva registrazione della nuova vendita dei beni non consegnati';
																		|pl = 'Realizacja zmniejsza się o niedostarczone towary z późniejszym sporządzeniem nowej realizacji niedostarczonych towarów';
																		|tr = 'Satış, eksik teslim edilen mal kadar azaltılır ve ardından eksik teslim edilen malın yeni satışı düzenlenir'");
		EndIf;
		
	EndIf;
	
	// Add without registration
	If ThisIsTransferOfOwnership Then
		Items.ShipNowDecoration.Title = NStr("vi = 'Hàng hóa chưa giao được giao từ kho, chưa tạo lại chứng từ';
											|ru = 'Неотгруженный товар отгружается со склада, документы не переоформляются';
											|en = 'Unshipped goods are shipped from the warehouse. The documents are not registered'; fa = 'Unshipped goods are shipped from the warehouse. The documents are not registered';
											|it = 'Unshipped goods are shipped from the warehouse. The documents are not registered';
											|pl = 'Unshipped goods are shipped from the warehouse. The documents are not registered';
											|tr = 'Sevk edilmemiş mal ambardan sevk edilir, belgeler yeniden düzenlenmez'");
	Else
		Items.ShipNowDecoration.Title = NStr("vi = 'Hàng hóa chưa giao được giao từ kho, không tạo lại chứng từ';
											|ru = 'Недопоставленный товар отгружается со склада, документы не переоформляются';
											|en = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.';
											|it = 'Il prodotto non consegnato sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
											|pl = 'Niedostarczony towar wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
											|tr = 'Tedarik edilmeyen mallar stok dışı gönderilir, belgeler yeniden düzenlenmez'");
	EndIf;

	// Not to recognize
	Items.ShortageNotRecognizedDecoration.Title = NStr("vi = 'Hàng hóa không được giao không được vận chuyển từ kho, chứng từ không được xuất lại';
														|ru = 'Недопоставленный товар не отгружается со склада, документы не переоформляются';
														|en = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.';
														|it = 'Il prodotto non consegnato non sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
														|pl = 'Niedostarczony towar nie wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Teslim edilmeyen mallar depodan çıkarılmaz, belgeler yeniden düzenlenmez'");
	
	// 2. Surplus
	
	Items.DecorationSurplusAgreedUpon.Title   = NStr("vi = 'Hàng thừa khi bán có thỏa thuận với khách hàng';
													|ru = 'Излишки при реализации согласованы с клиентом';
													|en = 'Customer confirms the inventory surplus'; fa = 'Customer confirms the inventory surplus';
													|it = 'Eccedenze alla vendita concordate con il cliente';
													|pl = 'Nadmiary podczas realizacji są uzgodnione z klientem';
													|tr = 'Satışlardaki fazlalıklar müşteri ile kararlaştırılır'");
	Items.DecorationSurplusNotAgreedUpon.Title = NStr("vi = 'Hàng thừa khi bán không được thỏa thuận với khách hàng';
														|ru = 'Излишки при реализации не согласованы с клиентом';
														|en = 'Customer doesn''t confirm the inventory surplus'; fa = 'Customer doesn''t confirm the inventory surplus';
														|it = 'Eccedenze di vendita? non concordate con il cliente';
														|pl = 'Nadmiary podczas realizacji nie są uzgodnione z klientem';
														|tr = 'Satışlardaki fazlalıklar müşteri ile kararlaştırılmaz'");
	
	// 2.1.
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		
		// Action With The Product
		Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
		Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
		
		Items.TakeIntoAccountInventoryActionWithGoodsSurplusDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																					|ru = 'Расхождения учитываются при инвентаризации';
																					|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																					|it = 'Discrepancies are recognized upon physical inventory count';
																					|pl = 'Discrepancies are recognized upon physical inventory count';
																					|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		
		// Action With A Document
		
		// ApplyAppearance
		Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ điều chỉnh bán hàng';
														|ru = 'На перепоставленный товар оформляется корректировка реализации (исправление)';
														|en = 'For overdelivered goods, sales adjustment (correction) is registered'; fa = 'For overdelivered goods, sales adjustment (correction) is registered';
														|it = 'For overdelivered goods, sales adjustment (correction) is registered';
														|pl = 'For overdelivered goods, sales adjustment (correction) is registered';
														|tr = 'Fazla teslim edilen mal için satış düzeltmesi (düzeltme) düzenlenir'");
		
		// Issue and return
		If ThisIsTransferOfOwnership Then
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ điều chỉnh bán hàng, sau đó lập chứng từ điều chỉnh bán hàng mới để trả lại hàng hóa giao thừa ""đang đi đường""';
																|ru = 'На перепоставленный товар оформляется корректировка реализации (исправление) с последующим оформлением новой корректировки реализации на возврат перепоставленного товара ""в путь""';
																|en = 'Sales adjustment is registered for overdelivered goods (correction), and a new sales adjustment is registered to return the overdelivered goods ""in transit""'; fa = 'Sales adjustment is registered for overdelivered goods (correction), and a new sales adjustment is registered to return the overdelivered goods ""in transit""';
																|it = 'Sales adjustment is registered for overdelivered goods (correction), and a new sales adjustment is registered to return the overdelivered goods ""in transit""';
																|pl = 'Sales adjustment is registered for overdelivered goods (correction), and a new sales adjustment is registered to return the overdelivered goods ""in transit""';
																|tr = 'Fazla teslim edilen mal için satış düzeltmesi (düzeltme) düzenlenir ve ardından “yoldaki” fazla teslim edilen malın iadesi için yeni satış düzeltmesi düzenlenir'");
		Else
			
			If UseReturnRequests Then
				Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ điều chỉnh bán hàng, sau đó lập giấy đề nghị trả lại mặt hàng giao thừa';
																	|ru = 'На перепоставленный товар оформляется корректировка реализации (исправление) с последующим оформлением заявки на возврат перепоставленного товара';
																	|en = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return request is registered'; fa = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return request is registered';
																	|it = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return request is registered';
																	|pl = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return request is registered';
																	|tr = 'Fazla teslim edilen mal için satış düzeltmesi (düzeltme) düzenlenir ve ardından fazla teslim edilen malın iadesi için talep düzenlenir'");
			Else
				Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ điều chỉnh bán hàng, sau đó lập chứng từ trả lại mặt hàng giao thừa';
																	|ru = 'На перепоставленный товар оформляется корректировка реализации (исправление) с последующим оформлением возврата перепоставленного товара';
																	|en = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return is registered'; fa = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return is registered';
																	|it = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return is registered';
																	|pl = 'For overdelivered goods, sales adjustment (correction) is registered, and a new overdelivered goods return is registered';
																	|tr = 'Fazla teslim edilen mal için satış düzeltmesi (düzeltme) düzenlenir ve ardından fazla teslim edilen malın iadesi düzenlenir'");
			EndIf;
			
		EndIf;
		
	// 2.2.
	ElsIf DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties") Then
		
		// Action With The Product
		Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
		Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
		
		Items.TakeIntoAccountInventoryActionWithGoodsSurplusDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																					|ru = 'Расхождения учитываются при инвентаризации';
																					|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																					|it = 'Discrepancies are recognized upon physical inventory count';
																					|pl = 'Discrepancies are recognized upon physical inventory count';
																					|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		
		// Action With A Document
		
		// ApplyAppearance
		Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Đối với hàng hóa được giao thừa, có lập chứng từ điều chỉnh giao hàng (theo thỏa thuận giữa các bên)';
														|ru = 'На перепоставленный товар оформляется корректировка реализации (по согласованию сторон)';
														|en = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties)'; fa = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties)';
														|it = 'Per la merce fornita in eccesso viene emessa una rettifica di vendita (mediante accordo delle parti)';
														|pl = 'Dla nadmiaru dostarczonych towarów sporządza się zapis korygujący sprzedaży (według uzgodnienia stron)';
														|tr = 'Fazla teslim edilen mal için satış düzeltmesi (tarafların mutabakatıyla) düzenlenir'");
		
		// Issue and return
		If ThisIsTransferOfOwnership Then
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ điều chỉnh bán hàng (theo thỏa thuận giữa các bên), sau đó lập chứng từ điều chỉnh bán hàng mới để trả lại mặt hàng giao thừa ""hàng đi đường""';
																|ru = 'На перепоставленный товар оформляется корректировка реализации (по согласованию сторон) с последующим оформлением новой корректировки реализации на возврат перепоставленного товара ""в путь""';
																|en = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), and a new sales adjustment is registered to return the overdelivered goods ""in transit""'; fa = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), and a new sales adjustment is registered to return the overdelivered goods ""in transit""';
																|it = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), and a new sales adjustment is registered to return the overdelivered goods ""in transit""';
																|pl = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), and a new sales adjustment is registered to return the overdelivered goods ""in transit""';
																|tr = 'Fazla teslim edilen mal için satış düzeltmesi (tarafların mutabakatıyla) düzenlenir ve ardından “yoldaki” fazla teslim edilen malın iadesi için yeni satış düzeltmesi düzenlenir'");
		Else
			
			If UseReturnRequests Then
				Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, có lập chứng từ điều chỉnh bán hàng (theo thỏa thuận giữa các bên), sau đó lập giấy đề nghị trả lại mặt hàng giao thừa';
																	|ru = 'На перепоставленный товар оформляется корректировка реализации (по согласованию сторон) с последующим оформлением заявки на возврат перепоставленного товара';
																	|en = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), overdelivered goods return request will be registered'; fa = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), overdelivered goods return request will be registered';
																	|it = 'Si emette una rettifica di vendita (mediante accordo delle parti) con successiva emissione di domanda di reso per la merce fornita in eccesso';
																	|pl = 'Dla nadmiaru dostarczanego towaru sporządza się korekcja realizacji (według uzgodnienia stron) z późniejszym sporządzeniem zamówienia na zwrot nadmiaru dostarczanego towaru';
																	|tr = 'Fazla teslim edilen mal için satış düzeltmesi (tarafların mutabakatıyla) düzenlenir ve ardından fazla teslim edilen malın iadesi için talep düzenlenir'");
			Else
				Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, có lập chứng từ điều chỉnh bán hàng (theo thỏa thuận giữa các bên), sau đó lập chứng từ trả lại mặt hàng giao thừa';
																	|ru = 'На перепоставленный товар оформляется корректировка реализации (по согласованию сторон) с последующим оформлением возврата перепоставленного товара';
																	|en = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), overdelivered goods return will be registered'; fa = 'Sales adjustment is registered for overdelivered goods (as agreed by the parties), overdelivered goods return will be registered';
																	|it = 'Si emette una rettifica di vendita (mediante accordo delle parti) con successiva emissione di reso per la merce fornita in eccesso';
																	|pl = 'Dla nadmiaru dostarczanego towaru sporządza się wpis korygujący sprzedaży (według uzgodnienia stron) z późniejszym sporządzeniem zwrotu nadmiaru dostarczanego towaru';
																	|tr = 'Fazla teslim edilen mal için satış düzeltmesi (tarafların mutabakatıyla) düzenlenir ve ardından fazla teslim edilen malın iadesi düzenlenir'");
			EndIf;
			
		EndIf;
		
	ElsIf DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments") Then
		
		Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, có lập chứng từ điều chỉnh bán hàng (bán mặt hàng giao thừa)';
														|ru = 'На перепоставленный товар оформляется корректировка реализации (реализация перепоставленного)';
														|en = 'Sales adjustment (overdelivered goods sale) is registered for overdelivered goods'; fa = 'Sales adjustment (overdelivered goods sale) is registered for overdelivered goods';
														|it = 'Per un prodotto riconsegnato viene emesso un adeguamento di vendita (vendita di prodotti non consegnati)';
														|pl = 'Dla nadmiaru dostarczanego towaru sporządza się korekcja realizacji (realizajca nadmiaru dostarczanego towaru)';
														|tr = 'Fazla teslim edilen mal için satış düzeltmesi (fazla teslim edilenin satışı) düzenlenir'");
		
		// Action With The Product
		Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
		Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
		
		Items.TakeIntoAccountInventoryActionWithGoodsSurplusDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																					|ru = 'Расхождения учитываются при инвентаризации';
																					|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																					|it = 'Discrepancies are recognized upon physical inventory count';
																					|pl = 'Discrepancies are recognized upon physical inventory count';
																					|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		
		// Action With A Document
		If UseReturnRequests Then
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, có lập chứng từ điều chỉnh bán hàng (bán mặt hàng giao thừa), sau đó lập giấy đề nghị trả lại mặt hàng giao thừa';
																|ru = 'На перепоставленный товар оформляется корректировка реализации (реализация перепоставленного товара) с последующим оформлением заявки на возврат перепоставленного товара';
																|en = 'Sales adjustment (overdelivered goods sale) is registered for overdelivered goods. A request for return of overdelivered goods will be registered'; fa = 'Sales adjustment (overdelivered goods sale) is registered for overdelivered goods. A request for return of overdelivered goods will be registered';
																|it = 'Per un prodotto riconsegnato è emesso un adeguamento di vendita (correzione di errori) con la successiva  domanda per la restituzione dei beni non consegnati';
																|pl = 'Dla nadmiaru dostarczanego towaru sporządza się korekcja realizacji (realizajca nadmiaru dostarczanego towaru) z późniejszym sporządzeniem zamówienia na zwrot nadmiaru dostarczanego towaru';
																|tr = 'Fazla teslim edilen mal için satış düzeltmesi (fazla teslim edilen malın satışı) düzenlenir ve ardından fazla teslim edilen malın iadesi için talep düzenlenir.'");
		Else
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thừa, có lập chứng từ điều chỉnh bán hàng (bán mặt hàng giao thừa), sau đó lập chứng từ trả lại mặt hàng giao thừa';
																|ru = 'На перепоставленный товар оформляется корректировка реализации (реализация перепоставленного товара) с последующим оформлением возврата перепоставленного товара';
																|en = 'Sales adjustment (overdelivered goods sale) is registered for overdelivered goods, return of overdelivered goods will be registered'; fa = 'Sales adjustment (overdelivered goods sale) is registered for overdelivered goods, return of overdelivered goods will be registered';
																|it = 'Per un prodotto riconsegnato è emesso un adeguamento di vendita (correzione di errori) con la successiva esecuzione della restituzione dei beni non consegnati';
																|pl = 'Dla nadmiaru dostarczanego towaru sporządza się korekcja realizacji (realizajca nadmiaru dostarczanego towaru) z późniejszym sporządzeniem zwrotu nadmiaru dostarczanego towaru';
																|tr = 'Fazla teslim edilen mal için satış düzeltmesi (fazla teslim edilen malın satışı) düzenlenir ve ardından fazla teslim edilen malın iadesi düzenlenir'");
		EndIf;
		
	Else // Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments
		
		// Action With The Product
		Items.EnterIntoWayOfActionWithSurplusGoods.Visible = ThisIsTransferOfOwnership;
		Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = ThisIsTransferOfOwnership;
		
		If ThisIsTransferOfOwnership Then
			Items.TakeIntoAccountInventoryActionWithGoodsSurplusDecoration.Title = NStr("vi = 'Việc giao hàng cho khách sẽ được tăng đối với hàng chưa giao đủ. Các chênh lệch được ghi nhận khi kiểm kê';
																						|ru = 'Отгрузка товаров клиенту увеличивается на недопоставленный товар. Расхождения учитываются при инвентаризации';
																						|en = 'Goods shipment to customer is increased for underdelivered goods. Discrepancies are recognized upon physical inventory count'; fa = 'Goods shipment to customer is increased for underdelivered goods. Discrepancies are recognized upon physical inventory count';
																						|it = 'Goods shipment to customer is increased for underdelivered goods. Discrepancies are recognized upon physical inventory count';
																						|pl = 'Goods shipment to customer is increased for underdelivered goods. Discrepancies are recognized upon physical inventory count';
																						|tr = 'Müşteriye ürün sevkiyatı, eksik teslim edilen mal kadar artırılır. Tutarsızlıklar stok sayımında dikkate alınır'");
		Else
			Items.TakeIntoAccountInventoryActionWithGoodsSurplusDecoration.Title = NStr("vi = 'Chênh lệch được ghi nhận khi kiểm kê';
																						|ru = 'Расхождения учитываются при инвентаризации';
																						|en = 'Discrepancies are recognized upon physical inventory count'; fa = 'مغایرت‌ها در شمارش فیزیکی موجودی شناسایی می‌شوند';
																						|it = 'Discrepancies are recognized upon physical inventory count';
																						|pl = 'Discrepancies are recognized upon physical inventory count';
																						|tr = 'Tutarsızlıklar stok sayımında dikkate alınır'");
		EndIf;
		
		// Action With A Document
		
		// ApplyAppearance
		Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Tăng doanh số cho mặt hàng giao thừa';
														|ru = 'Реализация увеличивается на перепоставленный товар';
														|en = 'Sales increases for overdelivered products'; fa = 'Sales increases for overdelivered products';
														|it = 'La vendita aumenta con la riconsegna delle merci';
														|pl = 'Realizacja powiększa się o nadmiar dostarczanego towaru';
														|tr = 'Satış, fazla tedarik edilen mal kadar artırılır'");
		
		// Issue and return
		If ThisIsTransferOfOwnership Then
			
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Doanh số tăng lên do mặt hàng giao thừa, sau đó tạo điều chỉnh giao hàng để trả lại đối với mặt hàng giao thừa ""hàng đi đường""';
																|ru = 'Реализация увеличиваются на перепоставленный товар с последующим оформлением корректировки реализации на возврат перепоставленного товара ""в путь""';
																|en = 'Sale is increased by the amount of overdelivered goods, and a sales adjustment is registered to return the overdelivered goods ""in transit""'; fa = 'Sale is increased by the amount of overdelivered goods, and a sales adjustment is registered to return the overdelivered goods ""in transit""';
																|it = 'Sale is increased by the amount of overdelivered goods, and a sales adjustment is registered to return the overdelivered goods ""in transit""';
																|pl = 'Sale is increased by the amount of overdelivered goods, and a sales adjustment is registered to return the overdelivered goods ""in transit""';
																|tr = 'Satış, fazla tedarik edilen mal kadar artırılır ve ardından “yoldaki” fazla tedarik edilen malın iadesi için satış düzeltmesi düzenlenir'");
			
		Else
			
			If UseReturnRequests Then
				Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Doanh số tăng lên do mặt hàng giao thừa, sau đó tạo giấy đề nghị trả lại đối với mặt hàng giao thừa';
																	|ru = 'Реализация увеличивается на перепоставленный товар с последующим оформлением заявки на возврат перепоставленного товара';
																	|en = 'Sale is increased by the amount of overdelivered goods. A request for return of overdelivered goods will be registered'; fa = 'Sale is increased by the amount of overdelivered goods. A request for return of overdelivered goods will be registered';
																	|it = 'La vendita aumenta con la riconsegna delle merci con la successiva esecuzione della domanda per la restituzione della merce consegnata';
																	|pl = 'Realizacja powiększa się o nadmiar dostarczanego towaru z późniejszym sporządzeniem zamówienia na zwrot nadmiaru dostarczanego towaru';
																	|tr = 'Satış, fazla tedarik edilen mal kadar artırılır ve ardından fazla tedarik edilen malın iadesi için talep düzenlenir'");
			Else
				Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Doanh số tăng lên do mặt hàng giao thừa, sau đó tạo chứng từ trả lại đối với mặt hàng giao thừa';
																	|ru = 'Реализация увеличивается на перепоставленный товар с последующим оформлением возврата перепоставленного товара';
																	|en = 'Sale is increased by overdelivered goods, return of overdelivered goods will be registered'; fa = 'Sale is increased by overdelivered goods, return of overdelivered goods will be registered';
																	|it = 'La vendita aumenta con la riconsegna delle merci con la successiva esecuzione della restituzione della merce consegnata';
																	|pl = 'Realizacja powiększa się o nadmiar dostarczanego towaru z późniejszym sporządzeniem zwrotu nadmiaru dostarczanego towaru';
																	|tr = 'Satış, fazla tedarik edilen mal kadar artırılır ve ardından fazla tedarik edilen malın iadesi düzenlenir'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Items.TheRepostedIsGivenAsADecoration.Title = NStr("vi = 'Hàng hóa vận chuyển lại không được trả lại kho, chứng từ không được cấp lại';
														|ru = 'Перепоставленный товар не возвращается на склад, документы не переоформляются';
														|en = 'Overdelivered goods are not returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are not returned to the warehouse. The documents are not registered';
														|it = 'Il prodotto riconsegnato non viene rimesso in magazzino, i documenti non si effettuano nuovamente';
														|pl = 'Nadmiar dostarczanego towaru nie zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Yeniden teslim edilen mallar stoka iade edilmeyecek ve belgeler yeniden düzenlenmeyecektir'");
	Items.EnterNowDecoration.Title = NStr("vi = 'Hàng giao lại được trả lại kho, chứng từ không được cấp lại';
											|ru = 'Перепоставленный товар возвращается на склад, документы не переоформляются';
											|en = 'Overdelivered goods are returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are returned to the warehouse. The documents are not registered';
											|it = 'Il prodotto riconsegnato ritorna in magazzino, i documenti non si effettuano nuovamente';
											|pl = 'Nadmiar dostarczanego towaru zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
											|tr = 'Fazla tedarik edilen mallar depoya iade edilir, belgeler yeniden düzenlenmez'");
	
EndProcedure

&AtClient
Procedure GenerateHeadingsActOfShipmentOfItemsToCustomer()

	// Shortages
	Items.DecorationShortfallsAgreed.Title   = NStr("vi = 'Hàng thiếu khi giao đã được thống nhất với khách hàng';
													|ru = 'Недостачи при отгрузке согласованы с клиентом';
													|en = 'Shortages on shipment are approved by the customer'; fa = 'Shortages on shipment are approved by the customer';
													|it = 'Shortages on shipment are approved by the customer';
													|pl = 'Shortages on shipment are approved by the customer';
													|tr = 'Sevkiyattaki eksiklikler, müşteri ile kararlaştırılır'");
	Items.DecorationShortfallsNotAgreedUpon.Title = NStr("vi = 'Hàng thiếu khi giao không được thống nhất với khách hàng';
														|ru = 'Недостачи при отгрузке не согласованы с клиентом';
														|en = 'Shortages on shipment are not approved by the customer'; fa = 'Shortages on shipment are not approved by the customer';
														|it = 'Shortages on shipment are not approved by the customer';
														|pl = 'Shortages on shipment are not approved by the customer';
														|tr = 'Satışlardaki eksiklikler müşteri ile kararlaştırılmamaktadır'");
	
	// Action With The Product
	Items.WriteOFFActionWithShortageGoods.Visible = False;
	Items.WriteOFFActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ReturnActionWithShortageGoodsDecoration.Title = NStr("vi = 'Tạo tiếp nhận hàng hóa từ khách';
																|ru = 'Оформляется поступление товаров от клиента';
																|en = 'Goods receipt from customer is registered'; fa = 'Goods receipt from customer is registered';
																|it = 'Goods receipt from customer is registered';
																|pl = 'Goods receipt from customer is registered';
																|tr = 'Müşteriden mal girişi düzenlenir'");
	
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		
		// Action With A Document
		
		// ApplyAppearance
		If ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit")
			Or ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_") Then
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Chưa tạo chỉnh sửa giao hàng cho khách';
																		|ru = 'Исправление отгрузки товаров клиенту не оформляется';
																		|en = 'Registering adjustment in goods shipment to customer is not required'; fa = 'Registering adjustment in goods shipment to customer is not required';
																		|it = 'Registering adjustment in goods shipment to customer is not required';
																		|pl = 'Registering adjustment in goods shipment to customer is not required';
																		|tr = 'Müşteriye mal sevkiyatı düzeltmesi düzenlenmez'");
		Else
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Đối với hàng hóa thiếu hụt, sẽ lập chứng từ điều chỉnh xuất hàng cho khách hàng, sau đó hủy các dòng thiếu hụt của đơn hàng';
																		|ru = 'На недопоставленный товар оформляется исправление отгрузки товаров клиенту с последующей отменой недопоставленных строк заказа';
																		|en = 'For underdelivered goods, an adjustment of goods shipment to customer is registered, followed by cancellation of the underdelivered order lines'; fa = 'For underdelivered goods, an adjustment of goods shipment to customer is registered, followed by cancellation of the underdelivered order lines';
																		|it = 'For underdelivered goods, an adjustment of goods shipment to customer is registered, followed by cancellation of the underdelivered order lines';
																		|pl = 'For underdelivered goods, an adjustment of goods shipment to customer is registered, followed by cancellation of the underdelivered order lines';
																		|tr = 'Eksik teslim edilen ürünler için, müşteriye ürün sevkiyatının düzeltilmesi ve ardından eksik teslim edilen sipariş satırlarının iptali düzenlenir'");
		EndIf;
		
		// Issue and add
		If ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit")
			Or ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_") Then
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Tạo giao hàng mới cho khách đối với hàng hóa chưa giao';
																		|ru = 'Оформляется новая отгрузка товаров клиенту на недопоставленный товар';
																		|en = 'A new goods shipment to customer is registered for underdelivered goods'; fa = 'A new goods shipment to customer is registered for underdelivered goods';
																		|it = 'A new goods shipment to customer is registered for underdelivered goods';
																		|pl = 'A new goods shipment to customer is registered for underdelivered goods';
																		|tr = 'Eksik teslim edilen mal için yeni bir müşteriye ürün sevkiyatı düzenlenir'");
		Else
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Đối với hàng giao thiếu, có lập điều chỉnh giao hàng cho khách, sau đó lập chứng từ mới để giao hàng thiếu cho khách';
																		|ru = 'На недопоставленный товар оформляется исправление отгрузки товаров клиенту с последующим оформлением новой отгрузки товаров клиенту недопоставленного товара';
																		|en = 'Adjustment of goods shipment to the customer is registered for underdelivered goods, and a new shipment of underdelivered goods to the customer is registered'; fa = 'Adjustment of goods shipment to the customer is registered for underdelivered goods, and a new shipment of underdelivered goods to the customer is registered';
																		|it = 'Adjustment of goods shipment to the customer is registered for underdelivered goods, and a new shipment of underdelivered goods to the customer is registered';
																		|pl = 'Adjustment of goods shipment to the customer is registered for underdelivered goods, and a new shipment of underdelivered goods to the customer is registered';
																		|tr = 'Eksik teslim edilen mal için müşteriye mal sevkiyatı düzeltmesi düzenlenir ve ardından müşteriye eksik teslim edilen malın yeni sevkiyatı düzenlenir'");
		EndIf;
		
	Else // Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments
		
		// Action With A Document
		
		// ApplyAppearance
		If ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit")
			Or ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_") Then
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Không thay đổi giao hàng cho khách';
																		|ru = 'Отгрузка товаров клиенту не изменяется';
																		|en = 'Changing goods shipment to customer is not required'; fa = 'Changing goods shipment to customer is not required';
																		|it = 'Changing goods shipment to customer is not required';
																		|pl = 'Changing goods shipment to customer is not required';
																		|tr = 'Müşteriye ürün sevkiyatı değiştirilmez'");
		Else
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Giao hàng cho khách bị giảm đối với mặt hàng giao thiếu, sau đó hủy các dòng giao thiếu trong đơn hàng';
																		|ru = 'Отгрузка товаров клиенту уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
																		|en = 'Goods shipment to customer is reduced for underdelivered goods, and underdelivered order lines are cancelled'; fa = 'Goods shipment to customer is reduced for underdelivered goods, and underdelivered order lines are cancelled';
																		|it = 'Goods shipment to customer is reduced for underdelivered goods, and underdelivered order lines are cancelled';
																		|pl = 'Goods shipment to customer is reduced for underdelivered goods, and underdelivered order lines are cancelled';
																		|tr = 'Müşteriye ürün sevkiyatı, eksik teslim edilen mal kadar azaltılır ve ardından eksik teslim edilen sipariş satırları iptal edilir'");
		EndIf;
		
		// Issue and add
		If ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit")
			Or ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_") Then
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Tạo giao hàng mới cho khách đối với hàng hóa chưa giao';
																		|ru = 'Оформляется новая отгрузка товаров клиенту на недопоставленный товар';
																		|en = 'A new goods shipment to customer is registered for underdelivered goods'; fa = 'A new goods shipment to customer is registered for underdelivered goods';
																		|it = 'A new goods shipment to customer is registered for underdelivered goods';
																		|pl = 'A new goods shipment to customer is registered for underdelivered goods';
																		|tr = 'Eksik teslim edilen mal için yeni bir müşteriye ürün sevkiyatı düzenlenir'");
		Else
			Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Giao hàng cho khách bị giảm đối với mặt hàng giao thiếu, sau đó lập chứng từ mới để giao hàng còn thiếu cho khách';
																		|ru = 'Отгрузка товаров клиенту уменьшается на недопоставленный товар с последующим оформлением новой отгрузки товаров клиенту недопоставленного товара';
																		|en = 'Goods shipment to customer is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered'; fa = 'Goods shipment to customer is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered';
																		|it = 'Goods shipment to customer is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered';
																		|pl = 'Goods shipment to customer is reduced for the underdelivered goods, and a new shipment of underdelivered goods to customer is registered';
																		|tr = 'Müşteriye ürün sevkiyatı, eksik teslim edilen mal kadar azaltılır ve ardından müşteriye eksik teslim edilen malın yeni sevkiyatı düzenlenir'");
		EndIf;
		
	EndIf;
	
	// Add without registration
	Items.ShipNowDecoration.Title = NStr("vi = 'Hàng giao thiếu được xuất kho, chứng từ không được lập lại, chứng từ bán hàng được ghi nhận mà không tính đến các chênh lệch';
										|ru = 'Недопоставленный товар отгружается со склада, документы не переоформляются, реализация оформляется без учета расхождений';
										|en = 'Underdelivered goods are shipped from the warehouse. The documents are not registered, the sale is registered without considering discrepancies'; fa = 'Underdelivered goods are shipped from the warehouse. The documents are not registered, the sale is registered without considering discrepancies';
										|it = 'Underdelivered goods are shipped from the warehouse. The documents are not registered, the sale is registered without considering discrepancies';
										|pl = 'Underdelivered goods are shipped from the warehouse. The documents are not registered, the sale is registered without considering discrepancies';
										|tr = 'Eksik teslim edilen mal ambardan sevk edilir, belgeler yeniden düzenlenmez, satış tutarsızlıklar dikkate alınmadan düzenlenir'");
	
	// Not to recognize
	If Items.GoodsShortageIsControversial.ChoiceList.Count() > 0 Then
		Items.GoodsShortageIsControversial.ChoiceList[0].Presentation = NStr("vi = 'Không công nhận và không tính chênh lệch trong bán hàng';
																			|ru = 'Не признавать и не учитывать расхождения в реализации';
																			|en = 'Do not recognize and do not consider discrepancies in sale'; fa = 'Do not recognize and do not consider discrepancies in sale';
																			|it = 'Do not recognize and do not consider discrepancies in sale';
																			|pl = 'Do not recognize and do not consider discrepancies in sale';
																			|tr = 'Gerçekleştirmelerdeki farklılıkların muhasebeleştirilmemesi veya hesaba katılmaması'");
	EndIf;
	
	Items.ShortageNotRecognizedDecoration.Title = NStr("vi = 'Chênh lệch không được ghi nhận, chứng từ không được lập lại, chứng từ bán hàng được ghi nhận mà không tính đến các phần chênh lệch';
														|ru = 'Расхождения не признаются, документы не переоформляются, реализация оформляется без учета расхождений';
														|en = 'Discrepancies are not recognized. The documents are not registered, the sale is registered without considering discrepancies'; fa = 'Discrepancies are not recognized. The documents are not registered, the sale is registered without considering discrepancies';
														|it = 'Discrepancies are not recognized. The documents are not registered, the sale is registered without considering discrepancies';
														|pl = 'Discrepancies are not recognized. The documents are not registered, the sale is registered without considering discrepancies';
														|tr = 'Tutarsızlıklar kabul edilmez, belgeler yeniden düzenlenmez, satış tutarsızlıklar dikkate alınmadan düzenlenir'");
	
	// Surpluses
	
	Items.DecorationSurplusAgreedUpon.Title   = NStr("vi = 'Hàng thừa khi giao hàng đã thỏa thuận với khách hàng';
													|ru = 'Излишки при отгрузке согласованы с клиентом';
													|en = 'Surpluses on shipment are approved by customer'; fa = 'Surpluses on shipment are approved by customer';
													|it = 'Surpluses on shipment are approved by customer';
													|pl = 'Surpluses on shipment are approved by customer';
													|tr = 'Sevkiyatlardaki fazlalıklar müşteri ile kararlaştırılır'");
	Items.DecorationSurplusNotAgreedUpon.Title = NStr("vi = 'Hàng thừa khi giao hàng chưa được thỏa thuận với khách';
														|ru = 'Излишки при отгрузке не согласованы с клиентом';
														|en = 'Surpluses on shipment are not approved by customer'; fa = 'Surpluses on shipment are not approved by customer';
														|it = 'Surpluses on shipment are not approved by customer';
														|pl = 'Surpluses on shipment are not approved by customer';
														|tr = 'Sevkiyatlardaki fazlalıklar müşteri ile kararlaştırılmaz'");
	
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		
		// ApplyAppearance
		If ActionWithSurplusGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
			Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Chưa tạo chỉnh sửa giao hàng cho khách';
															|ru = 'Исправление отгрузки товаров клиенту не оформляется';
															|en = 'Registering adjustment in goods shipment to customer is not required'; fa = 'Registering adjustment in goods shipment to customer is not required';
															|it = 'Registering adjustment in goods shipment to customer is not required';
															|pl = 'Registering adjustment in goods shipment to customer is not required';
															|tr = 'Müşteriye mal sevkiyatı düzeltmesi düzenlenmez'");
		Else
			Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Đối với hàng giao thừa, có lập chứng từ chỉnh sửa giao hàng cho khách';
															|ru = 'На перепоставленный товар оформляется исправление отгрузки товаров клиенту';
															|en = 'For overdelivered goods, an adjustment of goods shipment to customer is registered'; fa = 'For overdelivered goods, an adjustment of goods shipment to customer is registered';
															|it = 'For overdelivered goods, an adjustment of goods shipment to customer is registered';
															|pl = 'For overdelivered goods, an adjustment of goods shipment to customer is registered';
															|tr = 'Fazla tedarik edilen mal için müşteriye mal sevkiyatı düzeltmesi düzenlenir'");
		EndIf;
		
		// Issue and return
		If ActionWithSurplusGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Tạo tiếp nhận hàng hóa từ khách để trả lại hàng hóa giao thừa';
																|ru = 'Оформляется поступление товаров от клиента для возврата перепоставленного товара';
																|en = 'Goods receipt from customer is registered to return overdelivered goods'; fa = 'Goods receipt from customer is registered to return overdelivered goods';
																|it = 'Goods receipt from customer is registered to return overdelivered goods';
																|pl = 'Goods receipt from customer is registered to return overdelivered goods';
																|tr = 'Fazla teslim edilen ürünün iadesi için müşteriden ürün girişi düzenlenir'");
		Else
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Đối với hàng giao thừa, có lập chứng từ chỉnh sửa giao hàng cho khách, sau đó lập chứng từ tiếp nhận hàng từ khách để trả lại hàng giao thừa';
																|ru = 'На перепоставленный товар оформляется исправление отгрузки товаров клиенту с последующим оформлением поступления товаров от клиента для возврата перепоставленного товара';
																|en = 'Register adjustment in goods shipment to customer for overdelivered goods, followed by registering goods receipt from customer to return the overdelivered goods'; fa = 'Register adjustment in goods shipment to customer for overdelivered goods, followed by registering goods receipt from customer to return the overdelivered goods';
																|it = 'Register adjustment in goods shipment to customer for overdelivered goods, followed by registering goods receipt from customer to return the overdelivered goods';
																|pl = 'Register adjustment in goods shipment to customer for overdelivered goods, followed by registering goods receipt from customer to return the overdelivered goods';
																|tr = 'Fazla tedarik edilen mal için müşteriye mal sevkiyatı düzeltmesi düzenlenir ve ardından fazla tedarik edilen malın iadesi için müşteriden mal girişi düzenlenir'");
		EndIf;
		
	Else // Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments
		
		// ApplyAppearance
		If ActionWithSurplusGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
			Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Không thay đổi giao hàng cho khách';
															|ru = 'Отгрузка товаров клиенту не изменяется';
															|en = 'Changing goods shipment to customer is not required'; fa = 'Changing goods shipment to customer is not required';
															|it = 'Changing goods shipment to customer is not required';
															|pl = 'Changing goods shipment to customer is not required';
															|tr = 'Müşteriye ürün sevkiyatı değiştirilmez'");
		Else
			Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Lượng hàng hóa giao cho khách tăng lên đối với hàng giao thừa';
															|ru = 'Отгрузка товаров клиенту увеличивается на перепоставленный товар';
															|en = 'Goods shipment to customer is increased for overdelivered goods'; fa = 'Goods shipment to customer is increased for overdelivered goods';
															|it = 'Goods shipment to customer is increased for overdelivered goods';
															|pl = 'Goods shipment to customer is increased for overdelivered goods';
															|tr = 'Müşteriye mal sevkiyatı, fazla tedarik edilen mal kadar artırılır'");
		EndIf;
		
		// Issue and return
		If ActionWithSurplusGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Tạo tiếp nhận hàng hóa từ khách để trả lại hàng hóa giao thừa';
																|ru = 'Оформляется поступление товаров от клиента для возврата перепоставленного товара';
																|en = 'Goods receipt from customer is registered to return overdelivered goods'; fa = 'Goods receipt from customer is registered to return overdelivered goods';
																|it = 'Goods receipt from customer is registered to return overdelivered goods';
																|pl = 'Goods receipt from customer is registered to return overdelivered goods';
																|tr = 'Fazla teslim edilen ürünün iadesi için müşteriden ürün girişi düzenlenir'");
		Else
			Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Lượng hàng hóa giao cho khách tăng lên đối với hàng giao thừa, sau đó lập chứng từ trả lại hàng giao thừa';
																|ru = 'Отгрузка товаров клиенту увеличивается на перепоставленный товар с последующим оформлением возврата перепоставленного товара';
																|en = 'Goods shipment to customer is increased for overdelivered goods, and overdelivered goods return is registered'; fa = 'Goods shipment to customer is increased for overdelivered goods, and overdelivered goods return is registered';
																|it = 'Goods shipment to customer is increased for overdelivered goods, and overdelivered goods return is registered';
																|pl = 'Goods shipment to customer is increased for overdelivered goods, and overdelivered goods return is registered';
																|tr = 'Müşteriye yapılan sevkiyat, fazla teslim edilen ürün kadar artırılır ve ardından fazla teslim edilen ürünün iadesi düzenlenir.'");
		EndIf;
		
	EndIf;
	
	// Return without registration
	Items.EnterNowDecoration.Title = NStr("vi = 'Hàng giao thiếu được trả về kho, chứng từ không được lập lại, chứng từ bán hàng được ghi nhận mà không tính đến phần chênh lệch';
											|ru = 'Перепоставленный товар возвращается на склад, документы не переоформляются, реализация оформляется без учета расхождений';
											|en = 'Overdelivered goods are returned to the warehouse. The documents are not registered, the sale is registered without considering discrepancies'; fa = 'Overdelivered goods are returned to the warehouse. The documents are not registered, the sale is registered without considering discrepancies';
											|it = 'Overdelivered goods are returned to the warehouse. The documents are not registered, the sale is registered without considering discrepancies';
											|pl = 'Overdelivered goods are returned to the warehouse. The documents are not registered, the sale is registered without considering discrepancies';
											|tr = 'Fazla teslim edilen ürün depoya iade edilir, belgeler yeniden düzenlenmez, satış işlemi tutarsızlıklar dikkate alınmadan düzenlenir.'");

	// Not to recognize
	Items.TheRepostedIsGivenAsADecoration.Title = NStr("vi = 'Hàng hóa vận chuyển lại không được trả lại kho, chứng từ không được cấp lại';
														|ru = 'Перепоставленный товар не возвращается на склад, документы не переоформляются';
														|en = 'Overdelivered goods are not returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are not returned to the warehouse. The documents are not registered';
														|it = 'Il prodotto riconsegnato non viene rimesso in magazzino, i documenti non si effettuano nuovamente';
														|pl = 'Nadmiar dostarczanego towaru nie zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Yeniden teslim edilen mallar stoka iade edilmeyecek ve belgeler yeniden düzenlenmeyecektir'");

	If Items.DisregardShortage.ChoiceList.Count() > 0 Then
		Items.DisregardShortage.ChoiceList[0].Presentation = NStr("vi = 'Không công nhận và không tính chênh lệch trong bán hàng';
																	|ru = 'Не признавать и не учитывать расхождения в реализации';
																	|en = 'Do not recognize and do not consider discrepancies in sale'; fa = 'Do not recognize and do not consider discrepancies in sale';
																	|it = 'Do not recognize and do not consider discrepancies in sale';
																	|pl = 'Do not recognize and do not consider discrepancies in sale';
																	|tr = 'Gerçekleştirilmelerde tutarsızlıkların muhasebeleştirilmemesi ve hesaba katılmaması'");
	EndIf;

EndProcedure

&AtClient
Procedure GenerateReturnReportHeaders()
	
	// Shortages
	Items.DecorationShortfallsAgreed.Title   = NStr("vi = 'Hàng thiếu khi trả lại đã được thỏa thuận với nhà cung cấp';
													|ru = 'Недостачи при возврате согласованы с поставщиком';
													|en = 'Shortages on return are approved by the vendor'; fa = 'Shortages on return are approved by the vendor';
													|it = 'Ammanchi alla riconsegna concordati con il fornitore';
													|pl = 'Niedobory podczas zwrotu są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınan iade eksiklikleri'");
	Items.DecorationShortfallsNotAgreedUpon.Title = NStr("vi = 'Hàng thiếu khi trả lại không được thỏa thuận với nhà cung cấp';
														|ru = 'Недостачи при возврате не согласованы с поставщиком';
														|en = 'Shortages on return are not approved by the vendor'; fa = 'Shortages on return are not approved by the vendor';
														|it = 'Ammanchi alla riconsegna non concordati con il fornitore';
														|pl = 'Niedobory podczas zwrotu nie są uzgodnione z dostawcą';
														|tr = 'Tedarikçi ile mutabık kalınmayan iade eksiklikleri'");
	
	// Action With The Product
	Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
	Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
	
	Items.ReturnActionWithShortageGoods.Visible = False;
	Items.ReturnActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ExpectActionWithShortageGoods.Visible = False;
	Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
	
	// Action With A Document
	Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Việc trả lại hàng hóa cho nhà cung cấp bị giảm bởi hàng hóa chưa được giao';
																|ru = 'Возврат товаров поставщику уменьшается на недопоставленный товар';
																|en = 'Return of goods to vendor is reduced by the amount of underdelivered goods'; fa = 'Return of goods to vendor is reduced by the amount of underdelivered goods';
																|it = 'La riconsegna dei prodotti al fornitore diminuisce con i prodotti non consegnati';
																|pl = 'Zwrot towaru dostawcy zmniejsza się o niedostarczone towary';
																|tr = 'Teslim edilmeyen mallar nedeniyle azalan malların tedarikçiye iadesi'");
	Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Việc trả lại hàng hóa cho nhà cung cấp bị giảm bởi hàng hóa chưa được giao với việc thực hiện tiếp theo một khoản hoàn trả mới của hàng hóa chưa được giao';
																|ru = 'Возврат товаров поставщику уменьшается на недопоставленный товар с последующим оформлением нового возврата недопоставленного товара';
																|en = 'Return of goods to vendor is reduced by the amount of underdelivered goods, a new return of underdelivered goods is registered'; fa = 'Return of goods to vendor is reduced by the amount of underdelivered goods, a new return of underdelivered goods is registered';
																|it = 'La riconsegna viene decurtata dei beni non consegnati con la successiva registrazione della nuova restituzione dei beni non consegnati';
																|pl = 'Zwrot towaru dostawcy zmniejsza się o niedostarczone towary z późniejszym sporządzeniem nowego zwrotu niedostarczonych towarów';
																|tr = 'Malların tedarikçiye iadesi teslim edilmeyen mallar kadar azaltılır ve yeni bir teslim edilmeyen mal iadesi düzenlenir'");
	Items.ShortageNotRecognizedDecoration.Title = NStr("vi = 'Hàng hóa không được giao không được vận chuyển từ kho, chứng từ không được xuất lại';
														|ru = 'Недопоставленный товар не отгружается со склада, документы не переоформляются';
														|en = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.';
														|it = 'Il prodotto non consegnato non sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
														|pl = 'Niedostarczony towar nie wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Teslim edilmeyen mallar depodan çıkarılmaz, belgeler yeniden düzenlenmez'");
	Items.ShipNowDecoration.Title = NStr("vi = 'Hàng hóa chưa giao được giao từ kho, không tạo lại chứng từ';
										|ru = 'Недопоставленный товар отгружается со склада, документы не переоформляются';
										|en = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.';
										|it = 'Il prodotto non consegnato sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
										|pl = 'Niedostarczony towar wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
										|tr = 'Tedarik edilmeyen mallar stok dışı gönderilir, belgeler yeniden düzenlenmez'");
	
	// Surpluses
	Items.DecorationSurplusAgreedUpon.Title   = NStr("vi = 'Hàng thừa khi trả lại đã thỏa thuận với nhà cung cấp';
													|ru = 'Излишки при возврате согласованы с поставщиком';
													|en = 'Surpluses on return are approved by the vendor'; fa = 'Surpluses on return are approved by the vendor';
													|it = 'Eccedenze alla riconsegna concordate con il fornitore';
													|pl = 'Nadmiary podczas zwrotu są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınan iade fazlalıkları'");
	Items.DecorationSurplusNotAgreedUpon.Title = NStr("vi = 'Hàng thừa khi trả lại không thỏa thuận với nhà cung cấp';
														|ru = 'Излишки при возврате не согласованы с поставщиком';
														|en = 'Surpluses on return are not approved by the vendor'; fa = 'Surpluses on return are not approved by the vendor';
														|it = 'Eccedenze alla riconsegna non concordate con il fornitore';
														|pl = 'Nadmiary podczas zwrotu nie są uzgodnione z dostawcą';
														|tr = 'Tedarikçi ile mutabık kalınmayan iade fazlalıkları'");
	
	// Action With The Product
	Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
	Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
	
	// Action With A Document
	Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Việc trả lại hàng hóa cho nhà cung cấp được tăng lên bởi hàng hóa được vận chuyển lại';
													|ru = 'Возврат товаров поставщику увеличивается на перепоставленный товар';
													|en = 'Return of goods to vendor is increased by the amount of overdelivered goods'; fa = 'Return of goods to vendor is increased by the amount of overdelivered goods';
													|it = 'La riconsegna dei prodotti al fornitore diminuisce con i prodotti riconsegnati';
													|pl = 'Zwrot towaru dostawcy zwiększa się o nadmiar dostarczonych towarów';
													|tr = 'Fazla tedarik edilen mallar nedeniyle tedarikçiye mal iadesi artar'");
	Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Việc trả lại hàng hóa cho nhà cung cấp được tăng lên bởi hàng hóa được giao lại, tiếp theo là việc nhận lại hàng hóa được giao lại';
														|ru = 'Возврат товаров поставщику увеличивается на перепоставленный товар с последующим оформлением поступления перепоставленного товара';
														|en = 'Goods return to vendor is increased by the overdelivered goods, a receipt of overdelivered goods will be registered '; fa = 'Goods return to vendor is increased by the overdelivered goods, a receipt of overdelivered goods will be registered ';
														|it = 'La restituzione delle merci al fornitore aumenta con la riconsegna delle merci con la successiva esecuzione della ricevuta della merce consegnata';
														|pl = 'Zwrot towaru dostawcy zwiększa się o nadmiar dostarczonych towarów z późniejszym sporządzeniem wpływu nadmiaru dostarczanego towaru';
														|tr = 'Fazla tedarik edilen mallar nedeniyle tedarikçiye mal iadesinin artmasının ardından fazla tedarik edilen mallar teslim alınır'");
	Items.TheRepostedIsGivenAsADecoration.Title = NStr("vi = 'Hàng hóa vận chuyển lại không được trả lại kho, chứng từ không được cấp lại';
														|ru = 'Перепоставленный товар не возвращается на склад, документы не переоформляются';
														|en = 'Overdelivered goods are not returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are not returned to the warehouse. The documents are not registered';
														|it = 'Il prodotto riconsegnato non viene rimesso in magazzino, i documenti non si effettuano nuovamente';
														|pl = 'Nadmiar dostarczanego towaru nie zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Yeniden teslim edilen mallar stoka iade edilmeyecek ve belgeler yeniden düzenlenmeyecektir'");
	Items.EnterNowDecoration.Title = NStr("vi = 'Hàng giao lại được trả lại kho, chứng từ không được cấp lại';
											|ru = 'Перепоставленный товар возвращается на склад, документы не переоформляются';
											|en = 'Overdelivered goods are returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are returned to the warehouse. The documents are not registered';
											|it = 'Il prodotto riconsegnato ritorna in magazzino, i documenti non si effettuano nuovamente';
											|pl = 'Nadmiar dostarczanego towaru zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
											|tr = 'Fazla tedarik edilen mallar depoya iade edilir, belgeler yeniden düzenlenmez'");
	
EndProcedure

&AtClient
Procedure GenerateHeadingsOfActOfMoving()

	// Shortages
	Items.DecorationShortfallsAgreed.Title   = NStr("vi = 'Hàng thiếu khi tiếp nhận đã thỏa thuận với người gửi';
													|ru = 'Недостачи при поступлении согласованы с отправителем';
													|en = 'Shortages on receipt are approved with the sender'; fa = 'Shortages on receipt are approved with the sender';
													|it = 'Ammanchi in ricevuta concordati con il mittente';
													|pl = 'Niedobory podczas wpływu są uzgodnione z nadawcą';
													|tr = 'Gönderici ile mutabık kalınan makbuz eksiklikleri'");
	Items.DecorationShortfallsNotAgreedUpon.Title = NStr("vi = 'Hàng thiếu khi tiếp nhận chưa thỏa thuận với người gửi';
														|ru = 'Недостачи при поступлении не согласованы с отправителем';
														|en = 'Shortages on receipt are not approved with the sender'; fa = 'Shortages on receipt are not approved with the sender';
														|it = 'Ammanchi in ricevuta non concordati con il mittente';
														|pl = 'Niedobory podczas wpływu nie są uzgodnione z nadawcą';
														|tr = 'Gönderici ile mutabık kalınmayan makbuz eksiklikleri'");
	
	// Actions with the product
	Items.DecorationOfShortageOfActionWithGoods.Visible = False;
	Items.ShortageGroupActionWithGoodsColumn.Visible = False;
	Items.DecorationOfShortageOfActionWithDocument.Visible = False;
	
	If TheLineToOrder Or (GroupUpdate And UseTransferOrders) Then
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Điều chuyển hàng hóa bị giảm bởi hàng hóa chưa được giao với việc hủy bỏ các dòng đơn hàng chưa được gửi sau đó';
																	|ru = 'Перемещение товаров уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
																	|en = 'Goods transfer is reduced by underdelivered goods, underdelivered lines of the order will be canceled'; fa = 'Goods transfer is reduced by underdelivered goods, underdelivered lines of the order will be canceled';
																	|it = 'Lo spostamento di prodotti viene ridotto dai beni non consegnati con la conseguente cancellazione delle righe dell''ordine non consegnato';
																	|pl = 'Przemieszczenie towarów zmniejsza się o niedostarczone towary z późniejszym anulowaniem niedostarczonych wierszy zamówienia';
																	|tr = 'Mal transferi teslim edilmeyen mallardan dolayı azaltılır, ardından teslim edilmeyen sipariş satırları iptal edilir'");
	Else
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title = NStr("vi = 'Điều chuyển hàng hóa bị giảm bởi hàng hóa chưa được giao';
																	|ru = 'Перемещение товаров уменьшается на недопоставленный товар';
																	|en = 'Goods transfer reduces for underdelivered goods'; fa = 'Goods transfer reduces for underdelivered goods';
																	|it = 'Lo spostamento di prodotti viene ridotto dai beni non consegnati';
																	|pl = 'Przemieszczenie towarów zmniejsza się o niedostarczone towary';
																	|tr = 'Mal transferi teslim edilmeyen mallardan dolayı azaltılır'");
	EndIf;
	Items.AdditionalDeliveryIsRequiredDecoration.Title = NStr("vi = 'Điều chuyển hàng hóa bị giảm bởi hàng hóa chưa được giao với việc thực hiện tiếp theo một lưu chuyển mới của hàng hóa chưa được giao';
																|ru = 'Перемещение товаров уменьшается на недопоставленный товар с последующим оформлением нового перемещения недопоставленного товара';
																|en = 'Goods transfer will be reduced by underdelivered goods and new underdelivered goods transfer will be registered'; fa = 'Goods transfer will be reduced by underdelivered goods and new underdelivered goods transfer will be registered';
																|it = 'Lo spostamento di prodotti viene ridotto dai beni non consegnati con la successiva registrazione di un nuovo spostamento del prodotto non consegnato';
																|pl = 'Przemieszczenie towarów zmniejsza się o niedostarczone towary z późniejszym sporządzeniem nowego przemieszczenia niedostarczonych towarów';
																|tr = 'Mal transferi teslim edilmeyen mallardan dolayı azaltılır, ardından eksik teslim edilen mallar için yeni bir sevkiyat oluşturulur'");
	Items.ShortageNotRecognizedDecoration.Title = NStr("vi = 'Hàng hóa chưa được giao không được vận chuyển từ kho của người gửi, chứng từ không được xuất lại';
														|ru = 'Недопоставленный товар не отгружается со склада-отправителя, документы не переоформляются';
														|en = 'The underdelivered goods are not shipped from the origin warehouse; the documents are not reregistered'; fa = 'The underdelivered goods are not shipped from the origin warehouse; the documents are not reregistered';
														|it = 'Il prodotto non è consegnato dal magazzino del mittente, i documenti non sono eseguiti nuovamente';
														|pl = 'Nie przemieszczony towar nie wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Teslim edilmeyen mallar çıkış ambarından çıkarılmaz, belgeler yeniden düzenlenmez'");
	Items.ShipNowDecoration.Title = NStr("vi = 'Hàng hóa chưa được giao được chuyển từ kho của người gửi, chứng từ không được xuất lại';
										|ru = 'Недопоставленный товар отгружается со склада-отправителя, документы не переоформляются';
										|en = 'The underdelivered goods are shipped from the origin warehouse; the documents are not reregistered'; fa = 'The underdelivered goods are shipped from the origin warehouse; the documents are not reregistered';
										|it = 'Il prodotto non consegnato viene consegnato dal magazzino del mittente, i documenti non sono eseguiti nuovamente';
										|pl = 'Nie przemieszczony towar wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
										|tr = 'Teslim edilmeyen mallar çıkış ambarından sevk edilir, belgeler yeniden düzenlenmez'");
	
	// Surpluses
	Items.DecorationSurplusAgreedUpon.Title   = NStr("vi = 'Hàng thừa khi nhận có thỏa thuận với người gửi';
													|ru = 'Излишки при поступлении согласованы с отправителем';
													|en = 'Surpluses on receipt are approved with the sender'; fa = 'Surpluses on receipt are approved with the sender';
													|it = 'Eccedenze in ricevuta concordate con il mittente';
													|pl = 'Nadmiary podczas wpływu są uzgodnione z nadawcą';
													|tr = 'Gönderici ile mutabık kalınan makbuz fazlalıkları'");
	Items.DecorationSurplusNotAgreedUpon.Title = NStr("vi = 'Hàng thừa khi nhận không được thỏa thuận với người gửi';
														|ru = 'Излишки при поступлении не согласованы с отправителем';
														|en = 'Surpluses on receipt are not approved with the sender'; fa = 'Surpluses on receipt are not approved with the sender';
														|it = 'Eccedenze in ricevuta non concordate con il mittente';
														|pl = 'Nadmiary podczas wpływu nie są uzgodnione z nadawcą';
														|tr = 'Gönderici ile mutabık kalınmayan makbuz fazlalıkları'");
	
	// Actions with the product
	Items.DecorationSurplusActionsWithGoods.Visible = False;
	Items.GroupSurplusActionWithGoodsColumn.Visible = False;
	Items.DecorationExcessActionsWithDocument.Visible = False;
	
	Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Điều chuyển hàng hóa tăng lên bởi hàng hóa được vận chuyển lại';
													|ru = 'Перемещение товаров увеличивается на перепоставленный товар';
													|en = 'Goods transfer increases for overdelivered goods'; fa = 'Goods transfer increases for overdelivered goods';
													|it = 'Lo spostamento di prodotti aumenta con i beni riconsegnati';
													|pl = 'Przemieszczenie towarów zwiększa się o nadmiar dostarczonych towarów';
													|tr = 'Mal transferi, arz fazlası mallar nedeniyle artar'");
	Items.ReturnOfTheReDeliveredDecoration.Title = NStr("vi = 'Điều chuyển hàng hóa được tăng lên bởi hàng hóa được giao lại với sự thông quan tiếp theo của sự dịch chuyển ngược lại của hàng hóa được giao lại';
														|ru = 'Перемещение товаров увеличивается на перепоставленный товар с последующим оформлением обратного перемещения перепоставленного товара';
														|en = 'Goods transfer is increased by overdelivered goods, reverse overdelivered goods transfer will be registered'; fa = 'Goods transfer is increased by overdelivered goods, reverse overdelivered goods transfer will be registered';
														|it = 'Lo spostamento di prodotti aumenta con i beni riconsegnati con la successiva esecuzione dello spostamento inverso del prodotto consegnato';
														|pl = 'Przemieszczenie towarów zwiększa się o nadmiar dostarczonych towarów z późniejszym sporządzeniem powrotnego przemieszczenia nadmiaru dostarczonych towarów';
														|tr = 'Mal transferi, arz fazlası mallar nedeniyle artar, ardından yeniden teslim edilen malların iadesi gerçekleşir'");
	Items.TheRepostedIsGivenAsADecoration.Title = NStr("vi = 'Hàng hóa được vận chuyển lại không được trả lại cho người gửi, chứng từ không được xuất lại';
														|ru = 'Перепоставленный товар не возвращается на склад-отправитель, документы не переоформляются';
														|en = 'Overdelivered goods are not returned to the origin warehouse. The documents are not registered'; fa = 'Overdelivered goods are not returned to the origin warehouse. The documents are not registered';
														|it = 'Il prodotto riconsegnato non viene rimesso nel magazzino del mittente, i documenti non si effettuano nuovamente';
														|pl = 'Nadmiar dostarczanego towaru nie zwraca się do magazynu z którego został wysłany, dokumenty nie są sporządzane ponownie';
														|tr = 'Yeniden teslim edilen mallar çıkış ambarına iade edilmez ve belgeler yeniden düzenlenmez'");
	Items.EnterNowDecoration.Title = NStr("vi = 'Hàng được giao lại được trả lại cho kho của người gửi, chứng từ không được xuất lại';
											|ru = 'Перепоставленный товар возвращается на склад-отправитель, документы не переоформляются';
											|en = 'Overdelivered goods are returned to the origin warehouse. The documents are not registered'; fa = 'Overdelivered goods are returned to the origin warehouse. The documents are not registered';
											|it = 'Il prodotto riconsegnato ritorna in magazzino del mittente, i documenti non si effettuano nuovamente';
											|pl = 'Nadmiar dostarczanego towaru zwraca się do magazynu z którego został wysłany, dokumenty nie są sporządzane ponownie';
											|tr = 'Yeniden teslim edilen mallar gönderenin deposuna iade edilir, belgeler yeniden düzenlenmez'");
	
EndProcedure

&AtClient
Procedure GenerateTransferReportHeaders()
	
	// Shortages
	Items.DecorationShortfallsAgreed.Title   = NStr("vi = 'Hàng thiếu khi vận chuyển đã thống nhất với bạn hàng';
													|ru = 'Недостачи при передаче согласованы с партнером';
													|en = 'Shortages on transfer are agreed with the partner'; fa = 'Shortages on transfer are agreed with the partner';
													|it = 'Ammanchi alla consegna sono concordati con il partner';
													|pl = 'Niedobory przy przekazaniu zostały uzgodnione z partnerem';
													|tr = 'İş ortağıyla mutabık kalınan transfer eksiklikleri'");
	Items.DecorationShortfallsNotAgreedUpon.Title = NStr("vi = 'Hàng thiếu khi vận chuyển chưa thống nhất với bạn hàng';
														|ru = 'Недостачи при передаче не согласованы с партнером';
														|en = 'Shortages on transfer are not agreed with the partner'; fa = 'Shortages on transfer are not agreed with the partner';
														|it = 'Ammanchi alla consegna non sono concordati con il partner';
														|pl = 'Niedobory przy przekazaniu nie zostały uzgodnione z partnerem';
														|tr = 'İş ortağıyla mutabık kalınmayan transfer eksiklikleri'");
	
	// Action With The Product
	Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
	Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
	
	Items.ReturnActionWithShortageGoods.Visible = False;
	Items.ReturnActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ExpectActionWithShortageGoods.Visible = False;
	Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
	
	// Actions with the document
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		
		If TheLineToOrder
			Or (GroupUpdate
				And UseSalesOrders) Then
			
			If TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent") Then
				TitleText
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển giao đi ký gửi, đồng thời hủy các dòng giao thiếu trong đơn hàng';
							|ru = 'На недопоставленный товар оформляется передача на комиссию (исправление) с последующей отменой недопоставленных строк заказа';
							|en = 'For underdelivered goods, consignment sale (correction) is registered, followed by cancellation of the underdelivered order lines'; fa = 'For underdelivered goods, consignment sale (correction) is registered, followed by cancellation of the underdelivered order lines';
							|it = 'For underdelivered goods, consignment sale (correction) is registered, followed by cancellation of the underdelivered order lines';
							|pl = 'For underdelivered goods, consignment sale (correction) is registered, followed by cancellation of the underdelivered order lines';
							|tr = 'Fazla tedarik edilen mallar için konsinye satışı (hata düzeltmesi) yapılır ve ardından fazla tedarik edilen mallar iptal edilir'");
			ElsIf TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor") Then
				TitleText
					= NStr("vi = 'Đối với nguyên vật liệu giao thiếu, cần lập chứng từ chuyển giao cho bên nhận gia công, đồng thời hủy các dòng giao thiếu trong đơn hàng';
							|ru = 'На недопоставленное сырье оформляется передача переработчику (исправление) с последующей отменой недопоставленных строк заказа';
							|en = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, followed by cancellation of the underdelivered order lines.'; fa = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, followed by cancellation of the underdelivered order lines.';
							|it = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, followed by cancellation of the underdelivered order lines.';
							|pl = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, followed by cancellation of the underdelivered order lines.';
							|tr = 'Eksik teslim edilen hammaddeler fason üreticiye aktarılır ve sonrasında eksik teslim edilen sipariş hatları iptal edilir (yama)'");
			Else // Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee
				TitleText
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển giao cho bên lưu kho (điều chỉnh), sau đó hủy các dòng giao thiếu trong đơn hàng';
							|ru = 'На недопоставленный товар оформляется передача хранителю (исправление) с последующей отменой недопоставленных строк заказа';
							|en = 'For underdelivered goods, a VMI fill-up (correction) is registered, followed by cancellation of the underdelivered order lines'; fa = 'For underdelivered goods, a VMI fill-up (correction) is registered, followed by cancellation of the underdelivered order lines';
							|it = 'For underdelivered goods, a VMI fill-up (correction) is registered, followed by cancellation of the underdelivered order lines';
							|pl = 'For underdelivered goods, a VMI fill-up (correction) is registered, followed by cancellation of the underdelivered order lines';
							|tr = 'Eksik teslim edilen hammaddeler emanetçiye aktarılır ve sonrasında eksik teslim edilen sipariş hatları iptal edilir (yama)'");
			EndIf;
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = TitleText;
			
		Else
			
			If TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent") Then
				TitleText
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển đi ký gửi (điều chỉnh)';
							|ru = 'На недопоставленный товар оформляется передача на комиссию (исправление)';
							|en = 'For underdelivered goods, consignment sale (correction) is registered'; fa = 'For underdelivered goods, consignment sale (correction) is registered';
							|it = 'For underdelivered goods, consignment sale (correction) is registered';
							|pl = 'For underdelivered goods, consignment sale (correction) is registered';
							|tr = 'Eksik teslim edilen ürünler için bir komisyon aktarımı yapılır (yama)'");
			ElsIf TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor") Then
				TitleText
					= NStr("vi = 'Đối với nguyên vật liệu giao thiếu, cần lập chứng từ chuyển giao cho bên nhận gia công (điều chỉnh)';
							|ru = 'На недопоставленное сырье оформляется передача переработчику (исправление)';
							|en = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered'; fa = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered';
							|it = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered';
							|pl = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered';
							|tr = 'Eksik teslim edilen ürünler için fason üretici aktarımı yapılır (yama)'");
			Else // Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee
				TitleText
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển giao cho bên lưu kho (điều chỉnh)';
							|ru = 'На недопоставленный товар оформляется передача хранителю (исправление)';
							|en = 'For underdelivered goods, a VMI fill-up (correction) is registered'; fa = 'For underdelivered goods, a VMI fill-up (correction) is registered';
							|it = 'For underdelivered goods, a VMI fill-up (correction) is registered';
							|pl = 'For underdelivered goods, a VMI fill-up (correction) is registered';
							|tr = 'Eksik teslim edilen ürünler için bir emanetçiye aktarımı yapılır (düzeltme)'");
			EndIf;
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title = TitleText;
			
		EndIf;
		
		If TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent") Then
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển đi ký gửi (điều chỉnh), sau đó lập chứng từ chuyển giao mới cho mặt hàng chưa giao';
						|ru = 'На недопоставленный товар оформляется передача на комиссию (исправление) с последующим оформлением новой передачи недопоставленного товара';
						|en = 'For underdelivered goods, consignment sale (correction) is registered, and a new underdelivered goods transfer is registered'; fa = 'For underdelivered goods, consignment sale (correction) is registered, and a new underdelivered goods transfer is registered';
						|it = 'For underdelivered goods, consignment sale (correction) is registered, and a new underdelivered goods transfer is registered';
						|pl = 'For underdelivered goods, consignment sale (correction) is registered, and a new underdelivered goods transfer is registered';
						|tr = 'Eksik teslim edilen ürünlere komisyon için bir transfer gerçekleştirilir ve sonrasında eksik teslim edilen ürünler için yeni bir transfer yapılır (yama)'");
		ElsIf TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor") Then
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển giao cho bên nhận gia công (điều chỉnh), sau đó lập chứng từ chuyển giao mới cho mặt hàng chưa giao';
						|ru = 'На недопоставленное сырье оформляется передача переработчику (исправление) с последующим оформлением новой передачи недопоставленного товара';
						|en = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new underdelivered goods transfer is registered'; fa = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new underdelivered goods transfer is registered';
						|it = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new underdelivered goods transfer is registered';
						|pl = 'For underdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new underdelivered goods transfer is registered';
						|tr = 'Eksik teslim edilen hammaddeler için, fason üreticiye transfer yapılır ve sonrasında eksik teslim edilen ürünler için yeni bir transfer yapılır (yama)'");
		Else // Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển giao cho bên lưu kho (điều chỉnh), sau đó lập chứng từ chuyển giao mới cho mặt hàng chưa giao';
						|ru = 'На недопоставленный товар оформляется передача хранителю (исправление) с последующим оформлением новой передачи недопоставленного товара';
						|en = 'For underdelivered goods, a VMI fill-up (correction) is registered, and a new underdelivered goods transfer is registered'; fa = 'For underdelivered goods, a VMI fill-up (correction) is registered, and a new underdelivered goods transfer is registered';
						|it = 'For underdelivered goods, a VMI fill-up (correction) is registered, and a new underdelivered goods transfer is registered';
						|pl = 'For underdelivered goods, a VMI fill-up (correction) is registered, and a new underdelivered goods transfer is registered';
						|tr = 'Eksik teslim edilen ürünler emanetçiye devredilir ve eksik teslim edilen ürünlerin yeni bir transferi yapılır (yama)'");
		EndIf;
		Items.AdditionalDeliveryIsRequiredDecoration.Title = TitleText;
		
	Else
		
		If TheLineToOrder
			Or (GroupUpdate
				And UseSalesOrders) Then
			
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title
				= NStr("vi = 'Chuyển được giảm bởi hàng hóa chưa được giao với việc hủy bỏ các dòng đơn hàng chưa được giao';
						|ru = 'Передача уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
						|en = 'Transfer is reduced by short-delivered goods, and short-delivered order lines are canceled'; fa = 'Transfer is reduced by short-delivered goods, and short-delivered order lines are canceled';
						|it = 'La consegna viene decurtata delle merci non consegnate con la successiva cancellazione delle righe dell''ordine non consegnate';
						|pl = 'Przekazanie zmniejsza się na nie dostarczony towar z późniejszym anulowaniem nie dostarczonych wierszy zamówienia';
						|tr = 'Transfer, teslim edilmeyen mal kadar azaltılır ve ardından teslim edilmeyen sipariş satırları iptal edilir'");
			
		Else
			Items.AdditionalDeliveryIsNotRequiredDecoration.Title
				= NStr("vi = 'Chuyển giảm trên hàng hóa không gửi được';
						|ru = 'Передача уменьшается на недопоставленный товар';
						|en = 'Transfer is reduced by short-delivered goods'; fa = 'Transfer is reduced by short-delivered goods';
						|it = 'La consegna viene decurtata delle merci non consegnati';
						|pl = 'Przekazanie zmniejsza się na nie dostarczony towar';
						|tr = 'Transfer, teslim edilmeyen mallar nedeniyle azaltılır'");
		EndIf;
		
		Items.AdditionalDeliveryIsRequiredDecoration.Title
			= NStr("vi = 'Chuyển được giảm bởi hàng hóa chưa được giao với việc thực hiện chuyển tiếp mới của hàng hóa chưa được giao';
					|ru = 'Передача уменьшается на недопоставленный товар с последующим оформлением новой передачи недопоставленного товара';
					|en = 'Transfer is reduced by short-delivered goods, and a new transfer of short-delivered goods is registered'; fa = 'Transfer is reduced by short-delivered goods, and a new transfer of short-delivered goods is registered';
					|it = 'La consegna viene decurtata delle merci non consegnate con la successiva emissione della nuova consegna delle merci non consegnate';
					|pl = 'Przekazanie zmniejsza się na nie dostarczony towar z późniejszym sporządzeniem nowego przekazania nie dostarczonego towaru';
					|tr = 'Transfer, teslim edilmeyen mal kadar azaltılır, ardından teslim edilmeyen malların yeni bir transferi gerçekleştirilir'");
		
	EndIf;
	
	Items.ShortageNotRecognizedDecoration.Title
		= NStr("vi = 'Hàng hóa không được giao không được vận chuyển từ kho, chứng từ không được xuất lại';
				|ru = 'Недопоставленный товар не отгружается со склада, документы не переоформляются';
				|en = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.';
				|it = 'Il prodotto non consegnato non sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
				|pl = 'Niedostarczony towar nie wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
				|tr = 'Teslim edilmeyen mallar depodan çıkarılmaz, belgeler yeniden düzenlenmez'");
	Items.ShipNowDecoration.Title
		= NStr("vi = 'Hàng hóa chưa giao được giao từ kho, không tạo lại chứng từ';
				|ru = 'Недопоставленный товар отгружается со склада, документы не переоформляются';
				|en = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.';
				|it = 'Il prodotto non consegnato sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
				|pl = 'Niedostarczony towar wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
				|tr = 'Tedarik edilmeyen mallar stok dışı gönderilir, belgeler yeniden düzenlenmez'");
	
	// Surpluses
	Items.DecorationSurplusAgreedUpon.Title   = NStr("vi = 'Hàng thừa khi giao đã thống nhất với bạn hàng';
													|ru = 'Излишки при передаче согласованы с партнером';
													|en = 'Surpluses on transfer are agreed with the partner'; fa = 'Surpluses on transfer are agreed with the partner';
													|it = 'Le eccedenze alla consegna sono state concordate con il partner';
													|pl = 'Nadwyżka podczas przekazania została uzgodniona z partnerem';
													|tr = 'İş ortağıyla mutabık kalınan transfer fazlalıkları'");
	Items.DecorationSurplusNotAgreedUpon.Title = NStr("vi = 'Hàng thừa khi giao không thống nhất với bạn hàng';
														|ru = 'Излишки при передаче не согласованы с партнером';
														|en = 'Surpluses on transfer are not agreed with the partner'; fa = 'Surpluses on transfer are not agreed with the partner';
														|it = 'Le eccedenze alla consegna non sono state concordate con il partner';
														|pl = 'Nadwyżka podczas przekazania nie została uzgodniona z partnerem';
														|tr = 'İş ortağıyla mutabık kalınmayan transfer fazlalıkları'");
	
	// Action With The Product
	Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
	Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
	
	// Actions with the document
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		
		Items.PurchaseOfARepostedDecoration.Title
			= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ chuyển giao cho bên lưu kho (điều chỉnh)';
					|ru = 'На перепоставленный товар оформляется передача хранителю (исправление)';
					|en = 'For overdelivered goods, a VMI fill-up (correction) is registered'; fa = 'For overdelivered goods, a VMI fill-up (correction) is registered';
					|it = 'For overdelivered goods, a VMI fill-up (correction) is registered';
					|pl = 'For overdelivered goods, a VMI fill-up (correction) is registered';
					|tr = 'Yeniden teslim edilen ürünler için emanetçiye devir işlemi gerçekleştirilir (yama)'");
		
		If UseReturnRequests
			And TypeOfAct <> PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor")
			Then
			If TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent") Then
				TitleText
					= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ chuyển đi ký gửi (điều chỉnh), sau đó lập giấy đề nghị trả lại mặt hàng giao thừa';
							|ru = 'На перепоставленный товар оформляется передача на комиссию (исправление) с последующим оформлением заявки на возврат перепоставленного товара';
							|en = 'For overdelivered goods, a consignment sale (correction) is registered, and a new overdelivered goods return request is registered'; fa = 'For overdelivered goods, a consignment sale (correction) is registered, and a new overdelivered goods return request is registered';
							|it = 'For overdelivered goods, a consignment sale (correction) is registered, and a new overdelivered goods return request is registered';
							|pl = 'For overdelivered goods, a consignment sale (correction) is registered, and a new overdelivered goods return request is registered';
							|tr = 'Fazla tedarik edilen ürünler için bir satış düzeltmesi yapılır ve sonrasında fazla tedarik edilen ürünlerin iadesi talep edilir (yama)'");
			ElsIf TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor") Then
				TitleText
					= NStr("vi = 'Lập chứng từ chuyển giao cho bên nhận gia công (điều chỉnh) đối với nguyên vật liệu giao thừa, tiếp theo lập giấy đề nghị trả lại nguyên vật liệu giao thừa';
							|ru = 'На перепоставленное сырье оформляется передача переработчику (исправление) с последующим оформлением заявки на возврат перепоставленного сырья';
							|en = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered raw materials return request is registered'; fa = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered raw materials return request is registered';
							|it = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered raw materials return request is registered';
							|pl = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered raw materials return request is registered';
							|tr = 'Fazla teslim edilen hammaddeler için, fason üreticiye bir transfer yapılır ve sonrasında fazladan teslim edilen hammaddelerin iadesi için bir başvuru yapılır (yama)'");
			Else // Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee
				TitleText
					= NStr("vi = 'Đối với hàng hóa giao thừa, cần lập chứng từ chuyển giao cho bên lưu kho (điều chỉnh), sau đó lập giấy đề nghị trả lại hàng giao thừa';
							|ru = 'На перепоставленный товар оформляется передача хранителю (исправление) с последующим оформлением заявки на возврат перепоставленного товара';
							|en = 'For overdelivered goods, a VMI fill-up (correction) is registered, and a new overdelivered goods return request is registered'; fa = 'For overdelivered goods, a VMI fill-up (correction) is registered, and a new overdelivered goods return request is registered';
							|it = 'For overdelivered goods, a VMI fill-up (correction) is registered, and a new overdelivered goods return request is registered';
							|pl = 'For overdelivered goods, a VMI fill-up (correction) is registered, and a new overdelivered goods return request is registered';
							|tr = 'Fazla teslim edilen ürünler için emanetçiye devir işlemi yapılır ve sonrasında fazladan teslim edilen ürünlerin iadesi için bir talepte bulunulur (yama)'");
			EndIf;
			Items.ReturnOfTheReDeliveredDecoration.Title = TitleText;
		Else
			If TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent") Then
				TitleText
					= NStr("vi = 'Đối với hàng giao thừa, cần lập chứng từ chuyển đi ký gửi (điều chỉnh), sau đó lập chứng từ tiếp nhận hàng giao thừa';
							|ru = 'На перепоставленный товар оформляется передача на комиссию (исправление) с последующим оформлением поступления перепоставленного товара';
							|en = 'For overdelivered goods, a transfer to consignment (correction) is registered, and a new overdelivered goods receipt is registered'; fa = 'For overdelivered goods, a transfer to consignment (correction) is registered, and a new overdelivered goods receipt is registered';
							|it = 'For overdelivered goods, a transfer to consignment (correction) is registered, and a new overdelivered goods receipt is registered';
							|pl = 'For overdelivered goods, a transfer to consignment (correction) is registered, and a new overdelivered goods receipt is registered';
							|tr = 'Yeniden teslim edilen ürünler için komisyon transferi, yeniden teslim edilen ürünlerin teslim alındığına dair müteakip kayıtla birlikte yapılır (yama)'");
			ElsIf TypeOfAct = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor") Then
				TitleText
					= NStr("vi = 'Đối với nguyên vật liệu giao thừa, cần lập chứng từ chuyển giao cho bên nhận gia công (điều chỉnh), sau đó lập chứng từ tiếp nhận nguyên vật liệu giao thừa';
							|ru = 'На перепоставленное сырье оформляется передача переработчику (исправление) с последующим оформлением поступления перепоставленного сырья';
							|en = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered goods receipt is registered'; fa = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered goods receipt is registered';
							|it = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered goods receipt is registered';
							|pl = 'For overdelivered raw materials, a transfer to the subcontractor (correction) is registered, and a new overdelivered goods receipt is registered';
							|tr = 'Fason üreticiye transfer fazla teslim edilen hammaddeler için yapılır, sonrasında ise fazla teslim edilen hammaddelerin teslim alındığına dair kayıt yapılır (yama)'");
			Else // Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee
				TitleText
					= NStr("vi = 'Đối với hàng hóa giao thừa, cần lập chứng từ chuyển giao cho bên lưu kho (điều chỉnh), sau đó lập chứng từ tiếp nhận hàng hóa giao thừa';
							|ru = 'На перепоставленный товар оформляется передача хранителю (исправление) с последующим оформлением поступления перепоставленного товара';
							|en = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered'; fa = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered';
							|it = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered';
							|pl = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered';
							|tr = 'Yeniden teslim edilen ürünler için emanetçiye transfer işlemi yapılır ve sonrasında yeniden teslim edilen ürünlerin teslim alındığı kaydedilir (yama)'");
			EndIf;
			Items.ReturnOfTheReDeliveredDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ chuyển giao cho bên lưu kho (điều chỉnh), sau đó lập chứng từ tiếp nhận mặt hàng giao thừa';
						|ru = 'На перепоставленный товар оформляется передача хранителю (исправление) с последующим оформлением поступления перепоставленного товара';
						|en = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered'; fa = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered';
						|it = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered';
						|pl = 'For overdelivered goods, a VMI fill-up (correction) is registered and a new overdelivered goods receipt is registered';
						|tr = 'Yeniden teslim edilen ürünler için emanetçiye transfer işlemi yapılır ve sonrasında yeniden teslim edilen ürünlerin teslim alındığı kaydedilir (yama)'");
		EndIf;
		
	Else
		
		Items.PurchaseOfARepostedDecoration.Title = NStr("vi = 'Tăng hàng hóa do hàng hóa vận chuyển lại';
														|ru = 'Передача увеличивается на перепоставленный товар';
														|en = 'Transfer increases for overdelivered goods'; fa = 'Transfer increases for overdelivered goods';
														|it = 'La consegna è incrementata della merce consegnata oltre l''ordine';
														|pl = 'Przekazanie zwiększa się na nadwyżkę towaru';
														|tr = 'Transfer, arz fazlası mallar nedeniyle artırılır'");
		
		If UseReturnRequests
			And TypeOfAct <> PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor")
			Then
			Items.ReturnOfTheReDeliveredDecoration.Title
				= NStr("vi = 'Chuyển giao tăng hàng hóa được vận chuyển lại, tiếp theo là thực hiện giấy đề nghị để trả lại hàng hóa được vận chuyển lại';
						|ru = 'Передача увеличивается на перепоставленный товар с последующим оформлением заявки на возврат перепоставленного товара';
						|en = 'Transfer is increased by the amount of overdelivered goods. A request for return of overdelivered goods will be registered'; fa = 'Transfer is increased by the amount of overdelivered goods. A request for return of overdelivered goods will be registered';
						|it = 'La consegna viene incrementata della merce consegnata oltre l''ordine con la successiva emissione della richiesta di restituzione delle merci consegnate oltre l''ordine';
						|pl = 'Przekazanie zwiększa się na nadwyżkę towaru późniejszym sporządzeniem zgłoszenia o zwrot nadwyżki towaru';
						|tr = 'Transfer, arz fazlası mallar nedeniyle artırılır ve ardından arz fazlası malların iadesi için bir başvuru yapılır'");
		Else
			Items.ReturnOfTheReDeliveredDecoration.Title
				= NStr("vi = 'Việc chuyển giao tăng Theo hàng hóa được giao lại, tiếp theo là việc nhận lại hàng hóa được giao lại';
						|ru = 'Передача увеличивается на перепоставленный товар с последующим оформлением поступления перепоставленного товара';
						|en = 'Transfer is increased by overdelivered goods, a receipt for overdelivered goods will be registered'; fa = 'Transfer is increased by overdelivered goods, a receipt for overdelivered goods will be registered';
						|it = 'La consegna viene incrementata della merce consegnata oltre l''ordine con la successiva emissione della recezione delle merci consegnate oltre l''ordine';
						|pl = 'Przekazanie zwiększa się na nadwyżkę towaru późniejszym sporządzeniem wpływu nadwyżki towaru';
						|tr = 'Transfer, arz fazlası mallar nedeniyle artırılır ve ardından fazla tedarik edilen mallar teslim alınır'");
		EndIf;
		
	EndIf;
	
	Items.TheRepostedIsGivenAsADecoration.Title
		= NStr("vi = 'Hàng hóa vận chuyển lại không được trả lại kho, chứng từ không được cấp lại';
				|ru = 'Перепоставленный товар не возвращается на склад, документы не переоформляются';
				|en = 'Overdelivered goods are not returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are not returned to the warehouse. The documents are not registered';
				|it = 'Il prodotto riconsegnato non viene rimesso in magazzino, i documenti non si effettuano nuovamente';
				|pl = 'Nadmiar dostarczanego towaru nie zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
				|tr = 'Yeniden teslim edilen mallar stoka iade edilmeyecek ve belgeler yeniden düzenlenmeyecektir'");
	Items.EnterNowDecoration.Title
		= NStr("vi = 'Hàng giao lại được trả lại kho, chứng từ không được cấp lại';
				|ru = 'Перепоставленный товар возвращается на склад, документы не переоформляются';
				|en = 'Overdelivered goods are returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are returned to the warehouse. The documents are not registered';
				|it = 'Il prodotto riconsegnato ritorna in magazzino, i documenti non si effettuano nuovamente';
				|pl = 'Nadmiar dostarczanego towaru zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
				|tr = 'Fazla tedarik edilen mallar depoya iade edilir, belgeler yeniden düzenlenmez'");
	
EndProcedure

&AtClient
Procedure GenerateVMIActHeadings()
	
	// Shortages
	Items.DecorationShortfallsAgreed.Title   = NStr("vi = 'Hàng thiếu khi vận chuyển từ nơi cất giữ đã thỏa thuận với nhà cung cấp';
													|ru = 'Недостачи при отгрузке с ответственного хранения согласованы с поставщиком';
													|en = 'Shortages when VMI pick-up request is approved by the vendor.'; fa = 'Shortages when VMI pick-up request is approved by the vendor.';
													|it = 'Gli ammanchi durante la spedizione dalla custodia sono stati concordati con il fornitore';
													|pl = 'Niedobory podczas wysyłki z depozytu są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınan depodan yapılan sevkiyatta eksiklikler'");
	Items.DecorationShortfallsNotAgreedUpon.Title = NStr("vi = 'Hàng thiếu khi vận chuyển từ nơi cất giữ chưa thỏa thuận với nhà cung cấp';
														|ru = 'Недостачи при отгрузке с ответственного хранения не согласованы с поставщиком';
														|en = 'Shortages when VMI pick-up request is not approved by the vendor.'; fa = 'Shortages when VMI pick-up request is not approved by the vendor.';
														|it = 'Gli ammanchi durante la spedizione dalla custodia non sono stati concordati con il fornitore';
														|pl = 'Niedobory podczas wysyłki z depozytu nie są uzgodnione z dostawcą';
														|tr = 'Tedarikçi ile mutabık kalınmayan depodan yapılan sevkiyatta eksiklikler'");
	
	// Action With The Product
	Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
	Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
	
	Items.WriteOFFActionWithShortageGoods.Visible = False;
	Items.WriteOFFActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ReturnActionWithShortageGoods.Visible = False;
	Items.ReturnActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ExpectActionWithShortageGoods.Visible = False;
	Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
	
	// Action With A Document
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		If ShipmentToPrincipal Then
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ giao hàng cho bên giao đại lý (điều chỉnh)';
						|ru = 'На недопоставленный товар оформляется отгрузка принципалу (исправление)';
						|en = 'For underdelivered goods, shipment to the principal (correction) is registered'; fa = 'For underdelivered goods, shipment to the principal (correction) is registered';
						|it = 'For underdelivered goods, shipment to the principal (correction) is registered';
						|pl = 'For underdelivered goods, shipment to the principal (correction) is registered';
						|tr = 'Eksik teslim edilen ürünler ana şirkete gönderilir (yama)'");
		Else
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ giao hàng cho bên gửi hàng (điều chỉnh)';
						|ru = 'На недопоставленный товар оформляется отгрузка поклажедателю (исправление)';
						|en = 'For underdelivered goods, shipment to the depositor (correction) is registered'; fa = 'For underdelivered goods, shipment to the depositor (correction) is registered';
						|it = 'For underdelivered goods, shipment to the depositor (correction) is registered';
						|pl = 'For underdelivered goods, shipment to the depositor (correction) is registered';
						|tr = 'Eksik teslim edilen ürünler saklayıcıya gönderilir (yama)'");
		EndIf;
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title = TitleText;
		If ShipmentToPrincipal Then
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ giao hàng cho bên đại lý (điều chỉnh), sau đó lập chứng từ giao hàng mới cho mặt hàng giao thiếu';
						|ru = 'На недопоставленный товар оформляется отгрузка принципалу (исправление) с последующим оформлением новой отгрузки недопоставленного товара';
						|en = 'For underdelivered goods, shipment to the principal (correction) is registered, and a new underdelivered goods shipment is registered'; fa = 'For underdelivered goods, shipment to the principal (correction) is registered, and a new underdelivered goods shipment is registered';
						|it = 'For underdelivered goods, shipment to the principal (correction) is registered, and a new underdelivered goods shipment is registered';
						|pl = 'For underdelivered goods, shipment to the principal (correction) is registered, and a new underdelivered goods shipment is registered';
						|tr = 'Eksik teslim edilen ürünler ana şirkete gönderilir ve eksik teslim edilen ürünlerin yeni bir sevkiyatı yapılır (yama)'");
		Else
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ giao hàng cho bên gửi hàng (điều chỉnh), sau đó lập chứng từ giao hàng mới cho mặt hàng giao thiếu';
						|ru = 'На недопоставленный товар оформляется отгрузка поклажедателю (исправление) с последующим оформлением новой отгрузки недопоставленного товара';
						|en = 'For underdelivered goods, shipment to the depositor (correction) is registered, and a new underdelivered goods shipment is registered'; fa = 'For underdelivered goods, shipment to the depositor (correction) is registered, and a new underdelivered goods shipment is registered';
						|it = 'For underdelivered goods, shipment to the depositor (correction) is registered, and a new underdelivered goods shipment is registered';
						|pl = 'For underdelivered goods, shipment to the depositor (correction) is registered, and a new underdelivered goods shipment is registered';
						|tr = 'Eksik teslim edilen ürünler saklayıcıya gönderilir ve eksik teslim edilen ürünlerin yeni bir sevkiyatı yapılır (yama)'");
		EndIf;
		Items.AdditionalDeliveryIsRequiredDecoration.Title = TitleText;
	Else
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title
			= NStr("vi = 'Xuất kho hàng hóa đến người gửi tiền được giảm bởi hàng hóa chưa được giao';
					|ru = 'Отгрузка товаров поклажедателю уменьшается на недопоставленный товар';
					|en = 'Shipment of goods to the depositor is reduced by underdelivered goods'; fa = 'Shipment of goods to the depositor is reduced by underdelivered goods';
					|it = 'La spedizione di merce al depositante viene ridotta della quantità di merce non consegnata';
					|pl = 'Wysyłka towarów do depozytariusza zmniejsza się o niedostarczony towar';
					|tr = 'Göndericiye yapılan mal sevkiyatı, teslim edilmeyen mallar kadar azaltılır'");
		Items.AdditionalDeliveryIsRequiredDecoration.Title
			= NStr("vi = 'Xuất kho hàng hóa cho người gửi tiền được giảm bởi hàng hóa chưa được giao với việc thông quan tiếp theo của một lô hàng mới của hàng hóa chưa được giao';
					|ru = 'Отгрузка товаров поклажедателю уменьшается на недопоставленный товар с последующим оформлением новой отгрузки недопоставленного товара';
					|en = 'Shipment of goods to the depositor is reduced by the underdelivered goods with subsequent registration of a new shipment of underdelivered goods'; fa = 'Shipment of goods to the depositor is reduced by the underdelivered goods with subsequent registration of a new shipment of underdelivered goods';
					|it = 'La spedizione di merce al depositante viene ridotta della quantità di merce non consegnata con la succesiva registrazione di una nuova spedizione di merce non consegnata';
					|pl = 'Wysyłka towarów do depozytariusza zmniejsza się o niedostarczony towar z następnym sporządzeniem nowej wysyłki niedostarczonego towaru';
					|tr = 'Göndericiye yapılan mal sevkiyatı teslim edilmeyen mallar kadar azaltılır ve daha sonra teslim edilmeyen malların yeni bir sevkiyatı yapılır'");
	EndIf;
	
	Items.ShortageNotRecognizedDecoration.Title = NStr("vi = 'Hàng hóa không được giao không được vận chuyển từ kho, chứng từ không được xuất lại';
														|ru = 'Недопоставленный товар не отгружается со склада, документы не переоформляются';
														|en = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are not shipped from the warehouse; the documents are not reregistered.';
														|it = 'Il prodotto non consegnato non sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
														|pl = 'Niedostarczony towar nie wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Teslim edilmeyen mallar depodan çıkarılmaz, belgeler yeniden düzenlenmez'");
	Items.ShipNowDecoration.Title = NStr("vi = 'Hàng hóa chưa giao được giao từ kho, không tạo lại chứng từ';
										|ru = 'Недопоставленный товар отгружается со склада, документы не переоформляются';
										|en = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are shipped from the warehouse; the documents are not reregistered.';
										|it = 'Il prodotto non consegnato sarà spedito dal magazzino, i documenti non saranno emessi nuovamente';
										|pl = 'Niedostarczony towar wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
										|tr = 'Tedarik edilmeyen mallar stok dışı gönderilir, belgeler yeniden düzenlenmez'");
	
	// Surpluses
	Items.DecorationSurplusAgreedUpon.Title   = NStr("vi = 'Hàng thừa khi xuất từ nơi cất giữ có thỏa thuận với nhà cung cấp';
													|ru = 'Излишки при отгрузке с ответственного хранения согласованы с поставщиком';
													|en = 'Surpluses when VMI pick-up request is approved by the vendor'; fa = 'Surpluses when VMI pick-up request is approved by the vendor';
													|it = 'Gli eccessi durante la spedizione dalla custodia sono stati concordati con il fornitore';
													|pl = 'Nadwyżki podczas wysyłki z depozytu są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınan depo sevkiyatındaki fazlalıklar'");
	Items.DecorationSurplusNotAgreedUpon.Title = NStr("vi = 'Hàng thừa khi xuất từ nơi cất giữ không thỏa thuận với nhà cung cấp';
														|ru = 'Излишки при отгрузке с ответственного хранения не согласованы с поставщиком';
														|en = 'Surpluses when VMI pick-up request is not approved by the vendor'; fa = 'Surpluses when VMI pick-up request is not approved by the vendor';
														|it = 'Gli eccessi durante la spedizione dalla custodia non sono stati concordati con il fornitore';
														|pl = 'Nadwyżki podczas wysyłki z depozytu nie są uzgodnione z dostawcą';
														|tr = 'Tedarikçi ile mutabık kalınmayan depo sevkiyatındaki fazlalıklar'");
	
	// Action With The Product
	Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
	Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
	
	// Action With A Document
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		If ShipmentToPrincipal Then
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ giao hàng cho bên giao đại lý (điều chỉnh)';
						|ru = 'На перепоставленный товар оформляется отгрузка принципалу (исправление)';
						|en = 'For overdelivered goods, shipment to the principal is registered (correction)'; fa = 'For overdelivered goods, shipment to the principal is registered (correction)';
						|it = 'For overdelivered goods, shipment to the principal is registered (correction)';
						|pl = 'For overdelivered goods, shipment to the principal is registered (correction)';
						|tr = 'Yeniden teslim edilen ürünler için ana şirkete sevkiyat yapılır (yama)'");
		Else
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ giao hàng cho bên gửi hàng (điều chỉnh)';
						|ru = 'На перепоставленный товар оформляется отгрузка поклажедателю (исправление)';
						|en = 'For overdelivered goods, shipment to the depositor  (correction) is registered'; fa = 'For overdelivered goods, shipment to the depositor  (correction) is registered';
						|it = 'For overdelivered goods, shipment to the depositor  (correction) is registered';
						|pl = 'For overdelivered goods, shipment to the depositor  (correction) is registered';
						|tr = 'Yeniden teslim edilen ürünler için saklayıcıya sevkiyat yapılır (yama)'");
		EndIf;
		Items.PurchaseOfARepostedDecoration.Title = TitleText;
		If ShipmentToPrincipal Then
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ giao hàng cho bên đại lý (điều chỉnh), sau đó lập chứng từ tiếp nhận mặt hàng giao thừa';
						|ru = 'На перепоставленный товар оформляется отгрузка принципалу (исправление) с последующим оформлением поступления перепоставленного товара';
						|en = 'For overdelivered goods, shipment to the principal (correction) is registered, and a new overdelivered goods receipt is registered'; fa = 'For overdelivered goods, shipment to the principal (correction) is registered, and a new overdelivered goods receipt is registered';
						|it = 'For overdelivered goods, shipment to the principal (correction) is registered, and a new overdelivered goods receipt is registered';
						|pl = 'For overdelivered goods, shipment to the principal (correction) is registered, and a new overdelivered goods receipt is registered';
						|tr = 'Yeniden teslim edilen ürünler için ana şirkete sevkiyat yapılır ve yeniden teslim edilen ürünlerin makbuzu kaydedilir (yama)'");
		Else
			TitleText
				= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ giao hàng cho bên đại lý (điều chỉnh), sau đó lập chứng từ tiếp nhận mặt hàng giao thừa';
						|ru = 'На перепоставленный товар оформляется отгрузка поклажедателю (исправление) с последующим оформлением поступления перепоставленного товара';
						|en = 'For overdelivered goods, shipment to the depositor (correction) is registered, and a new overdelivered goods receipt is registered'; fa = 'For overdelivered goods, shipment to the depositor (correction) is registered, and a new overdelivered goods receipt is registered';
						|it = 'For overdelivered goods, shipment to the depositor (correction) is registered, and a new overdelivered goods receipt is registered';
						|pl = 'For overdelivered goods, shipment to the depositor (correction) is registered, and a new overdelivered goods receipt is registered';
						|tr = 'Yeniden teslim edilen ürünler için saklayıcıya sevkiyat yapılır ve yeniden teslim edilen ürünlerin teslim alındığına dair daha sonra resmileştirilir (yama)'");
		EndIf;
		Items.ReturnOfTheReDeliveredDecoration.Title = TitleText;
	Else
		Items.PurchaseOfARepostedDecoration.Title
			= NStr("vi = 'Xuất kho hàng hóa cho người gửi tăng theo giao lại hàng hóa';
					|ru = 'Отгрузка товаров поклажедателю увеличивается на перепоставленный товар';
					|en = 'Shipment of goods to the depositor is increased by the overdelivered goods'; fa = 'Shipment of goods to the depositor is increased by the overdelivered goods';
					|it = 'La spedizione di merce al depositante viene aumentata della quantità di merce in eccesso';
					|pl = 'Wysyłka towarów depozytariusza zwiększa się o niedostarczony towar';
					|tr = 'Malların göndericiye sevkiyatı, fazla tedarik edilen mallar kadar artırılır'");
		Items.ReturnOfTheReDeliveredDecoration.Title
			= NStr("vi = 'Xuất kho hàng hóa cho người gửi được tăng lên bởi hàng hóa được giao lại với việc xử lý tiếp theo của việc nhận lại hàng hóa được giao lại';
					|ru = 'Отгрузка товаров поклажедателю увеличивается на перепоставленный товар с последующим оформлением поступления перепоставленного товара';
					|en = 'Goods shipment to depositor is increased by the overdelivered goods, a receipt of overdelivered goods will be registered'; fa = 'Goods shipment to depositor is increased by the overdelivered goods, a receipt of overdelivered goods will be registered';
					|it = 'La spedizione di merce al depositante viene aumentata della quantità di merce in eccesso con successiva registrazione dell''arrivo della merce in eccesso';
					|pl = 'Wysyłka towarów depozytariuszowi zwiększa się o nadmiar dostarczonych towarów z późniejszym sporządzeniem wpływu nadmiaru dostarczanego towaru';
					|tr = 'Malların göndericiye sevkiyatı, fazla teslim edilen mallar kadar artırılır ve ardından fazla teslim edilen mallar teslim alınır'");
	EndIf;
	
	Items.TheRepostedIsGivenAsADecoration.Title = NStr("vi = 'Hàng hóa vận chuyển lại không được trả lại kho, chứng từ không được cấp lại';
														|ru = 'Перепоставленный товар не возвращается на склад, документы не переоформляются';
														|en = 'Overdelivered goods are not returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are not returned to the warehouse. The documents are not registered';
														|it = 'Il prodotto riconsegnato non viene rimesso in magazzino, i documenti non si effettuano nuovamente';
														|pl = 'Nadmiar dostarczanego towaru nie zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
														|tr = 'Yeniden teslim edilen mallar stoka iade edilmeyecek ve belgeler yeniden düzenlenmeyecektir'");
	Items.EnterNowDecoration.Title = NStr("vi = 'Hàng giao lại được trả lại kho, chứng từ không được cấp lại';
											|ru = 'Перепоставленный товар возвращается на склад, документы не переоформляются';
											|en = 'Overdelivered goods are returned to the warehouse. The documents are not registered'; fa = 'Overdelivered goods are returned to the warehouse. The documents are not registered';
											|it = 'Il prodotto riconsegnato ritorna in magazzino, i documenti non si effettuano nuovamente';
											|pl = 'Nadmiar dostarczanego towaru zwraca się do magazynu, dokumenty nie są sporządzane ponownie';
											|tr = 'Fazla tedarik edilen mallar depoya iade edilir, belgeler yeniden düzenlenmez'");
	
EndProcedure

&AtClient
Procedure GenerateHeadingsOfTransferActToGiver()
	
	// Shortages
	Items.DecorationShortfallsAgreed.Title     = NStr("vi = 'Hàng thiếu khi vận chuyển đã thống nhất với bên đặt gia công';
														|ru = 'Недостачи при передаче продукции согласованы с давальцем';
														|en = 'Shortage at transfer of manufactured products is approved with the provider'; fa = 'Shortage at transfer of manufactured products is approved with the provider';
														|it = 'Ammanchi al trasferimento dei prodotti concordati con il fornitore';
														|pl = 'Niedobory przy przekazaniu produkcji zostały uzgodnione z właścicielem surowców';
														|tr = 'Sağlayıcı ile mutabık kalınan transfer eksiklikleri'");
	Items.DecorationShortfallsNotAgreedUpon.Title   = NStr("vi = 'Hàng thiếu khi vận chuyển đã thống nhất với bên đặt gia công';
															|ru = 'Недостачи при передаче продукции не согласованы с давальцем';
															|en = 'Shortage at transfer of manufactured products is not approved with the provider'; fa = 'Shortage at transfer of manufactured products is not approved with the provider';
															|it = 'Ammanchi al trasferimento dei prodotti non concordati con il fornitore';
															|pl = 'Niedobory przy przekazaniu produkcji nie zostały uzgodnione z właścicielem surowców';
															|tr = 'Sağlayıcı ile mutabık kalınmayan transfer eksiklikleri'");
	
	// Action With The Product
	Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
	Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
	
	Items.WriteOFFActionWithShortageGoods.Visible = False;
	Items.WriteOFFActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ReturnActionWithShortageGoods.Visible = False;
	Items.ReturnActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ExpectActionWithShortageGoods.Visible = False;
	Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
	
	// Action With A Document
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title
			= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển giao cho người đặt gia công (điều chỉnh)';
					|ru = 'На недопоставленную продукцию оформляется передача давальцу (исправление)';
					|en = 'For underdelivered goods, transfer to the provider (correction) is registered'; fa = 'For underdelivered goods, transfer to the provider (correction) is registered';
					|it = 'For underdelivered goods, transfer to the provider (correction) is registered';
					|pl = 'For underdelivered goods, transfer to the provider (correction) is registered';
					|tr = 'Eksik teslim edilen ürünler alıcıya devredilir (yama)'");
		Items.AdditionalDeliveryIsRequiredDecoration.Title
			= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ chuyển giao cho người đặt gia công (điều chỉnh), sau đó lập chứng từ chuyển giao mới cho mặt hàng giao thiếu';
					|ru = 'На недопоставленную продукцию оформляется передача давальцу (исправление) с последующим оформлением новой передачи недопоставленной продукции';
					|en = 'For underdelivered goods, transfer to the provider (correction) is registered, and a new transfer of underdelivered goods is registered'; fa = 'For underdelivered goods, transfer to the provider (correction) is registered, and a new transfer of underdelivered goods is registered';
					|it = 'For underdelivered goods, transfer to the provider (correction) is registered, and a new transfer of underdelivered goods is registered';
					|pl = 'For underdelivered goods, transfer to the provider (correction) is registered, and a new transfer of underdelivered goods is registered';
					|tr = 'Eksik teslim edilen ürünler alıcıya transfer edilir ve sonrasında eksik teslim edilen ürünlerin yeni bir transferi yapılır (yama)'");
	Else
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title
			= NStr("vi = 'Việc chuyển sản phẩm cho bên đặt gia công bị giảm đối với sản phẩm chưa được giao';
					|ru = 'Передача продукции давальцу уменьшается на недопоставленную продукцию';
					|en = 'Transfer of manufactured products to the provider is reduced by the quantity of underdelivered goods'; fa = 'Transfer of manufactured products to the provider is reduced by the quantity of underdelivered goods';
					|it = 'Al trasferimento dei prodotti al fornitore viene sottratta la quantità di prodotti non consegnati';
					|pl = 'Przekazanie produkcji właścicielowi surowców jest zmniejszana o niedostarczoną produkcję';
					|tr = 'Üretimin ana şirkete transferi, eksik teslim edilen üretim kadar azaltılır'");
		Items.AdditionalDeliveryIsRequiredDecoration.Title
			= NStr("vi = 'Việc chuyển sản phẩm cho bên đặt gia công bị giảm đối với sản phẩm chưa được giao với việc thực hiện tiếp theo chuyển mới hàng hóa chưa được giao';
					|ru = 'Передача продукции давальцу уменьшается на недопоставленную продукцию с последующим оформлением новой передачи недопоставленной продукции';
					|en = 'Transfer of manufactured products to the provider is reduced by the quantity of undelivered goods with the subsequent registration of a new transfer of undelivered goods'; fa = 'Transfer of manufactured products to the provider is reduced by the quantity of undelivered goods with the subsequent registration of a new transfer of undelivered goods';
					|it = 'Al trasferimento dei prodotti al fornitore viene sottratta la quantità di prodotti non consegnati con l''ultima formalizzazione del nuovo trasferimento di prodotti non consegnati';
					|pl = 'Przekazanie produkcji właściciela surowców zmniejsza się o niedostarczoną produkcję z następującą rejestracją nowego przekazania niedostarczonej produkcji';
					|tr = 'Tedarikçiye yapılan devir teslim eksik teslim edilen ürün kadar azaltılır ve eksik teslim edilen ürünün yeni bir devir teslimi gerçekleştirilir'");
	EndIf;
	
	Items.ShortageNotRecognizedDecoration.Title      = NStr("vi = 'Hàng hóa không được giao được vận chuyển từ kho, chứng từ không được xuất lại';
															|ru = 'Недопоставленная продукция не отгружается со склада, документы не переоформляются';
															|en = 'Undelivered goods are not shipped from the warehouse. The documents are not reregistered'; fa = 'Undelivered goods are not shipped from the warehouse. The documents are not reregistered';
															|it = 'I prodotti non consegnati non sono spediti dal magazzino, i documenti non saranno nuovamente formalizzati';
															|pl = 'Niedostarczona produkcja nie wysyła się z magazynu, dokumenty nie są tworzone ponownie';
															|tr = 'Teslim edilmeyen imal edilen ürünler depodan sevk edilmez, belgeler yeniden düzenlenmez'");
	Items.ShipNowDecoration.Title          = NStr("vi = 'Hàng hóa không được giao được vận chuyển từ kho, chứng từ không được xuất lại';
													|ru = 'Недопоставленная продукция отгружается со склада, документы не переоформляются';
													|en = 'Undelivered goods are shipped from the warehouse. The documents are not reregistered'; fa = 'Undelivered goods are shipped from the warehouse. The documents are not reregistered';
													|it = 'I prodotti non consegnati vengono consegnati dal magazzino, i documenti non saranno nuovamente formalizzati';
													|pl = 'Niedostarczona produkcja jest wysyłana z magazynu, dokumenty nie są tworzone ponownie';
													|tr = 'Teslim edilmeyen imal edilen ürünler depodan sevk edilir, belgeler yeniden düzenlenmez'");
	
	// Surpluses
	Items.DecorationSurplusAgreedUpon.Title       = NStr("vi = 'Hàng thừa khi giao đã thống nhất với bên đặt gia công';
														|ru = 'Излишки при передаче продукции согласованы с давальцем';
														|en = 'Surplus at transfer of manufactured products is approved with the provider'; fa = 'Surplus at transfer of manufactured products is approved with the provider';
														|it = 'Eccedenze al trasferimento dei prodotti concordati con il fornitore';
														|pl = 'Nadwyżki przy przekazaniu produkcji zostały uzgodnione z właścicielem surowców';
														|tr = 'Sağlayıcı ile mutabık kalınan üretim transferi fazlası'");
	Items.DecorationSurplusNotAgreedUpon.Title     = NStr("vi = 'Hàng thừa khi giao không thống nhất với bên đặt gia công';
															|ru = 'Излишки при передаче продукции не согласованы с давальцем';
															|en = 'Surplus at transfer of manufactured products is not approved with the provider'; fa = 'Surplus at transfer of manufactured products is not approved with the provider';
															|it = 'Eccedenze al trasferimento dei prodotti non concordati con il fornitore';
															|pl = 'Nadwyżki przy przekazaniu produkcji nie zostały uzgodnione z właścicielem surowców';
															|tr = 'Sağlayıcı ile mutabık kalınmayan üretim transferi fazlası'");
	
	// Action With The Product
	Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
	Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
	
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		Items.PurchaseOfARepostedDecoration.Title
			= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ chuyển giao cho người đặt gia công (điều chỉnh)';
					|ru = 'На перепоставленную продукцию оформляется передача давальцу (исправление)';
					|en = 'For overdelivered goods, transfer to the provider (correction) is registered'; fa = 'For overdelivered goods, transfer to the provider (correction) is registered';
					|it = 'For overdelivered goods, transfer to the provider (correction) is registered';
					|pl = 'For overdelivered goods, transfer to the provider (correction) is registered';
					|tr = 'Fazla teslim edilen ürünler alıcıya transfer edilir (yama)'");
		Items.ReturnOfTheReDeliveredDecoration.Title
			= NStr("vi = 'Đối với mặt hàng giao thừa, cần lập chứng từ chuyển giao cho bên đặt gia công (điều chỉnh), sau đó lập chứng từ tiếp nhận mặt hàng giao thừa';
					|ru = 'На перепоставленную продукцию оформляется передача давальцу (исправление) с последующим оформлением поступления перепоставленной продукции';
					|en = 'For overdelivered goods, transfer to provider (correction) is registered, and a new receipt of overdelivered goods is registered'; fa = 'For overdelivered goods, transfer to provider (correction) is registered, and a new receipt of overdelivered goods is registered';
					|it = 'For overdelivered goods, transfer to provider (correction) is registered, and a new receipt of overdelivered goods is registered';
					|pl = 'For overdelivered goods, transfer to provider (correction) is registered, and a new receipt of overdelivered goods is registered';
					|tr = 'Yeniden teslim edilen ürünler alıcıya transfer edilir, yeniden teslim edilen ürünlerin teslim alındığına dair müteakip kayıt yapılır (yama)'");
	Else
		Items.PurchaseOfARepostedDecoration.Title
			= NStr("vi = 'Việc chuyển sản phẩm cho bên đặt gia công bị tăng đối với sản phẩm chưa được giao';
					|ru = 'Передача продукции давальцу увеличивается на перепоставленную продукцию';
					|en = 'Transfer of manufactured products to the provider increases by the quantity of overdelivered goods'; fa = 'Transfer of manufactured products to the provider increases by the quantity of overdelivered goods';
					|it = 'Al trasferimento di prodotti al fornitore vengono aggiunti i prodotti consegnati in eccesso';
					|pl = 'Przekazanie produkcji właścicielowi surowców jest zwiększana o nadmiar dostarczonej produkcji';
					|tr = 'Üretimin sağlayıcıya transferi, arz fazlası ürün kadar artar'");
		Items.ReturnOfTheReDeliveredDecoration.Title
			= NStr("vi = 'Việc chuyển sản phẩm cho bên đặt gia công bị tăng đối với sản phẩm chưa được giao với việc thực hiện tiếp theo nhận mới hàng hóa chưa được giao lại';
					|ru = 'Передача продукции давальцу увеличивается на перепоставленную продукцию с последующим оформлением поступления перепоставленной продукции';
					|en = 'Transfer of manufactured products to the provider increases by the quantity of overdelivered goods with the subsequent registration of a new receipt of overdelivered goods'; fa = 'Transfer of manufactured products to the provider increases by the quantity of overdelivered goods with the subsequent registration of a new receipt of overdelivered goods';
					|it = 'Al trasferimento di prodotti al fornitore vengono aggiunti i prodotti consegnati in eccesso con l''ultima formalizzazione di ricezione di prodotti consegnati in eccesso';
					|pl = 'Przekazanie produkcji właściciela surowców jest zwiększane o nadmiar produkcji z następującym utworzeniem przyjęcia nadmiaru dostarczonej produkcji';
					|tr = 'Üretimin sağlayıcı transferi arz fazlası üretim kadar artar ve ardından arz fazlası üretimin teslim alınması gerçekleştirilir'");
	EndIf;
	
	Items.TheRepostedIsGivenAsADecoration.Title  = NStr("vi = 'Trả lại kho hàng được giao lại, không tạo lại chứng từ';
														|ru = 'Перепоставленная продукция не возвращается на склад, документы не переоформляются';
														|en = 'Overdelivered goods are not returned to the warehouse. The documents are not reregistered'; fa = 'Overdelivered goods are not returned to the warehouse. The documents are not reregistered';
														|it = 'I prodotti consegnati in eccesso non vengono restituiti al magazzino, i documenti non saranno nuovamente formalizzati';
														|pl = 'Nadmiar dostarczanej produkcji nie zwraca się do magazynu, dokumenty nie są tworzone ponownie';
														|tr = 'Fazla teslim edilen imal edilen ürünler depoya iade edilmez, belgeler yeniden düzenlenmez'");
	Items.EnterNowDecoration.Title       = NStr("vi = 'Trả lại kho hàng được giao lại, không tạo lại chứng từ';
												|ru = 'Перепоставленная продукция возвращается на склад, документы не переоформляются';
												|en = 'Overdelivered goods are returned to the warehouse. The documents are not reregistered'; fa = 'Overdelivered goods are returned to the warehouse. The documents are not reregistered';
												|it = 'La produzione consegnata in eccesso viene restituita al magazzino, i documenti non vengono nuovamente formalizzati';
												|pl = 'Nadmiar dostarczanej produkcji zwraca się do magazynu, dokumenty nie są tworzone ponownie';
												|tr = 'Fazla teslim edilen imal edilen ürünler depoya iade edilir, belgeler yeniden düzenlenmez'");
	
EndProcedure

&AtClient
Procedure GenerateHeadersOfReturnCertificateToGiver()
	
	// Shortages
	Items.DecorationShortfallsAgreed.Title     = NStr("vi = 'Hàng thiếu khi nhận lại nguyên vật liệu đã thống nhất với bên đặt gia công';
														|ru = 'Недостачи при возврате сырья согласованы с давальцем';
														|en = 'Shortage at return of raw materials is approved with the provider'; fa = 'Shortage at return of raw materials is approved with the provider';
														|it = 'Ammanchi al reso di materie prime concordati con il fornitore';
														|pl = 'Niedobory podczas zwrotu surowców są uzgodnione z właścicielem surowców';
														|tr = 'Sağlayıcı ile mutabık kalınan hammaddelerin iadesinde yaşanan eksiklikler'");
	Items.DecorationShortfallsNotAgreedUpon.Title   = NStr("vi = 'Hàng thiếu khi nhận lại nguyên vật liệu chưa thống nhất với bên đặt gia công';
															|ru = 'Недостачи при возврате сырья не согласованы с давальцем';
															|en = 'Shortage at return of raw materials is not approved with the provider'; fa = 'Shortage at return of raw materials is not approved with the provider';
															|it = 'Ammanchi al reso di materie prime non concordati con il fornitore';
															|pl = 'Niedobory przy przekazaniu surowców nie zostały uzgodnione z właścicielem surowców';
															|tr = 'Sağlayıcı ile mutabık kalınmayan hammaddelerin iadesinde yaşanan eksiklikler'");
	
	// Action With The Product
	Items.WriteOffActionWithShortageGoodsOutOfWay.Visible = False;
	Items.WriteOffFromWayActionWithGoodsShortageDecoration.Visible = False;
	
	Items.WriteOFFActionWithShortageGoods.Visible = False;
	Items.WriteOFFActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ReturnActionWithShortageGoods.Visible = False;
	Items.ReturnActionWithShortageGoodsDecoration.Visible = False;
	
	Items.ExpectActionWithShortageGoods.Visible = False;
	Items.ExpectActionWithShortageGoodsDecoration.Visible = False;
	
	// Action With A Document
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title
			= NStr("vi = 'Đối với nguyên vật liệu giao thiếu, cần lập chứng từ trả lại cho bên nhận gia công (điều chỉnh)';
					|ru = 'На недопоставленное сырье оформляется возврат давальцу (исправление)';
					|en = 'For underdelivered raw materials, return to the provider is registered (correction)'; fa = 'For underdelivered raw materials, return to the provider is registered (correction)';
					|it = 'For underdelivered raw materials, return to the provider is registered (correction)';
					|pl = 'For underdelivered raw materials, return to the provider is registered (correction)';
					|tr = 'Teslim edilmeyen hammaddeler için alıcıya bir iade işlemi yapılır (yama)'");
		Items.AdditionalDeliveryIsRequiredDecoration.Title
			= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ trả lại cho bên nhận gia công (điều chỉnh), sau đó lập chứng từ trả lại mới cho mặt hàng chưa giao';
					|ru = 'На недопоставленное сырье оформляется возврат давальцу (исправление) с последующим оформлением нового возврата недопоставленного сырья';
					|en = 'For underdelivered raw materials, return to provider (correction) is registered, and a new return of underdelivered raw materials is registered'; fa = 'For underdelivered raw materials, return to provider (correction) is registered, and a new return of underdelivered raw materials is registered';
					|it = 'For underdelivered raw materials, return to provider (correction) is registered, and a new return of underdelivered raw materials is registered';
					|pl = 'For underdelivered raw materials, return to provider (correction) is registered, and a new return of underdelivered raw materials is registered';
					|tr = 'Eksik teslim edilen hammaddeler alıcıya iade edilir ve eksik teslim edilen hammaddelerin yeni bir iadesi yapılır (yama)'");
	Else
		Items.AdditionalDeliveryIsNotRequiredDecoration.Title
			= NStr("vi = 'Trả lại nguyên vật liệu cho bên đặt gia công bị giảm đối với nguyên vật liệu chưa giao';
					|ru = 'Возврат давальцу уменьшается на недопоставленное сырье';
					|en = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials'; fa = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials';
					|it = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials';
					|pl = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials';
					|tr = 'Sağlayıcıya iade, teslim edilmeyen hammaddeler kadar azaltılır'");
		Items.AdditionalDeliveryIsRequiredDecoration.Title
			= NStr("vi = 'Trả lại nguyên vật liệu cho bên đặt gia công bị giảm đối với nguyên vật liệu chưa giao, sau đó lập trả lại mới nguyên vật liệu chưa giao';
					|ru = 'Возврат давальцу уменьшается на недопоставленное сырье с последующим оформлением нового возврата недопоставленного сырья';
					|en = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials with the subsequent registration of a new return of underdelivered raw materials'; fa = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials with the subsequent registration of a new return of underdelivered raw materials';
					|it = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials with the subsequent registration of a new return of underdelivered raw materials';
					|pl = 'Goods return — Subcontracting services delivered is reduced by the quantity of underdelivered raw materials with the subsequent registration of a new return of underdelivered raw materials';
					|tr = 'Sağlayıcıya iade, teslim edilmeyen hammaddeler kadar azaltılır ve yeni bir teslim edilmeyen hammadde iadesi düzenlenir'");
	EndIf;
	
	Items.ShortageNotRecognizedDecoration.Title      = NStr("vi = 'Chưa giao nguyên vật liệu chưa giao từ kho, không tạo lại chứng từ';
															|ru = 'Недопоставленное сырье не отгружается со склада, документы не переоформляются';
															|en = 'Undelivered raw materials are not shipped from the warehouse. The documents are not reregistered'; fa = 'Undelivered raw materials are not shipped from the warehouse. The documents are not reregistered';
															|it = 'Le materie prime non consegnate non vengono spedite dal magazzino, i documenti non saranno nuovamente formalizzati';
															|pl = 'Niedostarczone surowce nie są wysyłane z magazynu, dokumenty nie są ponownie tworzone';
															|tr = 'Teslim edilmeyen hammaddeler depodan çıkarılmaz, belgeler yeniden düzenlenmez'");
	Items.ShipNowDecoration.Title          = NStr("vi = 'Giao nguyên vật liệu từ kho, không tạo lại chứng từ';
													|ru = 'Недопоставленное сырье отгружается со склада, документы не переоформляются';
													|en = 'Undelivered raw materials are shipped from the warehouse. The documents are not reregistered'; fa = 'Undelivered raw materials are shipped from the warehouse. The documents are not reregistered';
													|it = 'Le materie prime non consegnate sono spedite dal magazzino, i documenti non saranno nuovamente formalizzati';
													|pl = 'Niedostarczone surowce są wysyłane z magazynu, dokumenty nie są tworzone ponownie';
													|tr = 'Teslim edilmeyen hammaddeler stok dışı sevk edilir, belgeler yeniden düzenlenmez'");
	
	// Surpluses
	Items.DecorationSurplusAgreedUpon.Title       = NStr("vi = 'Hàng thừa khi nhận lại nguyên vật liệu đã thống nhất với bên đặt gia công';
														|ru = 'Излишки при возврате сырья согласованы с давальцем';
														|en = 'Surplus at return of raw materials is approved with the provider'; fa = 'Surplus at return of raw materials is approved with the provider';
														|it = 'Eccedenze al reso di materie prime concordate con il fornitore';
														|pl = 'Nadwyżki podczas zwrotu surowców są uzgodnione z właścicielem surowców';
														|tr = 'Sağlayıcı ile mutabık kalınan hammaddelerin iadesinde yaşanan fazlalıklar'");
	Items.DecorationSurplusNotAgreedUpon.Title     = NStr("vi = 'Hàng thiếu khi nhận lại nguyên vật liệu chưa thống nhất với bên đặt gia công';
															|ru = 'Излишки при возврате сырья не согласованы с давальцем';
															|en = 'Surplus at return of raw materials is not approved with the provider'; fa = 'Surplus at return of raw materials is not approved with the provider';
															|it = 'Eccedenze al reso di materie prime non concordate con il fornitore';
															|pl = 'Nadwyżki przy przekazaniu surowców nie zostały uzgodnione z właścicielem surowców';
															|tr = 'Sağlayıcı ile mutabık kalınmayan hammaddelerin iadesinde yaşanan fazlalıklar'");
	
	// Action With The Product
	Items.EnterIntoWayOfActionWithSurplusGoods.Visible = False;
	Items.EnterIntoWayOfActionWithGoodsSurplusDecoration.Visible = False;
	
	// Action With A Document
	If DiscrepanciesPostingMethod = PredefinedValue("Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection") Then
		Items.PurchaseOfARepostedDecoration.Title
			= NStr("vi = 'Đối với nguyên vật liệu giao thừa, cần lập chứng từ trả lại cho bên nhận gia công (điều chỉnh)';
					|ru = 'На перепоставленное сырье оформляется возврат давальцу (исправление)';
					|en = 'For overdelivered raw materials, a return to the provider (correction) is registered'; fa = 'For overdelivered raw materials, a return to the provider (correction) is registered';
					|it = 'For overdelivered raw materials, a return to the provider (correction) is registered';
					|pl = 'For overdelivered raw materials, a return to the provider (correction) is registered';
					|tr = 'Gereğinden fazla teslim edilen hammaddeler için alıcıya bir iade işlemi yapılır (yama)'");
		Items.ReturnOfTheReDeliveredDecoration.Title
			= NStr("vi = 'Đối với nguyên vật liệu giao thừa, cần lập chứng từ chuyển giao cho bên nhận gia công (điều chỉnh), sau đó lập chứng từ tiếp nhận nguyên vật liệu giao thừa';
					|ru = 'На перепоставленное сырье оформляется возврат давальцу (исправление) с последующим оформлением поступления перепоставленного сырья';
					|en = 'For overdelivered raw materials, a return to the provider (correction) is registered, and a new overdelivered goods receipt is registered'; fa = 'For overdelivered raw materials, a return to the provider (correction) is registered, and a new overdelivered goods receipt is registered';
					|it = 'For overdelivered raw materials, a return to the provider (correction) is registered, and a new overdelivered goods receipt is registered';
					|pl = 'For overdelivered raw materials, a return to the provider (correction) is registered, and a new overdelivered goods receipt is registered';
					|tr = 'Fazladan teslim edilen hammaddeler alıcıya iade edilir, sonrasında ise fazladan teslim edilen hammaddelerin teslim alındığına dair bir kayıt tutulur (yama)'");
	Else
		Items.PurchaseOfARepostedDecoration.Title
			= NStr("vi = 'Trả lại nguyên vật liệu cho bên đặt gia công tăng lên đối với nguyên vật liệu giao lại';
					|ru = 'Возврат давальцу увеличивается на перепоставленное сырье';
					|en = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials'; fa = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials';
					|it = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials';
					|pl = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials';
					|tr = 'Sağlayıcıya iade, arz fazlası hammaddeler dolayısıyla artar'");
		Items.ReturnOfTheReDeliveredDecoration.Title
			= NStr("vi = 'Trả lại nguyên vật liệu cho bên đặt gia công tăng lên đối với nguyên vật liệu giao lại, sau đó lập tiếp nhận nguyên vật liệu giao lại';
					|ru = 'Возврат давальцу увеличивается на перепоставленное сырье с последующим оформлением поступления перепоставленного сырья';
					|en = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials with the subsequent registration of overdelivered raw material receipt'; fa = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials with the subsequent registration of overdelivered raw material receipt';
					|it = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials with the subsequent registration of overdelivered raw material receipt';
					|pl = 'Goods return — Subcontracting services delivered is increased by the quantity of overdelivered raw materials with the subsequent registration of overdelivered raw material receipt';
					|tr = 'Sağlayıcıya iade, arz fazlası hammaddeler kadar artar ve ardından fazla tedarik edilen hammaddeler teslim alınır'");
	EndIf;
	
	Items.TheRepostedIsGivenAsADecoration.Title  = NStr("vi = 'Chưa trả lại nguyên vật liệu giao lại vào kho, không tạo lại chứng từ';
														|ru = 'Перепоставленное сырье не возвращается на склад, документы не переоформляются';
														|en = 'Overdelivered raw materials are not returned to the warehouse. The documents are not reregistered'; fa = 'Overdelivered raw materials are not returned to the warehouse. The documents are not reregistered';
														|it = 'Le materie prime consegnate in eccesso non vengono restituite al magazzino, i documenti non saranno nuovamente formalizzati';
														|pl = 'Nadmiar dostarczanych surowców nie zwraca się do magazynu, dokumenty nie są tworzone ponownie';
														|tr = 'Fazla tedarik edilen hammaddeler depoya iade edilmez, belgeler yeniden düzenlenmez'");
	Items.EnterNowDecoration.Title       = NStr("vi = 'Trả lại nguyên vật liệu giao lại vào kho, chưa tạo lại chứng từ';
												|ru = 'Перепоставленное сырье возвращается на склад, документы не переоформляются';
												|en = 'Overdelivered raw materials are returned to the warehouse. The documents are not reregistered'; fa = 'Overdelivered raw materials are returned to the warehouse. The documents are not reregistered';
												|it = 'Le materie prime consegnate in eccesso vengono restituite al magazzino, i documenti non saranno nuovamente formalizzati';
												|pl = 'Nadmiar dostarczanych surowców zwraca się do magazynu, dokumenty nie są tworzone ponownie';
												|tr = 'Fazla tedarik edilen hammaddeler depoya iade edilir, belgeler yeniden düzenlenmez'");
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfActions()
	
	// Shortages
	
	If ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off") Then
		
		Items.CreatingGoodsReceiptsByOrderAreNotMoreRequired.Enabled = True;
		Items.AdditionalSupplyRequired.Enabled = True;
		Items.ShipNow.Enabled = True;
		Items.GoodsShortageIsControversial.Enabled = False;
		
		If ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial") Then
			ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired");
		EndIf;
		
	ElsIf ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit") Then
		
		Items.CreatingGoodsReceiptsByOrderAreNotMoreRequired.Enabled = True;
		Items.AdditionalSupplyRequired.Enabled = True;
		Items.ShipNow.Enabled = False;
		Items.GoodsShortageIsControversial.Enabled = False;
		
		If ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial")
			Or ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow") Then
			ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired");
		EndIf;
		
	ElsIf ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount") Then
		
		Items.CreatingGoodsReceiptsByOrderAreNotMoreRequired.Enabled = True;
		Items.AdditionalSupplyRequired.Enabled = True;
		Items.ShipNow.Enabled = True;
		Items.GoodsShortageIsControversial.Enabled = True;
		
	ElsIf ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_") Then
		
		Items.CreatingGoodsReceiptsByOrderAreNotMoreRequired.Enabled = True;
		Items.AdditionalSupplyRequired.Enabled = True;
		Items.ShipNow.Enabled = False;
		Items.GoodsShortageIsControversial.Enabled = False;
		
		If ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial")
			Or ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow") Then
			ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired");
		EndIf;
		
	ElsIf ActionWithShortageGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait") Then
		
		Items.CreatingGoodsReceiptsByOrderAreNotMoreRequired.Enabled = False;
		Items.AdditionalSupplyRequired.Enabled = False;
		Items.ShipNow.Enabled = False;
		Items.GoodsShortageIsControversial.Enabled = True;
		
		If ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired")
			Or ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired")
			Or ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow") Then
			ActionWithShortageDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial");
		EndIf;
		
	EndIf;
	
	// Surpluses
	
	If ActionWithSurplusGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
		
		Items.PurchasingOverdelivery.Enabled = True;
		Items.ReturnOverdelivered.Enabled = True;
		Items.ReturnWithoutRegistration.Enabled = False;
		Items.DisregardShortage.Enabled = False;
		
		If ActionWithSurplusDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration")
			Or ActionWithSurplusDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage") Then
			ActionWithSurplusDocument = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery");
		EndIf;
		
	ElsIf ActionWithSurplusGoods = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount") Then
		
		Items.PurchasingOverdelivery.Enabled = True;
		Items.ReturnOverdelivered.Enabled = True;
		Items.ReturnWithoutRegistration.Enabled = True;
		Items.DisregardShortage.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

