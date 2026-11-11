
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CashRegister = Parameters.CashRegister;
	Cashier = Parameters.Cashier;
	Organization = Parameters.Organization;
	StructureRegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;
	
	CashRegisterParameters = Catalogs.CashRegisters.CashRegisterParameters(CashRegister);
	CashRegisterIsUsedWithoutConnectionOfEquipment = CashRegisterParameters.UseWithoutConnectingPeripherals;
	Period = New StandardPeriod(StandardPeriodVariant.Today);
	
	If ValueIsFilled(CashRegisterShift) Then
		UsedByKKTFZ54 = RetailSalesServerCall.UsedByKKTFZ54(CashRegisterShift);
	Else
		UsedByKKTFZ54 = False;
	EndIf;
		
	FillInTheGoodsTable();
	
	Warehouse = Common.ObjectAttributeValue(CashRegister, "Warehouse");
	
	Items.Period.Visible                  = (UsedByKKTFZ54 Or CashRegisterIsUsedWithoutConnectionOfEquipment);
	Items.TableOfGoodsPremise.Visible = WarehousesServer.UseWarerooms(Warehouse, CurrentSessionDate());
	
	UseSets                     = GetFunctionalOption("UseSets");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	Items.TableOfGoodsProductsInSet.Visible   = UseSets;
	Items.TableOfGoodsItemVariantOfSet.Visible = UseSets And UseItemVariants;
	
	FillInPresentationOfTitleOfIssueRefundButtonOnServer();
	Items.FormRegisterReturn.Title = PresentationOfRefundButtonTitle.RegisterReturn;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterReturn(Command)
	
	ClearMessages();
	If SelectedPositions = 0 Then
		MessageText = NStr("vi = 'Cần chọn phiếu tính tiền để lập chứng từ trả lại hàng theo phiếu.';
							|ru = 'Необходимо выбрать чек для оформления возврата по чеку.';
							|en = 'Select a receipt to register return'; fa = 'Select a receipt to register return';
							|it = 'È necessario selezionare uno scontrino per la compilazione del reso per scontrino.';
							|pl = 'Należy wybrać paragon do tworzenia zwrotu według paragonu.';
							|tr = 'Makbuz üzerinden iade yapmak için bir makbuz seçmelisiniz.'", CommonClient.DefaultLanguageCode());
		CommonClient.MessageToUser(MessageText);
		Return;
	Else
 		RowsSelected = TableOfGoods.FindRows(New Structure("Selected", True));
		AdditionalParameters = New Structure("RowsSelected", RowsSelected);
		CallbackDescriptionOnCompletion = New CallbackDescription("OpenCWPFormForIssuingCashRegisterReceipt", ThisObject, AdditionalParameters);
		If Not RequestConfirmationOfReceiptSelectionForRefund(CallbackDescriptionOnCompletion) Then
			RunCallback(CallbackDescriptionOnCompletion, DialogReturnCode.Yes);
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TableOfGoodsSelectedOnChange(Item)
	
	SelectedPositions = 0;
	Total            = 0;
	
	CurrentData = Items.TableOfGoods.CurrentData;
	
	ProductsInSet   = CurrentData.ProductsInSet;
	ItemVariantOfSet = CurrentData.ItemVariantOfSet;
	
	CashRegisterReceipt        = CurrentData.CashRegisterReceipt;
	PaidByCard = CurrentData.PaidByCard;
	PriceIsSetPerSet = CurrentData.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares")
						Or CurrentData.SetPricingOption = PredefinedValue("Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices");
	
	For Each TSRow In TableOfGoods Do
		If TSRow.CashRegisterReceipt = CashRegisterReceipt
			And (PaidByCard
				Or (TSRow.ProductsInSet = ProductsInSet
				And TSRow.ItemVariantOfSet = ItemVariantOfSet)) Then
			TSRow.Selected = CurrentData.Selected;
		EndIf;
		If Not TSRow.CashRegisterReceipt = CashRegisterReceipt Then
			TSRow.Selected = False;
		EndIf;
		If TSRow.Selected Then
			SelectedPositions = SelectedPositions + 1;
			Total = Total + TSRow.Sum;
		EndIf;			
	EndDo;
	
	DeferredReceiptCashRegistersRefund = CurrentData.DeferredReceiptCashRegistersRefund;
	If ValueIsFilled(DeferredReceiptCashRegistersRefund) Then
		Items.FormRegisterReturn.Title = PresentationOfRefundButtonTitle.OpenDeferredRefund;
	Else
		Items.FormRegisterReturn.Title = PresentationOfRefundButtonTitle.RegisterReturn;
	EndIf;
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure OpenCWPFormForIssuingCashRegisterReceipt(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		
		FormParameters = New Structure;	
		Rows = AdditionalParameters.RowsSelected;	
		DeferredReceiptCashRegistersRefund = Rows[0].DeferredReceiptCashRegistersRefund;
		If ValueIsFilled(DeferredReceiptCashRegistersRefund) Then
			FormParameters.Insert("Key", DeferredReceiptCashRegistersRefund);
		Else
			SelectedReceipt = Rows[0].CashRegisterReceipt;

			OpeningParameters = New Structure;
			OpeningParameters.Insert("Goods", AddressInTempStorage(SelectedReceipt, FormOwner.UUID));
			OpeningParameters.Insert("CashRegisterReceipt", SelectedReceipt);
			OpeningParameters.Insert("Cashier", Cashier);

			FormParameters.Insert("Basis", OpeningParameters);
		EndIf;

		OpenForm("Document.CashRegisterReceiptReturn.Form.CWPDocumentForm", FormParameters, FormOwner);
		
		Close();
	EndIf;
	
EndProcedure

&AtClient
Function RequestConfirmationOfReceiptSelectionForRefund(CallbackOnCompletion)
	Result = False;
	
	CashRegisterReceiptCashShiftIsOpen = CallbackOnCompletion.AdditionalParameters.RowsSelected[0].CashRegisterReceiptCashShiftIsOpen;	
	If CashRegisterReceiptCashShiftIsOpen = True Then
		Result = True;
		QueryText = NStr("vi = 'Phiên thu ngân của phiếu bán được chọn khác với phiên hiện tại và còn chưa bị đóng. 
							|Nếu sẽ đóng phiên hiện tại trước thì điều này có thể dẫn đến phản ánh sai khi ghi nhận dữ liệu về trả lại. Tiếp tục?';
							|ru = 'Кассовая смена выбранного чека продажи отличается от текущей и ещё не закрыта.
							|Если текущая кассовая смена будет закрыта раньше, это может привести к неправильному отражению в учете данных о возврате. Продолжить?';
							|en = 'The POS shift of the selected sales receipt differs from the current one and is not yet closed.
							|If the current POS shift is closed earlier, this may lead to incorrect recording of the return data in accounting. Continue?'; fa = 'The POS shift of the selected sales receipt differs from the current one and is not yet closed.
							|If the current POS shift is closed earlier, this may lead to incorrect recording of the return data in accounting. Continue?';
							|it = 'Кассовая смена выбранного чека продажи отличается от текущей и ещё не закрыта.
							|Если текущая кассовая смена будет закрыта раньше, это может привести к неправильному отражению в учете данных о возврате. Продолжить?';
							|pl = 'The POS shift of the selected sales receipt differs from the current one and is not yet closed.
							|If the current POS shift is closed earlier, this may lead to incorrect recording of the return data in accounting. Continue?';
							|tr = 'Seçilen satış fişinin kasa vardiyası mevcut kasa vardiyasından farklı ve henüz kapatılmamış.
							|Mevcut kasa vardiyasının daha erken kapatılması iade verilerinin muhasebeye yanlış yansımasına neden olabilir. Devam edilsin mi?'");
		ShowQueryBox(CallbackOnCompletion, QueryText, QuestionDialogMode.YesNo);

	EndIf;

	Return Result;
EndFunction

&AtServer
Procedure FillInPresentationOfTitleOfIssueRefundButtonOnServer()
	
	PresentationOfRefundButtonTitle = New Structure;
	PresentationOfRefundButtonTitle.Insert("RegisterReturn", Commands.Find(Items.FormRegisterReturn.CommandName).Title);
	PresentationOfRefundButtonTitle.Insert("OpenDeferredRefund", NStr("vi = 'Mở chứng từ trả lại hoãn lại';
																		|ru = 'Открыть отложенный возврат';
																		|en = 'Open deferred return'; fa = 'Open deferred return';
																		|it = 'Aprire reso postposto';
																		|pl = 'Otwórz odłożony zwrot';
																		|tr = 'Bekleyen bir iade açın'"));	
	
EndProcedure

&AtServerNoContext
Function AddressInTempStorage(SelectedReceipt, UUID)
	
	FilterParameters = Documents.CashRegisterReceipt.ParametersForReceivingNonReturnedItemsByCashRegisterReceipt();
	FilterParameters.CashRegisterReceipt = SelectedReceipt;
	FilterParameters.UsedByKKTFZ54 = True;

	DataToFill = Documents.CashRegisterReceipt.TableOfNonReturnedItemsByCashRegisterReceipt(FilterParameters);	
	Return PutToTempStorage(DataToFill, UUID);
	
EndFunction
&AtServer
Procedure FillInTheGoodsTable()
	
	TableOfGoods.Clear();
	
	FilterParameters = Documents.CashRegisterReceipt.ParametersForReceivingNonReturnedItemsByCashRegisterReceipt();
	FilterParameters.CashRegisterIsUsedWithoutConnectionOfEquipment = CashRegisterIsUsedWithoutConnectionOfEquipment;
	FilterParameters.UsedByKKTFZ54 = UsedByKKTFZ54;
	FilterParameters.CashRegisterShift = CashRegisterShift;
	FilterParameters.CashRegisterReceiptNumber = CashRegisterReceiptNumber;
	FilterParameters.Products = Products;
	FilterParameters.LoyaltyCard = LoyaltyCard;
	FilterParameters.Period = Period;
	FilterParameters.Organization = Organization;
	
	SelectedPositions = 0;
	Total = 0;
	SelectedReceipt = Undefined;
	
	DataToFill = Documents.CashRegisterReceipt.TableOfNonReturnedItemsByCashRegisterReceipt(FilterParameters);
	For Each DataLineToFillIn In DataToFill Do
		
		TSRow = TableOfGoods.Add();
		FillPropertyValues(TSRow, DataLineToFillIn);
		
		If SelectedReceipt = Undefined Then
			If ValueIsFilled(Products) Or ValueIsFilled(CashRegisterReceiptNumber) Or ValueIsFilled(LoyaltyCard) Then
				SelectedReceipt = TSRow.CashRegisterReceipt;
			EndIf;			
		EndIf;
		
		If ValueIsFilled(SelectedReceipt) And TSRow.CashRegisterReceipt = SelectedReceipt Then
			TSRow.Selected = True;
			SelectedPositions = SelectedPositions + 1;
			Total = Total + TSRow.Sum; 			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FindGoods(Command)
	
	TableOfGoods.Clear();
	FillInTheGoodsTable();
	
EndProcedure

#EndRegion

#EndRegion
