
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Orders                       = Parameters.Orders;
	DocumentInitiator            = Parameters.DocumentInitiator;
	
	CancelUnprocessedLines = ?(Parameters.Property("CancelUnprocessedLines"),
									Parameters.CancelUnprocessedLines,
									False);
	
	CorrectMeasuringGoods  = True;
	
	AdjustTheMeasuredGoodsUponAcceptance = ?(Parameters.Property("AdjustTheMeasuredGoodsUponAcceptance"),
									Parameters.AdjustTheMeasuredGoodsUponAcceptance,
									False);
	
	CorrectPrices          = ?(Parameters.Property("CorrectPrices"),
									Parameters.CorrectPrices,
									False);
	
	CloseOrders              = ?(Parameters.Property("CloseOrders"),
									Parameters.CloseOrders,
									False);
		
	TableOfGoodsReceipt         = ?(Parameters.Property("TableOfGoodsReceipt"),
									GetFromTempStorage(Parameters.TableOfGoodsReceipt),
									Undefined); 
	
	TableOfGoodsExpense         = ?(Parameters.Property("TableOfGoodsExpense"),
									GetFromTempStorage(Parameters.TableOfGoodsExpense),
									Undefined);
	
	If Not TableOfGoodsReceipt = Undefined Then
		DeleteFromTempStorage(Parameters.TableOfGoodsReceipt);
	EndIf;
	
	If Not TableOfGoodsReceipt = Undefined Then
		DeleteFromTempStorage(Parameters.TableOfGoodsExpense);
	EndIf;
	
	If ValueIsFilled(Orders) Then
		NumberOfUnverified = Common.CheckDocumentsPosting(Orders.UnloadValues()).Count();
		If NumberOfUnverified = 1 Then
			Raise NStr("vi = 'Để thực hiện lệnh, trước tiên cần kết chuyển chứng từ.';
						|ru = 'Для выполнения команды необходимо предварительно провести документ.';
						|en = 'Post the document to run the command.'; fa = 'Post the document to run the command.';
						|it = 'Per eseguire il comando è necessario prima registrare il documento.';
						|pl = 'Aby wykonać polecenie, należy najpierw zatwierdzić dokument.';
						|tr = 'Komutu çalıştırmak için belgeyi daha önce kaydetmek gerekir.'");
		ElsIf NumberOfUnverified > 1 Then
			Raise NStr("vi = 'Để thực hiện lệnh, trước tiên cần kết chuyển chứng từ.';
						|ru = 'Для выполнения команды необходимо предварительно провести документы.';
						|en = 'Post the documents to run the command.'; fa = 'Post the documents to run the command.';
						|it = 'Per eseguire il comando è necessario prima registrare i documenti.';
						|pl = 'Aby wykonać polecenie, należy najpierw zatwierdzić dokumenty.';
						|tr = 'Komutu çalıştırmak için belgeleri daha önce kaydetmek gerekir.'");
		EndIf;
	Else
		Raise NStr("vi = 'Để thực hiện một lệnh, cần chọn một chứng từ.';
					|ru = 'Для выполнения команды необходимо выбрать документ.';
					|en = 'To run the command, select the document.'; fa = 'To run the command, select the document.';
					|it = 'Per eseguire il comando è necessario selezionare un documento.';
					|pl = 'Aby wykonać polecenie, należy wybrać dokument.';
					|tr = 'Komutu çalıştırmak için belge seçilmeli.'");
	EndIf;
	
	SetConditionalAppearance();
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	FillInDeviationsForOrders(TableOfGoodsReceipt,TableOfGoodsExpense);
	
	FillInitialSettings();
	FillPagesForDisplay(ThisForm);
	FillInHintsAndDecorations();
	
	SetVisibilityOfElementsWhenCreating();
	SetCurPageOfNavigationBar(ThisForm);
	FormInscriptionCalculations();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ForceCloseTheForm Then 
		Return;
	EndIf;
	
	If Not Done And Modified Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Chưa thực hiện đóng đơn hàng. Đóng biểu mẫu?';
				|ru = 'Закрытие заказов не выполнено. Закрыть форму?';
				|en = 'The orders are not closed. Close the form?'; fa = 'The orders are not closed. Close the form?';
				|it = 'La chiusura degli ordini non è eseguita. Chiudere il modulo?';
				|pl = 'Nie wykonano zamknięcie zamówień. Zamknąć formularz?';
				|tr = 'Kapatma emirleri tamamlanmadı. Form kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "Close" Then
		ForceCloseTheForm = True;
		Close(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetOrderClosingAvailability();
	SetVisibilityOfCancellationReason();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ToCancelTheUndeliveredOnChange(Item)
	
	SetVisibilityOfCancellationReason();
	SetOrderClosingAvailability();
	FillPagesForDisplay(ThisForm);
	
EndProcedure

&AtClient
Procedure CorrectMeasuringGoodsOnChange(Item)
	
	SetOrderClosingAvailability();
	FillPagesForDisplay(ThisForm);
	
EndProcedure

&AtClient
Procedure CorrectPricesOnChange(Item)
	SetOrderClosingAvailability();
	FillPagesForDisplay(ThisForm);
EndProcedure

&AtClient
Procedure CloseOrdersOnChange(Item)
	FillPagesForDisplay(ThisForm);
EndProcedure

&AtClient
Procedure CalculationsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	PlaceForCard = PlaceForCard(Orders[0].Value);
	
	If OrderType_5 = "SalesOrder" Then
		ReportsTMClientOverridable.OpenCustomerSettlementCardReport("CardOfSettlementsWithClientsOnDocumentsContext",
																				PlaceForCard);
	ElsIf OrderType_5 = "PurchaseOrder" Then
		ReportsTMClientOverridable.OpenPaymentCardWithSuppliersReport("PaymentCardWithSuppliersAccordingToDocumentsContext",
																				PlaceForCard);
	ElsIf OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		ReportsTMClientOverridable.OpenCustomerSettlementCardReport("CardOfSettlementsWithClientsOnDocumentsContext",
																				PlaceForCard);
	ElsIf OrderType_5 = "SubcontractOrder2_5"
		Or False Then
		ReportsTMClientOverridable.OpenPaymentCardWithSuppliersReport("CardOfSettlementsWithClientsOnDocumentsContext",
																				PlaceForCard);
	ElsIf OrderType_5 = "MaterialProviderOrder2_5" Then
		ReportsTMClientOverridable.OpenCustomerSettlementCardReport("CardOfSettlementsWithClientsOnDocumentsContext",
																				PlaceForCard);
	EndIf;
	
EndProcedure

&AtServer
Function PlaceForCard(OrderDocument)
	OrderDetails = Common.ObjectAttributesValues(OrderDocument,"ARAPObjectSettings,Contract");
	If OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		Return OrderDetails.Contract;
	Else
		Return OrderDocument;
	EndIf;
EndFunction

#EndRegion

#Region FormTableItemsEventHandlersGoodsForCancellation

&AtClient
Procedure GoodsForCancellationShipmentSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.GoodsForCancellationShipment.CurrentData <> Undefined Then
		
		If Field.Name = "ItemsToCancelShipmentOrder" Then
			ShowValue(Undefined, Items.GoodsForCancellationShipment.CurrentData.OrderDocument);
		EndIf;
		
	EndIf;
	
EndProcedure


&AtClient
Procedure GoodsForCancellationReceivingSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.GoodsForCancellationReceiving.CurrentData <> Undefined Then
		
		If Field.Name = "TheGoodsToCancelTheAcceptanceOrder" Then
			ShowValue(Undefined, Items.GoodsForCancellationReceiving.CurrentData.OrderDocument);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MeasuringGoodsForAdjustmentReceivingSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.MeasuringGoodsForAdjustmentReceiving.CurrentData <> Undefined Then
		
		If Field.Name = "MeasuringGoodsForAdjustmentReceivingOrderDocument" Then
			ShowValue(Undefined, Items.MeasuringGoodsForAdjustmentReceiving.CurrentData.OrderDocument);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MeasuringGoodsForAdjustmentShipmentSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.MeasuringGoodsForAdjustmentShipment.CurrentData <> Undefined Then
		
		If Field.Name = "MeasuringGoodsForAdjustmentShipmentOrderDocument" Then
			ShowValue(Undefined, Items.MeasuringGoodsForAdjustmentShipment.CurrentData.OrderDocument);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPriceVariances

&AtClient
Procedure PriceVariancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.PriceVariances.CurrentData <> Undefined Then
		
		If Field.Name = "PriceVariancesPurchaseOrder" Then
			ShowValue(Undefined, Items.PriceVariances.CurrentData.PurchaseOrder);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormTableElementsReadyToClose

&AtClient
Procedure UnfulfilledOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Items.UnfulfilledOrders.CurrentData.OrderDocument);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTwoWayDivergenceProducts

&AtClient
Procedure ProductsDivergenceOnTwoWayDecorationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("PurposeUseKey", "OrderClosureWizard");
	FormParameters.Insert("CurrentPageName", "ReceiptOrderPage");
	
	OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	
	If UseOrderCancellationReasons And CancelUnprocessedLines And Not ValueIsFilled(CancellationReason) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Nguyên nhân hủy bỏ""';
						|ru = 'Поле ""Причина отмены"" не заполнено';
						|en = '""Cancellation reason"" is required'; fa = '""Cancellation reason"" is required';
						|it = 'Il campo ""Causa di annullamento"" non è compilato';
						|pl = 'Nie wypełniono pola ""Причина отмены""';
						|tr = '""İptal nedeni"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(
			ErrorText,,"CancellationReason",,);
			
		Return;
		
	EndIf;
	
	CurPageIndex =
		PagesToDisplay.IndexOf(PagesToDisplay.FindByValue(Items.Pages.CurrentPage.Name));
	
	Items.Pages.CurrentPage = Items.Find(PagesToDisplay[CurPageIndex+1]);
	
	SetCurPageOfNavigationBar(ThisForm);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	CurPageIndex =
		PagesToDisplay.IndexOf(PagesToDisplay.FindByValue(Items.Pages.CurrentPage.Name));
	
	Items.Pages.CurrentPage = Items.Find(PagesToDisplay[CurPageIndex-1]);
	
	SetCurPageOfNavigationBar(ThisForm);
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	ClearMessages();
	
	If UseOrderCancellationReasons And CancelUnprocessedLines And Not ValueIsFilled(CancellationReason) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Nguyên nhân hủy bỏ""';
						|ru = 'Поле ""Причина отмены"" не заполнено';
						|en = '""Cancellation reason"" is required'; fa = '""Cancellation reason"" is required';
						|it = 'Il campo ""Causa di annullamento"" non è compilato';
						|pl = 'Nie wypełniono pola ""Причина отмены""';
						|tr = '""İptal nedeni"" alanı doldurulmamış'");
		
		CommonClientServer.MessageToUser(
			ErrorText,,"CancellationReason",,);
			
		Return;
		
	EndIf;
	
	If OrdersAreClosed Or Items.Navigation.CurrentPage = Items.NavigationAllOrdersAreClosed Then
	
		Done = True;
		Close();
	
	Else
		
		StructureOfAdditionalParameters = New Structure;
		StructureOfAdditionalParameters.Insert("TabularSectionName",            "Goods");
		StructureOfAdditionalParameters.Insert("CancellationReason",                CancellationReason);
		StructureOfAdditionalParameters.Insert("CheckBalance",             False);
		StructureOfAdditionalParameters.Insert("CancelUnprocessedLines", CancelUnprocessedLines);
		StructureOfAdditionalParameters.Insert("CorrectMeasuringGoods",  CorrectMeasuringGoods);
		StructureOfAdditionalParameters.Insert("AdjustTheMeasuredGoodsUponAcceptance", AdjustTheMeasuredGoodsUponAcceptance);
		StructureOfAdditionalParameters.Insert("CorrectPrices",          CorrectPrices);
		StructureOfAdditionalParameters.Insert("CloseOrders",              CloseOrders);
		If PriceVariances.Count() > 0 Then 
			StructureOfAdditionalParameters.Insert("PriceVariances", PriceVariances);
		EndIf;
		
		// If you opened the assistant from the order
		If Orders.Count() = 1 And DocumentInitiator = Orders[0].Value Then
			NotifyChoice(StructureOfAdditionalParameters);
			Return;
		EndIf;
		
		DoneServer(CloseOrders, Orders, StructureOfAdditionalParameters);
		
		Notify("ClosingOrders", DocumentInitiator);
		
		If UnfulfilledOrders.Count() > 0 Then
			
			Items.ClosingOrdersDecorationFailure.Title = GenerateTextProcessed();
			
			Items.Pages.CurrentPage = Items.PageOrdersClosure;
			Items.Navigation.CurrentPage = Items.NavigationAllOrdersAreClosed;
			
		Else
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Help(Command)
	
	OpenFormHelp();
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region ProceduresAndFunctionsForSettingVisibilityAndAvailability

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPurchaseOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceVariances.PurchaseOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPictureIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesReceiptPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderReceiptAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesAmountImageIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceVariances.OrderPrice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("PriceVariances.ReceiptPrice");

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPictureIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderReceiptAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesReceiptPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesAmountImageIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceVariances.OrderPrice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("PriceVariances.ReceiptPrice");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPictureIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesReceiptPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderReceiptAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesAmountImageIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceVariances.OrderAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("PriceVariances.OrderReceiptAmount");

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPictureIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesReceiptPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderReceiptAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesOrderAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesAmountImageIndex.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceVariancesPercentageOfDeviationFromTheOrderAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PriceVariances.OrderAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("PriceVariances.OrderReceiptAmount");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsForCancellationReceivingUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("GoodsForCancellation.ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

&AtServer
Procedure SetVisibilityOfElementsWhenCreating()
	
	FilterParameters = New Structure("ThisIsShipment", True);
	ShipmentLines = MeasuringGoodsForAdjustment.FindRows(FilterParameters);
	
	FilterParameters = New Structure("ThisIsShipment", False);
	AcceptanceLines = MeasuringGoodsForAdjustment.FindRows(FilterParameters);
	
	ThereAreMeasuredGoodsToAdjust          = ShipmentLines.Count() > 0;
	ThereAreMeasuredGoodsForAdjustmentOnAcceptance = AcceptanceLines.Count() > 0;
	
	Items.CorrectMeasuringGoods.Visible          = ThereAreMeasuredGoodsToAdjust;
	Items.AdjustTheMeasuredGoodsUponAcceptance.Visible = ThereAreMeasuredGoodsForAdjustmentOnAcceptance;
	
	ThereAreGoodsForCancellation = GoodsForCancellation.Count() > 0;
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
																	"TheGroupBeganToCancelTheUndelivered",
																	"Visible",
																	ThereAreGoodsForCancellation);
	
	ThereArePriceDifferences = PriceVariances.Count() > 0;
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
																	"GroupBeginningOfPriceDifferences",
																	"Visible",
																	ThereArePriceDifferences);
	
	If OrderType_5 = "InventoryConsumptionOrder" Then
		Items.CloseOrders.Visible = Not OrdersAreClosed And Not TheClosedStatusIsSet;
	Else
		Items.CloseOrders.Visible = Not OrdersAreClosed And TheClosedStatusIsUsed And Not TheClosedStatusIsSet;
	EndIf;
	
	Items.MeasuringGoodsForAdjustmentShipmentOrderDocument.Visible = Orders.Count() > 1;
	Items.MeasuringGoodsForAdjustmentReceivingOrderDocument.Visible = Orders.Count() > 1;
	Items.ItemsToCancelShipmentOrder.Visible = Orders.Count() > 1;
	Items.TheGoodsToCancelTheAcceptanceOrder.Visible = Orders.Count() > 1;
	Items.TwoWayDivergenceProductsOrderDocument.Visible = Orders.Count() > 1;
	Items.PriceVariancesPurchaseOrder.Visible = Orders.Count() > 1;
	
	Items.CloseOrders.ToolTipRepresentation = ?(DocumentInitiator = Orders[0].Value, ToolTipRepresentation.None, ToolTipRepresentation.ShowBottom);
	
EndProcedure

&AtClient
Procedure SetVisibilityOfCancellationReason()
	
	If CancelUnprocessedLines And UseOrderCancellationReasons Then
		Items.GroupReasonForCancellation.CurrentPage = Items.CancellationReasonsAreUsed;
	Else
		Items.GroupReasonForCancellation.CurrentPage = Items.CancellationReasonsAreNotUsed
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOrderClosingAvailability()
	
	If Not OrdersAreClosed 
		And (CorrectMeasuringGoods
			Or AdjustTheMeasuredGoodsUponAcceptance 
			Or MeasuringGoodsForAdjustment.Count() = 0)
		And (CancelUnprocessedLines 
			Or GoodsForCancellation.Count() =0)
		And (CorrectPrices 
			Or PriceVariances.Count() =0) 
		And Not TheClosedStatusIsSet Then
		
		Items.CloseOrders.Enabled = True;
		
	Else
		
		Items.CloseOrders.Enabled = False;
		
	EndIf;
	
	If CloseOrders And Not Items.CloseOrders.Enabled Then
		CloseOrders = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInitialSettings()
	
	If OrderType_5 = "SalesOrder"
		Or OrderType_5 = "RequestForReturnOfGoodsFromCustomer"
		Or OrderType_5 = "MaterialProviderOrder2_5" Then
		UseOrderCancellationReasons = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
		Items.CancellationReason.TypeRestriction = New TypeDescription("CatalogRef.ReasonsForSaleOrderCancellation");
	ElsIf OrderType_5 = "PurchaseOrder"
		Or OrderType_5 = "SubcontractOrder2_5" Then
		UseOrderCancellationReasons = GetFunctionalOption("UseReasonsForPurchaseOrderCancellations");
		Items.CancellationReason.TypeRestriction = New TypeDescription("CatalogRef.ReasonsForPurchaseOrderCancellation");
	Else
		UseOrderCancellationReasons = False;
	EndIf;
	
	FilterParameters = New Structure("ThisIsShipment", True);
	ShipmentLines = MeasuringGoodsForAdjustment.FindRows(FilterParameters);
	
	FilterParameters = New Structure("ThisIsShipment", False);
	AcceptanceLines = MeasuringGoodsForAdjustment.FindRows(FilterParameters);
	
	ThereAreMeasuredGoodsToAdjust          = ShipmentLines.Count() > 0;
	ThereAreMeasuredGoodsForAdjustmentOnAcceptance = AcceptanceLines.Count() > 0;
	
	CorrectMeasuringGoods          = ThereAreMeasuredGoodsToAdjust;
	AdjustTheMeasuredGoodsUponAcceptance = ThereAreMeasuredGoodsForAdjustmentOnAcceptance;
	CancelUnprocessedLines         = CancelUnprocessedLines And GoodsForCancellation.Count() > 0;
	CorrectPrices                  = CorrectPrices And PriceVariances.Count() > 0;
	
	If (CorrectMeasuringGoods
			Or AdjustTheMeasuredGoodsUponAcceptance
			Or MeasuringGoodsForAdjustment.Count() = 0)
		And (CancelUnprocessedLines 
			Or GoodsForCancellation.Count() = 0)
		And (CorrectPrices 
			Or PriceVariances.Count() = 0)
		And Not OrdersAreClosed And CloseOrders And TheClosedStatusIsUsed 
		And Not TheClosedStatusIsSet Then
		CloseOrders = True;
	Else
		CloseOrders = False;
	EndIf;
	
	If OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		TheClosedStatus = "Executed";
	ElsIf OrderType_5 = "ProductionStage2_2" Then
		TheClosedStatus = "Completed";
	Else
		TheClosedStatus = "Closed";
	EndIf;
	
	RowFilter = New Structure;
	RowFilter.Insert("ThisIsShipment", True);
	Items.MeasuringGoodsForAdjustmentShipment.RowFilter = New FixedStructure(RowFilter);
	Items.GoodsForCancellationShipment.RowFilter              = New FixedStructure(RowFilter);
	
	RowFilter = New Structure;
	RowFilter.Insert("ThisIsShipment", False);
	Items.MeasuringGoodsForAdjustmentReceiving.RowFilter = New FixedStructure(RowFilter);
	Items.GoodsForCancellationReceiving.RowFilter              = New FixedStructure(RowFilter);
	
EndProcedure

&AtServer
Procedure FormInscriptionCalculations()
	
	If OrderType_5 = "SalesOrder" Or OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		DoNotCloseSalesOrdersWithoutCompletePayment   = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment");
		DoNotCloseSalesOrdersWithoutCompleteShipment = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment");
		
		If Not TheClosedStatusIsUsed Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		ElsIf DoNotCloseSalesOrdersWithoutCompletePayment And DoNotCloseSalesOrdersWithoutCompleteShipment Then
			Items.WarningsGroup.CurrentPage = Items.TheGroupIsClosingTheInvoiceWithoutPayment;
		ElsIf DoNotCloseSalesOrdersWithoutCompletePayment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutPayment;
		ElsIf DoNotCloseSalesOrdersWithoutCompleteShipment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutShipment;
		Else
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		EndIf;
		
		If Orders.Count() = 1 And OrderType_5 = "SalesOrder" Then
			
			StructureOfStateOfCalculations = New Structure;
			StructureOfStateOfCalculations.Insert("State", Enums.SalesOrderStates.EmptyRef());
			StructureOfStateOfCalculations.Insert("StateOverdue", False);
			StructureOfStateOfCalculations.Insert("PayAmount", 0);
			StructureOfStateOfCalculations.Insert("AmountByShipment", 0);
			StructureOfStateOfCalculations.Insert("PayPercentage", 0);
			StructureOfStateOfCalculations.Insert("OrderShipmentPercentage", 0);
			StructureOfStateOfCalculations.Insert("AmountOfDebt", 0);
			StructureOfStateOfCalculations.Insert("DebtPercentage", 0);
			StructureOfStateOfCalculations.Insert("AmountToPay", 0);
			StructureOfStateOfCalculations.Insert("ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice", False);
			
			OrderDetails = Common.ObjectAttributesValues(Orders[0].Value, "Contract, Currency, ARAPObjectSettings");
			
			Documents.SalesOrder.CalculateStatus(
				Orders[0].Value,
				OrderDetails.Contract,
				StructureOfStateOfCalculations);
			
			Items.GroupThereAreDifferencesInTheOrderInvoice.Visible = StructureOfStateOfCalculations.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice;

			If OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
				Or OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice Then
			
				TextPayment = NStr("vi = 'Được thanh toán theo đơn đặt hàng:%PayAmount%  %Currency%  %PayPercentage%%';
									|ru = 'Оплачено по заказу: %PayAmount%  %Currency%  %PayPercentage%%';
									|en = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%'; fa = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%';
									|it = 'Pagato dell''ordine:  %PayAmount%  %Currency%  %PayPercentage%%';
									|pl = 'Opłacono według zamówienia: %PayAmount% %Currency% %PayPercentage%%';
									|tr = 'Siparişe göre ödendi: %PayAmount%  %Currency%  %PayPercentage%%'");
				TextPayment = StrReplace(TextPayment, "%PayAmount%",   Format(StructureOfStateOfCalculations.PayAmount, "NFD=2; NZ="));
				TextPayment = StrReplace(TextPayment, "%Currency%",        OrderDetails.Currency);
				TextPayment = StrReplace(TextPayment, "%PayPercentage%", StructureOfStateOfCalculations.PayPercentage);
				
				TextShipment = NStr("vi = 'Đã giao hàng: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|ru = 'Отгружено: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|en = 'Shipped: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%'; fa = 'Shipped: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|it = 'Spedito: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|pl = 'Wysłano: %AmountByShipment% %Currency% %OrderShipmentPercentage%%';
									|tr = 'Sevk edildi: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%'");
				TextShipment = StrReplace(TextShipment, "%AmountByShipment%",   Format(StructureOfStateOfCalculations.AmountByShipment, "NFD=2; NZ="));
				TextShipment = StrReplace(TextShipment, "%Currency%",          OrderDetails.Currency);
				TextShipment = StrReplace(TextShipment, "%OrderShipmentPercentage%", StructureOfStateOfCalculations.OrderShipmentPercentage);
				
				Calculations = TextPayment + ", "+TextShipment;
			Else
				Calculations = GenerateTextCalculationProcedure(OrderDetails.ARAPObjectSettings);
			EndIf;
			
		ElsIf Orders.Count() = 1 And OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
			
			Items.DecorationThereAreDifferencesInTheOrderInvoice.Title = NStr("vi = 'Giấy đề nghị chưa được giao hoặc đã giao không đầy đủ';
																				|ru = 'Заявка не отгружена или отгружена не полностью';
																				|en = 'Request is not shipped or is not shipped in full'; fa = 'Request is not shipped or is not shipped in full';
																				|it = 'Richiesta non inviata o inviata parzialmente';
																				|pl = 'Wniosek nie został wysłany lub wysłany nie w całości';
																				|tr = 'Başvuru sevk edilmedi veya tam olarak sevk edilmedi'");
			
			StructureOfStateOfCalculations = New Structure;
			StructureOfStateOfCalculations.Insert("ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice", False);
			
			AttributesOfApplication = Common.ObjectAttributesValues(Orders[0].Value,"Contract, Currency, ARAPObjectSettings");
			
			Documents.RequestForReturnOfGoodsFromCustomer.CalculateStatus(
				Orders[0].Value,
				AttributesOfApplication.Contract,
				StructureOfStateOfCalculations);
				
			Items.GroupThereAreDifferencesInTheOrderInvoice.Visible = StructureOfStateOfCalculations.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice;
			
			If AttributesOfApplication.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
			
				Calculations = GenerateTextCalculationProcedure(AttributesOfApplication.ARAPObjectSettings);
			
			Else
			
				StructureOfCalculations = Documents.RequestForReturnOfGoodsFromCustomer.CalculationsForApplication(Orders[0].Value);
				
				If Not StructureOfCalculations.ThereWereCalculations Then
					
					Calculations = NStr("vi = 'Không có tính toán trên đơn';
										|ru = 'Расчеты по заявке отсутствуют';
										|en = 'No settlements for the request'; fa = 'No settlements for the request';
										|it = 'Non ci sono calcoli per la domanda';
										|pl = 'Brak rozliczeń według zleceń';
										|tr = 'Başvuru hesaplamaları eksik'");
					
				Else
					
					ResultOfCalculations = StructureOfCalculations.AccountsPayableOfCompany - StructureOfCalculations.CustomerAccountsReceivable;
					
					If StructureOfCalculations.AccountsPayableOfCompany > StructureOfCalculations.CustomerAccountsReceivable Then
						
						Calculations = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Nợ của chúng tôi theo yêu cầu: %1 %2';
								|ru = 'Наш долг по заявке: %1 %2';
								|en = 'Our request debt: %1 %2'; fa = 'Our request debt: %1 %2';
								|it = 'Nostro debito in base alla richiesta: %1%2';
								|pl = 'Nasze zobowiązanie dla zgłoszenia: %1 %2';
								|tr = 'Başvuru borcumuz: %1 %2'"),
							Format(ResultOfCalculations,"NFD=2"),
							AttributesOfApplication.Currency);
							
					ElsIf StructureOfCalculations.CustomerAccountsReceivable > StructureOfCalculations.AccountsPayableOfCompany Then
							
						Calculations = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Khách hàng nợ theo đơn: %1 %2';
								|ru = 'Долг клиента по заявке: %1 %2';
								|en = 'Total receivables under request: %1 %2'; fa = 'Total receivables under request: %1 %2';
								|it = 'Debito del cliente in base alla richiesta: %1 %2';
								|pl = 'Zobowiązanie klienta dla zgłoszenia: %1 %2';
								|tr = 'İstemcinin başvuru borcu: %1 %2'"),
							Format(ResultOfCalculations*-1,"NFD=2"),
							AttributesOfApplication.Currency);
							
					Else
						Calculations = NStr("vi = 'Đơn xin đóng để khấu trừ';
											|ru = 'Заявка закрыта по расчетам';
											|en = 'Request is closed by settlements'; fa = 'Request is closed by settlements';
											|it = 'La domanda è chiusa secondo i calcoli';
											|pl = 'Zlecenie zamknięte według rozliczeń';
											|tr = 'Başvuru mutabakat üzerine kapalı'");
					EndIf;
					
				EndIf;
			
			EndIf;

		EndIf;
	ElsIf OrderType_5 = "PurchaseOrder" Then
		
		DoNotClosePurchaseOrdersWithoutCompletePayment   =
			GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment");
		DoNotCloseOrdersToSuppliersWithoutFullShipment =
			GetFunctionalOption("DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived");
		
		If Not TheClosedStatusIsUsed Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		ElsIf DoNotClosePurchaseOrdersWithoutCompletePayment And DoNotCloseOrdersToSuppliersWithoutFullShipment Then
			Items.WarningsGroup.CurrentPage = Items.TheGroupIsClosingTheInvoiceWithoutPayment;
		ElsIf DoNotClosePurchaseOrdersWithoutCompletePayment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutPayment;
		ElsIf DoNotCloseOrdersToSuppliersWithoutFullShipment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutShipment;
		Else
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		EndIf;
		
		Items.DecorationThereAreDifferencesInTheOrderInvoice.Title = NStr("vi = 'Đơn hàng chưa được tiếp nhận hoặc đã tiếp nhận không toàn bộ';
																			|ru = 'Заказ не принят или принят не полностью';
																			|en = 'Order is not accepted or is not accepted in full'; fa = 'Order is not accepted or is not accepted in full';
																			|it = 'Ordine non ricevuto o ricevuto parzialmente';
																			|pl = 'Zamówienie nie jest przyjęte lub przyjęte nie w całości';
																			|tr = 'Sipariş kabul edilmedi veya tam olarak kabul edilmedi'");
		
		If Orders.Count() = 1 Then
			
			StructureOfStateOfCalculations = New Structure;
			StructureOfStateOfCalculations.Insert("State", Enums.PurchaseOrderStates.EmptyRef());
			StructureOfStateOfCalculations.Insert("StateOverdue", False);
			StructureOfStateOfCalculations.Insert("PayAmount", 0);
			StructureOfStateOfCalculations.Insert("PayPercentage", 0);
			StructureOfStateOfCalculations.Insert("AmountOfDebt", 0);
			StructureOfStateOfCalculations.Insert("DebtPercentage", 0);
			StructureOfStateOfCalculations.Insert("AmountToPay", 0);
			StructureOfStateOfCalculations.Insert("OrderReceiptAmount", 0);
			StructureOfStateOfCalculations.Insert("PercentageOfOrderReceipt",0);
			StructureOfStateOfCalculations.Insert("ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice", False);
			
			OrderDetails = Common.ObjectAttributesValues(Orders[0].Value,"Contract,Currency");
			
			Documents.PurchaseOrder.CalculateStatus(
				Orders[0].Value,
				OrderDetails.Contract,
				StructureOfStateOfCalculations);
			
			Items.GroupThereAreDifferencesInTheOrderInvoice.Visible = StructureOfStateOfCalculations.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice;
			
			TextPayment = NStr("vi = 'Được thanh toán theo đơn đặt hàng:%PayAmount%  %Currency%  %PayPercentage%%';
								|ru = 'Оплачено по заказу: %PayAmount%  %Currency%  %PayPercentage%%';
								|en = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%'; fa = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%';
								|it = 'Pagato dell''ordine:  %PayAmount%  %Currency%  %PayPercentage%%';
								|pl = 'Opłacono według zamówienia: %PayAmount% %Currency% %PayPercentage%%';
								|tr = 'Siparişe göre ödendi: %PayAmount%  %Currency%  %PayPercentage%%'");
			TextPayment = StrReplace(TextPayment, "%PayAmount%",   Format(StructureOfStateOfCalculations.PayAmount, "NFD=2; NZ="));
			TextPayment = StrReplace(TextPayment, "%Currency%",        OrderDetails.Currency);
			TextPayment = StrReplace(TextPayment, "%PayPercentage%", StructureOfStateOfCalculations.PayPercentage);
			
			TextShipment = NStr("vi = 'Đã nhận: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
								|ru = 'Поступило: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
								|en = 'Received: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%'; fa = 'Received: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
								|it = 'Ricevuto: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
								|pl = 'Otrzymano: %OrderReceiptAmount% %Currency% %PercentageOfOrderReceipt%%';
								|tr = 'Geldi: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%'");
			TextShipment = StrReplace(TextShipment, "%OrderReceiptAmount%",   Format(StructureOfStateOfCalculations.OrderReceiptAmount, "NFD=2; NZ="));
			TextShipment = StrReplace(TextShipment, "%Currency%",          OrderDetails.Currency);
			TextShipment = StrReplace(TextShipment, "%PercentageOfOrderReceipt%", StructureOfStateOfCalculations.PercentageOfOrderReceipt);
			
			Calculations = TextPayment + ", "+TextShipment;
		EndIf;
		
	ElsIf OrderType_5 = "InventoryConsumptionOrder" Or OrderType_5 = "ByAssemblyDisassemblyOrder" Then
		If TheClosedStatusIsUsed Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutShipment;
		Else
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		EndIf;
	ElsIf OrderType_5 = "ProductionStage2_2" Or OrderType_5 = "OrderOfMaterialsForProduction" Then
		Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
	ElsIf OrderType_5 = "MaterialProviderOrder2_5" Then
		
		DoNotCloseMaterialProviderOrdersWithoutCompletePayment    =
			GetFunctionalOption("DoNotCloseMaterialProviderOrdersWithoutCompletePayment2_5");
			
		DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment =
			GetFunctionalOption("DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment2_5");
		
		If Not TheClosedStatusIsUsed Then
			 Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		ElsIf DoNotCloseMaterialProviderOrdersWithoutCompletePayment And DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment Then
			Items.WarningsGroup.CurrentPage = Items.TheGroupIsClosingTheInvoiceWithoutPayment;
		ElsIf DoNotCloseMaterialProviderOrdersWithoutCompletePayment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutPayment;
		ElsIf DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutShipment;
		Else
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		EndIf;
		
		If Orders.Count() = 1 Then
			
			StructureOfStateOfCalculations = New Structure;
			StructureOfStateOfCalculations.Insert("State", Enums.SalesOrderStates.EmptyRef());
			StructureOfStateOfCalculations.Insert("StateOverdue", False);
			StructureOfStateOfCalculations.Insert("PayAmount", 0);
			StructureOfStateOfCalculations.Insert("AmountByShipment", 0);
			StructureOfStateOfCalculations.Insert("PayPercentage", 0);
			StructureOfStateOfCalculations.Insert("OrderShipmentPercentage", 0);
			StructureOfStateOfCalculations.Insert("AmountOfDebt", 0);
			StructureOfStateOfCalculations.Insert("DebtPercentage", 0);
			StructureOfStateOfCalculations.Insert("AmountToPay", 0);
			
			OrderDetails = Common.ObjectAttributesValues(Orders[0].Value, "Contract, Currency, ARAPObjectSettings");
			
			If OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
				Or OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice Then
				
				Documents.MaterialProviderOrder2_5.CalculateStatus(
						Orders[0].Value, OrderDetails.Contract, StructureOfStateOfCalculations);
					
				TextPayment = NStr("vi = 'Được thanh toán theo đơn đặt hàng:%PayAmount%  %Currency%  %PayPercentage%%';
									|ru = 'Оплачено по заказу: %PayAmount%  %Currency%  %PayPercentage%%';
									|en = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%'; fa = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%';
									|it = 'Pagato dell''ordine:  %PayAmount%  %Currency%  %PayPercentage%%';
									|pl = 'Opłacono według zamówienia: %PayAmount% %Currency% %PayPercentage%%';
									|tr = 'Siparişe göre ödendi: %PayAmount%  %Currency%  %PayPercentage%%'");
				TextPayment = StrReplace(
					TextPayment, "%PayAmount%", Format(StructureOfStateOfCalculations.PayAmount, "NFD=2; NZ="));
				TextPayment = StrReplace(TextPayment, "%Currency%", OrderDetails.Currency);
				TextPayment = StrReplace(TextPayment, "%PayPercentage%", StructureOfStateOfCalculations.PayPercentage);
				
				TextShipment = NStr("vi = 'Đã giao hàng: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|ru = 'Отгружено: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|en = 'Shipped: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%'; fa = 'Shipped: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|it = 'Spedito: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%';
									|pl = 'Wysłano: %AmountByShipment% %Currency% %OrderShipmentPercentage%%';
									|tr = 'Sevk edildi: %AmountByShipment% %Currency%  %OrderShipmentPercentage%%'");
				TextShipment = StrReplace(
					TextShipment, "%AmountByShipment%", Format(StructureOfStateOfCalculations.AmountByShipment, "NFD=2; NZ="));
				TextShipment = StrReplace(TextShipment, "%Currency%", OrderDetails.Currency);
				TextShipment = StrReplace(TextShipment, "%OrderShipmentPercentage%", StructureOfStateOfCalculations.OrderShipmentPercentage);
				
				Calculations = TextPayment + ", "+TextShipment;
				
			Else
				Calculations = GenerateTextCalculationProcedure(OrderDetails.ARAPObjectSettings);
			EndIf;
			
		EndIf;
	ElsIf OrderType_5 = "SubcontractOrder2_5"
		Or False Then
		
			DoNotCloseTollingOrdersWithoutCompletePayment    = GetFunctionalOption("DoNotCloseTollingOrdersWithoutCompletePayment2_5");
			DoNotCloseTollingOrdersWithoutCompleteFulfillment = GetFunctionalOption("DoNotCloseTollingOrdersWithoutCompleteFulfillment2_5");
		
		If Not TheClosedStatusIsUsed Then
			 Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		ElsIf DoNotCloseTollingOrdersWithoutCompletePayment And DoNotCloseTollingOrdersWithoutCompleteFulfillment Then
			Items.WarningsGroup.CurrentPage = Items.TheGroupIsClosingTheInvoiceWithoutPayment;
		ElsIf DoNotCloseTollingOrdersWithoutCompletePayment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutPayment;
		ElsIf DoNotCloseTollingOrdersWithoutCompleteFulfillment Then
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutShipment;
		Else
			Items.WarningsGroup.CurrentPage = Items.GroupClosingWithoutRestrictions;
		EndIf;
		
		If Orders.Count() = 1 Then
			StructureOfStateOfCalculations = New Structure;
			StructureOfStateOfCalculations.Insert("State",               Enums.StatesOfTollingOrders.EmptyRef());
			StructureOfStateOfCalculations.Insert("StateOverdue",     False);
			StructureOfStateOfCalculations.Insert("PayAmount",             0);
			StructureOfStateOfCalculations.Insert("PayPercentage",           0);
			StructureOfStateOfCalculations.Insert("OrderReceiptAmount",        0);
			StructureOfStateOfCalculations.Insert("PercentageOfOrderReceipt",      0);
			StructureOfStateOfCalculations.Insert("LatePaymentAmount", 0);
			StructureOfStateOfCalculations.Insert("AmountOfDebt",              0);
			StructureOfStateOfCalculations.Insert("DebtPercentage",            0);
			StructureOfStateOfCalculations.Insert("AmountToPay",            0);
			
			OrderDetails = Common.ObjectAttributesValues(Orders[0].Value, "Organization, DocumentAmount, Contract, Currency, ProcessingServices, ARAPObjectSettings");
			
			If OrderDetails.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder Then
				StructureOfCalculations = ARAPAccountingServer.StateOfSettlementsOfSettlementObject(
					Common.ObjectAttributeValue(Orders[0].Value, "ARAPObject"),
					OrderDetails.DocumentAmount,
					PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"),
					OrderDetails.Organization);
				
				StructureOfStateOfCalculations.PayAmount        = StructureOfCalculations.AmountOfPayments;
				StructureOfStateOfCalculations.PayPercentage      = StructureOfCalculations.PercentageOfPayments;
				StructureOfStateOfCalculations.OrderReceiptAmount   = StructureOfCalculations.AmountOfDeliveries;
				StructureOfStateOfCalculations.PercentageOfOrderReceipt = StructureOfCalculations.PercentageOfDeliveries;
				
				If OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
					Or OrderDetails.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice Then
				
					TextPayment = NStr("vi = 'Được thanh toán theo đơn đặt hàng:%PayAmount%  %Currency%  %PayPercentage%%';
										|ru = 'Оплачено по заказу: %PayAmount%  %Currency%  %PayPercentage%%';
										|en = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%'; fa = 'Amount paid: %PayAmount%  %Currency%  %PayPercentage%%';
										|it = 'Pagato dell''ordine:  %PayAmount%  %Currency%  %PayPercentage%%';
										|pl = 'Opłacono według zamówienia: %PayAmount% %Currency% %PayPercentage%%';
										|tr = 'Siparişe göre ödendi: %PayAmount%  %Currency%  %PayPercentage%%'");
					TextPayment = StrReplace(TextPayment, "%PayAmount%",   Format(StructureOfStateOfCalculations.PayAmount, "NFD=2; NZ="));
					TextPayment = StrReplace(TextPayment, "%Currency%",        OrderDetails.Currency);
					TextPayment = StrReplace(TextPayment, "%PayPercentage%", StructureOfStateOfCalculations.PayPercentage);
				
					TextShipment = NStr("vi = 'Đã nhận: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
										|ru = 'Поступило: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
										|en = 'Received: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%'; fa = 'Received: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
										|it = 'Ricevuto: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%';
										|pl = 'Otrzymano: %OrderReceiptAmount% %Currency% %PercentageOfOrderReceipt%%';
										|tr = 'Geldi: %OrderReceiptAmount% %Currency%  %PercentageOfOrderReceipt%%'");
					TextShipment = StrReplace(TextShipment, "%OrderReceiptAmount%",   Format(StructureOfStateOfCalculations.OrderReceiptAmount, "NFD=2; NZ="));
					TextShipment = StrReplace(TextShipment, "%Currency%",          OrderDetails.Currency);
					TextShipment = StrReplace(TextShipment, "%PercentageOfOrderReceipt%", StructureOfStateOfCalculations.PercentageOfOrderReceipt);
					
					Calculations = TextPayment + ", "+TextShipment;
				Else
					Calculations = GenerateTextCalculationProcedure(OrderDetails.ARAPObjectSettings);
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillPagesForDisplay(Form)
	
	If Form.OrdersAreClosed Then
		Form.Items.Pages.CurrentPage = Form.Items.PageAllOrdersAreClosed;
		Return;
	EndIf;
	
	Form.PagesToDisplay.Clear();
	
	Form.PagesToDisplay.Add("StartPage_");
	
	ThereIsMeasuredShipment  =
		Form.MeasuringGoodsForAdjustment.FindRows(New Structure("ThisIsShipment", True)).Count() > 0;
		
	ThereAreDimensionalAcceptance   =
		Form.MeasuringGoodsForAdjustment.FindRows(New Structure("ThisIsShipment", False)).Count() > 0;
		
	ThereIsShipmentReadyToCancel =
		Form.GoodsForCancellation.FindRows(New Structure("ThisIsShipment", True)).Count() > 0;
		
	ReadyToCancelAcceptance  =
		Form.GoodsForCancellation.FindRows(New Structure("ThisIsShipment", False)).Count() > 0;
		
	ThereIsTwoWayDivergence =
		Form.TwoWayDivergenceProducts.Count() > 0;
	
	If Form.CorrectMeasuringGoods Then
		If ThereIsMeasuredShipment Then
			Form.PagesToDisplay.Add("PageMeasuringGoodsAdjustmentShipment");
		EndIf;
	EndIf;
	If Form.AdjustTheMeasuredGoodsUponAcceptance Then
		If ThereAreDimensionalAcceptance Then
			Form.PagesToDisplay.Add("PageMeasuringGoodsAdjustmentReceiving");
		EndIf;
	EndIf;
	If Form.CancelUnprocessedLines Then
		If ThereIsShipmentReadyToCancel Then
			Form.PagesToDisplay.Add("PageGoodsForCancellationShipment");
		EndIf;
		If ReadyToCancelAcceptance Then
			Form.PagesToDisplay.Add("PageGoodsForCancellationReceiving");
		EndIf;
	EndIf;
	If ThereIsTwoWayDivergence Then
		Form.PagesToDisplay.Add("ProductsPageTwoWayDivergences");
	EndIf;
	
	If Form.CorrectPrices Then
		Form.PagesToDisplay.Add("DifferencesInPricesPage");
	EndIf;
	
	SetCurPageOfNavigationBar(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetCurPageOfNavigationBar(Form)
	
	If Form.PagesToDisplay.Count() < 2 Then
		If Not Form.CloseOrders Then
			Form.Items.Navigation.CurrentPage = Form.Items.NavigationAllOrdersAreClosed;
			Form.Items.AllOrdersAreClosedReady.DefaultButton = True;
		Else
			Form.Items.Navigation.CurrentPage = Form.Items.NavigationEndingWithoutBeginning;
			Form.Items.TheEndingWithoutTheBeginningIsReady.DefaultButton = True;
		EndIf;
		Return;
	EndIf;
	
	FirstPage = Form.Items.Pages.CurrentPage = Form.Items.StartPage_
					And Not Form.OrdersAreClosed;
	
	NotLastPage = Not Form.Items.Pages.CurrentPage.Name
							= Form.PagesToDisplay.Get(Form.PagesToDisplay.Count()-1).Value
						  And Not Form.OrdersAreClosed;
	
	If FirstPage Then
		Form.Items.Navigation.CurrentPage = Form.Items.StartNavigation;
		Form.Items.StartIsReady.DefaultButton = True;
	ElsIf NotLastPage Then
		Form.Items.Navigation.CurrentPage = Form.Items.NavigationContinued;
		Form.Items.ContinuationIsReady.DefaultButton = True;
	ElsIf Form.OrdersAreClosed Then
		Form.Items.Navigation.CurrentPage = Form.Items.NavigationAllOrdersAreClosed;
		Form.Items.AllOrdersAreClosedReady.DefaultButton = True;
	Else
		Form.Items.Navigation.CurrentPage = Form.Items.EndNavigation;
		Form.Items.TheEndIsReady.DefaultButton = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInHintsAndDecorations()
	
	OrderTypeSettings = CaseSettingsByOrderType(OrderType_5, Orders.Count());
	
	RPText = OrderTypeSettings.RPText;
	IPText = OrderTypeSettings.IPText;
	DPText = OrderTypeSettings.DPText;
	TheClosedStatusPresentation = OrderTypeSettings.TheClosedStatusPresentation;
	
	TextShipmentNotProcessed = "";
	TextNotAccepted  = "";
	
	If OrderType_5 = "SalesOrder" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa lập chứng từ bán hàng và không thực hiện giao hàng';
										|ru = 'не оформлена реализация и не осуществлялась отгрузка';
										|en = 'sale is not registered and shipment was not performed'; fa = 'sale is not registered and shipment was not performed';
										|it = 'non è stata formalizzata la vendita e non è stata effettuata la spedizione';
										|pl = 'nie sporządzona realizacja i nie odbywała się wysyłka';
										|tr = 'satış ve sevkiyat düzenlenmedi'");
	ElsIf OrderType_5 = "PurchaseOrder" Then
		TextNotAccepted = NStr("vi = 'không nhận và không chấp nhận';
								|ru = 'не оформлено поступление и не осуществлялась приемка';
								|en = 'receipt is not registered and receiving was not performed'; fa = 'receipt is not registered and receiving was not performed';
								|it = 'non è stato formalizzato l''arrivo e non è stata eseguita l''accettazione';
								|pl = 'nie sporządzono wpłatę i nie odbywało się przyjęcie';
								|tr = 'tahsilat ve kabul işlemleri düzenlenmedi'");
	ElsIf OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		TextShipmentNotProcessed = NStr("vi = 'thay thế không được hoàn thành và không có lô hàng được thực hiện';
										|ru = 'не оформлена реализация замены и не осуществлялась отгрузка';
										|en = 'replacement sale is not registered and shipment was not performed'; fa = 'replacement sale is not registered and shipment was not performed';
										|it = 'non è stata formalizzata la vendita della sostituzione e non è stata effettuata la spedizione';
										|pl = 'nie sporządzono realizacji wymiany i nie odbywała się wysyłka';
										|tr = 'ikame satışı ve sevkiyat düzenlenmedi'");
		TextNotAccepted = NStr("vi = 'không lập đơn trả lại';
								|ru = 'не оформлен возврат';
								|en = 'return is not registered'; fa = 'return is not registered';
								|it = 'non è formalizzata la restituzione';
								|pl = 'nie sporządzono zwrotu';
								|tr = 'iade düzenlenmedi'");
	ElsIf OrderType_5 = "InventoryConsumptionOrder" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa tạo ghi giảm và chưa giao hàng';
										|ru = 'не оформлено списание и не осуществлялась отгрузка';
										|en = 'write-off is not registered and shipment was not performed'; fa = 'write-off is not registered and shipment was not performed';
										|it = 'non è stata formalizzata la cancellazione e non è stata effettuata la spedizione';
										|pl = 'nie sporządzono rozchodu i nie odbywała się wysyłka';
										|tr = 'gider yazma düzenlenemedi ve sevkiyat gerçekleştirilemedi'");
	ElsIf OrderType_5 = "ByAssemblyDisassemblyOrder" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa tạo đóng bộ và chưa giao hàng';
										|ru = 'не оформлена сборка и не осуществлялась отгрузка';
										|en = 'picking is not registered and shipment was not performed'; fa = 'picking is not registered and shipment was not performed';
										|it = 'non è stato formalizzato l''assemblaggio e non è stata effettuata la spedizione';
										|pl = 'nie sporządzono montażu i nie odbywała się wysyłka';
										|tr = 'montaj düzenlenemedi ve sevkiyat gerçekleştirilemedi'");
		TextNotAccepted = NStr("vi = 'chưa tiếp nhận';
								|ru = 'не осуществлялась приемка';
								|en = 'not received'; fa = 'not received';
								|it = 'non è stata eseguita l''accettazione';
								|pl = 'nie odbywało się przyjęcie';
								|tr = 'kabul edilmedi'");
	ElsIf OrderType_5 = "TransferOrder" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa tạo điều chuyển và chưa giao hàng';
										|ru = 'не оформлено перемещение и не осуществлялась отгрузка';
										|en = 'transfer is not registered and shipment was not performed'; fa = 'transfer is not registered and shipment was not performed';
										|it = 'non è stato formalizzato il trasferimento e non è stata effettuata la spedizione';
										|pl = 'nie sporządzono przemieszczenie i nie odbywała się wysyłka';
										|tr = 'transfer düzenlenemedi ve sevkiyat gerçekleştirilemedi'");
		TextNotAccepted = NStr("vi = 'chưa tiếp nhận';
								|ru = 'не осуществлялась приемка';
								|en = 'not received'; fa = 'not received';
								|it = 'non è stata eseguita l''accettazione';
								|pl = 'nie odbywało się przyjęcie';
								|tr = 'kabul edilmedi'");
	ElsIf OrderType_5 = "OrderOfMaterialsForProduction" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa tạo chuyển giao và chưa thực hiện giao hàng';
										|ru = 'не оформлена передача и не осуществлялась отгрузка';
										|en = 'transfer is not registered and shipment was not carried out'; fa = 'transfer is not registered and shipment was not carried out';
										|it = 'non è stato formalizzato il trasferimento e non è stata eseguita la spedizione';
										|pl = 'nie sporządzono przekazywanie i nie odbywała się wysyłka';
										|tr = 'hiçbir transfer ve sevkiyat düzenlenmedi'");
	ElsIf OrderType_5 = "SubcontractOrder2_5" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa tạo chuyển giao và chưa thực hiện giao hàng';
										|ru = 'не оформлена передача и не осуществлялась отгрузка';
										|en = 'transfer is not registered and shipment was not carried out'; fa = 'transfer is not registered and shipment was not carried out';
										|it = 'non è stato formalizzato il trasferimento e non è stata eseguita la spedizione';
										|pl = 'nie sporządzono przekazywanie i nie odbywała się wysyłka';
										|tr = 'hiçbir transfer ve sevkiyat düzenlenmedi'");
		TextNotAccepted = NStr("vi = 'không nhận và không chấp nhận';
								|ru = 'не оформлено поступление и не осуществлялась приемка';
								|en = 'receipt is not registered and receiving was not performed'; fa = 'receipt is not registered and receiving was not performed';
								|it = 'non è stato formalizzato l''arrivo e non è stata eseguita l''accettazione';
								|pl = 'nie sporządzono wpłatę i nie odbywało się przyjęcie';
								|tr = 'tahsilat ve kabul işlemleri düzenlenmedi'");
	ElsIf OrderType_5 = "MaterialProviderOrder2_5" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa tạo chuyển giao và chưa thực hiện giao hàng';
										|ru = 'не оформлена передача и не осуществлялась отгрузка';
										|en = 'transfer is not registered and shipment was not carried out'; fa = 'transfer is not registered and shipment was not carried out';
										|it = 'non è stato formalizzato il trasferimento e non è stata eseguita la spedizione';
										|pl = 'nie sporządzono przekazywanie i nie odbywała się wysyłka';
										|tr = 'hiçbir transfer ve sevkiyat düzenlenmedi'");
		TextNotAccepted = NStr("vi = 'không nhận và không chấp nhận';
								|ru = 'не оформлено поступление и не осуществлялась приемка';
								|en = 'receipt is not registered and receiving was not performed'; fa = 'receipt is not registered and receiving was not performed';
								|it = 'non è stato formalizzato l''arrivo e non è stata eseguita l''accettazione';
								|pl = 'nie sporządzono wpłatę i nie odbywało się przyjęcie';
								|tr = 'tahsilat ve kabul işlemleri düzenlenmedi'");
	ElsIf OrderType_5 = "ProductionStage2_2" Then
		TextShipmentNotProcessed = NStr("vi = 'chưa tạo chuyển giao và chưa thực hiện giao hàng';
										|ru = 'не оформлена передача и не осуществлялась отгрузка';
										|en = 'transfer is not registered and shipment was not carried out'; fa = 'transfer is not registered and shipment was not carried out';
										|it = 'non è stato formalizzato il trasferimento e non è stata eseguita la spedizione';
										|pl = 'nie sporządzono przekazywanie i nie odbywała się wysyłka';
										|tr = 'hiçbir transfer ve sevkiyat düzenlenmedi'");
		TextNotAccepted = NStr("vi = 'chưa tạo trả lại và chưa tiếp nhận';
								|ru = 'не оформлен возврат и не осуществлялась приемка';
								|en = 'return is not registered and receiving is not performed'; fa = 'return is not registered and receiving is not performed';
								|it = 'non è stata formalizzata la restituzione e non è stata eseguita l''accettazione';
								|pl = 'nie sporządzono zwrot i nie odbywało się przyjęcie';
								|tr = 'herhangi iade veya kabul işlemi düzenlenmedi'");
	EndIf;
	
	OrdersQuantity = Orders.Count();
	If OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		Title = NStr("vi = 'Trợ giúp đóng đơn (yêu cầu)';
					|ru = 'Помощник закрытия заявок';
					|en = 'Requests closing wizard'; fa = 'Requests closing wizard';
					|it = 'Помощник закрытия заявок';
					|pl = 'Requests closing wizard';
					|tr = 'Talep kapatma sihirbazı'");
		If OrdersQuantity = 1 Then
			Title = NStr("vi = 'Trợ giúp đóng đơn (yêu cầu)';
						|ru = 'Помощник закрытия заявки';
						|en = 'Request closing wizard'; fa = 'Request closing wizard';
						|it = 'Помощник закрытия заявки';
						|pl = 'Request closing wizard';
						|tr = 'Talep kapatma sihirbazı'");
		EndIf;
	ElsIf OrderType_5 = "ProductionStage2_2" Then
		Title = NStr("vi = 'Trợ giúp đóng giai đoạn';
					|ru = 'Помощник закрытия этапов';
					|en = 'Stages closing wizard'; fa = 'Stages closing wizard';
					|it = 'Помощник закрытия этапов';
					|pl = 'Stages closing wizard';
					|tr = 'Aşama kapatma sihirbazı'");
		If OrdersQuantity = 1 Then
			Title = NStr("vi = 'Trợ giúp đóng giai đoạn';
						|ru = 'Помощник закрытия этапа';
						|en = 'Stage closing wizard'; fa = 'Stage closing wizard';
						|it = 'Помощник закрытия этапа';
						|pl = 'Stage closing wizard';
						|tr = 'Aşama kapatma sihirbazı'");
		EndIf;
	Else
		Title = NStr("vi = 'Trợ giúp đóng đơn hàng';
					|ru = 'Помощник закрытия заказов';
					|en = 'Order closure wizard'; fa = 'دستیار بستن سفارش';
					|it = 'Помощник закрытия заказов';
					|pl = 'Asystent zamknięcia zamówień';
					|tr = 'Sipariş kapatma sihirbazı'");
		If OrdersQuantity = 1 Then
			Title = NStr("vi = 'Trợ giúp đóng đơn hàng';
						|ru = 'Помощник закрытия заказа';
						|en = 'Order closing wizard'; fa = 'Order closing wizard';
						|it = 'Помощник закрытия заказа';
						|pl = 'Order closing wizard';
						|tr = 'Sipariş kapatma sihirbazı'");
		EndIf;
	EndIf;
	
	TextAnd             = ?(ValueIsFilled(TextShipmentNotProcessed) And ValueIsFilled(TextNotAccepted),
							NStr("vi = ', cũng như';
								|ru = ', а также';
								|en = ', as well as'; fa = ', as well as';
								|it = ', а также';
								|pl = ', as well as';
								|tr = ', aynı zamanda'"),
							"");
	TextReasonForCancellation = ?(UseOrderCancellationReasons, NStr("vi = 'Vui lòng cho biết lý do hủy bỏ.';
																	|ru = 'Необходимо указать причину отмены.';
																	|en = 'Specify reason for cancellation.'; fa = 'Specify reason for cancellation.';
																	|it = 'È necessario specificare il motivo di annullamento.';
																	|pl = 'Należy podać przyczynę anulowania.';
																	|tr = 'İptal nedeni belirtilmelidir.'"), "");
	
	TextOfShipmentLine = NStr("vi = 'Dòng';
								|ru = 'Строки';
								|en = 'Rows'; fa = 'سطرها';
								|it = 'Righe';
								|pl = 'Wiersze';
								|tr = 'Satırlar'");
	TextOfAcceptanceLine  = NStr("vi = 'Dòng';
								|ru = 'Строки';
								|en = 'Rows'; fa = 'سطرها';
								|it = 'Righe';
								|pl = 'Wiersze';
								|tr = 'Satırlar'");
	
	If OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		TextOfShipmentLine = NStr("vi = 'Dòng mặt hàng thay thế';
									|ru = 'Строки заменяющих товаров';
									|en = 'Substitute goods lines'; fa = 'Substitute goods lines';
									|it = 'Righe delle merci sostitutive';
									|pl = 'Wiersze zastępczych towarów';
									|tr = 'İkame ürünlerin satırları'");
		TextOfAcceptanceLine  = NStr("vi = 'Hàng sản phẩm bị trả lại';
									|ru = 'Строки возвращаемых товаров';
									|en = 'Goods pending return lines'; fa = 'Goods pending return lines';
									|it = 'Righe delle merci in restituzione';
									|pl = 'Wiersze zwracanych towarów';
									|tr = 'İade edilen ürünlerin satırları'");
	ElsIf OrderType_5 = "ByAssemblyDisassemblyOrder" Then
		TextOfShipmentLine = NStr("vi = 'Dòng của bộ sản phẩm được tách / đóng bộ được ghi giảm';
									|ru = 'Строки списываемых комплектующих / разбираемых комплектов';
									|en = 'Lines of written-off components/disassembled kits'; fa = 'Lines of written-off components/disassembled kits';
									|it = 'Righe di componenti / kit scomponibili da cancellare';
									|pl = 'Wiersze rozchodowych części / rozbieranych zestawów';
									|tr = 'Kayıttan düşülen bileşenlerin / demontaj setlerin satırları'");
		TextOfAcceptanceLine  = NStr("vi = 'Các dòng của bộ sản phẩm được tách / đóng bộ được ghi tăng';
									|ru = 'Строки приходуемых комплектующих / собираемых комплектов';
									|en = 'Lines of recorded as received components/assembled kits'; fa = 'Lines of recorded as received components/assembled kits';
									|it = 'Righe di componenti /kit assemblati da registrare';
									|pl = 'Wiersze przyjętych części / zbieranych zestawów';
									|tr = 'Gelen bileşenlerin / montaj setlerin satırları'");
	ElsIf OrderType_5 = "SubcontractOrder2_5" Then
		TextOfShipmentLine = NStr("vi = 'Dòng nguyên vật liệu';
									|ru = 'Строки сырья и материалов';
									|en = 'Lines with raw and consumable materials'; fa = 'Lines with raw and consumable materials';
									|it = 'Righe di materiali e materie prime';
									|pl = 'Wiersze surowców i materiałów';
									|tr = 'Hammadde ve sarf malzeme satırları'");
		TextOfAcceptanceLine  = NStr("vi = 'Dòng sản phẩm đầu ra';
									|ru = 'Строки выходных изделий';
									|en = 'Finished product lines'; fa = 'Finished product lines';
									|it = 'Righe di prodotti finiti';
									|pl = 'Wiersze wyrobów wychodzących';
									|tr = 'Çıktı nihai ürün satırları'");
	ElsIf OrderType_5 = "MaterialProviderOrder2_5" Then
		TextOfShipmentLine = NStr("vi = 'Dòng sản phẩm';
									|ru = 'Строки выпускаемой продукции';
									|en = 'Released product lines'; fa = 'Released product lines';
									|it = 'Righe di prodotti rilasciati';
									|pl = 'Wiersze wypuszczanej produkcji';
									|tr = 'İmal edilen ürün satırları'");
		TextOfAcceptanceLine  = NStr("vi = 'Dòng nguyên liệu sản xuất';
									|ru = 'Строки сырья и материалов для производства';
									|en = 'Lines with raw and consumable materials for production'; fa = 'Lines with raw and consumable materials for production';
									|it = 'Righe di materie prime e materiali per la produzione';
									|pl = 'Wiersze surowców i materiałów dla produkcji';
									|tr = 'Üretim için hammadde ve sarf malzemele satırları'");
	ElsIf OrderType_5 = "ProductionStage2_2" Then
		TextOfShipmentLine = NStr("vi = 'Dòng của nguyên vật liệu được cung cấp';
									|ru = 'Строки обеспечиваемых материалов';
									|en = 'Lines of supplied materials'; fa = 'Lines of supplied materials';
									|it = 'Righe di materiali forniti';
									|pl = 'Wiersze obsługiwanych materiałów';
									|tr = 'Tedarik edilecek malzeme satırları'");
		TextOfAcceptanceLine  = NStr("vi = 'Dòng vật liệu chưa sử dụng';
									|ru = 'Строки неизрасходованных материалов';
									|en = 'Unused material lines'; fa = 'Unused material lines';
									|it = 'Righe di materiali non consumati';
									|pl = 'Wiersze niewykorzystanych materiałów';
									|tr = 'Kullanılmayan malzeme satırları'");
	EndIf;
	
	// Start page
	
	Items.CorrectMeasuringGoods.Title          = NStr("vi = 'Điều chỉnh dòng của hàng đo lường.';
														|ru = 'Скорректировать строки мерных товаров.';
														|en = 'Correct lines with measured goods.'; fa = 'Correct lines with measured goods.';
														|it = 'Correggere righe merci misurabili.';
														|pl = 'Skorygować wiersze towarów wymiarowych.';
														|tr = 'Ölçülebilen ürünlerin satırlarını düzelt.'");
	Items.AdjustTheMeasuredGoodsUponAcceptance.Title = NStr("vi = 'Điều chỉnh dòng của hàng đo lường.';
															|ru = 'Скорректировать строки мерных товаров.';
															|en = 'Correct lines with measured goods.'; fa = 'Correct lines with measured goods.';
															|it = 'Correggere righe merci misurabili.';
															|pl = 'Skorygować wiersze towarów wymiarowych.';
															|tr = 'Ölçülebilen ürünlerin satırlarını düzelt.'");
	
	If OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		Items.CorrectMeasuringGoods.Title          = NStr("vi = 'Điều chỉnh dòng của hàng đo lường được thay thế.';
															|ru = 'Скорректировать строки мерных заменяющих товаров.';
															|en = 'Correct lines of measuring substitute goods.'; fa = 'Correct lines of measuring substitute goods.';
															|it = 'Correggere righe merci misurabili di sostituzione.';
															|pl = 'Skorygować wiersze zastępczych towarów wymiarowych.';
															|tr = 'Ölçülebilen ikame ürünlerin satırlarını düzelt.'");
		Items.AdjustTheMeasuredGoodsUponAcceptance.Title = NStr("vi = 'Điều chỉnh các dòng của hàng đo lường được trả lại.';
																|ru = 'Скорректировать строки мерных возвращаемых товаров.';
																|en = 'Correct lines of goods pending return.'; fa = 'Correct lines of goods pending return.';
																|it = 'Correggere righe merci misurabili da restituire.';
																|pl = 'Skorygować wiersze zwracanych towarów wymiarowych.';
																|tr = 'Ölçülebilen iade edilen ürünlerin satırlarını düzelt.'");
	ElsIf OrderType_5 = "ByAssemblyDisassemblyOrder" Then
		Items.CorrectMeasuringGoods.Title          = NStr("vi = 'Sửa lỗi các dòng của các bộ phận / bộ tháo rời đo lường.';
															|ru = 'Скорректировать строки мерных списываемых комплектующих / разбираемых комплектов.';
															|en = 'Correct lines of measuring written-off components/disassembled kits.'; fa = 'Correct lines of measuring written-off components/disassembled kits.';
															|it = 'Correggere righe di componenti /kit assemblati misurabili da cancellare.';
															|pl = 'Skorygować wiersze rozchodowych części wymiarowych / rozbieranych zestawów.';
															|tr = 'Ölçülebilen kayıttan düşülen bileşenlerin / demontaj edilebilen setlerin satırlarını düzelt.'");
		Items.AdjustTheMeasuredGoodsUponAcceptance.Title = NStr("vi = 'Điều chỉnh các dòng của các thành phần chi tiết / bộ lắp ráp đo lường được ghi tăng.';
																|ru = 'Скорректировать строки мерных приходуемых комплектующих / собираемых комплектов.';
																|en = 'Correct lines of measuring recorded as received components/assembled kits.'; fa = 'Correct lines of measuring recorded as received components/assembled kits.';
																|it = 'Correggere righe di componenti /kit assemblati misurabili da registrare.';
																|pl = 'Skorygować wiersze przyjmowanych części wymiarowych / zbieranych zestawów.';
																|tr = 'Ölçülebilen gelen bileşenlerin / montaj edilebilen setlerin satırlarını düzelt.'");
	ElsIf OrderType_5 = "SubcontractOrder2_5" Then
		Items.CorrectMeasuringGoods.Title          = NStr("vi = 'Điều chỉnh các dòng nguyên vật liệu đo lường.';
															|ru = 'Скорректировать строки мерных сырья и материалов.';
															|en = 'Correct lines of measuring raw and consumable materials.'; fa = 'Correct lines of measuring raw and consumable materials.';
															|it = 'Correggere righe di materie prime e materiali misurabili.';
															|pl = 'Skorygować wiersze surowców i materiałów wymiarowych.';
															|tr = 'Ölçülebilen hammadde ve sarf malzeme satırlarını düzelt.'");
		Items.AdjustTheMeasuredGoodsUponAcceptance.Title = NStr("vi = 'Điều chỉnh các dòng đầu ra đo lường.';
																|ru = 'Скорректировать строки мерных выходных изделий.';
																|en = 'Correct lines of measuring finished products.'; fa = 'Correct lines of measuring finished products.';
																|it = 'Correggere righe di prodotti finiti misurabili.';
																|pl = 'Skorygować wiersze wychodzących wyrobów wymiarowych.';
																|tr = 'Ölçülebilen üretilen nihai ürünlerin satırlarını düzelt.'");
	ElsIf OrderType_5 = "MaterialProviderOrder2_5" Then
		Items.CorrectMeasuringGoods.Title          =
			NStr("vi = 'Điều chỉnh các dòng thành phẩm xuất xưởng đo lường.';
				|ru = 'Скорректировать строки мерной выпускаемой продукции.';
				|en = 'Correct lines of measuring released products.'; fa = 'Correct lines of measuring released products.';
				|it = 'Correggere righe di prodotti rilasciati miusrabili.';
				|pl = 'Skorygować wiersze wypuszczanej produkcji wymiarowej.';
				|tr = 'Ölçülebilen imal edilen ürünlerin satırlarını düzelt.'");
		Items.AdjustTheMeasuredGoodsUponAcceptance.Title =
			NStr("vi = 'Điều chỉnh các dòng nguyên vật liệu đo lường đối với sản xuất.';
				|ru = 'Скорректировать строки мерных сырья и материалов для производства.';
				|en = 'Correct lines of measuring raw and consumable materials for production.'; fa = 'Correct lines of measuring raw and consumable materials for production.';
				|it = 'Correggere righe di materie prime e materiali misurabili per la produzione.';
				|pl = 'Skorygować wiersze surowców i materiałów wymiarowych dla produkcji.';
				|tr = 'Üretim için ölçülebilen hammadde ve sarf malzeme satırlarını düzelt.'");
	ElsIf OrderType_5 = "ProductionStage2_2" Then
		Items.CorrectMeasuringGoods.Title          = NStr("vi = 'Điều chỉnh các dòng nguyên vật liệu được cung cấp và đo lường.';
															|ru = 'Скорректировать строки мерных обеспечиваемых материалов.';
															|en = 'Correct lines of measuring supplied materials.'; fa = 'Correct lines of measuring supplied materials.';
															|it = 'Coreggere righe di materiali misurabili forniti.';
															|pl = 'Skorygować wiersze obsługiwanych materiałów wymiarowych.';
															|tr = 'Ölçülebilen tedarik malzemelerinin satırlarını düzelt.'");
		Items.AdjustTheMeasuredGoodsUponAcceptance.Title = NStr("vi = 'Điều chỉnh các dòng nguyên vật liệu đo lường chưa xuất.';
																|ru = 'Скорректировать строки мерных неизрасходованных материалов.';
																|en = 'Correct lines of measuring unused materials.'; fa = 'Correct lines of measuring unused materials.';
																|it = 'Correggere righe di materiali misurabili non consumati.';
																|pl = 'Skorygować wiersze niewykorzystanych materiałów wymiarowych.';
																|tr = 'Ölçülebilen kullanılmayan malzeme satırlarını düzelt.'");
	EndIf;
	
	Items.CorrectMeasuringGoods.ExtendedTooltip.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong dòng %1 với hàng hóa đo lường sẽ loại bỏ chênh lệch với hóa đơn trong giới hạn chênh lệch được phép.';
				|ru = 'В строках %1 с мерными товарами будут устранены расхождения с накладными в пределах допустимых отклонений.';
				|en = 'Goods receipt discrepancies within the allowable deviation will be eliminated in lines %1 with measured goods.'; fa = 'Goods receipt discrepancies within the allowable deviation will be eliminated in lines %1 with measured goods.';
				|it = 'Nelle righe%1 con le merci misurabili saranno eliminate le discrepanze con i documenti di trasporto entro i limiti di tolleranza consentiti.';
				|pl = 'W wierszach %1 z towarami wymiarowymi zostanie usunięte odchylenie z fakturami w granicach dopuszczalnego odchylenia.';
				|tr = 'Ölçülen ürünlerin bulunduğu %1''lik satırlarda irsaliyelerle olan tutarsızlıklar mümkünlük dahilinde giderildi.'"),
			RPText);
			
	Items.AdjustTheMeasuredGoodsUponAcceptance.ExtendedTooltip.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong dòng %1 với hàng hóa đo lường sẽ loại bỏ chênh lệch với hóa đơn trong giới hạn chênh lệch được phép.';
				|ru = 'В строках %1 с мерными товарами будут устранены расхождения с накладными в пределах допустимых отклонений.';
				|en = 'Goods receipt discrepancies within the allowable deviation will be eliminated in lines %1 with measured goods.'; fa = 'Goods receipt discrepancies within the allowable deviation will be eliminated in lines %1 with measured goods.';
				|it = 'Nelle righe%1 con le merci misurabili saranno eliminate le discrepanze con i documenti di trasporto entro i limiti di tolleranza consentiti.';
				|pl = 'W wierszach %1 z towarami wymiarowymi zostanie usunięte odchylenie z fakturami w granicach dopuszczalnego odchylenia.';
				|tr = 'Ölçülen ürünlerin bulunduğu %1''lik satırlarda irsaliyelerle olan tutarsızlıklar mümkünlük dahilinde giderildi.'"),
			RPText);
	
	Items.TheGroupBeganToCancelTheUndelivered.ExtendedTooltip.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Dòng %1, theo đó %2%3 %4, sẽ bị hủy. %5';
				|ru = 'Строки %1, по которым %2%3 %4, будут отменены. %5';
				|en = 'Lines %1 for which %2%3 %4 will be canceled. %5'; fa = 'Lines %1 for which %2%3 %4 will be canceled. %5';
				|it = 'Строки %1, по которым %2%3 %4, будут отменены. %5';
				|pl = 'Lines %1 for which %2%3 %4 will be canceled. %5';
				|tr = '%2%3 %4 olan %1 satırları iptal edilecektir. %5'"), 
			RPText,
			TextShipmentNotProcessed,
			TextAnd,
			TextNotAccepted,
			TextReasonForCancellation);
		
	Items.CloseOrders.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đặt trạng thái %1.';
			|ru = 'Устанавливать статус %1.';
			|en = 'Set the %1 status.'; fa = 'Set the %1 status.';
			|it = 'Impostare lo stato %1.';
			|pl = 'Ustawić status %1.';
			|tr = 'Durumu %1 ayarla.'"), 
		TheClosedStatusPresentation);
		
	Items.CloseOrders.ExtendedTooltip.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khi thực hiện các điều kiện cần thiết %1 sẽ đặt trạng thái %2.';
			|ru = 'При выполнении необходимых условий %1 будет установлен статус %2.';
			|en = 'If the required %1 conditions are fulfilled, the %2 status will be set.'; fa = 'If the required %1 conditions are fulfilled, the %2 status will be set.';
			|it = 'Dopo l''esecuzione delle condizioni necessarie %1 sarà impostato lo stato %2.';
			|pl = 'Podczas wykonywania wymaganych warunków %1 zostanie ustawiony status %2.';
			|tr = 'Eğer %1 için şartlar karşılanırsa, %2 durumu ayarlanacaktır.'"), 
		DPText,
		TheClosedStatusPresentation);
		
	If Orders.Count() = 1 Then
		If OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
			TitleTextWithoutPayment = StrTemplate(NStr("vi = 'Đã trả một phần %1 sẽ không bị đóng.';
														|ru = 'Частично оплаченный %1 не будет закрыт.';
														|en = 'Partially paid %1 will not be closed.'; fa = 'Partially paid %1 will not be closed.';
														|it = 'Pagata parzialmente%1 non sarà chiusa.';
														|pl = 'Częściowo opłacony %1 nie zostanie zamknięty.';
														|tr = 'Kısmen ödenen %1 kapatılmayacaktır.'"),IPText);
			TitleTextWithoutShipment = StrTemplate(NStr("vi = 'Thực hiện một phần %1 sẽ không bị đóng.';
														|ru = 'Частично выполненный %1 не будет закрыт.';
														|en = 'Partially completed %1 will not be closed.'; fa = 'Partially completed %1 will not be closed.';
														|it = 'Eseguita parzialmente %1 non sarà chiusa.';
														|pl = 'Częściowo wykonany %1 nie zostanie zamknięty.';
														|tr = 'Kısmen gerçekleştirilmiş %1 kapatılmayacaktır.'"),IPText);
			TitleTextWithoutEverything = StrTemplate(NStr("vi = 'Hoàn thành một phần hoặc trả một phần %1 sẽ không bị đóng.';
															|ru = 'Частично выполненный или частично оплаченный %1 не будет закрыт.';
															|en = 'Partially completed or partially paid %1 will not be closed.'; fa = 'Partially completed or partially paid %1 will not be closed.';
															|it = 'Eseguita parzialmente o eseguita parzialmente%1 non sarà chiusa.';
															|pl = 'Częściowo wykonany lub częściowo opłacony %1 nie zostanie zamknięty.';
															|tr = 'Kısmen gerçekleştirilmiş veya kısmen ödenmiş %1 kapatılmayacaktır.'"),IPText);
		Else
			TitleTextWithoutPayment = StrTemplate(NStr("vi = 'Đã trả một phần %1 sẽ không bị đóng.';
														|ru = 'Частично оплаченный %1 не будет закрыт.';
														|en = 'Partially paid %1 will not be closed.'; fa = 'Partially paid %1 will not be closed.';
														|it = 'Pagata parzialmente%1 non sarà chiusa.';
														|pl = 'Częściowo opłacony %1 nie zostanie zamknięty.';
														|tr = 'Kısmen ödenen %1 kapatılmayacaktır.'"),IPText);
			TitleTextWithoutShipment = StrTemplate(NStr("vi = 'Thực hiện một phần %1 sẽ không bị đóng.';
														|ru = 'Частично выполненный %1 не будет закрыт.';
														|en = 'Partially completed %1 will not be closed.'; fa = 'Partially completed %1 will not be closed.';
														|it = 'Eseguita parzialmente %1 non sarà chiusa.';
														|pl = 'Częściowo wykonany %1 nie zostanie zamknięty.';
														|tr = 'Kısmen gerçekleştirilmiş %1 kapatılmayacaktır.'"),IPText);
			TitleTextWithoutEverything = StrTemplate(NStr("vi = 'Hoàn thành một phần hoặc trả một phần %1 sẽ không bị đóng.';
															|ru = 'Частично выполненный или частично оплаченный %1 не будет закрыт.';
															|en = 'Partially completed or partially paid %1 will not be closed.'; fa = 'Partially completed or partially paid %1 will not be closed.';
															|it = 'Eseguita parzialmente o eseguita parzialmente%1 non sarà chiusa.';
															|pl = 'Częściowo wykonany lub częściowo opłacony %1 nie zostanie zamknięty.';
															|tr = 'Kısmen gerçekleştirilmiş veya kısmen ödenmiş %1 kapatılmayacaktır.'"),IPText);
		EndIf;
	Else
		TitleTextWithoutPayment = StrTemplate(NStr("vi = 'Đã trả một phần %1 sẽ không bị đóng.';
													|ru = 'Частично оплаченный %1 не будет закрыт.';
													|en = 'Partially paid %1 will not be closed.'; fa = 'Partially paid %1 will not be closed.';
													|it = 'Pagata parzialmente%1 non sarà chiusa.';
													|pl = 'Częściowo opłacony %1 nie zostanie zamknięty.';
													|tr = 'Kısmen ödenen %1 kapatılmayacaktır.'"),IPText);
		TitleTextWithoutShipment = StrTemplate(NStr("vi = 'Thực hiện một phần %1 sẽ không bị đóng.';
													|ru = 'Частично выполненный %1 не будет закрыт.';
													|en = 'Partially completed %1 will not be closed.'; fa = 'Partially completed %1 will not be closed.';
													|it = 'Eseguita parzialmente %1 non sarà chiusa.';
													|pl = 'Częściowo wykonany %1 nie zostanie zamknięty.';
													|tr = 'Kısmen gerçekleştirilmiş %1 kapatılmayacaktır.'"),IPText);
		TitleTextWithoutEverything = StrTemplate(NStr("vi = 'Hoàn thành một phần hoặc trả một phần %1 sẽ không bị đóng.';
														|ru = 'Частично выполненный или частично оплаченный %1 не будет закрыт.';
														|en = 'Partially completed or partially paid %1 will not be closed.'; fa = 'Partially completed or partially paid %1 will not be closed.';
														|it = 'Eseguita parzialmente o eseguita parzialmente%1 non sarà chiusa.';
														|pl = 'Częściowo wykonany lub częściowo opłacony %1 nie zostanie zamknięty.';
														|tr = 'Kısmen gerçekleştirilmiş veya kısmen ödenmiş %1 kapatılmayacaktır.'"),IPText);
	EndIf;
	
	Items.DecorationShipmentWithoutPayment.Title = TitleTextWithoutPayment;
	
	Items.DecorationShipmentWithoutShipment.Title = StrTemplate(
		NStr("vi = '%1 Trạng thái hiện tại có thể thay đổi sau khi điều chỉnh dòng.';
			|ru = '%1 Текущее состояние может измениться после корректировок строк.';
			|en = '%1 The current state may change after the line adjustments.'; fa = '%1 The current state may change after the line adjustments.';
			|it = '%1 Lo stato corrente può cambiarsi dopo le correzioni delle righe.';
			|pl = '%1 Aktualny stan może ulec zmianie po korektach wierszy.';
			|tr = '%1 satır düzeltmelerinden sonra mevcut durum değişebilir.'"), 
		TitleTextWithoutShipment);
	
	Items.DecorationShipmentWithoutPaymentOrShipment.Title = StrTemplate(
		NStr("vi = '%1 Trạng thái hiện tại có thể thay đổi sau khi điều chỉnh dòng.';
			|ru = '%1 Текущее состояние может измениться после корректировок строк.';
			|en = '%1 The current state may change after the line adjustments.'; fa = '%1 The current state may change after the line adjustments.';
			|it = '%1 Lo stato corrente può cambiarsi dopo le correzioni delle righe.';
			|pl = '%1 Aktualny stan może ulec zmianie po korektach wierszy.';
			|tr = '%1 satır düzeltmelerinden sonra mevcut durum değişebilir.'"),
		TitleTextWithoutEverything);
	
	// Dimensional goods
	Items.DimensionalGoodsToBeAdjustedShipmentDecoration.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2 với hàng hóa đo lường mà có sự khác biệt trong phạm vi dung sai sẽ được điều chỉnh.';
				|ru = '%1 %2 с мерными товарами, по которым имеются расхождения в пределах допустимых отклонений будут скорректированы.';
				|en = '%1 %2 with measured goods that have discrepancies within the allowable deviation will be adjusted.'; fa = '%1 %2 with measured goods that have discrepancies within the allowable deviation will be adjusted.';
				|it = '%1 %2 con le merci misurabili di cui sono presenti le discrepanze entro i limiti di tolleranza consentiti saranno corretti.';
				|pl = '%1 %2 z towarami wymiarowymi, dla których istnieje odchylenie w dopuszczalnych granicach zostaną skorygowane.';
				|tr = '%1 %2 ile mümkün sınırlar dahilinde tutarsızlıklar bulunan ölçülebilen ürünler düzeltilecektir.'"),
			TextOfShipmentLine,
			RPText);
	
	Items.MeasuringTheGoodsToAdjustTheAcceptanceDecoration.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2 với hàng hóa đo lường mà có sự khác biệt trong phạm vi dung sai sẽ được điều chỉnh.';
				|ru = '%1 %2 с мерными товарами, по которым имеются расхождения в пределах допустимых отклонений будут скорректированы.';
				|en = '%1 %2 with measured goods that have discrepancies within the allowable deviation will be adjusted.'; fa = '%1 %2 with measured goods that have discrepancies within the allowable deviation will be adjusted.';
				|it = '%1 %2 con le merci misurabili di cui sono presenti le discrepanze entro i limiti di tolleranza consentiti saranno corretti.';
				|pl = '%1 %2 z towarami wymiarowymi, dla których istnieje odchylenie w dopuszczalnych granicach zostaną skorygowane.';
				|tr = '%1 %2 ile mümkün sınırlar dahilinde tutarsızlıklar bulunan ölçülebilen ürünler düzeltilecektir.'"),
			TextOfAcceptanceLine,
			RPText);
	
	// Products to cancel
	Items.ProductsToCancelShipmentDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 %2 trong đó %3 sẽ bị hủy.';
			|ru = '%1 %2, по которым %3, будут отменены.';
			|en = '%1 %2 under which %3 will be cancelled.'; fa = '%1 %2 under which %3 will be cancelled.';
			|it = '%1 %2, per cui %3, saranno annullati.';
			|pl = '%1 %2, dla których %3, będą anulowane.';
			|tr = '%1 %2, %3 göre iptal edilecektir.'"),
		TextOfShipmentLine,
		RPText,
		TextShipmentNotProcessed);
	
	Items.TheGoodsToCancelTheAcceptanceOfTheDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 %2 trong đó %3 sẽ bị hủy.';
			|ru = '%1 %2, по которым %3, будут отменены.';
			|en = '%1 %2 under which %3 will be cancelled.'; fa = '%1 %2 under which %3 will be cancelled.';
			|it = '%1 %2, per cui %3, saranno annullati.';
			|pl = '%1 %2, dla których %3, będą anulowane.';
			|tr = '%1 %2, %3 göre iptal edilecektir.'"),
		TextOfAcceptanceLine,
		RPText,
		TextNotAccepted);
	
	// The closure orders
	Items.ClosingOrdersDecorationFailure.Title = StrTemplate(NStr("vi = 'Không thể xử lý %1:';
																	|ru = 'Не удалось обработать %1:';
																	|en = 'Cannot process %1:'; fa = 'Cannot process %1:';
																	|it = 'Non è stato possibile elaborare %1:';
																	|pl = 'Nie udało się opracować %1:';
																	|tr = '%1 işlenemedi:'"), IPText);
	
	If Orders.Count() = 1 Then
		If OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
			TitleTextFailure = StrTemplate(NStr("vi = 'Đã chỉ ra %1 đã xử lý.';
												|ru = 'Указанная %1 обработана.';
												|en = 'The specified request %1 is processed.'; fa = 'The specified request %1 is processed.';
												|it = 'Indicata%1elaborata.';
												|pl = 'Wskazana %1 została przetworzona.';
												|tr = 'Belirtilen %1 işlendi.'"), IPText);
			TitleTextAllClosed = StrTemplate(NStr("vi = 'Đã chỉ ra %1 đã đóng hoặc không cần đóng.';
													|ru = 'Указанная %1 уже закрыта или не требует закрытия.';
													|en = 'The %1 is already closed or does not need closing.'; fa = 'The %1 is already closed or does not need closing.';
													|it = 'Indicata %1 è già chiusa o non richiede la chiusura.';
													|pl = 'Wskazana %1 została zamknięta lub nie potrzebuje zamknięcia.';
													|tr = 'Belirtilen %1 artık kapalı veya kapanması gerekmiyor.'"),IPText);
		Else
			TitleTextFailure = StrTemplate(NStr("vi = 'Đã chỉ ra %1 đã xử lý.';
												|ru = 'Указанный %1 обработан.';
												|en = 'The specified order %1 is processed.'; fa = 'The specified order %1 is processed.';
												|it = 'Indicato%1elaborato.';
												|pl = 'Wskazany %1 został przetworzony.';
												|tr = 'Belirtilen %1 işlendi.'"), IPText);
			TitleTextAllClosed = StrTemplate(NStr("vi = 'Đã chỉ ra %1';
													|ru = 'Указанный %1 уже закрыт или не требует закрытия.';
													|en = 'The %1 is already closed or does not require closing.'; fa = 'The %1 is already closed or does not require closing.';
													|it = 'Indicato %1 è già chiuso o non richiede la chiusura.';
													|pl = 'Wskazany %1 został zamknięty lub nie potrzebuje zamknięcia.';
													|tr = 'Belirtilen %1 artık kapalı veya kapanması gerekmiyor.'"),IPText);
		EndIf;
	Else
		TitleTextFailure = StrTemplate(NStr("vi = 'Tất cả %1 đã xử lý.';
											|ru = 'Все %1 обработаны.';
											|en = 'All %1 are processed.'; fa = 'All %1 are processed.';
											|it = 'Tutti i%1elaborati.';
											|pl = 'Wszystkie %1 zostały przetworzone.';
											|tr = 'Tümü %1 işlendi.'"), IPText);
		TitleTextAllClosed = StrTemplate(NStr("vi = 'Tất cả %1 đã bị đóng hoặc không cần đóng.';
												|ru = 'Все %1 уже закрыты или не требуют закрытия.';
												|en = 'All %1 are already closed or do not require closing.'; fa = 'All %1 are already closed or do not require closing.';
												|it = 'Tutti i %1 sono già chiusi o non richiedono la chiusura.';
												|pl = 'Wszystkie %1 zostały zamknięte lub nie potrzebują zamknięcia.';
												|tr = 'Tümü %1 artık kapalı veya kapanması gerekmiyor.'"),IPText);
	EndIf;
		
	Items.ClosingOrdersDecorationFailure.Title =
		StrTemplate(NStr("vi = '%1 Nhấn ''''Đóng'''' để hoàn thành.';
						|ru = '%1 Нажмите ""Закрыть"" для завершения.';
						|en = '%1 Press ""Close"" to finish.'; fa = '%1 Press ""Close"" to finish.';
						|it = '%1 Premere ""Chiudere"" per terminare.';
						|pl = '%1 Kliknij ""Zamknij"", aby zakończyć.';
						|tr = '%1 Bitirmek için ""Kapat"" düğmesine tıkla.'"), TitleTextFailure);
	
	Items.AllOrdersAreClosedDecoration.Title =
		StrTemplate(NStr("vi = '%1 Nhấn ''''Đóng'''' để hoàn thành.';
						|ru = '%1 Нажмите ""Закрыть"" для завершения.';
						|en = '%1 Press ""Close"" to finish.'; fa = '%1 Press ""Close"" to finish.';
						|it = '%1 Premere ""Chiudere"" per terminare.';
						|pl = '%1 Kliknij ""Zamknij"", aby zakończyć.';
						|tr = '%1 Bitirmek için ""Kapat"" düğmesine tıkla.'"), TitleTextAllClosed);
	
EndProcedure

&AtClientAtServerNoContext
Function CaseSettingsByOrderType(OrderType_5, OrdersQuantity)
	If OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		If OrdersQuantity = 1 Then
			RPText = NStr("vi = 'giấy đề nghị';
							|ru = 'заявок';
							|en = 'requests'; fa = 'requests';
							|it = 'richieste';
							|pl = 'zgłoszeń';
							|tr = 'başvuruların'");
			IPText = NStr("vi = 'giấy đề nghị';
							|ru = 'заявка';
							|en = 'application'; fa = 'application';
							|it = 'richiesta';
							|pl = 'zgłoszenie';
							|tr = 'Başvuru'");
			DPText = NStr("vi = 'đơn';
							|ru = 'заявке';
							|en = 'request'; fa = 'درخواست';
							|it = 'alla richiesta';
							|pl = 'zgłoszeniu';
							|tr = 'başvuruya'");
		Else
			RPText = NStr("vi = 'giấy đề nghị';
							|ru = 'заявок';
							|en = 'requests'; fa = 'requests';
							|it = 'richieste';
							|pl = 'zgłoszeń';
							|tr = 'başvuruların'");
			IPText = NStr("vi = 'đơn';
							|ru = 'заявки';
							|en = 'requests'; fa = 'requests';
							|it = 'richieste';
							|pl = 'zgłoszenia';
							|tr = 'başvurular'");
			DPText = NStr("vi = 'đơn';
							|ru = 'заявкам';
							|en = 'requests'; fa = 'requests';
							|it = 'alle richieste';
							|pl = 'zgłoszeniom';
							|tr = 'başvurulara'");
		EndIf;
		IPECHText = NStr("vi = 'giấy đề nghị';
						|ru = 'заявка';
						|en = 'application'; fa = 'application';
						|it = 'richiesta';
						|pl = 'zgłoszenie';
						|tr = 'Başvuru'");
		TextOfIPMCH = NStr("vi = 'giấy đề nghị';
							|ru = 'заявки';
							|en = 'requests'; fa = 'requests';
							|it = 'richieste';
							|pl = 'zgłoszenia';
							|tr = 'başvurular'");
		TheClosedStatusPresentation = NStr("vi = '""Đã thực hiện""';
											|ru = '""Выполнена""';
											|en = '""Executed""'; fa = '""Executed""';
											|it = '""Выполнена""';
											|pl = '""Executed""';
											|tr = '""Tamamlandı""'");
	ElsIf OrderType_5 = "ProductionStage2_2" Then
		If OrdersQuantity = 1 Then
			RPText = NStr("vi = 'công đoạn';
							|ru = 'этапа';
							|en = 'stage'; fa = 'stage';
							|it = 'della fase';
							|pl = 'etapu';
							|tr = 'aşama'");
			IPText = NStr("vi = 'công đoạn';
							|ru = 'этап';
							|en = 'stage'; fa = 'stage';
							|it = 'fase';
							|pl = 'etap';
							|tr = 'aşama'");
			DPText = NStr("vi = 'công đoạn';
							|ru = 'этапу';
							|en = 'stage'; fa = 'stage';
							|it = 'fase';
							|pl = 'etapu';
							|tr = 'aşamaya'");
		Else
			RPText = NStr("vi = 'công đoạn';
							|ru = 'этапов';
							|en = 'steps'; fa = 'steps';
							|it = 'delle fasi';
							|pl = 'etapów';
							|tr = 'aşamaların'");
			IPText = NStr("vi = 'công đoạn';
							|ru = 'этапы';
							|en = 'stages'; fa = 'stages';
							|it = 'fasi';
							|pl = 'etapy';
							|tr = 'aşamalar'");
			DPText = NStr("vi = 'công đoạn';
							|ru = 'этапам';
							|en = 'steps'; fa = 'steps';
							|it = 'fasi';
							|pl = 'etapy';
							|tr = 'aşamalara'");
		EndIf;
		IPECHText = NStr("vi = 'công đoạn';
						|ru = 'этап';
						|en = 'stage'; fa = 'stage';
						|it = 'fase';
						|pl = 'etap';
						|tr = 'aşama'");
		TextOfIPMCH = NStr("vi = 'công đoạn';
							|ru = 'этапы';
							|en = 'stages'; fa = 'stages';
							|it = 'fasi';
							|pl = 'etapy';
							|tr = 'aşamalar'");
		TheClosedStatusPresentation = NStr("vi = '""Đã hoàn thành""';
											|ru = '""Завершен""';
											|en = 'Completed'; fa = 'تکمیل‌شده';
											|it = '""Завершен""';
											|pl = 'Completed';
											|tr = '""Tamamlandı.""'");
	Else
		If OrdersQuantity = 1 Then
			RPText = NStr("vi = 'đơn hàng';
							|ru = 'заказа';
							|en = 'order'; fa = 'order';
							|it = 'dell''ordine';
							|pl = 'zamówienia';
							|tr = 'siparişin'");
			IPText = NStr("vi = 'đơn hàng';
							|ru = 'заказ';
							|en = 'order'; fa = 'order';
							|it = 'ordine';
							|pl = 'zamówienie';
							|tr = 'sipariş'");
			DPText = NStr("vi = 'đơn hàng';
							|ru = 'заказу';
							|en = 'order'; fa = 'order';
							|it = 'ordine';
							|pl = 'zleceniu';
							|tr = 'siparişe'");
		Else
			RPText = NStr("vi = 'đơn hàng';
							|ru = 'заказов';
							|en = 'orders'; fa = 'orders';
							|it = 'degli ordini';
							|pl = 'zamówień';
							|tr = 'siparişlerin'");
			IPText = NStr("vi = 'đặt hàng';
							|ru = 'заказы';
							|en = 'Orders'; fa = 'سفارش‌ها';
							|it = 'ordini';
							|pl = 'zamówienia';
							|tr = 'siparişler'");
			DPText = NStr("vi = 'đơn đặt hàng';
							|ru = 'заказам';
							|en = 'orders'; fa = 'orders';
							|it = 'agli ordini';
							|pl = 'zleceniom';
							|tr = 'siparişlere'");
		EndIf;
		IPECHText = NStr("vi = 'đơn hàng';
						|ru = 'заказ';
						|en = 'order'; fa = 'order';
						|it = 'ordine';
						|pl = 'zamówienie';
						|tr = 'sipariş'");
		TextOfIPMCH = NStr("vi = 'đặt hàng';
							|ru = 'заказы';
							|en = 'Orders'; fa = 'سفارش‌ها';
							|it = 'ordini';
							|pl = 'zamówienia';
							|tr = 'siparişler'");
		TheClosedStatusPresentation = NStr("vi = '""Đã đóng""';
											|ru = '""Закрыт""';
											|en = 'Closed'; fa = 'بسته‌شده';
											|it = '""Закрыт""';
											|pl = 'Closed';
											|tr = '""Kapalı""'");
	EndIf;
	
	Result = New Structure;
	Result.Insert("RPText", RPText);
	Result.Insert("IPText", IPText);
	Result.Insert("IPECHText", IPECHText);
	Result.Insert("TextOfIPMCH", TextOfIPMCH);
	Result.Insert("DPText", DPText);
	Result.Insert("TheClosedStatusPresentation", TheClosedStatusPresentation);
	
	Return Result;
EndFunction

&AtServer
Function GenerateTextCalculationProcedure(ARAPObjectSettings)
	
	Calculations = "";
	
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		Calculations = NStr("vi = 'Tính toán theo hợp đồng';
							|ru = 'Расчеты по договору';
							|en = 'AR/AP under contract'; fa = 'دریافتنی/پرداختنی تحت قرارداد';
							|it = 'Regolazioni dei conti per il contratto';
							|pl = 'Rozliczenia kontraktowe';
							|tr = 'Sözleşme kapsamında mutabakat işlemleri'");
	EndIf;
	
	Return Calculations;
	
EndFunction 

#EndRegion

#Region FillingTableParts

&AtServer
Procedure FillInDeviationsForOrders(TableOfGoodsReceipt, TableOfGoodsExpense)
	
	If TypeOf(Orders[0].Value) = Type("DocumentRef.PurchaseOrder") Then
		
		OrderType_5 = "PurchaseOrder";
		
		TheClosedStatusIsUsed = GetFunctionalOption("DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived")
								Or GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment");
		
		FillOutDeviationsForOrdersToSuppliers();
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.SalesOrder") Then
		
		OrderType_5 = "SalesOrder";
		
		TheClosedStatusIsUsed = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment") 
								Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment");
		
		FillDeviationsOnCustomerOrders(TableOfGoodsExpense);
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.InventoryConsumptionOrder") Then
		
		OrderType_5 = "InventoryConsumptionOrder";
		
		TheClosedStatusIsUsed = GetFunctionalOption("DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment");
		
		FillDeviationsOnDomesticConsumptionOrders();
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.TransferOrder") Then
		
		OrderType_5 = "TransferOrder";
		
		TheClosedStatusIsUsed = GetFunctionalOption("DoNotCloseTransferOrdersWithoutCompleteShipment");
		
		FillInDeviationsForMovingOrders();
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
		
		OrderType_5 = "ByAssemblyDisassemblyOrder";
		
		TheClosedStatusIsUsed = GetFunctionalOption("DoNotCloseAssemblyOrdersWithoutCompleteShipment");
		
		FillInDeviationsForAssemblyOrders();
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		OrderType_5 = "RequestForReturnOfGoodsFromCustomer";
		
		TheClosedStatusIsUsed = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment") 
								Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment");
		
		FillInDeviationsOnRequestsForReturnOfGoodsFromClient(TableOfGoodsReceipt, TableOfGoodsExpense);
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.SubcontractOrder2_5") Then
		
		OrderType_5 = "SubcontractOrder2_5";
		
		TheClosedStatusIsUsed = GetFunctionalOption("UseTollingOrderStatuses2_5");
		
		FillInDeviationsForOrdersToProcessors();

	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.OrderOfMaterialsForProduction") Then
		
		OrderType_5 = "OrderOfMaterialsForProduction";
		
		TheClosedStatusIsUsed = True;
		
		FillDeviationsOnOrdersOfMaterialsInProduction();
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.MaterialProviderOrder2_5") Then
		
		OrderType_5 = "MaterialProviderOrder2_5";
		
		TheClosedStatusIsUsed = GetFunctionalOption("UseStatusesOfMaterialProviderOrders2_5");
		
		FillOutDeviationsForGiverSOrders();
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.RMOrder") Then
		
		OrderType_5 = "InventoryConsumptionOrder";
		
		TheClosedStatusIsUsed = GetFunctionalOption("DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment")
			Or GetFunctionalOption("UseRMManagement");
		
		FillDeviationsOnDomesticConsumptionOrders();
		
	ElsIf TypeOf(Orders[0].Value) = Type("DocumentRef.ProductionStage2_2") Then
		
		OrderType_5 = "ProductionStage2_2";
		
		TheClosedStatusIsUsed = True;
		
		FillInDeviationsByStagesOfProduction();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOutDeviationsForOrdersToSuppliers()
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	PurchaseOrder.Ref AS PurchaseOrder
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref IN(&PurchaseOrders)
	|	AND PurchaseOrder.Status <> VALUE(Enum.PurchaseOrderStatuses.Closed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.PurchaseOrder AS OrderDocument,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Warehouse AS Warehouse,
	|	CASE
	|		WHEN CAST(Balance.PurchaseOrder AS Document.PurchaseOrder).Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
	|			THEN Balance.ToRegisterClosingBalance
	|		ELSE Balance.OrderedClosingBalance
	|	END AS Count,
	|	Balance.OrderedReceipt AS Ordered
	|FROM
	|	AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(&InitialOrdersToSuppliers, &CounterOrdersToSuppliers,
	|		,, PurchaseOrder IN (&PurchaseOrders)) AS Balance
	|WHERE
	|	Balance.ToRegisterClosingBalance <> 0
	|	OR Balance.OrderedClosingBalance <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceive.Products         AS Products,
	|	GoodsToReceive.Characteristic       AS Characteristic,
	|	GoodsToReceive.Warehouse                AS Warehouse,
	|	GoodsToReceive.PurchaseOrder      AS OrderDocument,
	|	SUM(GoodsToReceive.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.PurchaseOrders.Turnovers(&InitialOrdersToSuppliers, &CounterOrdersToSuppliers,
	|		, PurchaseOrder IN (&PurchaseOrders)) AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.PurchaseOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrder.Ref AS PurchaseOrder
	|INTO TT_Orders
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref IN(&PurchaseOrders)
	|	AND PurchaseOrder.Status <> VALUE(Enum.PurchaseOrderStatuses.Closed)
	|	AND &UseClosedStatus
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseOrder.Contract AS PurchaseOrder
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref IN(&PurchaseOrders)
	|	AND PurchaseOrder.Status <> VALUE(Enum.PurchaseOrderStatuses.Closed)
	|	AND &UseClosedStatus
	|	AND PurchaseOrder.Contract.GoodsReceiptOption IN (
	|		VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
	|		VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
	|		VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TwoWayDivergence.DocumentInflow AS OrderDocument,
	|	TwoWayDivergence.Products AS Products,
	|	TwoWayDivergence.Characteristic AS Characteristic,
	|	TwoWayDivergence.Purpose AS Purpose,
	|	TwoWayDivergence.Series AS Series,
	|	TwoWayDivergence.ToRegisterReceiptsByInvoicesBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|		,
	|		DocumentInflow IN (
	|			SELECT
	|				References.PurchaseOrder
	|			FROM
	|				TT_Orders AS References
	|			)) AS TwoWayDivergence
	|WHERE
	|	TwoWayDivergence.ToRegisterReceiptsByInvoicesBalance <> 0
	|	AND &TwoWayIsUsed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PurchaseOrders.Recorder                                                 AS DocumentInflow,
	|	CAST(PurchaseOrders.PurchaseOrder AS Document.PurchaseOrder)      AS PurchaseOrder
	|INTO ReceiptDocuments
	|FROM
	|	AccumulationRegister.PurchaseOrders AS PurchaseOrders
	|WHERE
	|	PurchaseOrders.PurchaseOrder IN (&PurchaseOrders)
	|	AND PurchaseOrders.Recorder REFS Document.VendorInvoice
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOfGoodsServicesGoods.RowCode                                            AS RowCode,
	|	ReceiptDocuments.DocumentInflow.Currency                        AS Currency,
	|	ReceiptDocuments.DocumentInflow.ARAPCurrency          AS ARAPCurrency,
	|	ReceiptDocuments.DocumentInflow.CourseDenominator               AS CourseDenominator,
	|	ReceiptDocuments.DocumentInflow.CourseNumerator                 AS CourseNumerator,
	|	BEGINOFPERIOD(ReceiptDocuments.DocumentInflow.Date, DAY)     AS Date,
	|	PurchaseOfGoodsServicesGoods.Price                                    AS Price,
	|	PurchaseOfGoodsServicesGoods.PurchaseOrder                         AS PurchaseOrder,
	|	PurchaseOfGoodsServicesGoods.Sum                                   AS Sum,
	|	PurchaseOfGoodsServicesGoods.Products                            AS Products,
	|	PurchaseOfGoodsServicesGoods.Count                              AS Count,
	|	PurchaseOfGoodsServicesGoods.ManualDiscount                       AS ManualDiscount,
	|	PurchaseOfGoodsServicesGoods.PercentRateOfManualDiscount                     AS PercentRateOfManualDiscount,
	|	PurchaseOfGoodsServicesGoods.Package                                AS Package,
	|	ISNULL(&QueryTextPackagingFactor2, 1)                         AS ConversionFactorOfPackaging,
	|	PurchaseOfGoodsServicesGoods.Ref                                  AS Purchase
	|INTO PurchaseOfGoodsServicesGoods
	|FROM
	|	ReceiptDocuments AS ReceiptDocuments
	|	LEFT JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|		ON ReceiptDocuments.DocumentInflow = PurchaseOfGoodsServicesGoods.Ref
	|WHERE
	|	PurchaseOfGoodsServicesGoods.RowCode > 0
	|	AND PurchaseOfGoodsServicesGoods.PurchaseOrder IN (&PurchaseOrders)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PurchaseOfGoodsServicesGoods.Currency                                               AS Currency,
	|	PurchaseOfGoodsServicesGoods.Date                                                 AS Date,
	|	DocumentPurchaseOrder.Currency                                                 AS OrderCurrency,
	|	PurchaseOfGoodsServicesGoods.Purchase.Organization.LocalAccountingCurrency AS CurrencyOfComplianceAccounting,
	|	DocumentPurchaseOrder.Organization.LocalAccountingCurrency AS CurrencyOfLocalOrderAccounting
	|INTO DatesOfExchangeRatesOfReceipts
	|FROM
	|	PurchaseOfGoodsServicesGoods AS PurchaseOfGoodsServicesGoods
	|	LEFT JOIN Document.PurchaseOrder AS DocumentPurchaseOrder
	|		ON PurchaseOfGoodsServicesGoods.PurchaseOrder = DocumentPurchaseOrder.Ref
	|WHERE
	|	NOT PurchaseOfGoodsServicesGoods.Currency = DocumentPurchaseOrder.Currency
	|	AND NOT PurchaseOfGoodsServicesGoods.ARAPCurrency = DocumentPurchaseOrder.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	DatesOfExchangeRatesOfReceipts.Currency                                      AS Currency,
	|	DatesOfExchangeRatesOfReceipts.Date                                        AS Date,
	|	DatesOfExchangeRatesOfReceipts.CurrencyOfComplianceAccounting                             AS CurrencyOfComplianceAccounting
	|INTO CurrencyExchangeRateDates
	|FROM
	|	DatesOfExchangeRatesOfReceipts AS DatesOfExchangeRatesOfReceipts
	|
	|UNION ALL
	|
	|SELECT
	|	DatesOfExchangeRatesOfReceipts.OrderCurrency                                AS Currency,
	|	DatesOfExchangeRatesOfReceipts.Date                                        AS Date,
	|	DatesOfExchangeRatesOfReceipts.CurrencyOfLocalOrderAccounting                       AS CurrencyOfComplianceAccounting
	|
	|FROM
	|	DatesOfExchangeRatesOfReceipts AS DatesOfExchangeRatesOfReceipts
	|
	|INDEX BY
	|	Currency,
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	NestedQuery.Date                                                   AS Date,
	|	NestedQuery.Currency                                                 AS Currency,
	|	ExchangeRates.CourseNumerator                                               AS CourseNumerator,
	|	ExchangeRates.CourseDenominator                                             AS CourseDenominator
	|INTO ExchangeRatesForTranslation
	|FROM
	|	(SELECT
	|		CurrencyExchangeRateDates.Date AS Date,
	|		ExchangeRates.Currency AS Currency,
	|		ExchangeRates.BaseCurrency AS BaseCurrency,
	|		MAX(ExchangeRates.Period) AS Period
	|	FROM
	|		CurrencyExchangeRateDates AS CurrencyExchangeRateDates
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON CurrencyExchangeRateDates.Currency = ExchangeRates.Currency
	|				AND CurrencyExchangeRateDates.Date >= ExchangeRates.Period
	|				AND CurrencyExchangeRateDates.CurrencyOfComplianceAccounting >= ExchangeRates.BaseCurrency
	|	
	|	GROUP BY
	|		CurrencyExchangeRateDates.Date,
	|		ExchangeRates.Currency,
	|		ExchangeRates.BaseCurrency) AS NestedQuery
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON NestedQuery.Currency = ExchangeRates.Currency
	|			AND NestedQuery.BaseCurrency = ExchangeRates.BaseCurrency
	|			AND NestedQuery.Period = ExchangeRates.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DatesOfExchangeRatesOfReceipts.Date                                        AS Date,
	|	DatesOfExchangeRatesOfReceipts.Currency                                      AS Currency,
	|	OrderExchangeRates.Currency                                                AS OrderCurrency,
	|	AcquisitionExchangeRates.CourseNumerator * OrderExchangeRates.CourseDenominator /
	|		(OrderExchangeRates.CourseNumerator * AcquisitionExchangeRates.CourseDenominator) AS ConversionFactor_
	|INTO ExchangeRates
	|FROM
	|	DatesOfExchangeRatesOfReceipts AS DatesOfExchangeRatesOfReceipts
	|	LEFT JOIN ExchangeRatesForTranslation AS AcquisitionExchangeRates
	|	ON 
	|		DatesOfExchangeRatesOfReceipts.Date = AcquisitionExchangeRates.Date
	|		AND DatesOfExchangeRatesOfReceipts.Currency = AcquisitionExchangeRates.Currency
	|		
	|	LEFT JOIN ExchangeRatesForTranslation AS OrderExchangeRates
	|	ON DatesOfExchangeRatesOfReceipts.Date = OrderExchangeRates.Date
	|	AND OrderExchangeRates.Currency = DatesOfExchangeRatesOfReceipts.OrderCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.Ref                            AS PurchaseOrder,
	|	GoodsFromOrder.RowCode                         AS RowCode,
	|	GoodsFromOrder.Products                      AS Products,
	|	GoodsFromOrder.Characteristic                    AS Characteristic,
	|	GoodsFromOrder.Ref.Currency                     AS OrderCurrency,
	|	GoodsFromOrder.Count                        AS Count,
	|	GoodsFromOrder.Price                              AS Price,
	|	GoodsFromOrder.Sum                             AS Sum,
	|	GoodsFromOrder.PercentRateOfManualDiscount               AS PercentRateOfManualDiscount,
	|	GoodsFromOrder.Package                          AS Package,
	|	ISNULL(&QueryTextPackagingFactor1, 1) AS ConversionFactorOfPackaging
	|INTO GoodsFromOrder
	|FROM
	|	Document.PurchaseOrder.Goods AS GoodsFromOrder
	|WHERE
	|	GoodsFromOrder.Ref IN(&PurchaseOrders)
	|	AND GoodsFromOrder.Ref.Posted
	|	AND NOT GoodsFromOrder.Canceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.PurchaseOrder                     AS PurchaseOrder,
	|	GoodsFromOrder.RowCode                           AS RowCode,
	|	SUM(CAST(CASE
	|		WHEN GoodsFromOrder.OrderCurrency <> PurchaseOfGoodsServicesGoods.Currency THEN
	|			CASE
	|				WHEN GoodsFromOrder.OrderCurrency = PurchaseOfGoodsServicesGoods.ARAPCurrency THEN
	|					CASE
	|						WHEN PurchaseOfGoodsServicesGoods.Currency = PurchaseOfGoodsServicesGoods.Purchase.Organization.LocalAccountingCurrency THEN
	|							PurchaseOfGoodsServicesGoods.Price / PurchaseOfGoodsServicesGoods.CourseNumerator * PurchaseOfGoodsServicesGoods.CourseDenominator
	|						ELSE PurchaseOfGoodsServicesGoods.Price * PurchaseOfGoodsServicesGoods.CourseNumerator / PurchaseOfGoodsServicesGoods.CourseDenominator
	|					END
	|				ELSE PurchaseOfGoodsServicesGoods.Price * ISNULL(ExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE PurchaseOfGoodsServicesGoods.Price
	|	END * PurchaseOfGoodsServicesGoods.Count / PurchaseOfGoodsServicesGoods.ConversionFactorOfPackaging AS NUMBER(31, 2))) AS SumOfReceiptPrices_,
	|	SUM(CAST(CASE
	|		WHEN GoodsFromOrder.OrderCurrency <> PurchaseOfGoodsServicesGoods.Currency THEN
	|			CASE
	|				WHEN GoodsFromOrder.OrderCurrency = PurchaseOfGoodsServicesGoods.ARAPCurrency THEN
	|					CASE
	|						WHEN PurchaseOfGoodsServicesGoods.Currency = PurchaseOfGoodsServicesGoods.Purchase.Organization.LocalAccountingCurrency THEN
	|							PurchaseOfGoodsServicesGoods.Sum / PurchaseOfGoodsServicesGoods.CourseNumerator * PurchaseOfGoodsServicesGoods.CourseDenominator
	|						ELSE PurchaseOfGoodsServicesGoods.Sum * PurchaseOfGoodsServicesGoods.CourseNumerator / PurchaseOfGoodsServicesGoods.CourseDenominator
	|					END
	|				ELSE PurchaseOfGoodsServicesGoods.Sum * ISNULL(ExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE PurchaseOfGoodsServicesGoods.Sum
	|	END AS NUMBER(31, 2)))                         AS OrderReceiptAmount,
	|	SUM(CAST(CASE
	|		WHEN GoodsFromOrder.OrderCurrency <> PurchaseOfGoodsServicesGoods.Currency THEN
	|			CASE
	|				WHEN GoodsFromOrder.OrderCurrency = PurchaseOfGoodsServicesGoods.ARAPCurrency THEN
	|					CASE
	|						WHEN PurchaseOfGoodsServicesGoods.Currency = PurchaseOfGoodsServicesGoods.Purchase.Organization.LocalAccountingCurrency THEN
	|							PurchaseOfGoodsServicesGoods.ManualDiscount / PurchaseOfGoodsServicesGoods.CourseNumerator * PurchaseOfGoodsServicesGoods.CourseDenominator
	|						ELSE PurchaseOfGoodsServicesGoods.ManualDiscount * PurchaseOfGoodsServicesGoods.CourseNumerator / PurchaseOfGoodsServicesGoods.CourseDenominator
	|					END
	|				ELSE PurchaseOfGoodsServicesGoods.ManualDiscount * ISNULL(ExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE PurchaseOfGoodsServicesGoods.ManualDiscount
	|	END AS NUMBER(31, 2)))                         AS ManualDiscountAmountGoodsReceipt,
	|	SUM(PurchaseOfGoodsServicesGoods.Count) AS NumberOfReceipts_1,
	|	MAX(PurchaseOfGoodsServicesGoods.PercentRateOfManualDiscount) AS PercentageOfManualReceiptDiscount
	|INTO DataOnReceiptPrices
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		LEFT JOIN PurchaseOfGoodsServicesGoods AS PurchaseOfGoodsServicesGoods
	|		ON GoodsFromOrder.PurchaseOrder = PurchaseOfGoodsServicesGoods.PurchaseOrder
	|			AND GoodsFromOrder.RowCode = PurchaseOfGoodsServicesGoods.RowCode
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON PurchaseOfGoodsServicesGoods.Currency = ExchangeRates.Currency
	|			AND PurchaseOfGoodsServicesGoods.Date = ExchangeRates.Date
	|			AND GoodsFromOrder.OrderCurrency = ExchangeRates.OrderCurrency
	|GROUP BY
	|	GoodsFromOrder.PurchaseOrder,
	|	GoodsFromOrder.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromOrder.PurchaseOrder                                      AS PurchaseOrder,
	|	GoodsFromOrder.RowCode                                            AS RowCode,
	|	GoodsFromOrder.OrderCurrency                                         AS OrderCurrency,
	|	GoodsFromOrder.Products                                         AS Products,
	|	GoodsFromOrder.Characteristic                                       AS Characteristic,
	|	MAX(DataOnReceiptPrices.PercentageOfManualReceiptDiscount) AS PercentageOfManualReceiptDiscount,
	|	CAST(AVG(DataOnReceiptPrices.SumOfReceiptPrices_ / DataOnReceiptPrices.NumberOfReceipts_1 * GoodsFromOrder.ConversionFactorOfPackaging)
	|		AS NUMBER(31,2))                                              AS ReceiptPrice,
	|	DataOnReceiptPrices.OrderReceiptAmount                         AS OrderReceiptAmount,
	|	DataOnReceiptPrices.ManualDiscountAmountGoodsReceipt             AS ManualDiscountAmountGoodsReceipt,
	|	DataOnReceiptPrices.NumberOfReceipts_1                    AS NumberOfReceipts_1,
	|	NULL                                                              AS OrderQuantity_,
	|	NULL                                                              AS OrderPrice,
	|	NULL                                                              AS OrderAmount,
	|	NULL                                                              AS ManualOrderDiscountPercentage
	|INTO PriceVariances
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		LEFT JOIN DataOnReceiptPrices AS DataOnReceiptPrices
	|			ON GoodsFromOrder.PurchaseOrder = DataOnReceiptPrices.PurchaseOrder
	|			AND GoodsFromOrder.RowCode = DataOnReceiptPrices.RowCode
	|GROUP BY
	|	GoodsFromOrder.Products,
	|	GoodsFromOrder.Characteristic,
	|	GoodsFromOrder.PurchaseOrder,
	|	GoodsFromOrder.RowCode,
	|	GoodsFromOrder.OrderCurrency,
	|	DataOnReceiptPrices.OrderReceiptAmount,
	|	DataOnReceiptPrices.ManualDiscountAmountGoodsReceipt,
	|	DataOnReceiptPrices.NumberOfReceipts_1
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsFromOrder.PurchaseOrder                                      AS PurchaseOrder,
	|	GoodsFromOrder.RowCode                                            AS RowCode,
	|	GoodsFromOrder.OrderCurrency                                         AS OrderCurrency,
	|	GoodsFromOrder.Products                                         AS Products,
	|	GoodsFromOrder.Characteristic                                       AS Characteristic,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	GoodsFromOrder.Count                                           AS OrderQuantity_,
	|	GoodsFromOrder.Price                                                 AS OrderPrice,
	|	GoodsFromOrder.Sum                                                AS OrderAmount,
	|	GoodsFromOrder.PercentRateOfManualDiscount                                  AS ManualOrderDiscountPercentage
	|FROM
	|	GoodsFromOrder AS GoodsFromOrder
	|		LEFT JOIN DataOnReceiptPrices AS DataOnReceiptPrices
	|			ON GoodsFromOrder.PurchaseOrder = DataOnReceiptPrices.PurchaseOrder
	|			AND GoodsFromOrder.RowCode = DataOnReceiptPrices.RowCode
	|GROUP BY
	|	GoodsFromOrder.Products,
	|	GoodsFromOrder.Characteristic,
	|	GoodsFromOrder.PurchaseOrder,
	|	GoodsFromOrder.RowCode,
	|	GoodsFromOrder.OrderCurrency,
	|	GoodsFromOrder.Price,
	|	GoodsFromOrder.Sum,
	|	GoodsFromOrder.Count,
	|	GoodsFromOrder.PercentRateOfManualDiscount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PriceVariances.PurchaseOrder                          AS PurchaseOrder,
	|	PriceVariances.RowCode                                AS RowCode,
	|	PriceVariances.Products                             AS Products,
	|	PriceVariances.Characteristic                           AS Characteristic,
	|	PriceVariances.OrderCurrency                             AS OrderCurrency,
	|	AVG(PriceVariances.OrderPrice)                      AS OrderPrice,
	|	SUM(PriceVariances.OrderAmount)                       AS OrderAmount,
	|	SUM(PriceVariances.ReceiptPrice)                   AS ReceiptPrice,
	|	SUM(PriceVariances.OrderReceiptAmount)                  AS OrderReceiptAmount,
	|	SUM(PriceVariances.ManualDiscountAmountGoodsReceipt)      AS ManualDiscountAmountGoodsReceipt,
	|	CASE
	|		WHEN AVG(PriceVariances.OrderPrice) = 0
	|				OR SUM(PriceVariances.ReceiptPrice) = 0
	|			THEN 0
	|		ELSE SUM(PriceVariances.ReceiptPrice) * 100 / AVG(PriceVariances.OrderPrice) - 100
	|	END AS PercentageOfDeviationFromTheOrderPrice,
	|	CASE
	|		WHEN SUM(PriceVariances.OrderAmount) = 0
	|				OR SUM(PriceVariances.OrderReceiptAmount) = 0
	|			THEN 0
	|		ELSE SUM(PriceVariances.OrderReceiptAmount) * 100 / SUM(PriceVariances.OrderAmount) - 100
	|	END                                                  AS PercentageOfDeviationFromTheOrderAmount,
	|	CASE
	|		WHEN AVG(PriceVariances.OrderPrice) <> 0
	|				AND SUM(PriceVariances.ReceiptPrice) <> 0
	|				AND SUM(PriceVariances.ReceiptPrice) < AVG(PriceVariances.OrderPrice)
	|			THEN 3
	|		WHEN AVG(PriceVariances.OrderPrice) <> 0
	|				AND SUM(PriceVariances.ReceiptPrice) <> 0
	|				AND SUM(PriceVariances.ReceiptPrice) > AVG(PriceVariances.OrderPrice)
	|			THEN 1
	|		ELSE 8
	|	END                                                  AS PictureIndex,
	|	CASE
	|		WHEN SUM(PriceVariances.OrderAmount) <> 0
	|				AND SUM(PriceVariances.OrderReceiptAmount) < SUM(PriceVariances.OrderAmount)
	|			THEN 3
	|		WHEN SUM(PriceVariances.OrderAmount) <> 0
	|				AND SUM(PriceVariances.OrderReceiptAmount) > SUM(PriceVariances.OrderAmount)
	|			THEN 1
	|		ELSE 8
	|	END                                                  AS AmountImageIndex,
	|	CASE
	|		WHEN SUM(PriceVariances.ReceiptPrice) <> 0
	|				AND AVG(PriceVariances.OrderPrice) <> 0
	|				AND SUM(PriceVariances.ReceiptPrice) <> AVG(PriceVariances.OrderPrice)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                  AS PriceChanged,
	|	CASE
	|		WHEN MAX(PriceVariances.OrderQuantity_) = SUM(PriceVariances.NumberOfReceipts_1)
	|				AND SUM(PriceVariances.OrderAmount) <> 0
	|				AND SUM(PriceVariances.OrderReceiptAmount) <> 0
	|				AND SUM(PriceVariances.OrderReceiptAmount) <> SUM(PriceVariances.OrderAmount)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                  AS TheAmountHasChanged,
	|	MAX(PriceVariances.ManualOrderDiscountPercentage)      AS ManualOrderDiscountPercentage,
	|	MAX(PriceVariances.PercentageOfManualReceiptDiscount) AS PercentageOfManualReceiptDiscount
	|FROM
	|	PriceVariances AS PriceVariances
	|
	|GROUP BY
	|	PriceVariances.PurchaseOrder,
	|	PriceVariances.RowCode,
	|	PriceVariances.Products,
	|	PriceVariances.Characteristic,
	|	PriceVariances.OrderCurrency
	|
	|HAVING
	|	(SUM(PriceVariances.ReceiptPrice) <> 0 AND AVG(PriceVariances.OrderPrice) <> SUM(PriceVariances.ReceiptPrice))
	|	OR (SUM(PriceVariances.ReceiptPrice) = 0 AND AVG(PriceVariances.OrderPrice) <> SUM(PriceVariances.ReceiptPrice))
	|		OR ((MAX(PriceVariances.OrderQuantity_) = SUM(PriceVariances.NumberOfReceipts_1)
	|			AND SUM(PriceVariances.OrderAmount) <> SUM(PriceVariances.OrderReceiptAmount)))");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsFromOrder.Package",
		"GoodsFromOrder.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"PurchaseOfGoodsServicesGoods.Package",
		"PurchaseOfGoodsServicesGoods.Products"));
	
	TwoWayIsUsed = GetFunctionalOption("UseGoodsInTransitFromVendors")
		Or GetFunctionalOption("UseImportedPurchasesOfGoodsInTransit")
		Or GetFunctionalOption("UseImportOfGoodsFromCustomsUnionGoodsInTransit")
		Or GetFunctionalOption("UseImportOfGoodsFromCustomsUnionUninvoicedDeliveries")
		Or GetFunctionalOption("UseUninvoicedDeliveries");
	
	Query.SetParameter("PurchaseOrders", Orders.UnloadValues());
	Query.SetParameter("ReceiptDocuments", Orders.UnloadValues());
	Query.SetParameter("TwoWayIsUsed", TwoWayIsUsed);
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("PurchaseOrders",
																"PurchaseOrder IN (&PurchaseOrders)",
																Query.Parameters);
	
	Query.SetParameter("InitialOrdersToSuppliers", SpeedLimits.MinDate);
	Query.SetParameter("CounterOrdersToSuppliers", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[0].Select();
	TableGoodsToCancel = Result[1].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[2].Unload();
	Table1TwoWayDivergence = Result[4].Unload();
	TwoWayDivergenceProducts.Load(Table1TwoWayDivergence);
	PriceVariances.Load(Result[14].Unload());
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Warehouse, OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0
		And PriceVariances.Count() = 0
		And Table1TwoWayDivergence.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillDeviationsOnCustomerOrders(TableOfGoodsExpense)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	SalesOrder.Ref AS SalesOrder
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.Ref IN (&CustomerOrders)
	|	AND SalesOrder.Status <> VALUE(Enum.SalesOrderStatuses.Closed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShippingOrdersTurnover.ReferenceOrder AS SalesOrder,
	|	ShippingOrdersTurnover.Products AS Products,
	|	ShippingOrdersTurnover.Characteristic AS Characteristic,
	|	ShippingOrdersTurnover.Warehouse AS Warehouse,
	|	ShippingOrdersTurnover.Series AS Series,
	|	SUM(ShippingOrdersTurnover.QuantityToBeShippedTurnover) -
	|		SUM(ShippingOrdersTurnover.ShippedQuantityTurnover) AS ToRegisterClosingBalance,
	|	SUM(ShippingOrdersTurnover.QuantityToBeShippedTurnover) AS ToRegisterReceipt
	|INTO TTOrdersForShipmentTurnover
	|FROM
	|	#ShipmentOrdersTurnoverExpanded1 AS ShippingOrdersTurnover
	|GROUP BY
	|	ShippingOrdersTurnover.ReferenceOrder,
	|	ShippingOrdersTurnover.Products,
	|	ShippingOrdersTurnover.Characteristic,
	|	ShippingOrdersTurnover.Warehouse,
	|	ShippingOrdersTurnover.Series
	|HAVING
	|	SUM(ShippingOrdersTurnover.QuantityToBeShippedTurnover) -
	|		SUM(ShippingOrdersTurnover.ShippedQuantityTurnover) <> 0
	|	OR SUM(ShippingOrdersTurnover.QuantityToBeShippedTurnover) <> 0
	|
	|INDEX BY
	|	SalesOrder,
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS OrderDocument,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Count AS Count,
	|	TRUE AS ThisIsShipment
	|FROM
	|	Document.SalesOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&CustomerOrders)
	|	AND (GoodsTable.Ref.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
	|	OR GoodsTable.SupplyOption <> VALUE(Enum.SupplyOptions.Ship))
	|	AND NOT GoodsTable.Ref.ThisIsOrderAsInvoice
	|	AND NOT GoodsTable.Canceled
	|	AND NOT GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssueBalance.OrderDocument AS OrderDocument,
	|	GoodsForIssueBalance.Products AS Products,
	|	GoodsForIssueBalance.Characteristic AS Characteristic,
	|	GoodsForIssueBalance.Series AS Series,
	|	GoodsForIssueBalance.Warehouse AS Warehouse,
	|	CASE
	|		WHEN SUM(GoodsForIssueBalance.ToShipmentInExcessOfOrder) >= SUM(GoodsForIssueBalance.Count)
	|			THEN 0
	|		ELSE SUM(GoodsForIssueBalance.Count) - SUM(GoodsForIssueBalance.ToShipmentInExcessOfOrder)
	|	END AS Count,
	|	SUM(GoodsForIssueBalance.AllowableVariance) AS AllowableVariance
	|FROM
	|	(SELECT
	|		GoodsForIssueBalance.DocumentShipments AS OrderDocument,
	|		GoodsForIssueBalance.Products AS Products,
	|		GoodsForIssueBalance.Characteristic AS Characteristic,
	|		GoodsForIssueBalance.Series AS Series,
	|		GoodsForIssueBalance.Warehouse AS Warehouse,
	|		GoodsForIssueBalance.ToShipExpense + GoodsForIssueBalance.AssembledReceipt +
	|			GoodsForIssueBalance.AssemblyInProgressReceipt AS Count,
	|		GoodsForIssueBalance.ToShipReceipt AS ToShipmentInExcessOfOrder,
	|		0 AS AllowableVariance
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(&InitialGoodsForShipment, &ConPeriodGoodsReadyForShipment,,,
	|			DocumentShipments IN (&CustomerOrders)
	|		AND Products.ItemsType NOT IN
	|		(VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))) AS
	|			GoodsForIssueBalance
	|
	|	UNION ALL
	|
	|	SELECT
	|		RequirementsForRegistration_1.ReferenceOrder AS OrderDocument,
	|		RequirementsForRegistration_1.Products AS Products,
	|		RequirementsForRegistration_1.Characteristic AS Characteristic,
	|		RequirementsForRegistration_1.Series AS Series,
	|		RequirementsForRegistration_1.Warehouse AS Warehouse,
	|		0 AS Count,
	|		-RequirementsForRegistration_1.QuantityToBeShippedTurnover AS ToShipmentInExcessOfOrder,
	|		0 AS AllowableVariance
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS RequirementsForRegistration_1) AS GoodsForIssueBalance
	|GROUP BY
	|	GoodsForIssueBalance.OrderDocument,
	|	GoodsForIssueBalance.Products,
	|	GoodsForIssueBalance.Characteristic,
	|	GoodsForIssueBalance.Series,
	|	GoodsForIssueBalance.Warehouse
	|
	|UNION ALL
	|
	|SELECT
	|	SalesOrdersBalance.ReferenceOrder AS OrderDocument,
	|	SalesOrdersBalance.Products AS Products,
	|	SalesOrdersBalance.Characteristic AS Characteristic,
	|	SalesOrdersBalance.Series AS Series,
	|	SalesOrdersBalance.Warehouse AS Warehouse,
	|	SalesOrdersBalance.ShippedQuantityTurnover AS Count,
	|	0 AS AllowableVariance
	|FROM
	|	#ShipmentOrdersTurnoverExpanded3 AS SalesOrdersBalance
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForIssue.ReferenceOrder AS OrderDocument,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Series AS Series,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	0,
	|	SUM(GoodsForIssue.QuantityToBeShippedTurnover * (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
	|FROM
	|	#ShipmentOrdersTurnoverExpanded4 AS GoodsForIssue
	|GROUP BY
	|	GoodsForIssue.ReferenceOrder,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Warehouse
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerOrderGoods.Ref,
	|	CustomerOrderGoods.Products,
	|	CustomerOrderGoods.Characteristic,
	|	CustomerOrderGoods.Series,
	|	CustomerOrderGoods.Warehouse,
	|	GoodsAndServicesToRegisterPurchasingReportsToConsignorBalance.CountBalance,
	|	0
	|FROM
	|	Document.SalesOrder.Goods AS CustomerOrderGoods
	|		INNER JOIN AccumulationRegister.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Balance AS
	|			GoodsAndServicesToRegisterPurchasingReportsToConsignorBalance
	|		ON (CustomerOrderGoods.Ref.Purpose = GoodsAndServicesToRegisterPurchasingReportsToConsignorBalance.Purpose)
	|		AND (CustomerOrderGoods.Products = GoodsAndServicesToRegisterPurchasingReportsToConsignorBalance.Products)
	|WHERE
	|	CustomerOrderGoods.Ref IN (&CustomerOrders)
	|	AND
	|		CustomerOrderGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS OrderDocument,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Count AS Count
	|INTO TTActualProductsOrders
	|FROM
	|	Document.SalesOrder.Goods AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.OrderDocument AS OrderDocument,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Count AS Count,
	|	SalesOrdersBalance.ToRegisterClosingBalance AS ToRegisterBalance,
	|	CASE
	|		WHEN GoodsTable.Count > SalesOrdersBalance.ToRegisterReceipt
	|			THEN GoodsTable.Count - SalesOrdersBalance.ToRegisterReceipt
	|		ELSE 0
	|	END AS QuantityInExcessOfIssued,
	|	GoodsTable.Series AS Series,
	|	TRUE AS ThisIsShipment
	|FROM
	|	TTActualProductsOrders AS GoodsTable
	|		INNER JOIN TTOrdersForShipmentTurnover AS SalesOrdersBalance
	|		ON GoodsTable.OrderDocument = SalesOrdersBalance.SalesOrder
	|		AND GoodsTable.Products = SalesOrdersBalance.Products
	|		AND GoodsTable.Characteristic = SalesOrdersBalance.Characteristic
	|		AND GoodsTable.Warehouse = SalesOrdersBalance.Warehouse
	|		AND GoodsTable.Series = SalesOrdersBalance.Series
	|
	|ORDER BY
	|	ToRegisterBalance ASC");
	
	// Subquery #of the order of the offload turnout1
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&CustomerOrders)
		|		AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	// Subquery #dispositioningrelease turnoversrefoot2
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&CustomerOrders)
		|		AND RowCode <> 0
		|		AND Products.ItemsType NOT IN
		|			(VALUE(Enum.ItemsTypes.OperationService),
		|			VALUE(Enum.ItemsTypes.Work_5))";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	// Subquery #dispositioningrelease rotations3
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&CustomerOrders)
		|		AND Products.ItemsType IN
		|			(VALUE(Enum.ItemsTypes.OperationService),
		|			VALUE(Enum.ItemsTypes.Work_5))";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded3 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded3",
		ShipmentOrdersTurnoverExpanded3);
	
	// Subquery #dispositioningrelease turnovers 4
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&CustomerOrders)
		|		AND RowCode <> 0
		|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded4 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded4",
		ShipmentOrdersTurnoverExpanded4);
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("CustomerOrders", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("ShipmentAndReturnReferences",
																"ReferenceOrder IN (&CustomerOrders)",
																Query.Parameters);
	
	Query.SetParameter("InitialCustomerOrders", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodCustomerOrders", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsForIssue",
																"DocumentShipments IN (&CustomerOrders)",
																Query.Parameters);
	
	Query.SetParameter("InitialGoodsForShipment", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodGoodsReadyForShipment", SpeedLimits.MaxDate);
	
	ByDocument = Orders.Count() = 1 And Orders[0].Value = DocumentInitiator;
	
	RequestTextForSubstitution =
	"SELECT
	|	GoodsTable.Ref AS OrderDocument,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Count AS Count
	|INTO TTActualProductsOrders
	|FROM
	|	Document.SalesOrder.Goods AS GoodsTable";
	
	Query.SetParameter("ByDocument", ByDocument);
	If ByDocument Then
		
		Query.Text = StrReplace(Query.Text,
			RequestTextForSubstitution,
			"SELECT
			|	&OrderDocument AS Ref,
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Series AS Series,
			|	Table.Count AS Count,
			|	Table.Canceled AS Canceled,
			|	Table.SupplyOption AS SupplyOption
			|INTO TTProducts_1
			|FROM
			|	&Goods AS Table
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GoodsTable.Ref AS OrderDocument,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Warehouse AS Warehouse,
			|	GoodsTable.Series AS Series,
			|	SUM(GoodsTable.Count) AS Count
			|INTO TTActualProductsOrders
			|FROM
			|	TTProducts_1 AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN (&CustomerOrders)
			|	AND NOT GoodsTable.Ref.ThisIsOrderAsInvoice
			|	AND GoodsTable.Ref.Status NOT IN (VALUE(Enum.SalesOrderStatuses.NotApproved),
			|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon),
			|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
			|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
			|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|	AND NOT GoodsTable.Canceled
			|GROUP BY
			|	GoodsTable.Ref,
			|	GoodsTable.Products,
			|	GoodsTable.Characteristic,
			|	GoodsTable.Warehouse,
			|	GoodsTable.Series");
		
		Query.SetParameter("Goods",TableOfGoodsExpense);
		
		Query.SetParameter("OrderDocument",DocumentInitiator);
		
		NumberOfRequests_ = 6;
		
	Else
		
		Query.Text = StrReplace(Query.Text,
			RequestTextForSubstitution,
			"SELECT
			|	GoodsTable.Ref AS OrderDocument,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Warehouse AS Warehouse,
			|	GoodsTable.Series AS Series,
			|	SUM(GoodsTable.Count) AS Count
			|INTO TTActualProductsOrders
			|FROM
			|	Document.SalesOrder.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN (&CustomerOrders)
			|	AND NOT GoodsTable.Ref.ThisIsOrderAsInvoice
			|	AND NOT GoodsTable.Ref.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
			|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|GROUP BY
			|	GoodsTable.Ref,
			|	GoodsTable.Products,
			|	GoodsTable.Characteristic,
			|	GoodsTable.Warehouse,
			|	GoodsTable.Series");
		
		NumberOfRequests_ = 5;
	EndIf;
	
	Result             = Query.ExecuteBatch();
	SampleOrders         = Result[0].Select();
	SelectionToCancel        = Result[2].Select();
	ShippedGoods_     = Result[3].Unload();
	Selection               = Result[NumberOfRequests_].Select();
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
	ShippedGoods_.GroupBy("OrderDocument, Products, Characteristic, Series, Warehouse","Count, AllowableVariance");
	
	SetPrivilegedMode(False);
	
	ListOfPropertiesReadyToCancel = "OrderDocument,Products,Characteristic,Warehouse,Series,ThisIsShipment,Count";
	
	// Cancel directly
	
	While SelectionToCancel.Next() Do
		
		NwRw = GoodsForCancellation.Add();
		FillPropertyValues(NwRw, SelectionToCancel, ListOfPropertiesReadyToCancel);
		NwRw.Ordered = NwRw.Count;
		
	EndDo;
	
	// Canceling lines
	
	While Selection.Next() Do
		
		SearchParameters = New Structure();
		SearchParameters.Insert("OrderDocument", Selection.OrderDocument);
		SearchParameters.Insert("Products", Selection.Products);
		SearchParameters.Insert("Characteristic", Selection.Characteristic);
		SearchParameters.Insert("Warehouse", Selection.Warehouse);
		SearchParameters.Insert("Series", Selection.Series);
			
		ShippedQuantity_ = 0;
		AllowableVariance  = 0;
		ShippedLine     = Undefined;
		
		FoundRows = ShippedGoods_.FindRows(SearchParameters);
		If FoundRows.Count() > 0 Then
			ShippedLine = FoundRows[0];
			ShippedQuantity_ = ShippedLine.Count;
			AllowableVariance = ShippedLine.AllowableVariance;
		EndIf;
		
		CancelQuantity = 0;
		
		If Selection.Count >= ShippedQuantity_ Then
			CancelQuantity = Min(Selection.ToRegisterBalance, Selection.Count - ShippedQuantity_);
			If ShippedLine <> Undefined Then
				If ShippedQuantity_ >
						(Selection.Count - Selection.QuantityInExcessOfIssued - Selection.ToRegisterBalance) Then
					ShippedLine.Count = ShippedQuantity_ - (Selection.Count
						- Selection.QuantityInExcessOfIssued - Selection.ToRegisterBalance);
				Else
					ShippedLine.Count = 0;
				EndIf;
			EndIf;
		Else
			ShippedLine.Count = ShippedLine.Count - Selection.Count;
		EndIf;
		
		If CancelQuantity <= AllowableVariance Then
			DeviationWithinDelta = True;
			ShippedLine.AllowableVariance = ShippedLine.AllowableVariance - CancelQuantity;
		Else
			DeviationWithinDelta = False;
		EndIf;
		
		If CancelQuantity = Selection.Count Then
			NewRow = GoodsForCancellation.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Ordered    = NewRow.Count;
		ElsIf CancelQuantity > 0 Then
			
			CancelQuantity = CancelQuantity + Selection.QuantityInExcessOfIssued;
			
			If DeviationWithinDelta Then
				NewRow = MeasuringGoodsForAdjustment.Add();
				Multiplier = -1;
			Else
				NewRow = GoodsForCancellation.Add();
				Multiplier = 1;
			EndIf;
			
			FillPropertyValues(NewRow, Selection, ListOfPropertiesReadyToCancel);
			
			NewRow.Count  = Multiplier*CancelQuantity;
			NewRow.Ordered    = Selection.Count;
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	// We adjust in plus
	
	If CorrectMeasuringGoods Then
		
		Selection.Reset();
		
		While Selection.Next() Do
			
			SearchParameters = New Structure("OrderDocument, Products, Characteristic, Warehouse, Series");
			FillPropertyValues(SearchParameters, Selection);
			
			FoundRows = ShippedGoods_.FindRows(SearchParameters);
			If FoundRows.Count() > 0 
				And FoundRows[0].Count > 0 Then
				ShippedLine = FoundRows[0];
				ShippedOverLine = ShippedLine.Count;
			Else
				Continue;
			EndIf;
			
			If Selection.ToRegisterBalance < 0 And ShippedOverLine > 0 Then
				
				QuantityReissued = -Selection.ToRegisterBalance;
				
				If QuantityReissued >= ShippedOverLine Then
					ShippedLine.Count = 0;
					QuantityAdd = ShippedOverLine;
				Else
					ShippedLine.Count = ShippedLine.Count - QuantityReissued;
					QuantityAdd = QuantityReissued;
				EndIf;
				
				NwRw = MeasuringGoodsForAdjustment.Add();
				FillPropertyValues(NwRw,Selection);
				NwRw.Count = QuantityAdd;
				NwRw.Ordered = Selection.Count;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If SampleOrders.Count() = 0 And
		GoodsForCancellation.Count() = 0 And
		MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;

EndProcedure

&AtServer
Procedure FillDeviationsOnDomesticConsumptionOrders()
	
	Query = New Query(
	"SELECT
	|	InventoryConsumptionOrder.Ref AS OrderDocument
	|FROM
	|	Document.InventoryConsumptionOrder AS InventoryConsumptionOrder
	|WHERE
	|	InventoryConsumptionOrder.Ref IN(&InventoryConsumptionOrders)
	|	AND InventoryConsumptionOrder.Status <> VALUE(Enum.InternalOrderStatuses.Closed)
	|
	|UNION ALL
	|
	|SELECT
	|	RMOrder.Ref
	|FROM
	|	Document.RMOrder AS RMOrder
	|WHERE
	|	RMOrder.Ref IN(&InventoryConsumptionOrders)
	|	AND RMOrder.Status <> VALUE(Enum.RMOrderStatuses.Closed)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	Balance.Series,
	|	SUM(Balance.ToRegisterBalance),
	|	CASE
	|		WHEN SUM(Balance.ToShipmentInExcessOfOrder) >= SUM(Balance.ToShipBalance)
	|			THEN 0
	|		ELSE SUM(Balance.ToShipBalance) - SUM(Balance.ToShipmentInExcessOfOrder)
	|	END AS ToShipBalance,
	|	SUM(Balance.Ordered),
	|	SUM(Balance.ForCompletion)
	|INTO TTBalance
	|FROM (SELECT
	|		RequirementsForRegistration_1.InventoryConsumptionOrder AS OrderDocument,
	|		RequirementsForRegistration_1.Products                 AS Products,
	|		RequirementsForRegistration_1.Characteristic               AS Characteristic,
	|		RequirementsForRegistration_1.Warehouse                        AS Warehouse,
	|		RequirementsForRegistration_1.Series                        AS Series,
	|		RequirementsForRegistration_1.ToRegisterClosingBalance   AS ToRegisterBalance,
	|		0                                               AS ToShipBalance,
	|		- RequirementsForRegistration_1.ToRegisterReceipt          AS ToShipmentInExcessOfOrder,
	|		RequirementsForRegistration_1.OrderedReceipt               AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- RequirementsForRegistration_1.ToRegisterReceipt      AS ForCompletion
	|	FROM
	|		AccumulationRegister.InventoryConsumptionOrders.BalanceAndTurnovers(&StartPeriod_,&ConPeriod,,,
	|			InventoryConsumptionOrder IN (&InventoryConsumptionOrders) AND RowCode <> 0) AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesForShipment.DocumentShipments         AS OrderDocument,
	|		BalancesForShipment.Products             AS Products,
	|		BalancesForShipment.Characteristic           AS Characteristic,
	|		BalancesForShipment.Warehouse                    AS Warehouse,
	|		BalancesForShipment.Series                    AS Series,
	|		0                                         AS ToRegisterBalance,
	|		BalancesForShipment.ToShipClosingBalance AS ToShipBalance,
	|		BalancesForShipment.ToShipReceipt          AS ToShipmentInExcessOfOrder,
	|		0                                         AS Ordered,
	|		0                                         AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(&ReadyToShipPeriod,&ConPeriodToShipment,,,
	|			DocumentShipments IN (&InventoryConsumptionOrders)) AS BalancesForShipment) AS Balance
	|GROUP BY
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.ToShipBalance
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.ToShipBalance
	|	END + Balance.ForCompletion AS Count,
	|	TRUE AS ThisIsShipment,
	|	Balance.Ordered
	|FROM TTBalance AS Balance
	|WHERE
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.ToShipBalance
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.ToShipBalance
	|	END + Balance.ForCompletion <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products                 AS Products,
	|	GoodsForIssue.Characteristic               AS Characteristic,
	|	GoodsForIssue.Series                        AS Series,
	|	GoodsForIssue.Warehouse                        AS Warehouse,
	|	GoodsForIssue.InventoryConsumptionOrder AS OrderDocument,
	|	SUM(GoodsForIssue.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.InventoryConsumptionOrders.Turnovers(&StartPeriod_,&ConPeriod,,
	|		InventoryConsumptionOrder IN (&InventoryConsumptionOrders)) AS GoodsForIssue
	|WHERE
	|	GoodsForIssue.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.InventoryConsumptionOrder");
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
	
	Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("InventoryConsumptionOrders", Orders.UnloadValues());
	
	SetPrivilegedMode(True);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("InventoryConsumptionOrders",
		"InventoryConsumptionOrder IN (&InventoryConsumptionOrders)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsForIssue",
		"DocumentShipments IN (&InventoryConsumptionOrders)", Query.Parameters);
	
	Query.SetParameter("ReadyToShipPeriod", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodToShipment", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[0].Select();
	TableGoodsToCancel = Result[2].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[3].Unload();
	
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Series,Warehouse,OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDeviationsForMovingOrders()
	
	Query = New Query(
	"SELECT
	|	TransferOrder.Ref AS SalesOrder
	|FROM
	|	Document.TransferOrder AS TransferOrder
	|WHERE
	|	TransferOrder.Ref IN(&TransferOrders)
	|	AND TransferOrder.Status <> VALUE(Enum.InternalOrderStatuses.Closed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.OrderDocument.SourceWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.OrderDocument.SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	SUM(Balance.ToRegisterBalance),
	|	SUM(Balance.ToShipBalance) AS ToShipBalance,
	|	SUM(Balance.Ordered),
	|	SUM(Balance.ForCompletion)
	|INTO TTBalance
	|FROM (SELECT
	|		RequirementsForRegistration_1.TransferOrder         AS OrderDocument,
	|		RequirementsForRegistration_1.Products               AS Products,
	|		RequirementsForRegistration_1.Characteristic             AS Characteristic,
	|		RequirementsForRegistration_1.Series                      AS Series,
	|		RequirementsForRegistration_1.ToRegisterClosingBalance AS ToRegisterBalance,
	|		0                                             AS ToShipBalance,
	|		- RequirementsForRegistration_1.ToRegisterReceipt        AS ToShipmentInExcessOfOrder,
	|		RequirementsForRegistration_1.OrderedReceipt             AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- RequirementsForRegistration_1.ToRegisterReceipt    AS ForCompletion
	|	FROM
	|		AccumulationRegister.TransferOrders.BalanceAndTurnovers(&StartPeriod_,&ConPeriod,,,
	|			TransferOrder IN (&TransferOrders) AND RowCode <> 0) AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesForShipment.DocumentShipments         AS OrderDocument,
	|		BalancesForShipment.Products             AS Products,
	|		BalancesForShipment.Characteristic           AS Characteristic,
	|		BalancesForShipment.Series                    AS Series,
	|		0                                         AS ToRegisterBalance,
	|		BalancesForShipment.ToShipClosingBalance AS ToShipBalance,
	|		BalancesForShipment.ToShipReceipt          AS ToShipmentInExcessOfOrder,
	|		0                                         AS Ordered,
	|		0                                         AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(&ReadyToShipPeriod,&ConPeriodToShipment,,,
	|			DocumentShipments IN (&TransferOrders)) AS BalancesForShipment) AS Balance
	|GROUP BY
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.OrderDocument.SourceWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.OrderDocument.SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Series,
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.ToShipBalance
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.ToShipBalance
	|	END + Balance.ForCompletion AS Count,
	|	Balance.Ordered,
	|	Balance.OrderDocument.SourceWarehouse AS Warehouse,
	|	TRUE AS ThisIsShipment
	|FROM TTBalance AS Balance
	|WHERE
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.ToShipBalance
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.ToShipBalance
	|	END + Balance.ForCompletion <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products       AS Products,
	|	GoodsForIssue.Characteristic     AS Characteristic,
	|	GoodsForIssue.Series              AS Series,
	|	GoodsForIssue.TransferOrder AS OrderDocument,
	|	SUM(GoodsForIssue.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance,
	|	TRUE                             AS ThisIsShipment
	|FROM
	|	AccumulationRegister.TransferOrders.Turnovers(&StartPeriod_,&ConPeriod,,
	|		TransferOrder IN (&TransferOrders)) AS GoodsForIssue
	|WHERE
	|	GoodsForIssue.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.TransferOrder");
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("TransferOrders", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SetPrivilegedMode(True);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("TransferOrders",
		"TransferOrder IN (&TransferOrders)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsForIssue",
		"DocumentShipments IN (&TransferOrders)", Query.Parameters);
	
	Query.SetParameter("ReadyToShipPeriod", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodToShipment", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[0].Select();
	TableGoodsToCancel = Result[2].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[3].Unload();
	
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Series,OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDeviationsForAssemblyOrders()
	
	Query = New Query(
	"SELECT
	|	ByAssemblyDisassemblyOrder.Ref AS ByAssemblyDisassemblyOrder
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
	|WHERE
	|	ByAssemblyDisassemblyOrder.Ref IN(&AssemblyOrders)
	|	AND ByAssemblyDisassemblyOrder.Status <> VALUE(Enum.InternalOrderStatuses.Closed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.ThisIsShipment,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.AssemblyDisassemblyStart >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnGoodsReceipt,
	|	SUM(Balance.ToRegisterBalance),
	|	SUM(Balance.BalanceOnOrders),
	|	SUM(Balance.Ordered),
	|	SUM(Balance.ForCompletion)
	|INTO TTBalance
	|FROM (SELECT
	|		RequirementsForRegistration_1.ByAssemblyDisassemblyOrder              AS OrderDocument,
	|		RequirementsForRegistration_1.Products               AS Products,
	|		RequirementsForRegistration_1.Characteristic             AS Characteristic,
	|		CASE 
	|			WHEN RequirementsForRegistration_1.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment) 
	|				THEN TRUE
	|			ELSE FALSE 
	|		END                                         AS ThisIsShipment,
	|		RequirementsForRegistration_1.ByAssemblyDisassemblyOrder.Warehouse        AS Warehouse,
	|		RequirementsForRegistration_1.Series                      AS Series,
	|		RequirementsForRegistration_1.ToRegisterClosingBalance AS ToRegisterBalance,
	|		0                                             AS BalanceOnOrders,
	|		RequirementsForRegistration_1.OrderedReceipt             AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- RequirementsForRegistration_1.ToRegisterReceipt    AS ForCompletion
	|	FROM
	|		AccumulationRegister.AssemblyOrders.BalanceAndTurnovers(&InitialBuildOrders, &ConPeriodAssemblyOrders,
	|			,, ByAssemblyDisassemblyOrder IN (&AssemblyOrders) AND RowCode <> 0) AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesForShipment.DocumentShipments AS OrderDocument,
	|		BalancesForShipment.Products     AS Products,
	|		BalancesForShipment.Characteristic   AS Characteristic,
	|		TRUE                            AS ThisIsShipment,
	|		BalancesForShipment.Warehouse            AS Warehouse,
	|		BalancesForShipment.Series            AS Series,
	|		0                                 AS ToRegisterBalance,
	|		BalancesForShipment.ToShipBalance AS BalanceOnOrders,
	|		0                                 AS Ordered,
	|		0                                 AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN (&AssemblyOrders)) AS BalancesForShipment
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesDue.DocumentInflow             AS OrderDocument,
	|		BalancesDue.Products                    AS Products,
	|		BalancesDue.Characteristic                  AS Characteristic,
	|		FALSE                                                AS ThisIsShipment,
	|		BalancesDue.Warehouse                           AS Warehouse,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|		0                                                   AS ToRegisterBalance,
	|		BalancesDue.GoodsReceiptNotesToRegisterBalance       AS BalanceOnOrders,
	|		0                                                   AS Ordered,
	|		0                                                   AS Issued_1
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(,
	|			DocumentInflow IN (&AssemblyOrders)) AS BalancesDue) AS Balance
	|GROUP BY
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.ThisIsShipment,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.AssemblyDisassemblyStart >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.ThisIsShipment,
	|	Balance.Series,
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR (Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnShipment)
	|			OR (NOT Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnGoodsReceipt) THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion AS Count,
	|	Balance.Ordered
	|FROM TTBalance AS Balance
	|WHERE
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR (Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnShipment)
	|			OR (NOT Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnGoodsReceipt) THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products                 AS Products,
	|	GoodsForIssue.Characteristic               AS Characteristic,
	|	GoodsForIssue.Series                        AS Series,
	|	CASE
	|		WHEN GoodsForIssue.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment) 
	|			THEN TRUE
	|		ELSE FALSE 
	|	END                                        AS ThisIsShipment,
	|	GoodsForIssue.ByAssemblyDisassemblyOrder                AS OrderDocument,
	|	GoodsForIssue.ByAssemblyDisassemblyOrder.Warehouse          AS Warehouse,
	|	SUM(GoodsForIssue.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.AssemblyOrders.Turnovers(&InitialBuildOrders,&ConPeriodAssemblyOrders,
	|		, ByAssemblyDisassemblyOrder IN (&AssemblyOrders)) AS GoodsForIssue
	|WHERE
	|	GoodsForIssue.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	CASE
	|		WHEN GoodsForIssue.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment) 
	|			THEN TRUE
	|		ELSE FALSE 
	|	END,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.ByAssemblyDisassemblyOrder");
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AssemblyOrders", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SetPrivilegedMode(True);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("AssemblyOrders",
		"ByAssemblyDisassemblyOrder IN (&AssemblyOrders)", Query.Parameters);
	
	Query.SetParameter("InitialBuildOrders", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodAssemblyOrders", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[0].Select();
	TableGoodsToCancel = Result[2].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[3].Unload();
	
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Series,Warehouse,ThisIsShipment,OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDeviationsOnRequestsForReturnOfGoodsFromClient(TableOfGoodsReceipt, TableOfGoodsExpense)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	RequestForReturnOfGoodsFromCustomer.Ref AS RequestForReturnOfGoodsFromCustomer
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|WHERE
	|	RequestForReturnOfGoodsFromCustomer.Ref IN(&RequestsForReturnOfGoodsFromClient)
	|	AND RequestForReturnOfGoodsFromCustomer.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed)
	|	AND &UseClosedStatus
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.ReferenceOrder AS OrderDocument,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	FALSE AS ThisIsShipment,
	|	SUM(GoodsToReceive.ForRegistrationOnReturnsQuantityTurnover
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	#RequestsForReturnsTurnoverExpanded1 AS GoodsToReceive
	|
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.ReferenceOrder,
	|	GoodsToReceive.Warehouse
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.ReferenceOrder AS OrderDocument,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	TRUE AS ThisIsShipment,
	|	SUM(GoodsForIssue.QuantityToBeShippedTurnover
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	#ShipmentOrdersTurnoverExpanded1 AS GoodsForIssue
	|
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	CASE
	|		WHEN Table.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN Table.Products
	|		ELSE Table.ProductsRecordingAsReceived
	|	END                  AS Products,
	|	CASE
	|		WHEN Table.CharacteristicRecordingAsReceived = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN Table.Characteristic
	|		ELSE Table.CharacteristicRecordingAsReceived
	|	END                  AS Characteristic,
	|	Table.Count     AS Count,
	|	Table.Warehouse          AS Warehouse,
	|	Table.Canceled       AS Canceled
	|INTO TTReturnItems
	|FROM &ReturnedGoods AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Count     AS Count,
	|	Table.Warehouse          AS Warehouse,
	|	Table.Canceled       AS Canceled
	|INTO TTReplacementProducts
	|FROM &SubstituteGoods AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Shipments.OrderDocument          AS OrderDocument,
	|	Shipments.Products   AS Products,
	|	Shipments.Characteristic AS Characteristic,
	|	Shipments.Warehouse          AS Warehouse,
	|	CASE
	|		WHEN Shipments.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Shipments.OrderDocument.Date >= Shipments.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END                   AS AdvancedWarehousingOnShipment,
	|	SUM(Shipments.Issued_1)      AS Issued_1,
	|	SUM(Shipments.Shipped)      AS Shipped,
	|	SUM(Shipments.Ordered)       AS Ordered
	|INTO TTShipped
	|FROM (SELECT
	|		Balance.ReferenceOrder AS OrderDocument,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.Warehouse AS Warehouse,
	|		SUM(Balance.ShippedQuantityTurnover) AS Issued_1,
	|		SUM(0) AS Shipped,
	|		SUM(CASE
	|			WHEN &ByDocument
	|				THEN 0
	|			ELSE
	|				Balance.OrderedQuantityTurnover
	|		END) AS Ordered
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS Balance
	|	GROUP BY
	|		Balance.ReferenceOrder,
	|		Balance.Products,
	|		Balance.Characteristic,
	|		Balance.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssueBalance.DocumentShipments                                     AS OrderDocument,
	|		GoodsForIssueBalance.Products                                         AS Products,
	|		GoodsForIssueBalance.Characteristic                                       AS Characteristic,
	|		GoodsForIssueBalance.Warehouse                                                AS Warehouse,
	|		0                                                                           AS Issued_1,
	|		GoodsForIssueBalance.ToShipExpense + GoodsForIssueBalance.AssembledReceipt
	|			+ GoodsForIssueBalance.AssemblyInProgressReceipt                               AS Shipped,
	|		0                                                                           AS Ordered
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(,,,,
	|			DocumentShipments IN (&RequestsForReturnOfGoodsFromClient)) AS GoodsForIssueBalance
	|
	|	UNION ALL
	|
	|	SELECT
	|		&OrderDocument                                                   AS OrderDocument,
	|		SubstituteGoods.Products                            AS Products,
	|		SubstituteGoods.Characteristic                          AS Characteristic,
	|		SubstituteGoods.Warehouse                                   AS Warehouse,
	|		0                                                        AS Issued_1,
	|		0                                                        AS Shipped,
	|		SUM(SubstituteGoods.Count)                       AS Ordered
	|	FROM
	|		TTReplacementProducts AS SubstituteGoods
	|	WHERE
	|		NOT SubstituteGoods.Canceled
	|	GROUP BY
	|		SubstituteGoods.Products,
	|		SubstituteGoods.Characteristic,
	|		SubstituteGoods.Warehouse
	|
	|	) AS Shipments
	|
	|GROUP BY
	|	Shipments.OrderDocument,
	|	CASE
	|		WHEN Shipments.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Shipments.OrderDocument.Date >= Shipments.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	Shipments.Products,
	|	Shipments.Characteristic,
	|	Shipments.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Inflow.OrderDocument          AS OrderDocument,
	|	Inflow.Products   AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	Inflow.Warehouse          AS Warehouse,
	|	CASE
	|		WHEN Inflow.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Inflow.OrderDocument.Date >= Inflow.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END                        AS AdvancedWarehousingOnReceiving,
	|	SUM(Inflow.Issued_1) AS Issued_1,
	|	SUM(Inflow.Accepted)   AS Accepted,
	|	SUM(Inflow.Ordered)  AS Ordered
	|INTO TTAccepted
	|FROM (SELECT
	|		Balance.ReferenceOrder AS OrderDocument,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.Warehouse AS Warehouse,
	|		Balance.IssuedByReturnsQuantityTurnover AS Issued_1,
	|		0 AS Accepted,
	|		CASE
	|			WHEN &ByDocument
	|				THEN 0
	|			ELSE Balance.QuantityRequestedForReturnTurnover
	|		END AS Ordered
	|	FROM
	|		#RequestsForReturnsTurnoverExpanded2 AS Balance
	|
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToReceiveBalance.DocumentInflow                                  AS OrderDocument,
	|		GoodsToReceiveBalance.Products                                         AS Products,
	|		GoodsToReceiveBalance.Characteristic                                       AS Characteristic,
	|		GoodsToReceiveBalance.Warehouse                                                AS Warehouse,
	|		0                                                                              AS Issued_1,
	|		GoodsToReceiveBalance.GoodsReceiptNotesToRegisterExpense                             AS Accepted,
	|		0                                                                              AS Ordered
	|	FROM
	|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(,,,,
	|			DocumentInflow IN (&RequestsForReturnOfGoodsFromClient)) AS GoodsToReceiveBalance
	|	
	|	UNION ALL
	|
	|	SELECT
	|		&OrderDocument                                                   AS OrderDocument,
	|		ReturnedGoods.Products                          AS Products,
	|		ReturnedGoods.Characteristic                        AS Characteristic,
	|		ReturnedGoods.Warehouse                                 AS Warehouse,
	|		0                                                        AS Issued_1,
	|		0                                                        AS Accepted,
	|		SUM(ReturnedGoods.Count)                     AS Ordered
	|	FROM
	|		TTReturnItems AS ReturnedGoods
	|	WHERE
	|		NOT ReturnedGoods.Canceled
	|	GROUP BY
	|		ReturnedGoods.Products,
	|		ReturnedGoods.Characteristic,
	|		ReturnedGoods.Warehouse
	|	) AS Inflow
	|
	|GROUP BY
	|	Inflow.OrderDocument,
	|	Inflow.Products,
	|	CASE
	|		WHEN Inflow.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Inflow.OrderDocument.Date >= Inflow.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	Inflow.Characteristic,
	|	Inflow.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Inflow.OrderDocument                                 AS OrderDocument,
	|	Inflow.Products                          AS Products,
	|	Inflow.Characteristic                        AS Characteristic,
	|	Inflow.Warehouse                                 AS Warehouse,
	|	FALSE                                              AS ThisIsShipment,
	|	Inflow.Ordered                              AS Ordered,
	|	CASE 
	|		WHEN Inflow.Ordered - Inflow.Issued_1 < 0 
	|			THEN Inflow.Ordered - Inflow.Issued_1
	|		WHEN NOT Inflow.AdvancedWarehousingOnReceiving 
	|			THEN  Inflow.Ordered - Inflow.Issued_1
	|		ELSE CASE 
	|					WHEN Inflow.Issued_1 > Inflow.Accepted
	|						THEN Inflow.Ordered - Inflow.Issued_1
	|					ELSE Inflow.Ordered - Inflow.Accepted
	|			END
	|	END                                              AS Count
	|FROM
	|	TTAccepted AS Inflow
	|WHERE CASE 
	|		WHEN Inflow.Ordered - Inflow.Issued_1 < 0 
	|			THEN Inflow.Ordered - Inflow.Issued_1
	|		WHEN NOT Inflow.AdvancedWarehousingOnReceiving 
	|			THEN  Inflow.Ordered - Inflow.Issued_1
	|		ELSE CASE 
	|					WHEN Inflow.Issued_1 > Inflow.Accepted
	|						THEN Inflow.Ordered - Inflow.Issued_1
	|					ELSE Inflow.Ordered - Inflow.Accepted
	|			END
	|	END <> 0
	|	
	|	
	|UNION ALL
	|	
	|SELECT
	|	Shipments.OrderDocument                                 AS OrderDocument,
	|	Shipments.Products                          AS Products,
	|	Shipments.Characteristic                        AS Characteristic,
	|	Shipments.Warehouse                                 AS Warehouse,
	|	TRUE                                         AS ThisIsShipment,
	|	Shipments.Ordered                              AS Ordered,
	|	CASE 
	|		WHEN Shipments.Ordered - Shipments.Issued_1 < 0 
	|			THEN Shipments.Ordered - Shipments.Issued_1
	|		WHEN NOT Shipments.AdvancedWarehousingOnShipment 
	|			THEN  Shipments.Ordered - Shipments.Issued_1
	|		ELSE CASE 
	|					WHEN Shipments.Issued_1 > Shipments.Shipped
	|						THEN Shipments.Ordered - Shipments.Issued_1
	|					ELSE Shipments.Ordered - Shipments.Shipped
	|			END
	|	END                                              AS Count
	|FROM
	|	TTShipped AS Shipments
	|WHERE	CASE 
	|		WHEN Shipments.Ordered - Shipments.Issued_1 < 0 
	|			THEN Shipments.Ordered - Shipments.Issued_1
	|		WHEN NOT Shipments.AdvancedWarehousingOnShipment 
	|			THEN  Shipments.Ordered - Shipments.Issued_1
	|		ELSE CASE 
	|					WHEN Shipments.Issued_1 > Shipments.Shipped
	|						THEN Shipments.Ordered - Shipments.Issued_1
	|					ELSE Shipments.Ordered - Shipments.Shipped
	|			END
	|	END <> 0
	|");
	
	// Subquery #of the order of the offload turnout1
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&RequestsForReturnOfGoodsFromClient)
		|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse";
	TableFormationParameters.Indicators = "ToShip";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	// Subquery #dispositioningrelease turnoversrefoot2
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&RequestsForReturnOfGoodsFromClient)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse";
	TableFormationParameters.Indicators = "Ordered, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	// Subquery #requestingreferences
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&ApplicationPeriod";
	TableFormationParameters.EndOfPeriod = "&EndOfApplicationPeriod";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&RequestsForReturnOfGoodsFromClient)
		|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse";
	TableFormationParameters.Indicators = "ToRegisterForReturns";
	TableFormationParameters.Resources = "Count";
	
	RequestsForReturnsTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#RequestsForReturnsTurnoverExpanded1",
		RequestsForReturnsTurnoverExpanded1);
	
	// Subquery #requestingreferences
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&ApplicationPeriod";
	TableFormationParameters.EndOfPeriod = "&EndOfApplicationPeriod";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&RequestsForReturnOfGoodsFromClient)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse";
	TableFormationParameters.Indicators = "RequestedForReturn, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	
	RequestsForReturnsTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#RequestsForReturnsTurnoverExpanded2",
		RequestsForReturnsTurnoverExpanded2);
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("RequestsForReturnOfGoodsFromClient", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns(
		"ShipmentAndReturnReferences",
		"ReferenceOrder IN (&RequestsForReturnOfGoodsFromClient)",
		Query.Parameters);
	
	Query.SetParameter("InitialCustomerOrders", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodCustomerOrders", SpeedLimits.MaxDate);
	
	Query.SetParameter("ApplicationPeriod", SpeedLimits.MinDate);
	Query.SetParameter("EndOfApplicationPeriod", SpeedLimits.MaxDate);
	
	ByDocument = Orders.Count() = 1 And Orders[0].Value = DocumentInitiator;
	
	Query.SetParameter("ByDocument",ByDocument);
	
	If ByDocument Then
		Query.SetParameter("ReturnedGoods", TableOfGoodsReceipt);
		Query.SetParameter("SubstituteGoods", TableOfGoodsExpense);
		
		Query.SetParameter("OrderDocument", DocumentInitiator);
		Query.SetParameter("Warehouse", Common.ObjectAttributeValue(DocumentInitiator, "Warehouse"));
	Else
		EmptyProductTable = NewProductTableReceiptExpense();
		Query.SetParameter("ReturnedGoods", EmptyProductTable);
		Query.SetParameter("SubstituteGoods", EmptyProductTable);
	
		Query.SetParameter("OrderDocument", Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef());
		Query.SetParameter("Warehouse", Catalogs.Warehouses.EmptyRef());
	EndIf;
	
	NumberOfRequests_ = 6;
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders         = Result[0].Select();
	AcceptableDeviations  = Result[1].Unload();
	TableGoodsToCancel  = Result[NumberOfRequests_].Unload(); // ValueTable
	
	TableGoodsToCancel.GroupBy("OrderDocument, Products, Characteristic, ThisIsShipment, Warehouse", "Count, Ordered");
	GoodsForCancellation.Load(TableGoodsToCancel);
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Warehouse, OrderDocument, ThisIsShipment");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDeviationsForOrdersToProcessors()
	
	Query = New Query(
	"SELECT
	|	SubcontractOrder.Ref AS SubcontractOrder
	|FROM
	|	Document.SubcontractOrder2_5 AS SubcontractOrder
	|WHERE
	|	SubcontractOrder.Ref IN(&OrdersToProcessor)
	|	AND SubcontractOrder.Status <> VALUE(Enum.TollingOrderStatuses.Closed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument                     AS OrderDocument,
	|	Balance.Products              AS Products,
	|	Balance.Characteristic            AS Characteristic,
	|	Balance.ThisIsShipment               AS ThisIsShipment,
	|	Balance.Warehouse                     AS Warehouse,
	|	Balance.Series                     AS Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END                             AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                             AS AdvancedWarehousingOnGoodsReceipt,
	|	SUM(Balance.ToRegisterBalance) AS ToRegisterBalance,
	|	CASE
	|		WHEN SUM(Balance.OverOrderByOrders) >= SUM(Balance.BalanceOnOrders)
	|			THEN 0
	|		ELSE SUM(Balance.BalanceOnOrders) - SUM(Balance.OverOrderByOrders)
	|	END                             AS BalanceOnOrders,
	|	SUM(Balance.Ordered)           AS Ordered,
	|	SUM(Balance.ForCompletion)        AS ForCompletion
	|INTO TTBalance
	|FROM (SELECT
	|		RequirementsForRegistration_1.ReferenceOrder AS OrderDocument,
	|		RequirementsForRegistration_1.Products AS Products,
	|		RequirementsForRegistration_1.Characteristic AS Characteristic,
	|		TRUE AS ThisIsShipment,
	|		RequirementsForRegistration_1.Warehouse AS Warehouse,
	|		RequirementsForRegistration_1.Series AS Series,
	|		SUM(RequirementsForRegistration_1.ForRegistrationQuantityTurnover -
	|			RequirementsForRegistration_1.IssuedQuantityTurnover) AS ToRegisterBalance,
	|		0 AS BalanceOnOrders,
	|		SUM(- RequirementsForRegistration_1.ForRegistrationQuantityTurnover) AS OverOrderByOrders,
	|		SUM(RequirementsForRegistration_1.OrderedQuantityTurnover) AS Ordered,
	|		SUM(RequirementsForRegistration_1.OrderedQuantityTurnover -
	|			RequirementsForRegistration_1.ForRegistrationQuantityTurnover) AS ForCompletion
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS RequirementsForRegistration_1
	|	GROUP BY
	|		RequirementsForRegistration_1.ReferenceOrder,
	|		RequirementsForRegistration_1.Products,
	|		RequirementsForRegistration_1.Characteristic,
	|		RequirementsForRegistration_1.Warehouse,
	|		RequirementsForRegistration_1.Series
	|	HAVING
	|		SUM(RequirementsForRegistration_1.ForRegistrationQuantityTurnover -
	|			RequirementsForRegistration_1.IssuedQuantityTurnover) <> 0
	|		OR SUM(- RequirementsForRegistration_1.ForRegistrationQuantityTurnover) <> 0
	|		OR SUM(RequirementsForRegistration_1.OrderedQuantityTurnover) <> 0
	|		OR SUM(RequirementsForRegistration_1.OrderedQuantityTurnover -
	|			RequirementsForRegistration_1.ForRegistrationQuantityTurnover) <> 0
	|	
	|	UNION ALL
	|
	|	SELECT
	|		RequirementsForRegistration_1.PurchaseOrder                  AS OrderDocument,
	|		RequirementsForRegistration_1.Products                     AS Products,
	|		RequirementsForRegistration_1.Characteristic                   AS Characteristic,
	|		FALSE                                                AS ThisIsShipment,
	|		RequirementsForRegistration_1.Warehouse                            AS Warehouse,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|		RequirementsForRegistration_1.ToRegisterClosingBalance       AS ToRegisterBalance,
	|		0                                                   AS BalanceOnOrders,
	|		- RequirementsForRegistration_1.ToRegisterReceipt              AS OverOrderByOrders,
	|		RequirementsForRegistration_1.OrderedReceipt                   AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- RequirementsForRegistration_1.ToRegisterReceipt          AS ForCompletion
	|	FROM
	|		AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(&InitialOrdersToSuppliers, &CounterOrdersToSuppliers,
	|			,, PurchaseOrder IN (&OrdersToProcessor) AND RowCode <> 0) AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesForShipment.DocumentShipments         AS OrderDocument,
	|		BalancesForShipment.Products             AS Products,
	|		BalancesForShipment.Characteristic           AS Characteristic,
	|		TRUE                                    AS ThisIsShipment,
	|		BalancesForShipment.Warehouse                    AS Warehouse,
	|		BalancesForShipment.Series                    AS Series,
	|		0                                         AS ToRegisterBalance,
	|		BalancesForShipment.ToShipClosingBalance AS BalanceOnOrders,
	|		BalancesForShipment.ToShipReceipt          AS OverOrderByOrders,
	|		0                                         AS Ordered,
	|		0                                         AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(&ReadyToShipPeriod,&ConPeriodToShipment,,,
	|			DocumentShipments IN (&OrdersToProcessor)) AS BalancesForShipment
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesDue.DocumentInflow               AS OrderDocument,
	|		BalancesDue.Products                      AS Products,
	|		BalancesDue.Characteristic                    AS Characteristic,
	|		FALSE                                                  AS ThisIsShipment,
	|		BalancesDue.Warehouse                             AS Warehouse,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)   AS Series,
	|		0                                                     AS ToRegisterBalance,
	|		BalancesDue.GoodsReceiptNotesToRegisterClosingBalance AS BalanceOnOrders,
	|		BalancesDue.GoodsReceiptNotesToRegisterReceipt          AS OverOrderByOrders,
	|		0                                                     AS Ordered,
	|		0                                                     AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(&InitialAdmissionPeriod,&ConPeriodForAdmission,,,
	|			DocumentInflow IN (&OrdersToProcessor)) AS BalancesDue) AS Balance
	|GROUP BY
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.ThisIsShipment,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	ProductData_1.ItemsType,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.ThisIsShipment,
	|	Balance.Series,
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR (Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnShipment)
	|			OR (NOT Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnGoodsReceipt) THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion AS Count,
	|	Balance.Ordered
	|FROM
	|	TTBalance AS Balance
	|	
	|	LEFT JOIN Catalog.Products AS ProductData_1
	|	ON Balance.Products = ProductData_1.Ref
	|
	|WHERE
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR (Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnShipment)
	|			OR (NOT Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnGoodsReceipt) THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion <> 0
	|	AND NOT Balance.OrderDocument.ProcessingByOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products    AS Products,
	|	GoodsForIssue.Characteristic  AS Characteristic,
	|	GoodsForIssue.Series           AS Series,
	|	TRUE                          AS ThisIsShipment,
	|	GoodsForIssue.ReferenceOrder    AS OrderDocument,
	|	GoodsForIssue.Warehouse           AS Warehouse,
	|	SUM(GoodsForIssue.ForRegistrationQuantityTurnover
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	#ShipmentOrdersTurnoverExpanded2 AS GoodsForIssue
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.ReferenceOrder,
	|	GoodsForIssue.Warehouse
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.Products                     AS Products,
	|	GoodsToReceive.Characteristic                   AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	FALSE                                                AS ThisIsShipment,
	|	GoodsToReceive.PurchaseOrder                  AS OrderDocument,
	|	GoodsToReceive.Warehouse                            AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.PurchaseOrders.Turnovers(&InitialOrdersToSuppliers, &CounterOrdersToSuppliers,
	|		, PurchaseOrder IN (&OrdersToProcessor)) AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.PurchaseOrder,
	|	GoodsToReceive.Warehouse");
	
	// Subquery #of the order of the offload turnout1
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&OrdersToProcessor)
		|		AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "Ordered, ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	// Subquery #dispositioningrelease turnoversrefoot2
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&OrdersToProcessor)
		|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "ToRegister";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("OrdersToProcessor", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SetPrivilegedMode(True);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("ShipmentAndReturnReferences",
		"ReferenceOrder IN (&OrdersToProcessor)", Query.Parameters);
	
	Query.SetParameter("InitialCustomerOrders", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodCustomerOrders", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("PurchaseOrders",
		"PurchaseOrder IN (&OrdersToProcessor)", Query.Parameters);
	
	Query.SetParameter("InitialOrdersToSuppliers", SpeedLimits.MinDate);
	Query.SetParameter("CounterOrdersToSuppliers", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsForIssue",
		"DocumentShipments IN (&OrdersToProcessor)", Query.Parameters);
	
	Query.SetParameter("ReadyToShipPeriod", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodToShipment", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsToReceive",
		"DocumentInflow IN (&OrdersToProcessor)", Query.Parameters);
	
	Query.SetParameter("InitialAdmissionPeriod", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodForAdmission", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[0].Select();
	TableGoodsToCancel = Result[2].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[3].Unload();
	
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Series,Warehouse,ThisIsShipment,OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillDeviationsOnOrdersOfMaterialsInProduction()
	
	Query = New Query(
	"SELECT
	|	OrderOfMaterials.Ref AS OrderOfMaterials
	|FROM
	|	Document.OrderOfMaterialsForProduction AS OrderOfMaterials
	|WHERE
	|	OrderOfMaterials.Ref IN(&OrdersForMaterials)
	|	AND OrderOfMaterials.Status <> VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	Balance.Series,
	|	SUM(Balance.ToRegisterBalance),
	|	CASE
	|		WHEN SUM(Balance.ToShipmentInExcessOfOrder) >= SUM(Balance.ToShipBalance)
	|			THEN 0
	|		ELSE SUM(Balance.ToShipBalance) - SUM(Balance.ToShipmentInExcessOfOrder)
	|	END AS ToShipBalance,
	|	SUM(Balance.Ordered),
	|	SUM(Balance.ForCompletion)
	|INTO TTBalance
	|FROM (SELECT
	|		RequirementsForRegistration_1.ReferenceOrder               AS OrderDocument,
	|		RequirementsForRegistration_1.Products               AS Products,
	|		RequirementsForRegistration_1.Characteristic             AS Characteristic,
	|		RequirementsForRegistration_1.Warehouse                      AS Warehouse,
	|		RequirementsForRegistration_1.Series                      AS Series,
	|		RequirementsForRegistration_1.ToRegisterClosingBalance AS ToRegisterBalance,
	|		0                                             AS ToShipBalance,
	|		- RequirementsForRegistration_1.ToRegisterReceipt        AS ToShipmentInExcessOfOrder,
	|		RequirementsForRegistration_1.OrderedReceipt             AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- RequirementsForRegistration_1.ToRegisterReceipt    AS ForCompletion
	|	FROM
	|		AccumulationRegister.OrdersOfMaterialsForProduction.BalanceAndTurnovers(&StartPeriod_,&ConPeriod,,,
	|			ReferenceOrder IN (&OrdersForMaterials) AND RowCode <> 0) AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesForShipment.DocumentShipments         AS OrderDocument,
	|		BalancesForShipment.Products             AS Products,
	|		BalancesForShipment.Characteristic           AS Characteristic,
	|		BalancesForShipment.Warehouse                    AS Warehouse,
	|		BalancesForShipment.Series                    AS Series,
	|		0                                         AS ToRegisterBalance,
	|		BalancesForShipment.ToShipClosingBalance AS ToShipBalance,
	|		BalancesForShipment.ToShipReceipt          AS ToShipmentInExcessOfOrder,
	|		0                                         AS Ordered,
	|		0                                         AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(&ReadyToShipPeriod,&ConPeriodToShipment,,,
	|			DocumentShipments IN (&OrdersForMaterials)) AS BalancesForShipment) AS Balance
	|GROUP BY
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.ToShipBalance
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.ToShipBalance
	|	END + Balance.ForCompletion AS Count,
	|	TRUE AS ThisIsShipment,
	|	Balance.Ordered
	|FROM TTBalance AS Balance
	|WHERE
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.ToShipBalance
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.ToShipBalance
	|	END + Balance.ForCompletion <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products                 AS Products,
	|	GoodsForIssue.Characteristic               AS Characteristic,
	|	GoodsForIssue.Series                        AS Series,
	|	GoodsForIssue.Warehouse                        AS Warehouse,
	|	GoodsForIssue.ReferenceOrder                 AS OrderDocument,
	|	SUM(GoodsForIssue.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.OrdersOfMaterialsForProduction.Turnovers(&StartPeriod_,&ConPeriod,,
	|		ReferenceOrder IN (&OrdersForMaterials)) AS GoodsForIssue
	|WHERE
	|	GoodsForIssue.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.ReferenceOrder");
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
	
	Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("OrdersForMaterials", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SetPrivilegedMode(True);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("OrdersOfMaterialsForProduction",
		"ReferenceOrder IN (&OrdersForMaterials)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsForIssue",
		"DocumentShipments IN (&OrdersForMaterials)", Query.Parameters);
	
	Query.SetParameter("ReadyToShipPeriod", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodToShipment", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[0].Select();
	TableGoodsToCancel = Result[2].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[3].Unload();
	
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Series,Warehouse,OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure
&AtServer
Procedure FillOutDeviationsForGiverSOrders()
	
	Query = New Query(" 
	|SELECT
	|	RequirementsForRegistration_1.ReferenceOrder               AS SalesOrder,
	|	RequirementsForRegistration_1.Products               AS Products,
	|	RequirementsForRegistration_1.Characteristic             AS Characteristic,
	|	RequirementsForRegistration_1.Warehouse                      AS Warehouse,
	|	RequirementsForRegistration_1.Series                      AS Series, 
	|	SUM(RequirementsForRegistration_1.ForRegistrationQuantityTurnover) -
	|		SUM(RequirementsForRegistration_1.IssuedQuantityTurnover) AS ToRegisterClosingBalance,
	|	SUM(RequirementsForRegistration_1.QuantityToBeShippedTurnover) -
	|		SUM(RequirementsForRegistration_1.ShippedQuantityTurnover) AS ToTransferClosingBalance,
	|	SUM(RequirementsForRegistration_1.ForRegistrationQuantityTurnover) AS ToRegisterReceipt,
	|	SUM(RequirementsForRegistration_1.QuantityToBeShippedTurnover) AS ToTransferReceipt,
	|	SUM(RequirementsForRegistration_1.OrderedQuantityTurnover) AS OrderedReceipt
	|INTO TTBalancesForRegistration
	|FROM
	|	#ShipmentOrdersTurnoverExpanded1 AS RequirementsForRegistration_1
	|GROUP BY
	|	RequirementsForRegistration_1.ReferenceOrder,
	|	RequirementsForRegistration_1.Products,
	|	RequirementsForRegistration_1.Characteristic,
	|	RequirementsForRegistration_1.Warehouse,
	|	RequirementsForRegistration_1.Series
	|HAVING
	|	SUM(RequirementsForRegistration_1.ForRegistrationQuantityTurnover) -
	|		SUM(RequirementsForRegistration_1.IssuedQuantityTurnover) <> 0
	|	OR SUM(RequirementsForRegistration_1.QuantityToBeShippedTurnover) -
	|		SUM(RequirementsForRegistration_1.ShippedQuantityTurnover) <> 0
	|	OR SUM(RequirementsForRegistration_1.ForRegistrationQuantityTurnover) <> 0
	|	OR SUM(RequirementsForRegistration_1.QuantityToBeShippedTurnover) <> 0
	|	OR SUM(RequirementsForRegistration_1.OrderedQuantityTurnover) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialProviderOrder2_5.Ref AS MaterialProviderOrder
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	MaterialProviderOrder2_5.Ref IN(&MaterialProviderOrders)
	|	AND MaterialProviderOrder2_5.Status <> VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.ThisIsShipment,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnGoodsReceipt,
	|	SUM(Balance.ToRegisterBalance),
	|	CASE
	|		WHEN SUM(Balance.OverOrderByOrders) >= SUM(Balance.BalanceOnOrders)
	|			THEN 0
	|		ELSE SUM(Balance.BalanceOnOrders) - SUM(Balance.OverOrderByOrders)
	|	END AS BalanceOnOrders,
	|	SUM(Balance.Ordered),
	|	SUM(Balance.ForCompletion)
	|INTO TTBalance
	|FROM (SELECT
	|		RequirementsForRegistration_1.SalesOrder               AS OrderDocument,
	|		RequirementsForRegistration_1.Products               AS Products,
	|		RequirementsForRegistration_1.Characteristic             AS Characteristic,
	|		TRUE                                        AS ThisIsShipment,
	|		RequirementsForRegistration_1.Warehouse                      AS Warehouse,
	|		RequirementsForRegistration_1.Series                      AS Series,
	|		CASE
	|			WHEN TRUE
	|				THEN CASE
	|					WHEN RequirementsForRegistration_1.ToRegisterClosingBalance < RequirementsForRegistration_1.ToTransferClosingBalance
	|						THEN RequirementsForRegistration_1.ToRegisterClosingBalance
	|					ELSE RequirementsForRegistration_1.ToTransferClosingBalance
	|				  END		
	|		END                                         AS ToRegisterBalance, 
	|		0                                             AS BalanceOnOrders,
	|		CASE
	|			WHEN TRUE
	|				THEN - RequirementsForRegistration_1.ToTransferReceipt
	|		END                                         AS OverOrderByOrders,
	|		RequirementsForRegistration_1.OrderedReceipt             AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- CASE
	|				WHEN TRUE
	|					THEN CASE
	|						WHEN RequirementsForRegistration_1.ToRegisterReceipt > RequirementsForRegistration_1.ToTransferReceipt
	|							THEN RequirementsForRegistration_1.ToRegisterReceipt
	|						ELSE RequirementsForRegistration_1.ToTransferReceipt
	|					  END
	|			  END                                   AS ForCompletion
	|	FROM
	|		TTBalancesForRegistration AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|
	|	SELECT
	|		RequirementsForRegistration_1.PurchaseOrder                  AS OrderDocument,
	|		RequirementsForRegistration_1.Products                     AS Products,
	|		RequirementsForRegistration_1.Characteristic                   AS Characteristic,
	|		FALSE                                                AS ThisIsShipment,
	|		RequirementsForRegistration_1.Warehouse                            AS Warehouse,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|		RequirementsForRegistration_1.ToRegisterClosingBalance       AS ToRegisterBalance,
	|		0                                                   AS BalanceOnOrders,
	|		- RequirementsForRegistration_1.ToRegisterReceipt              AS OverOrderByOrders,
	|		RequirementsForRegistration_1.OrderedReceipt                   AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- RequirementsForRegistration_1.ToRegisterReceipt          AS ForCompletion
	|	FROM
	|		AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(&InitialOrdersToSuppliers, &CounterOrdersToSuppliers,
	|			,, PurchaseOrder IN (&MaterialProviderOrders) AND RowCode <> 0) AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesForShipment.DocumentShipments         AS OrderDocument,
	|		BalancesForShipment.Products             AS Products,
	|		BalancesForShipment.Characteristic           AS Characteristic,
	|		TRUE                                    AS ThisIsShipment,
	|		BalancesForShipment.Warehouse                    AS Warehouse,
	|		BalancesForShipment.Series                    AS Series,
	|		0                                         AS ToRegisterBalance,
	|		BalancesForShipment.ToShipClosingBalance AS BalanceOnOrders,
	|		BalancesForShipment.ToShipReceipt          AS OverOrderByOrders,
	|		0                                         AS Ordered,
	|		0                                         AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(&ReadyToShipPeriod,&ConPeriodToShipment,,,
	|			DocumentShipments IN (&MaterialProviderOrders)) AS BalancesForShipment
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BalancesDue.DocumentInflow               AS OrderDocument,
	|		BalancesDue.Products                      AS Products,
	|		BalancesDue.Characteristic                    AS Characteristic,
	|		FALSE                                                  AS ThisIsShipment,
	|		BalancesDue.Warehouse                             AS Warehouse,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)   AS Series,
	|		0                                                     AS ToRegisterBalance,
	|		BalancesDue.GoodsReceiptNotesToRegisterClosingBalance AS BalanceOnOrders,
	|		BalancesDue.GoodsReceiptNotesToRegisterReceipt          AS OverOrderByOrders,
	|		0                                                     AS Ordered,
	|		0                                                     AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(&InitialAdmissionPeriod,&ConPeriodForAdmission,,,
	|			DocumentInflow IN (&MaterialProviderOrders)) AS BalancesDue) AS Balance
	|GROUP BY
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.ThisIsShipment,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.ThisIsShipment,
	|	Balance.Series,
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR (Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnShipment)
	|			OR (NOT Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnGoodsReceipt) THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion AS Count,
	|	Balance.Ordered
	|FROM TTBalance AS Balance
	|WHERE
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR (Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnShipment)
	|			OR (NOT Balance.ThisIsShipment AND NOT Balance.AdvancedWarehousingOnGoodsReceipt) THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products    AS Products,
	|	GoodsForIssue.Characteristic  AS Characteristic,
	|	GoodsForIssue.Series           AS Series,
	|	TRUE                          AS ThisIsShipment,
	|	GoodsForIssue.ReferenceOrder    AS OrderDocument,
	|	GoodsForIssue.Warehouse           AS Warehouse,
	|	SUM(GoodsForIssue.ForRegistrationQuantityTurnover
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	#ShipmentOrdersTurnoverExpanded2 AS GoodsForIssue
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.ReferenceOrder,
	|	GoodsForIssue.Warehouse
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.Products                     AS Products,
	|	GoodsToReceive.Characteristic                   AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	FALSE                                                AS ThisIsShipment,
	|	GoodsToReceive.PurchaseOrder                  AS OrderDocument,
	|	GoodsToReceive.Warehouse                            AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.PurchaseOrders.Turnovers(&InitialOrdersToSuppliers, &CounterOrdersToSuppliers,
	|		, PurchaseOrder IN (&MaterialProviderOrders)) AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.PurchaseOrder,
	|	GoodsToReceive.Warehouse");
	
	// Subquery #of the order of the offload turnout1
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&MaterialProviderOrders)
		|		AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "Ordered, ToRegister, Issued_1, ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	// Subquery #dispositioningrelease turnoversrefoot2
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
	TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&MaterialProviderOrders)
		|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
	TableFormationParameters.Indicators = "ToRegister";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("MaterialProviderOrders", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SetPrivilegedMode(True);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("ShipmentAndReturnReferences",
		"ReferenceOrder IN (&MaterialProviderOrders)", Query.Parameters);
	
	Query.SetParameter("InitialCustomerOrders", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodCustomerOrders", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("PurchaseOrders",
		"PurchaseOrder IN (&MaterialProviderOrders)", Query.Parameters);
	
	Query.SetParameter("InitialOrdersToSuppliers", SpeedLimits.MinDate);
	Query.SetParameter("CounterOrdersToSuppliers", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsForIssue",
		"DocumentShipments IN (&MaterialProviderOrders)", Query.Parameters);
	
	Query.SetParameter("ReadyToShipPeriod", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodToShipment", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsToReceive",
		"DocumentInflow IN (&MaterialProviderOrders)", Query.Parameters);
	
	Query.SetParameter("InitialAdmissionPeriod", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodForAdmission", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[1].Select();
	TableGoodsToCancel = Result[3].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[4].Unload();
	
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Series,Warehouse,ThisIsShipment,OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDeviationsByStagesOfProduction()
	
	Query = New Query(
	"SELECT
	|	ProductionStage2_2.Ref AS MaterialProviderOrder
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.Ref IN(&ProductionStages)
	|	AND ProductionStage2_2.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|	AND &UseClosedStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnGoodsReceipt,
	|	SUM(Balance.ToRegisterBalance),
	|	SUM(Balance.BalanceOnOrders),
	|	SUM(Balance.Ordered),
	|	SUM(Balance.ForCompletion)
	|INTO TTBalance
	|FROM (SELECT
	|		RequirementsForRegistration_1.ReferenceOrder               AS OrderDocument,
	|		RequirementsForRegistration_1.Products               AS Products,
	|		RequirementsForRegistration_1.Characteristic             AS Characteristic,
	|		RequirementsForRegistration_1.Warehouse                      AS Warehouse,
	|		RequirementsForRegistration_1.Series                      AS Series,
	|		RequirementsForRegistration_1.ToRegisterClosingBalance AS ToRegisterBalance,
	|		0                                             AS BalanceOnOrders,
	|		RequirementsForRegistration_1.OrderedReceipt             AS Ordered,
	|		RequirementsForRegistration_1.OrderedReceipt
	|			- RequirementsForRegistration_1.ToRegisterReceipt    AS ForCompletion
	|	FROM
	|		AccumulationRegister.OrdersOfMaterialsForProduction.BalanceAndTurnovers(&StartPeriod_, &ConPeriod,
	|			,, ReferenceOrder IN (&ProductionStages) AND RowCode <> 0) AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|
	|	SELECT
	|		BalancesForShipment.DocumentShipments AS OrderDocument,
	|		BalancesForShipment.Products     AS Products,
	|		BalancesForShipment.Characteristic   AS Characteristic,
	|		BalancesForShipment.Warehouse            AS Warehouse,
	|		BalancesForShipment.Series            AS Series,
	|		0                                 AS ToRegisterBalance,
	|		BalancesForShipment.ToShipBalance AS BalanceOnOrders,
	|		0                                 AS Ordered,
	|		0                                 AS ForCompletion
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN (&ProductionStages)) AS BalancesForShipment) AS Balance
	|GROUP BY
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN Balance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Balance.OrderDocument.Date >= Balance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.OrderDocument,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series,
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion AS Count,
	|	TRUE AS ThisIsShipment,
	|	Balance.Ordered
	|FROM TTBalance AS Balance
	|WHERE
	|	CASE WHEN Balance.ToRegisterBalance >= 0 AND Balance.ToRegisterBalance < Balance.BalanceOnOrders
	|			OR Balance.ToRegisterBalance < 0
	|			OR NOT Balance.AdvancedWarehousingOnShipment THEN
	|		Balance.ToRegisterBalance
	|	ELSE
	|		Balance.BalanceOnOrders
	|	END + Balance.ForCompletion <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Products    AS Products,
	|	GoodsForIssue.Characteristic  AS Characteristic,
	|	GoodsForIssue.Series           AS Series,
	|	TRUE                          AS ThisIsShipment,
	|	GoodsForIssue.ReferenceOrder    AS OrderDocument,
	|	GoodsForIssue.Warehouse           AS Warehouse,
	|	SUM(GoodsForIssue.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.OrdersOfMaterialsForProduction.Turnovers(&StartPeriod_, &ConPeriod,
	|		, ReferenceOrder IN (&ProductionStages)) AS GoodsForIssue
	|WHERE
	|	GoodsForIssue.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.ReferenceOrder,
	|	GoodsForIssue.Warehouse");
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("ProductionStages", Orders.UnloadValues());
	Query.SetParameter("UseClosedStatus", TheClosedStatusIsUsed);
	
	SetPrivilegedMode(True);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("OrdersOfMaterialsForProduction",
		"ReferenceOrder IN (&ProductionStages)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SampleOrders = Result[0].Select();
	TableGoodsToCancel = Result[2].Unload();
	GoodsForCancellation.Load(TableGoodsToCancel);
	AcceptableDeviations = Result[3].Unload();
	
	TheStructureOfTheSearch = New Structure("Products,Characteristic,Series,Warehouse,ThisIsShipment,OrderDocument");
	SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch);
	GoodsForCancellation.Clear(); // we do not propose to cancel the materials, only the adjustment of the dimensional
	
	If SampleOrders.Count() = 0
		And GoodsForCancellation.Count() = 0
		And MeasuringGoodsForAdjustment.Count() = 0 Then
		OrdersAreClosed = True;
		Return;
	EndIf;
	
	If SampleOrders.Count() = 0 Then
		TheClosedStatusIsSet = True;
	EndIf;
	
EndProcedure
&AtServer
Procedure SelectDimensionalGoods(GoodsForCancellation, AcceptableDeviations, TheStructureOfTheSearch)
	
	Cnt = GoodsForCancellation.Count()-1;
	While Cnt >= 0 Do
		
		RemainderLine_ = GoodsForCancellation[Cnt];
		
		FillPropertyValues(TheStructureOfTheSearch, RemainderLine_);
		
		ToleranceLines = AcceptableDeviations.FindRows(TheStructureOfTheSearch);
		
		If RemainderLine_.Count < 0 Then //exceeding the order
			
			If ToleranceLines.Count() > 0 Then
				
				AllowableVariance = ToleranceLines[0].AllowableVariance;
				
				If -RemainderLine_.Count <= AllowableVariance Then
					NwRw = MeasuringGoodsForAdjustment.Add();
					FillPropertyValues(NwRw, RemainderLine_);
					NwRw.Count = -NwRw.Count;
				EndIf;
				
			EndIf;
			
			GoodsForCancellation.Delete(Cnt);
			
		ElsIf RemainderLine_.Count > 0 Then
			
			If ToleranceLines.Count() > 0 Then
				
				AllowableVariance = ToleranceLines[0].AllowableVariance;
				
				If RemainderLine_.Count <= AllowableVariance Then
					NwRw = MeasuringGoodsForAdjustment.Add();
					FillPropertyValues(NwRw,RemainderLine_);
					NwRw.Count = -NwRw.Count;
					GoodsForCancellation.Delete(Cnt);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		Cnt = Cnt - 1;
		
	EndDo;
	
EndProcedure

#EndRegion

&AtClient
Function GenerateTextProcessed()
	
	Processed = Orders.Count() - UnfulfilledOrders.Count();
	
	OrderTypeSettings = CaseSettingsByOrderType(OrderType_5, Processed);
	
	RPText = OrderTypeSettings.RPText;
	IPText = OrderTypeSettings.IPText;
	IPECHText = OrderTypeSettings.IPECHText;
	TextOfIPMCH = OrderTypeSettings.TextOfIPMCH;
	DPText = OrderTypeSettings.DPText;
	TheClosedStatusPresentation = OrderTypeSettings.TheClosedStatusPresentation;
	
	If Processed = 0 Then
		Return StrTemplate(NStr("vi = 'Không thể xử lý %1:';
								|ru = 'Не удалось обработать %1:';
								|en = 'Cannot process %1:'; fa = 'Cannot process %1:';
								|it = 'Non è stato possibile elaborare %1:';
								|pl = 'Nie udało się opracować %1:';
								|tr = '%1 işlenemedi:'"), IPText);
	EndIf;
	
	If OrderType_5 = "SalesOrder" Then
		TextFor = NStr("vi = 'Đối với đơn hàng của khách (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заказов клиентов (%ProcessedItemsCount%) %ActionText%';
						|en = 'For sales orders (%ProcessedItemsCount%) %ActionText%'; fa = 'For sales orders (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini dei clienti (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień sprzedaży (%ProcessedItemsCount%) %ActionText%';
						|tr = 'İstemci siparişleri için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "PurchaseOrder" Then
		TextFor = NStr("vi = 'Đối với đơn hàng đặt nhà cung cấp (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заказов поставщикам (%ProcessedItemsCount%) %ActionText%';
						|en = 'For purchase orders (%ProcessedItemsCount%) %ActionText%'; fa = 'For purchase orders (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini ai fornitori (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień zakupu (%ProcessedItemsCount%) %ActionText%';
						|tr = 'Satın alma siparişleri için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "ByAssemblyDisassemblyOrder" Then
		TextFor = NStr("vi = 'Đối với đơn hàng đóng bộ (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заказов на сборку (%ProcessedItemsCount%) %ActionText%';
						|en = 'For kitting orders (%ProcessedItemsCount%) %ActionText%'; fa = 'For kitting orders (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini di assemblaggio (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień na montaż (%ProcessedItemsCount%) %ActionText%';
						|tr = 'Montaj siparişleri için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "OrderForInternalEviction" Then
		TextFor = NStr("vi = 'Đối với đơn tiêu dùng nội bộ (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заказов на внутреннее потребление (%ProcessedItemsCount%) %ActionText%';
						|en = 'For inventory consumption orders (%ProcessedItemsCount%) %ActionText%'; fa = 'For inventory consumption orders (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini di consumo interno (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień na wewnętrzną konsumpcję (%ProcessedItemsCount%) %ActionText%';
						|tr = 'İç tüketim siparişleri için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "TransferOrder" Then
		TextFor = NStr("vi = 'Đối với đơn hàng điều chuyển (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заказов на перемещение (%ProcessedItemsCount%) %ActionText%';
						|en = 'For transfer orders (%ProcessedItemsCount%) %ActionText%'; fa = 'For transfer orders (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini di trasferimento (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień na przemieszczenie (%ProcessedItemsCount%) %ActionText%';
						|tr = 'Transfer siparişleri için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "RequestForReturnOfGoodsFromCustomer" Then
		TextFor = NStr("vi = 'Đối với giấy đề nghị trả lại hàng từ người mua (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заявок на возврат товаров от клиента (%ProcessedItemsCount%) %ActionText%';
						|en = 'For sales return requests (%ProcessedItemsCount%) %ActionText%'; fa = 'For sales return requests (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per le richieste di restituzione delle merci dal cliente (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień na zwrot towarów od klienta (%ProcessedItemsCount%) %ActionText%';
						|tr = 'İstemciden ürün iadesi başvuruları için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "SubcontractOrder2_5" Then
		TextFor = NStr("vi = 'Đối với các đơn hàng đặt gia công (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заказов переработчикам (%ProcessedItemsCount%) %ActionText%';
						|en = 'For subcontracting purchase orders (%ProcessedItemsCount%) %ActionText%'; fa = 'For subcontracting purchase orders (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini ai subfornitori (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień przetwórcom (%ProcessedItemsCount%) %ActionText%';
						|tr = 'Fason satın alma siparişi için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "OrderOfMaterialsForProduction" Then
		TextFor = NStr("vi = 'Đối với các đơn nguyên vật liệu sản xuất (%ProcessedItemsCount%)%ActionText%';
						|ru = 'Для заказов материалов в производство (%ProcessedItemsCount%) %ActionText%';
						|en = 'To order materials for shop floor stockroom (%ProcessedItemsCount%) %ActionText%'; fa = 'To order materials for shop floor stockroom (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini di materiali per la produzione (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień materiałów do produkcji (%ProcessedItemsCount%) %ActionText%';
						|tr = 'Üretimde malzeme siparişleri için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "MaterialProviderOrder2_5" Then
		TextFor = NStr("vi = 'Đối với đơn hàng của người đặt gia công (%ProcessedItemsCount%) %ActionText%';
						|ru = 'Для заказов давальцев (%ProcessedItemsCount%) %ActionText%';
						|en = 'For subcontracting sales orders (%ProcessedItemsCount%) %ActionText%'; fa = 'For subcontracting sales orders (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per gli ordini dei committenti (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla zamówień dawców (%ProcessedItemsCount%) %ActionText%';
						|tr = 'Tedarikçi siparişleri için (%ProcessedItemsCount%) %ActionText%'");
	ElsIf OrderType_5 = "ProductionStage2_2" Then
		TextFor = NStr("vi = 'Đối với các giai đoạn sản xuất (%ProcessedItemsCount%)%ActionText%';
						|ru = 'Для этапов производства (%ProcessedItemsCount%) %ActionText%';
						|en = 'For production stages (%ProcessedItemsCount%) %ActionText%'; fa = 'For production stages (%ProcessedItemsCount%) %ActionText%';
						|it = 'Per le fasi di produzione (%ProcessedItemsCount%) %ActionText%';
						|pl = 'Dla etapów produkcji (%ProcessedItemsCount%) %ActionText%';
						|tr = 'Üretim aşamaları için (%ProcessedItemsCount%) %ActionText%'");
	EndIf;
	
	ActionText = "";
	If CorrectMeasuringGoods Then
		ActionText = ActionText + NStr("vi = 'dòng sản phẩm điều chỉnh';
										|ru = 'скорректированы строки мерных товаров';
										|en = 'lines with measured goods are corrected'; fa = 'lines with measured goods are corrected';
										|it = 'le righe di merci misurabili sono state corrette';
										|pl = 'skorygowano wiersze towarów wymiarowych';
										|tr = 'ölçülebilen ürün satırları düzeltildi'");
	EndIf;
	
	If CorrectPrices Then
		ActionText = ActionText + ?(ActionText="","",", ") + NStr("vi = 'điều chỉnh giá';
																	|ru = 'скорректированы цены';
																	|en = 'prices corrected'; fa = 'prices corrected';
																	|it = 'i prezzi sono stati corretti';
																	|pl = 'skorygowano ceny';
																	|tr = 'fiyatlar düzeltildi'");
	EndIf;
	
	If CancelUnprocessedLines Then
		ActionText = ActionText + ?(ActionText="","",", ") + NStr("vi = 'đã hủy các dòng chưa lập';
																	|ru = 'отменены непоставленные строки';
																	|en = 'undelivered lines are canceled'; fa = 'undelivered lines are canceled';
																	|it = 'sono state annullate le righe non collocate';
																	|pl = 'anulowano niedostarczone wiersze';
																	|tr = 'karşılaştırılmayan satırlar iptal edildi'");
	EndIf;
	
	If CloseOrders Then
		ActionText = ActionText + ?(ActionText="","",", ") + NStr("vi = 'đã thiết lập trạng thái ""Đã đóng""';
																	|ru = 'установлен статус ""Закрыт""';
																	|en = 'the Closed status is set'; fa = 'the Closed status is set';
																	|it = 'è stato impostato lo stato ""Chiuso""';
																	|pl = 'ustawiono status ""Zamknięty""';
																	|tr = 'durum ""Kapalı"" olarak ayarlandı'");
	EndIf;
	
	TextFor = StrReplace(TextFor, "%ProcessedItemsCount%", Orders.Count()-UnfulfilledOrders.Count());
	
	If UnfulfilledOrders.Count() > 0 Then
		 ActionText = ActionText + Chars.LF + StrTemplate(NStr("vi = 'Không thể xử lý %1:';
																|ru = 'Не удалось обработать %1:';
																|en = 'Cannot process %1:'; fa = 'Cannot process %1:';
																|it = 'Non è stato possibile elaborare %1:';
																|pl = 'Nie udało się opracować %1:';
																|tr = '%1 işlenemedi:'"), TextOfIPMCH);
	EndIf;
	
	TextFor = StrReplace(TextFor, "%ActionText%", ActionText);
	
	Return TextFor;
	
EndFunction

&AtServer
Function TextOfFailedProcessing(Close)
	
	ActionText = "";
	
	If Close Then 
		TemplateFailedToClose = NStr("vi = 'Không thể đặt trạng thái %1.';
									|ru = 'Не удалось установить статус %1.';
									|en = 'Cannot set the %1 status.'; fa = 'Cannot set the %1 status.';
									|it = 'Non è stato possibile impostare lo stato %1.';
									|pl = 'Nie udało się ustawić status %1.';
									|tr = 'Durum ayarlanamadı %1.'");
		
		ActionText = StrTemplate(TemplateFailedToClose, TheClosedStatusPresentation);
	Else
		
		If CorrectMeasuringGoods
			And CorrectPrices
			And CancelUnprocessedLines Then
			ActionText = NStr("vi = 'Không thể điều chỉnh các hàng hóa đo lường, điều chỉnh giá, hủy các hàng chưa được gửi.';
								|ru = 'Не удалось скорректировать строки мерных товаров, скорректировать цены, отменить непоставленные строки.';
								|en = 'Cannot correct lines with measured goods, correct prices, cancel undelivered lines.'; fa = 'Cannot correct lines with measured goods, correct prices, cancel undelivered lines.';
								|it = 'Non è stato possibile correggere le righe delle merci misurabili, correggere i prezzi, annullare le righe non collocate.';
								|pl = 'Nie udało się skorygować wiersze towarów wymiarowych, skorygować ceny, anulować niedostarczone wiersze.';
								|tr = 'Ölçülebilen ürün satırlarını düzeltmek, fiyatları düzeltmek veya sağlanmayan satırları iptal etmek mümkün olmadı.'");
		ElsIf CorrectMeasuringGoods
			And CorrectPrices
			And Not CancelUnprocessedLines Then
			ActionText = NStr("vi = 'Không thể điều chỉnh dòng hàng đo lường, đã điều chỉnh giá.';
								|ru = 'Не удалось скорректировать строки мерных товаров, скорректировать цены.';
								|en = 'Cannot correct lines with measured goods, correct prices.'; fa = 'Cannot correct lines with measured goods, correct prices.';
								|it = 'Non è stato possibile correggere le righe delle merci misurabili, correggere i prezzi.';
								|pl = 'Nie udało się skorygować wiersze towarów wymiarowych, skorygować ceny.';
								|tr = 'Ölçülebilen ürünlerin satırlarını düzeltmek, fiyatları düzeltmek mümkün olmadı.'");
		ElsIf CorrectMeasuringGoods
			And Not CorrectPrices
			And CancelUnprocessedLines Then
			ActionText = NStr("vi = 'Không thể sửa các dòng sản phẩm đo lường, hủy các dòng chưa được gửi.';
								|ru = 'Не удалось скорректировать строки мерных товаров, отменить непоставленные строки.';
								|en = 'Cannot correct lines with measured goods, cancel undelivered lines.'; fa = 'Cannot correct lines with measured goods, cancel undelivered lines.';
								|it = 'Non è stato possibile correggere le righe delle merci miusrabili, annullare le righe non collocate.';
								|pl = 'Nie udało się skorygować wiersze towarów wymiarowych, anulować niedostarczone wiersze.';
								|tr = 'Ölçülebilen ürün satırlarını düzeltmek, sağlanmayan iptal etmek mümkün olmadı.'");
		ElsIf CorrectMeasuringGoods
			And Not CorrectPrices
			And Not CancelUnprocessedLines Then
			ActionText = NStr("vi = 'Không thể điều chỉnh các dòng sản phẩm đo lường.';
								|ru = 'Не удалось скорректировать строки мерных товаров.';
								|en = 'Cannot correct lines with measured goods.'; fa = 'Cannot correct lines with measured goods.';
								|it = 'Non è stato possibile correggere le righe delle merci misurabili.';
								|pl = 'Nie udało się skorygować wiersze towarów wymiarowych.';
								|tr = 'Ölçülebilen ürünlerin satırlarını düzeltmek mümkün olmadı.'");
		ElsIf Not CorrectMeasuringGoods
			And CorrectPrices
			And CancelUnprocessedLines Then
			ActionText = NStr("vi = 'Không thể điều chỉnh giá, hủy các hàng chưa được gửi.';
								|ru = 'Не удалось скорректировать цены, отменить непоставленные строки.';
								|en = 'Cannot correct prices, cancel undelivered lines.'; fa = 'Cannot correct prices, cancel undelivered lines.';
								|it = 'Non è stato possibile correggere i prezzi, annullare le righe non collocate.';
								|pl = 'Nie udało się skorygować ceny, anulować niedostarczone wiersze.';
								|tr = 'Fiyatları düzeltmek, sağlanmayan satırları iptal etmek mümkün olmadı.'");
		ElsIf Not CorrectMeasuringGoods
			And CorrectPrices
			And Not CancelUnprocessedLines Then
			ActionText = NStr("vi = 'Không thể điều chỉnh giá.';
								|ru = 'Не удалось скорректировать цены.';
								|en = 'Cannot correct prices.'; fa = 'Cannot correct prices.';
								|it = 'Non è stato possibile correggere i prezzi.';
								|pl = 'Nie udało się skorygować ceny.';
								|tr = 'Fiyatları düzeltmek mümkün olmadı.'");
		ElsIf Not CorrectMeasuringGoods
			And Not CorrectPrices
			And CancelUnprocessedLines Then
			ActionText = NStr("vi = 'Không thể hủy các hàng chưa được gửi.';
								|ru = 'Не удалось отменить непоставленные строки.';
								|en = 'Cannot cancel the undelivered lines.'; fa = 'Cannot cancel the undelivered lines.';
								|it = 'Non è stato possibile annullare le righe non collocate.';
								|pl = 'Nie udało się anulować niedostarczone wiersze.';
								|tr = 'Sağlanmayan satırlar iptal edilemedi.'");
		EndIf;
		
	EndIf;
	
	Return ActionText;
	
EndFunction

&AtServer
Procedure DoneServer(CloseInCurCall, OrdersToBeProcessed, StructureOfAdditionalParameters)
	
	If Items.Pages.CurrentPage = Items.PageOrdersClosure 
		Or Items.Pages.CurrentPage = Items.PageAllOrdersAreClosed Then
		Return
	EndIf;
	
	BlockErrorTemplate     = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
									|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
									|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
									|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
									|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
									|tr = '%Document% engellenemedi. %ErrorDescription%'");
	WriteErrorTemplate          = NStr("vi = 'Không thể ghi %Document%. %ErrorDescription%';
										|ru = 'Не удалось записать %Document%. %ErrorDescription%';
										|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
										|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
										|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
										|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
	
	For Each CurRow In OrdersToBeProcessed Do
		
		// Capturing an object for editing
		Try
			LockDataForEdit(CurRow.Value);
		Except
			
			RowsOfUnprocessedOrders = UnfulfilledOrders.FindRows(New Structure("OrderDocument", CurRow.Value));
			If RowsOfUnprocessedOrders.Count() = 0 Then
				RowOfUnprocessedOrders = UnfulfilledOrders.Add();
				RowOfUnprocessedOrders.OrderDocument = CurRow.Value;
			Else
				RowOfUnprocessedOrders = RowsOfUnprocessedOrders[0];
			EndIf;
			
			If RowOfUnprocessedOrders.Failure <> NStr("vi = 'Không thể khóa chứng từ.';
														|ru = 'Не удалось заблокировать документ.';
														|en = 'Cannot lock the document.'; fa = 'Cannot lock the document.';
														|it = 'Non è stato possibile bloccare il documento.';
														|pl = 'Nie udało się zablokować dokument.';
														|tr = 'Belge kilitlenemedi.'") Then
				RowOfUnprocessedOrders.Failure = NStr("vi = 'Không thể khóa chứng từ.';
														|ru = 'Не удалось заблокировать документ.';
														|en = 'Cannot lock the document.'; fa = 'Cannot lock the document.';
														|it = 'Non è stato possibile bloccare il documento.';
														|pl = 'Nie udało się zablokować dokument.';
														|tr = 'Belge kilitlenemedi.'");
				
				ErrorText = StrReplace(BlockErrorTemplate, "%Document%", CurRow.Presentation);
				ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				CommonClientServer.MessageToUser(ErrorText, CurRow.Value);
			EndIf;
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				CurRow.Value.Metadata(),
				CurRow.Value,
				ErrorText);
			
			Continue;
		EndTry;
		
		// Getting a Document object
		OrderObject = CurRow.Value.GetObject();
		
		OrderChanged = False;
		
		// Price adjustment
		If CorrectPrices Then
			
			CurOrderLines = PriceVariances.FindRows(New Structure("PurchaseOrder",OrderObject.Ref));
			CurOrderDeviations =PriceVariances.Unload(CurOrderLines);
			
			OrderObject.AdjustOrderPrices(OrderObject, CurOrderDeviations);
			OrderChanged= True;
		EndIf;
		
		If CloseInCurCall Then
			
			If Not OrderObject.SetStatus(TheClosedStatus, StructureOfAdditionalParameters) Then
				
				RowsOfUnprocessedOrders = UnfulfilledOrders.FindRows(New Structure("OrderDocument", CurRow.Value));
				If RowsOfUnprocessedOrders.Count() = 0 Then
					RowOfUnprocessedOrders = UnfulfilledOrders.Add();
					RowOfUnprocessedOrders.OrderDocument = CurRow.Value;
				Else
					RowOfUnprocessedOrders = RowsOfUnprocessedOrders[0];
				EndIf;
				
				RowOfUnprocessedOrders.Failure = TextOfFailedProcessing(True);
				
				Continue;
			EndIf;
			
			OrderChanged = True;
			
		ElsIf CancelUnprocessedLines 
			Or CorrectMeasuringGoods
			Or AdjustTheMeasuredGoodsUponAcceptance Then
			
			OrderChanged = OrdersServer.AdjustOrderLines(OrderObject, StructureOfAdditionalParameters);
			
		EndIf;
		
		If OrderChanged Then
			// Document recording
			Try
				OrderObject.Write(DocumentWriteMode.Posting);
			Except
				RowsOfUnprocessedOrders = UnfulfilledOrders.FindRows(New Structure("OrderDocument", CurRow.Value));
				If RowsOfUnprocessedOrders.Count() = 0 Then
					RowOfUnprocessedOrders = UnfulfilledOrders.Add();
					RowOfUnprocessedOrders.OrderDocument = CurRow.Value;
				Else
					RowOfUnprocessedOrders = RowsOfUnprocessedOrders[0];
				EndIf;
				
				RowOfUnprocessedOrders.Failure = TextOfFailedProcessing(CloseInCurCall);
				
				ErrorText = StrReplace(WriteErrorTemplate, "%Document%", CurRow.Presentation);
				ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				CommonClientServer.MessageToUser(ErrorText, CurRow.Value);
				
				WriteLogEvent(InfobaseUpdate.EventLogEvent(),
					EventLogLevel.Error,
					CurRow.Value.Metadata(),
					CurRow.Value,
					ErrorText);
				
			EndTry
		EndIf;
		
	EndDo;
	
	If CloseInCurCall And UnfulfilledOrders.Count()>0 Then
		ListToProcess = New ValueList;
		ListToProcess.LoadValues(UnfulfilledOrders.Unload().UnloadColumn("OrderDocument"));
		DoneServer(Not CloseInCurCall, ListToProcess, StructureOfAdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Function NewProductTableReceiptExpense()
	
	Result = New ValueTable;
	Result.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Warehouse", 	     New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Count",     New TypeDescription("Number"));
	Result.Columns.Add("Canceled",       New TypeDescription("Boolean"));
	Result.Columns.Add("ProductsRecordingAsReceived",   New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("CharacteristicRecordingAsReceived", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	Return Result;
	
EndFunction;

#EndRegion
