
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DiscrepanciesServer.PageManagementSelectAction(ThisObject, Parameters);
	
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	NumberOfDiscrepancyPackaging = Parameters.NumberOfDiscrepancyPackaging;
	GroupUpdate = Parameters.GroupUpdate;
	
	If Parameters.ChosenAction = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses
		Or (Parameters.Property("ShortfallAction")
			And Parameters.ShortfallAction = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses) Then
		AtWhoseExpense = ?(Parameters.ThirdPartyIsGuilty, "ThirdPartyIsGuilty", "AtOurExpense");
	EndIf;
	
	EconomicOperationsOfSeparatePurchase = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
	If Parameters.Property("BusinessOperation") Then
		ThisIsSeparatePurchase = EconomicOperationsOfSeparatePurchase.Find(Parameters.BusinessOperation) <> Undefined;
		BusinessOperation = Parameters.BusinessOperation;
	Else
		ThisIsSeparatePurchase = False;
	EndIf;
	
	If Not GroupUpdate Then
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
	Else
		Title = NStr("vi = 'Cách xử lý chênh lệch';
					|ru = 'Как отработать расхождения';
					|en = 'Discrepancy treatment'; fa = 'رسیدگی به مغایرت';
					|it = 'Come elaborare le differenze';
					|pl = 'Jak przetworzyć odchylenie';
					|tr = 'Tutarsızlıkların giderilme biçimi'");
	EndIf;
	
	CertificateOfAcceptanceForStorage = Parameters.TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
							Or Parameters.TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor
							Or Parameters.TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor
							Or Parameters.TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
							Or Parameters.TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian;
	
	Items.ThirdPartyIsGuilty.Visible          = Not CertificateOfAcceptanceForStorage;
	Items.ThroughTheFaultOfAThirdPartyCompanyDecoration.Visible = Not CertificateOfAcceptanceForStorage;
	
	Items.NotesPicture.Visible = Parameters.ShowExplanation;
	Items.Explanation.Visible         = Parameters.ShowExplanation;
	
	Items.ReturnOverdeliveredWithoutRegistration.Visible = Not ThisIsSeparatePurchase;
	Items.ReturnTheReDeliveredWithoutDecorationDecoration.Visible = Not ThisIsSeparatePurchase;
	
	GenerateHeadings(Parameters.TypeOfAct,
						Parameters.NumberOfDiscrepancyPackaging,
						Parameters.DiscrepanciesPostingMethod,
						Parameters.GroupUpdate,
						Parameters.TheLineToOrder,
						ThisIsSeparatePurchase);
	
	If Not GroupUpdate Then
		If NumberOfDiscrepancyPackaging >= 0 Then
			
			Items.Pages.CurrentPage = Items.Surpluses;
			ActionSurplus                   = Parameters.ChosenAction;
			
			If Parameters.ItemsType = Enums.ItemsTypes.Work_5
				Or Parameters.ItemsType = Enums.ItemsTypes.OperationService Then
				
				If ActionSurplus = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered Then
					ActionSurplus = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef();
				EndIf;
				
				Items.RegisterAndReturnOverdelivered.Visible                         = False;
				Items.ArrangeTheReDeliveredAndReturnTheDecoration.Visible                = False;
				Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title            = NStr("vi = 'Sẽ đảo ngược thao tác tạo dịch vụ hoặc công việc';
																								|ru = 'Операция по оформлению услуг или работы будет сторнирована';
																								|en = 'Registration of services or works will be reversed'; fa = 'Registration of services or works will be reversed';
																								|it = 'Операция по оформлению услуг или работы будет сторнирована';
																								|pl = 'Registration of services or works will be reversed';
																								|tr = 'Hizmet veya iş operasyonu iptal edilecektir'");
				Items.ReturnOverdeliveredWithoutRegistration.ChoiceList[0].Presentation = NStr("vi = 'Đảo ngược';
																								|ru = 'Сторнировать';
																								|en = 'Reverse'; fa = 'معکوس';
																								|it = 'Сторнировать';
																								|pl = 'Reverse';
																								|tr = 'İptal et'");
				
			EndIf;
			
		Else
			
			Items.Pages.CurrentPage = Items.Shortages;
			ShortfallAction = Parameters.ChosenAction;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Not ClosingInProgress And Modified Then
		
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject),
		               NStr("vi = 'Những thay đổi được thực hiện sẽ bị mất. Vẫn đóng?';
							|ru = 'Выполненные изменения будут утеряны. Все равно закрыть?';
							|en = 'Made changes will be lost. Close anyway?'; fa = 'Made changes will be lost. Close anyway?';
							|it = 'Le modifiche apportate andanno perse. Chiudere ugualmente?';
							|pl = 'Wprowadzone zmiany zostaną utracone. Zamknąć mimo wszystko?';
							|tr = 'Yapılan değişiklikler kaybolacaktır. Yine de kapatılsın mı?'"),
		               QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure AtOurExpenseOnChange(Item)
	
	OptionToReflectWriteOffToOtherExpensesWhenChanging();
	
EndProcedure

&AtClient
Procedure ThirdPartyIsGuiltyOnChange(Item)
	
	OptionToReflectWriteOffToOtherExpensesWhenChanging();
	
EndProcedure

&AtClient
Procedure Register_OnChange(Item)
	
	ActionOfShortageInCaseOfChange();
	
EndProcedure

&AtClient
Procedure RegisterAndWaitForGoodsReceiptWithoutInvoicesOnChange(Item)
	
	ActionOfShortageInCaseOfChange();
	
EndProcedure

&AtClient
Procedure WaitForGoodsReceiptWithoutInvoicesOnChange(Item)
	
	ActionOfShortageInCaseOfChange();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClosingInProgress = True;
	
	ClosingParameters = New Structure();
	ClosingParameters.Insert("ActionSurplus", Undefined);
	ClosingParameters.Insert("ShortfallAction", Undefined);
	ClosingParameters.Insert("ThirdPartyIsGuilty", True);
	
	If GroupUpdate Then
		
		ClosingParameters.ActionSurplus   = ActionSurplus;
		ClosingParameters.ShortfallAction = ShortfallAction;
		ClosingParameters.ThirdPartyIsGuilty = ThirdPartyIsGuilty();
		
	ElsIf NumberOfDiscrepancyPackaging > 0 Then
		
		ClosingParameters.ActionSurplus = ActionSurplus;

	ElsIf NumberOfDiscrepancyPackaging < 0 Then
		
		ClosingParameters.ShortfallAction = ShortfallAction;
		ClosingParameters.ThirdPartyIsGuilty = ThirdPartyIsGuilty();
		
	EndIf;
	
	Close(ClosingParameters);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ClosingInProgress = True;
	Close(Undefined);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateHeadings(TypeOfAct,
								NumberOfDiscrepancyPackaging,
								DiscrepanciesPostingMethod,
								GroupUpdate,
								TheLineToOrder,
								ThisIsSeparatePurchase)
	
	If TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Hàng thiếu khi tiếp nhận, đã thống nhất với nhà cung cấp';
														|ru = 'Недостачи при поступлении согласованы с поставщиком';
														|en = 'Shortages on receipt are approved by the vendor'; fa = 'Shortages on receipt are approved by the vendor';
														|it = 'Ammanchi in ricevuta concordati con il fornitore';
														|pl = 'Niedobory podczas wpływu są uzgodnione z dostawcą';
														|tr = 'Tedarikçi ile mutabık kalınan makbuz eksiklikleri'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Sự thiếu sót khi nhận không được thỏa thuận với nhà cung cấp';
													|ru = 'Недостачи при поступлении не согласованы с поставщиком';
													|en = 'Shortages on receipt are not approved by the vendor'; fa = 'Shortages on receipt are not approved by the vendor';
													|it = 'Ammanchi in ricevuta non concordati con il fornitore';
													|pl = 'Niedobory podczas wpływu nie są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınmayan makbuz eksiklikleri'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments Then
			If TheLineToOrder Or (GroupUpdate And UsePurchaseOrders) Then
				Items.DrawUpAShortfallDecoration.Title = NStr("vi = 'Việc mua hàng được giảm bởi hàng hóa chưa giao và tiếp theo, hủy bỏ các dòng chưa giao trong đơn hàng';
																|ru = 'Приобретение уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
																|en = 'Purchase is reduced by the amount of underdelivered goods, and underdelivered order lines are canceled'; fa = 'Purchase is reduced by the amount of underdelivered goods, and underdelivered order lines are canceled';
																|it = 'Приобретение уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
																|pl = 'Purchase is reduced by the amount of underdelivered goods, and underdelivered order lines are canceled';
																|tr = 'Giriş, eksik teslim edilen ürünler kadar azaltılır ve eksik teslim edilen sipariş satırları daha sonra iptal edilir'");
			Else
				Items.DrawUpAShortfallDecoration.Title = NStr("vi = 'Việc mua hàng bị giảm đối với hàng chưa giao';
																|ru = 'Приобретение уменьшается на недопоставленный товар';
																|en = 'Purchase is reduced by the amount of underdelivered goods'; fa = 'Purchase is reduced by the amount of underdelivered goods';
																|it = 'Приобретение уменьшается на недопоставленный товар';
																|pl = 'Purchase is reduced by the amount of underdelivered goods';
																|tr = 'Edinim, teslim edilmeyen ürünlerle azaltılır'");
			EndIf;
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title = NStr("vi = 'Giá trị mua hàng sẽ được giảm trừ tương ứng với số hàng giao thiếu, sau đó lập chứng từ mua mới đối với mặt hàng giao thiếu này';
																					|ru = 'Приобретение уменьшается на недопоставленный товар с последующим оформлением нового приобретения недопоставленного товара';
																					|en = 'Purchase is reduced by the amount of underdelivered goods, and a new purchase of underdelivered goods is registered'; fa = 'Purchase is reduced by the amount of underdelivered goods, and a new purchase of underdelivered goods is registered';
																					|it = 'Purchase is reduced by the amount of underdelivered goods, and a new purchase of underdelivered goods is registered';
																					|pl = 'Purchase is reduced by the amount of underdelivered goods, and a new purchase of underdelivered goods is registered';
																					|tr = 'Alım, teslim edilmeyen ürünlerden düşülür ve teslim edilmemiş ürünlere dair yeni bir alım kaydı tutulur (yama)'");
		ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.DrawUpAShortfallDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ điều chỉnh mua hàng (điều chỉnh)';
															|ru = 'На недопоставленный товар оформляется корректировка приобретения (исправление)';
															|en = 'For underdelivered goods, purchase adjustment (correction) is registered'; fa = 'For underdelivered goods, purchase adjustment (correction) is registered';
															|it = 'For underdelivered goods, purchase adjustment (correction) is registered';
															|pl = 'For underdelivered goods, purchase adjustment (correction) is registered';
															|tr = 'Teslim edilmemiş ürünler için satın alma düzeltmesi yapılır (yama)'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title = NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ điều chỉnh mua hàng, sau đó lập chứng từ mới';
																					|ru = 'На недопоставленный товар оформляется корректировка приобретения (исправление) с последующим оформлением нового приобретения недопоставленного товара';
																					|en = 'For underdelivered goods, purchase adjustment (correction) is registered, and a new purchase of the underdelivered goods is registered'; fa = 'For underdelivered goods, purchase adjustment (correction) is registered, and a new purchase of the underdelivered goods is registered';
																					|it = 'For underdelivered goods, purchase adjustment (correction) is registered, and a new purchase of the underdelivered goods is registered';
																					|pl = 'For underdelivered goods, purchase adjustment (correction) is registered, and a new purchase of the underdelivered goods is registered';
																					|tr = 'Eksik teslim edilmiş ürünlere bir alım ayarlaması yapılır ve eksik teslim edilmiş ürünlere ilişkin yeni bir alım yapılır (yama)'");
		EndIf;
		
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title = NStr("vi = 'Đợi tiếp nhận hàng giao thiếu, chưa tạo lại chứng từ mua hàng';
																				|ru = 'Ожидается поступление недопоставленного товара, документ приобретения не переоформляется';
																				|en = 'Pending receipt of underdelivered goods. The purchase document is not re-registered'; fa = 'Pending receipt of underdelivered goods. The purchase document is not re-registered';
																				|it = 'Ожидается поступление недопоставленного товара, документ приобретения не переоформляется';
																				|pl = 'Pending receipt of underdelivered goods. The purchase document is not re-registered';
																				|tr = 'Teslim edilmeyen ürünlerin teslim alınması beklenir, satın alma belgesi yeniden düzenlenmez'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title   = NStr("vi = 'Hàng lại khi nhận có thỏa thuận với nhà cung cấp';
													|ru = 'Излишки при поступлении согласованы с поставщиком';
													|en = 'Surpluses on receipt are approved by the vendor'; fa = 'Surpluses on receipt are approved by the vendor';
													|it = 'Eccedenze in entrata concordate con il fornitore';
													|pl = 'Nadmiary podczas wpływu są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınan makbuz fazlası'");
		Items.GroupSurplusesNotAgreed.Title = NStr("vi = 'Hàng thừa khi nhận không được thỏa thuận với nhà cung cấp';
													|ru = 'Излишки при поступлении не согласованы с поставщиком';
													|en = 'Surpluses on receipt are not approved by the vendor'; fa = 'Surpluses on receipt are not approved by the vendor';
													|it = 'Eccedenze in entrata non concordate con il fornitore';
													|pl = 'Nadmiary podczas wpływu nie są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınmayan makbuz fazlalıkları'");

		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments Then
			Items.ArrangeTheRepostedDecoration.Title = NStr("vi = 'Việc mua hàng được tăng lên đối với hàng hóa giao lại';
															|ru = 'Приобретение увеличивается на перепоставленный товар';
															|en = 'Purchase is increased by the amount of overdelivered goods'; fa = 'Purchase is increased by the amount of overdelivered goods';
															|it = 'Приобретение увеличивается на перепоставленный товар';
															|pl = 'Purchase is increased by the amount of overdelivered goods';
															|tr = 'Edinim, arz fazlası ürünlerle artırılır'");
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title = NStr("vi = 'Việc mua hàng được tăng lên do hàng giao lại và tiếp theo, tạo trả lại đối với hàng giao lại';
																			|ru = 'Приобретение увеличивается на перепоставленный товар с последующим оформлением возврата перепоставленного товара';
																			|en = 'Purchase is increased by the amount of overdelivered goods, and a return of the overdelivered goods is registered'; fa = 'Purchase is increased by the amount of overdelivered goods, and a return of the overdelivered goods is registered';
																			|it = 'Приобретение увеличивается на перепоставленный товар с последующим оформлением возврата перепоставленного товара';
																			|pl = 'Purchase is increased by the amount of overdelivered goods, and a return of the overdelivered goods is registered';
																			|tr = 'Edinim, yeniden teslim edilen ürünlerin iadesinin daha sonra kaydedilmesiyle birlikte yeniden teslim edilen ürünlerle artırılır'");
		ElsIf DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.ArrangeTheRepostedDecoration.Title = NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ điều chỉnh mua hàng';
															|ru = 'На перепоставленный товар оформляется корректировка приобретения (исправление)';
															|en = 'For overdelivered goods, purchase adjustment (correction) is registered'; fa = 'For overdelivered goods, purchase adjustment (correction) is registered';
															|it = 'For overdelivered goods, purchase adjustment (correction) is registered';
															|pl = 'For overdelivered goods, purchase adjustment (correction) is registered';
															|tr = 'Yeniden teslim edilen ürünler için alım düzeltmesi yapılır (yama)'");
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title = NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ điều chỉnh mua, sau đó lập chứng từ trả lại mặt hàng giao lại';
																			|ru = 'На перепоставленный товар оформляется корректировка приобретения (исправление) с последующим оформлением возврата перепоставленного товара';
																			|en = 'For overdelivered goods, purchase adjustment (correction) is registered, and a new overdelivered goods return is registered'; fa = 'For overdelivered goods, purchase adjustment (correction) is registered, and a new overdelivered goods return is registered';
																			|it = 'For overdelivered goods, purchase adjustment (correction) is registered, and a new overdelivered goods return is registered';
																			|pl = 'For overdelivered goods, purchase adjustment (correction) is registered, and a new overdelivered goods return is registered';
																			|tr = 'Fazla teslim edilen mallar için alım ayarlaması yapılır ve sonrasında ise fazla teslim edilen ürünler iade edilir (yama)'");
		EndIf;
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title = NStr("vi = 'Chênh lệch giữa tiếp nhận và mua hàng có liên quan đến thu nhập khác, chưa tạo lại chứng từ';
																				|ru = 'Расхождения между поступлением и приобретением относятся на прочие доходы, документы не переоформляются';
																				|en = 'Discrepancies between receipt and purchase are allocated to other income. The documents are not reregistered'; fa = 'Discrepancies between receipt and purchase are allocated to other income. The documents are not reregistered';
																				|it = 'Расхождения между поступлением и приобретением относятся на прочие доходы, документы не переоформляются';
																				|pl = 'Discrepancies between receipt and purchase are allocated to other income. The documents are not reregistered';
																				|tr = 'Giriş ve edinim arasındaki tutarsızlıklar diğer gelirlere yansıtılır, belgeler yeniden düzenlenmez'");
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title  = NStr("vi = 'Hàng hóa được vận chuyển lại được vận chuyển từ kho, chứng từ không được xuất lại';
																			|ru = 'Перепоставленный товар отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered goods are shipped from the warehouse. The documents are not registered'; fa = 'Overdelivered goods are shipped from the warehouse. The documents are not registered';
																			|it = 'Il prodotto riconsegnato viene spedito dal magazzino, i documenti non sono eseguiti nuovamente';
																			|pl = 'Nadmiar towaru wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
																			|tr = 'Yeniden tedarik edilen mallar depodan sevk edilir, belgeler yeniden düzenlenmez'");
		
	ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Hàng thiếu khi trả lại đã được thỏa thuận với khách hàng';
														|ru = 'Недостачи при возврате согласованы с клиентом';
														|en = 'Shortages on return are agreed with the customer'; fa = 'Shortages on return are agreed with the customer';
														|it = 'Ammanchi alla restituzione concordati con il cliente';
														|pl = 'Niedobory podczas zwrotu są uzgodnione z klientem';
														|tr = 'Müşteri ile mutabık kalınan iade eksiklikleri'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Hàng thiếu khi trả lại không được thỏa thuận với khách hàng';
													|ru = 'Недостачи при возврате не согласованы с клиентом';
													|en = 'Shortages on return are not agreed with the customer'; fa = 'Shortages on return are not agreed with the customer';
													|it = 'Ammanchi alla restituzione non concordati con il cliente';
													|pl = 'Niedobory podczas zwrotu nie są uzgodnione z klientem';
													|tr = 'Müşteri ile mutabık kalınmayan iade eksiklikleri'");
		
		Items.DrawUpAShortfallDecoration.Title                   = NStr("vi = 'Việc trả lại hàng hóa từ khách hàng bị giảm đối với hàng hóa giao thiếu';
																		|ru = 'Возврат товаров от клиента уменьшается на недопоставленный товар';
																		|en = 'Return of goods from the customer is reduced by the amount of underdelivered goods'; fa = 'Return of goods from the customer is reduced by the amount of underdelivered goods';
																		|it = 'La restituzione del prodotto dal cliente diminuisce con i prodotti non riconsegnati';
																		|pl = 'Zwrot towaru od klienta zmniejsza się o niedostarczone towary';
																		|tr = 'Müşteriden gelen iadeler teslim edilmeyen mallar kadar azaltılır'");
		Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title = NStr("vi = 'Việc nhận hàng hóa bị trả lại bị giảm đối với hàng hóa giao thiếu, sau đó tạo chứng từ trả lại mới của hàng hóa giao thiếu';
																				|ru = 'Возврат товаров от клиента уменьшается на недопоставленный товар с последующим оформлением нового возврата недопоставленного товара';
																				|en = 'Return of goods from the customer is reduced by the amount of underdelivered goods. A new return of underdelivered goods will be registered'; fa = 'Return of goods from the customer is reduced by the amount of underdelivered goods. A new return of underdelivered goods will be registered';
																				|it = 'La restituzione del prodotto dal cliente diminuisce con i prodotti non consegnati con la successiva registrazione della nuova restituzione dei beni non consegnati';
																				|pl = 'Zwrot towaru od klienta zmniejsza się o niedostarczone towary z późniejszym sporządzeniem nowego zwrotu niedostarczonych towarów';
																				|tr = 'Müşteriden gelen iadeler teslim edilmeyen mallar kadar azaltılır ve teslim edilmeyen mallar için yeni bir iade düzenlenir'");
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title      = NStr("vi = 'Đợi tiếp nhận hàng giao thiếu, chưa tạo lại chứng từ mua hàng';
																					|ru = 'Ожидается поступление недопоставленного товара, документ приобретения не переоформляется';
																					|en = 'Pending receipt of underdelivered goods. The purchase document is not re-registered'; fa = 'Pending receipt of underdelivered goods. The purchase document is not re-registered';
																					|it = 'Ожидается поступление недопоставленного товара, документ приобретения не переоформляется';
																					|pl = 'Pending receipt of underdelivered goods. The purchase document is not re-registered';
																					|tr = 'Teslim edilmeyen ürünlerin teslim alınması beklenir, satın alma belgesi yeniden düzenlenmez'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title = NStr("vi = 'Hàng thừa khi trả lại đã thỏa thuận với nhà cung cấp';
												|ru = 'Излишки при возврате согласованы с поставщиком';
												|en = 'Surpluses on return are approved by the vendor'; fa = 'Surpluses on return are approved by the vendor';
												|it = 'Eccedenze alla riconsegna concordate con il fornitore';
												|pl = 'Nadmiary podczas zwrotu są uzgodnione z dostawcą';
												|tr = 'Tedarikçi ile mutabık kalınan iade fazlalıkları'");
		Items.GroupSurplusesNotAgreed.Title  = NStr("vi = 'Hàng thừa khi trả lại không thỏa thuận với nhà cung cấp';
													|ru = 'Излишки при возврате не согласованы с поставщиком';
													|en = 'Surpluses on return are not approved by the vendor'; fa = 'Surpluses on return are not approved by the vendor';
													|it = 'Eccedenze alla riconsegna non concordate con il fornitore';
													|pl = 'Nadmiary podczas zwrotu nie są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınmayan iade fazlalıkları'");
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title  = NStr("vi = 'Lợi nhuận vượt quá được vốn hóa, được phân bổ cho thu nhập khác, chứng từ không được cấp lại';
																					|ru = 'Излишки возврата оприходуются, относятся на прочие доходы, документы не переоформляются';
																					|en = 'Return surpluses are received and allocated to income, documents are not reregistered'; fa = 'Return surpluses are received and allocated to income, documents are not reregistered';
																					|it = 'Le eccedenze alla riconsegna sono accreditate ad altre entrate, i documenti non vengono riemessi';
																					|pl = 'Nadmiar dostarczanego towaru jest księgowany, zalicza się do innych dochodów, dokumenty nie są sporządzane ponownie';
																					|tr = 'Fazla iadeler kaydedilir, diğer gelirlere yansıtılır, belgeler yeniden düzenlenmez'");
		Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title       = NStr("vi = 'Việc nhận hàng bán bị trả lại được tăng lên bởi hàng hóa giao lại, sau đó tạo tiếp theo chứng từ tiếp nhận của hàng hóa giao lại';
																			|ru = 'Возврат товаров от клиента увеличивается на перепоставленный товар с последующим оформлением поступления перепоставленного товара';
																			|en = 'Return of goods from the customer is increased by the amount of overdelivered goods. A receipt of overdelivered goods will be registered'; fa = 'Return of goods from the customer is increased by the amount of overdelivered goods. A receipt of overdelivered goods will be registered';
																			|it = 'La restituzione delle merci dal cliente viene incrementata con i prodotti riconsegnati con la successiva esecuzione della ricevuta della merce consegnata';
																			|pl = 'Zwrot towaru od klienta zwiększa się o nadmiar dostarczonych towarów z późniejszym sporządzeniem wpływu nadmiaru dostarczanego towaru';
																			|tr = 'Müşteriden gelen iadeler, fazla tedarik edilen mallar nedeniyle artar, ardından fazla tedarik edilen mallar teslim alınır'");
		Items.ArrangeTheRepostedDecoration.Title               = NStr("vi = 'Việc nhận hàng bán bị trả lại được tăng lên đối với hàng hóa giao lại';
																		|ru = 'Возврат товаров от клиента увеличивается на перепоставленный товар';
																		|en = 'Return of goods from the customer is increased by the amount of overdelivered goods'; fa = 'Return of goods from the customer is increased by the amount of overdelivered goods';
																		|it = 'La restituzione dal cliente aumenta con i prodotti riconsegnati';
																		|pl = 'Zwrot towaru od klienta zwiększa się o nadmiar dostarczonych towarów';
																		|tr = 'Müşteriden gelen iadeler, fazla tedarik edilen mallar nedeniyle artar'");
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title   = NStr("vi = 'Hàng hóa được vận chuyển lại được vận chuyển từ kho, chứng từ không được xuất lại';
																			|ru = 'Перепоставленный товар отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered goods are shipped from the warehouse. The documents are not registered'; fa = 'Overdelivered goods are shipped from the warehouse. The documents are not registered';
																			|it = 'Il prodotto riconsegnato viene spedito dal magazzino, i documenti non sono eseguiti nuovamente';
																			|pl = 'Nadmiar towaru wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
																			|tr = 'Yeniden tedarik edilen mallar depodan sevk edilir, belgeler yeniden düzenlenmez'");
		
	ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Hàng thiếu khi tiếp nhận, đã thống nhất với nhà cung cấp';
														|ru = 'Недостачи при поступлении согласованы с поставщиком';
														|en = 'Shortages on receipt are approved by the vendor'; fa = 'Shortages on receipt are approved by the vendor';
														|it = 'Ammanchi in ricevuta concordati con il fornitore';
														|pl = 'Niedobory podczas wpływu są uzgodnione z dostawcą';
														|tr = 'Tedarikçi ile mutabık kalınan makbuz eksiklikleri'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Sự thiếu sót khi nhận không được thỏa thuận với nhà cung cấp';
													|ru = 'Недостачи при поступлении не согласованы с поставщиком';
													|en = 'Shortages on receipt are not approved by the vendor'; fa = 'Shortages on receipt are not approved by the vendor';
													|it = 'Ammanchi in ricevuta non concordati con il fornitore';
													|pl = 'Niedobory podczas wpływu nie są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınmayan makbuz eksiklikleri'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			If TheLineToOrder Or (GroupUpdate And UsePurchaseOrders) Then
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ nhập hàng vào kho (điều chỉnh), sau đó hủy các dòng giao thiếu trong đơn hàng';
							|ru = 'На недопоставленный товар оформляется приемка на хранение (исправление) с последующей отменой недопоставленных строк заказа';
							|en = 'For underdelivered goods, receipt for storage (correction) is registered, followed by cancellation of the underdelivered order lines'; fa = 'For underdelivered goods, receipt for storage (correction) is registered, followed by cancellation of the underdelivered order lines';
							|it = 'For underdelivered goods, receipt for storage (correction) is registered, followed by cancellation of the underdelivered order lines';
							|pl = 'For underdelivered goods, receipt for storage (correction) is registered, followed by cancellation of the underdelivered order lines';
							|tr = 'Eksik teslim edilen ürünler, eksik teslim edilen sipariş satırlarının sonradan iptaliyle depolama için kabul edilir (yama)'");
			Else
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ nhập hàng vào kho (điều chỉnh)';
							|ru = 'На недопоставленный товар оформляется приемка на хранение (исправление)';
							|en = 'For underdelivered goods, VMI procurement (correction) is registered'; fa = 'For underdelivered goods, VMI procurement (correction) is registered';
							|it = 'For underdelivered goods, VMI procurement (correction) is registered';
							|pl = 'For underdelivered goods, VMI procurement (correction) is registered';
							|tr = 'Eksik teslim edilen ürünler, depolama için kabul edilir (yama)'");
			EndIf;
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ nhập hàng vào kho (điều chỉnh), sau đó lập chứng từ tiếp nhận mới đối với mặt hàng giao thiếu';
						|ru = 'На недопоставленный товар оформляется приемка на хранение (исправление) с последующим оформлением нового поступления недопоставленного товара';
						|en = 'For underdelivered goods, VMI procurement (correction) is registered, and a new underdelivered goods receipt is registered'; fa = 'For underdelivered goods, VMI procurement (correction) is registered, and a new underdelivered goods receipt is registered';
						|it = 'For underdelivered goods, VMI procurement (correction) is registered, and a new underdelivered goods receipt is registered';
						|pl = 'For underdelivered goods, VMI procurement (correction) is registered, and a new underdelivered goods receipt is registered';
						|tr = 'Eksik teslim edilen ürünler, eksik teslim edilen ürünlerin yeni bir makbuzunun sonradan kaydedilmesiyle depolama için kabul edilir (yama)'");
		Else
			If TheLineToOrder Or (GroupUpdate And UsePurchaseOrders) Then
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Việc mua hàng được giảm bởi hàng hóa chưa giao và tiếp theo, hủy bỏ các dòng chưa giao trong đơn hàng';
							|ru = 'Приобретение уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
							|en = 'Purchase is reduced by the amount of underdelivered goods, and underdelivered order lines are canceled'; fa = 'Purchase is reduced by the amount of underdelivered goods, and underdelivered order lines are canceled';
							|it = 'Приобретение уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
							|pl = 'Purchase is reduced by the amount of underdelivered goods, and underdelivered order lines are canceled';
							|tr = 'Giriş, eksik teslim edilen ürünler kadar azaltılır ve eksik teslim edilen sipariş satırları daha sonra iptal edilir'");
			Else
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Việc mua hàng bị giảm đối với hàng chưa giao';
							|ru = 'Приобретение уменьшается на недопоставленный товар';
							|en = 'Purchase is reduced by the amount of underdelivered goods'; fa = 'Purchase is reduced by the amount of underdelivered goods';
							|it = 'Приобретение уменьшается на недопоставленный товар';
							|pl = 'Purchase is reduced by the amount of underdelivered goods';
							|tr = 'Edinim, teslim edilmeyen ürünlerle azaltılır'");
			EndIf;
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Mua hàng được giảm bởi hàng hóa chưa được giao và tiếp theo, tạo tiếp nhận mới đối với hàng hóa chưa giao';
						|ru = 'Приобретение уменьшается на недопоставленный товар с последующим оформлением нового поступления недопоставленного товара';
						|en = 'Purchase is reduced by the amount of underdelivered goods, and a new receipt of the underdelivered goods is registered'; fa = 'Purchase is reduced by the amount of underdelivered goods, and a new receipt of the underdelivered goods is registered';
						|it = 'Приобретение уменьшается на недопоставленный товар с последующим оформлением нового поступления недопоставленного товара';
						|pl = 'Purchase is reduced by the amount of underdelivered goods, and a new receipt of the underdelivered goods is registered';
						|tr = 'Edinim, teslim edilmeyen ürünler kadar azaltılır ve teslim edilmeyen ürünler için yeni bir giriş işlenir'");
		EndIf;
		
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title = NStr("vi = 'Đang đợi tiếp nhận mặt hàng giao thiếu, không lập lại chứng từ nhập hàng';
																				|ru = 'Ожидается поступление недопоставленного товара, документ приемки не переоформляется';
																				|en = 'Pending receipt of underdelivered goods. The receipt document is not reregistered'; fa = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|it = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|pl = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|tr = 'Teslim edilmeyen ürünlerin alınması beklenir, kabul belgesi yeniden düzenlenmez'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title   = NStr("vi = 'Hàng lại khi nhận có thỏa thuận với nhà cung cấp';
													|ru = 'Излишки при поступлении согласованы с поставщиком';
													|en = 'Surpluses on receipt are approved by the vendor'; fa = 'Surpluses on receipt are approved by the vendor';
													|it = 'Eccedenze in entrata concordate con il fornitore';
													|pl = 'Nadmiary podczas wpływu są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınan makbuz fazlası'");
		Items.GroupSurplusesNotAgreed.Title = NStr("vi = 'Hàng thừa khi nhận không được thỏa thuận với nhà cung cấp';
													|ru = 'Излишки при поступлении не согласованы с поставщиком';
													|en = 'Surpluses on receipt are not approved by the vendor'; fa = 'Surpluses on receipt are not approved by the vendor';
													|it = 'Eccedenze in entrata non concordate con il fornitore';
													|pl = 'Nadmiary podczas wpływu nie są uzgodnione z dostawcą';
													|tr = 'Tedarikçi ile mutabık kalınmayan makbuz fazlalıkları'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ nhập hàng vào kho (điều chỉnh)';
						|ru = 'На перепоставленный товар оформляется приемка на хранение (исправление)';
						|en = 'For overdelivered goods, VMI procurement (correction) is registered'; fa = 'For overdelivered goods, VMI procurement (correction) is registered';
						|it = 'For overdelivered goods, VMI procurement (correction) is registered';
						|pl = 'For overdelivered goods, VMI procurement (correction) is registered';
						|tr = 'Yeniden teslim edilen ürünler için depolama kabulü yapılır (yama)'");
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ nhập hàng vào kho (điều chỉnh), sau đó lập chứng từ xuất kho mặt hàng lại';
						|ru = 'На перепоставленный товар оформляется приемка на хранение (исправление) с последующим оформлением отгрузки перепоставленного товара';
						|en = 'For overdelivered goods, VMI procurement (correction) is registered, and a new shipment of overdelivered goods is registered'; fa = 'For overdelivered goods, VMI procurement (correction) is registered, and a new shipment of overdelivered goods is registered';
						|it = 'For overdelivered goods, VMI procurement (correction) is registered, and a new shipment of overdelivered goods is registered';
						|pl = 'For overdelivered goods, VMI procurement (correction) is registered, and a new shipment of overdelivered goods is registered';
						|tr = 'Yeniden teslim edilen ürünler için depolama kabulü gerçekleştirilir ve sonrasında ise yeniden teslim edilen ürünlerin sevkiyatı kaydedilir (yama)'");
		Else
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Việc mua hàng được tăng lên đối với hàng hóa giao lại';
						|ru = 'Приобретение увеличивается на перепоставленный товар';
						|en = 'Purchase is increased by the amount of overdelivered goods'; fa = 'Purchase is increased by the amount of overdelivered goods';
						|it = 'Приобретение увеличивается на перепоставленный товар';
						|pl = 'Purchase is increased by the amount of overdelivered goods';
						|tr = 'Edinim, arz fazlası ürünlerle artırılır'");
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Việc mua hàng được tăng lên do hàng giao lại và tiếp theo, tạo giao hàng đối với hàng giao lại';
						|ru = 'Приобретение увеличивается на перепоставленный товар с последующим оформлением отгрузки перепоставленного товара';
						|en = 'Purchase is increased by the amount of overdelivered goods, and shipment of the overdelivered goods is registered'; fa = 'Purchase is increased by the amount of overdelivered goods, and shipment of the overdelivered goods is registered';
						|it = 'Приобретение увеличивается на перепоставленный товар с последующим оформлением отгрузки перепоставленного товара';
						|pl = 'Purchase is increased by the amount of overdelivered goods, and shipment of the overdelivered goods is registered';
						|tr = 'Edinim, yeniden teslim edilen ürünlerin sevkiyatından daha sonra kaydedilmesiyle birlikte yeniden teslim edilen ürünlerle artırılır'");
		EndIf;
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title = NStr("vi = 'Hàng hóa giao lại được ghi tăng, không cần tạo chứng từ';
																				|ru = 'Перепоставленный товар оприходуется, документы не переоформляются';
																				|en = 'Overdelivered goods will be received, documents are not reissued'; fa = 'Overdelivered goods will be received, documents are not reissued';
																				|it = 'La merce consegnata oltre l''ordine verrà registrata come ricevuta, i documenti non verranno riemessi';
																				|pl = 'Nadwyżka towaru przyjmuje się na stan, dokumenty nie są sporządzane ponownie';
																				|tr = 'Yeniden teslim edilen mallar kaydedilir, belgeler yeniden düzenlenmez'");
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title  = NStr("vi = 'Hàng hóa được vận chuyển lại được vận chuyển từ kho, chứng từ không được xuất lại';
																			|ru = 'Перепоставленный товар отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered goods are shipped from the warehouse. The documents are not registered'; fa = 'Overdelivered goods are shipped from the warehouse. The documents are not registered';
																			|it = 'Il prodotto riconsegnato viene spedito dal magazzino, i documenti non sono eseguiti nuovamente';
																			|pl = 'Nadmiar towaru wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
																			|tr = 'Yeniden tedarik edilen mallar depodan sevk edilir, belgeler yeniden düzenlenmez'");
		
	ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Sự thiếu sót khi nhận được thỏa thuận với người giám sát';
														|ru = 'Недостачи при поступлении согласованы с хранителем';
														|en = 'Shortages on receipt are agreed with the custodian'; fa = 'Shortages on receipt are agreed with the custodian';
														|it = 'Gli ammanchi alla ricezione sono stati concordati con il depositario';
														|pl = 'Niedobory podczas nadejścia zostały uzgodnione z opiekunem';
														|tr = 'Emanetçi ile mutabık kalınan makbuz eksiklikleri'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Sự thiếu sót khi nhận không được thỏa thuận với người giám sát';
													|ru = 'Недостачи при поступлении не согласованы с хранителем';
													|en = 'Shortages on receipt are not agreed with custodian'; fa = 'Shortages on receipt are not agreed with custodian';
													|it = 'Gli ammanchi alla ricezione non sono concordati con il depositario';
													|pl = 'Niedobory podczas nadejścia nie zostały uzgodnione z opiekunem';
													|tr = 'Emanetçi ile mutabık kalınmayan makbuz eksiklikleri'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.DrawUpAShortfallDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ bên lưu kho (điều chỉnh)';
						|ru = 'На недопоставленный товар оформляется поступление от хранителя (исправление)';
						|en = 'For underdelivered goods, a VMI return (correction) is registered'; fa = 'For underdelivered goods, a VMI return (correction) is registered';
						|it = 'For underdelivered goods, a VMI return (correction) is registered';
						|pl = 'For underdelivered goods, a VMI return (correction) is registered';
						|tr = 'Teslim edilmeyen ürünler için emanetçiden makbuz alınır (yama)'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ bên lưu kho (điều chỉnh), sau đó lập chứng từ tiếp nhận mới cho mặt hàng giao thiếu';
						|ru = 'На недопоставленный товар оформляется поступление от хранителя (исправление) с последующим оформлением нового поступления недопоставленного товара';
						|en = 'For underdelivered goods, a VMI return (correction) is registered, and a new underdelivered goods receipt is registered'; fa = 'For underdelivered goods, a VMI return (correction) is registered, and a new underdelivered goods receipt is registered';
						|it = 'For underdelivered goods, a VMI return (correction) is registered, and a new underdelivered goods receipt is registered';
						|pl = 'For underdelivered goods, a VMI return (correction) is registered, and a new underdelivered goods receipt is registered';
						|tr = 'Teslim edilmeyen ürünler için emanetçiden makbuz alınır ve sonrasında ise teslim edilmeyen ürünler için yeni bir makbuz alınır (düzeltme)'");
		Else
			Items.DrawUpAShortfallDecoration.Title
				= NStr("vi = 'Việc tiếp nhận hàng từ bên lưu kho bị giảm bởi mặt hàng giao thiếu';
						|ru = 'Поступление товаров от хранителя уменьшается на недопоставленный товар';
						|en = 'VMI return is reduced by short-delivered goods.'; fa = 'VMI return is reduced by short-delivered goods.';
						|it = 'La ricezione delle merci dal depositario diminuisce per la merce non consegnata';
						|pl = 'Nadejście towarów od opiekuna zostaje pomniejszone na nie dostarczony towar';
						|tr = 'VMI''dan gelen mal makbuzu teslim edilmeyen mallar kadar azaltılır'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng từ bên lưu kho bị giảm bởi mặt hàng giao thiếu, sau đó lập chứng từ tiếp nhận mới cho hàng hóa giao thiếu';
						|ru = 'Поступление товаров от хранителя уменьшается на недопоставленный товар с последующим оформлением нового поступления недопоставленного товара';
						|en = 'VMI return is reduced by short-delivered goods, and a new receipt of short-delivered goods is issued'; fa = 'VMI return is reduced by short-delivered goods, and a new receipt of short-delivered goods is issued';
						|it = 'La ricezione delle merci dal depositario diminuisce per la merce non consegnata con la successiva formalizzazione della nuova ricezione delle merci non consegnate';
						|pl = 'Nadejście towarów od opiekuna zostaje pomniejszone na nie dostarczony towar z późniejszym sporządzeniem nowego nadejścia nie dostarczonego towaru';
						|tr = 'VMI''dan gelen mal makbuzu teslim edilmeyen mallar kadar azaltılır ve teslim edilmeyen mallar için yeni bir makbuz düzenlenir'");
		EndIf;
		
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title = NStr("vi = 'Đang đợi tiếp nhận mặt hàng giao thiếu, không lập lại chứng từ nhập hàng';
																				|ru = 'Ожидается поступление недопоставленного товара, документ приемки не переоформляется';
																				|en = 'Pending receipt of underdelivered goods. The receipt document is not reregistered'; fa = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|it = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|pl = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|tr = 'Teslim edilmeyen ürünlerin alınması beklenir, kabul belgesi yeniden düzenlenmez'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title = NStr("vi = 'Hàng thừa khi tiếp nhận có thỏa thuận với bên lưu kho';
												|ru = 'Излишки при поступлении согласованы с хранителем';
												|en = 'Surpluses on receipt are agreed with the custodian'; fa = 'Surpluses on receipt are agreed with the custodian';
												|it = 'Eccedenze alla ricezione sono stati concordati con il depositario';
												|pl = 'Nadwyżki przy nadejściu zostały uzgodnione z opiekunem';
												|tr = 'VMI ile mutabık kalınan makbuz fazlalıkları'");
		Items.GroupSurplusesNotAgreed.Title  = NStr("vi = 'Hàng thừa khi trả lại không thỏa thuận với bên lưu kho';
													|ru = 'Излишки при возврате не согласованы с хранителем';
													|en = 'Surpluses on return are not agreed with the custodian'; fa = 'Surpluses on return are not agreed with the custodian';
													|it = 'Eccedenze alla restituzione non sono state concordate con il depositario';
													|pl = 'Nadwyżki przy nadejściu nie zostały uzgodnione z opiekunem';
													|tr = 'Emanetçi ile mutabık kalınmayan iade fazlalıkları'");
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title
			= NStr("vi = 'Hàng thừa khi tiếp nhận từ bên lưu kho được ghi tăng theo thu nhập khác, không cần lập lại chứng từ';
					|ru = 'Излишки поступления товаров от хранителя оприходуются, относятся на прочие доходы, документы не переоформляются';
					|en = 'Surplus goods are received from the custodian and allocated to income; the documents are not reissued'; fa = 'Surplus goods are received from the custodian and allocated to income; the documents are not reissued';
					|it = 'Le eccedenze alla ricezione delle merci dal depositario vengono registrate come ricevute, vengono attribuite ad altre entrate, i documenti non vengono riemessi';
					|pl = 'Nadwyżki nadejścia towarów od opiekuna są przyjmowane na stan, traktują się jak inne dochody, dokumenty nie są sporządzane ponownie';
					|tr = 'VMI''dan alınan makbuz fazlalıkları kaydedilir, diğer gelirlere yansıtılır, belgeler yeniden düzenlenmez'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ bên lưu kho (điều chỉnh), sau đó lập chứng từ chuyển giao mặt hàng giao lại';
						|ru = 'На перепоставленный товар оформляется поступление от хранителя (исправление) с последующим оформлением передачи перепоставленного товара';
						|en = 'For overdelivered goods, a VMI return (correction) is registered, and a new transfer of overdelivered goods is registered'; fa = 'For overdelivered goods, a VMI return (correction) is registered, and a new transfer of overdelivered goods is registered';
						|it = 'For overdelivered goods, a VMI return (correction) is registered, and a new transfer of overdelivered goods is registered';
						|pl = 'For overdelivered goods, a VMI return (correction) is registered, and a new transfer of overdelivered goods is registered';
						|tr = 'Yeniden teslim edilen ürünler için emanetçiden makbuz alınır ve sonrasında iseyeniden teslim edilen ürünlerin transferi kaydedilir (düzeltme)'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ bên lưu kho (điều chỉnh)';
						|ru = 'На перепоставленный товар оформляется поступление от хранителя (исправление)';
						|en = 'For overdelivered goods, a VMI return (correction) is registered'; fa = 'For overdelivered goods, a VMI return (correction) is registered';
						|it = 'For overdelivered goods, a VMI return (correction) is registered';
						|pl = 'For overdelivered goods, a VMI return (correction) is registered';
						|tr = 'Teslim edilmeyen ürünler için emanetçiden makbuz oluşturulur (yama)'");
		Else
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng hóa từ bên lưu kho tăng bởi mặt hàng giao lại, sau đó lập chứng từ chuyển giao hàng giao lại';
						|ru = 'Поступление товаров от хранителя увеличивается на перепоставленный товар с последующим оформлением передачи перепоставленного товара';
						|en = 'VMI return is increased by overdelivered goods, transfer of overdelivered goods will be registered'; fa = 'VMI return is increased by overdelivered goods, transfer of overdelivered goods will be registered';
						|it = 'La ricezione articoli dal magazzino risulterà aumentata con la successiva formalizzazione del trasferimento dell''articolo ricollocato';
						|pl = 'Wpływ towarów od opiekuna zwiększa się o nadwyżkę towaru z późniejszą rejestracją przekazania nadwyżki towaru';
						|tr = 'VMI''dan alınan mal makbuzları, fazla tedarik edilen mallar nedeniyle artar ve ardından fazla tedarik edilen malların devri yapılır'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng hóa từ bên lưu kho tăng theo mặt hàng giao lại';
						|ru = 'Поступление товаров от хранителя увеличивается на перепоставленный товар';
						|en = 'VMI return is increased by overdelivered goods'; fa = 'VMI return is increased by overdelivered goods';
						|it = 'La ricezione delle merci dal depositario aumenta per la merce consegnata oltre l''ordine';
						|pl = 'Nadejście towarów od opiekuna zwiększa się na nadwyżkę towaru';
						|tr = 'VMI''dan alınan mal makbuzları, fazla tedarik edilen mallar nedeniyle artar'");
		EndIf;
		
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title = NStr("vi = 'Hàng hóa được vận chuyển lại được vận chuyển từ kho, chứng từ không được xuất lại';
																			|ru = 'Перепоставленный товар отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered goods are shipped from the warehouse. The documents are not registered'; fa = 'Overdelivered goods are shipped from the warehouse. The documents are not registered';
																			|it = 'Il prodotto riconsegnato viene spedito dal magazzino, i documenti non sono eseguiti nuovamente';
																			|pl = 'Nadmiar towaru wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
																			|tr = 'Yeniden tedarik edilen mallar depodan sevk edilir, belgeler yeniden düzenlenmez'");
		
	ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Hàng thiếu khi tiếp nhận được thỏa thuận với người nhận ký gửi';
														|ru = 'Недостачи при поступлении согласованы с комиссионером';
														|en = 'Shortage upon receipt are approved by the consignee'; fa = 'Shortage upon receipt are approved by the consignee';
														|it = 'Ammanchi alle ricezioni concordate con il commissionario';
														|pl = 'Niedobory przy przyjęciu zostały uzgodnione z komisantem';
														|tr = 'Konsinye ile mutabık kalınan makbuz eksiklikleri'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Hàng thiếu khi tiếp nhận không được thỏa thuận với người nhận ký gửi';
													|ru = 'Недостачи при поступлении не согласованы с комиссионером';
													|en = 'Shortage upon receipt are not approved by the consignee'; fa = 'Shortage upon receipt are not approved by the consignee';
													|it = 'Ammanchi alle ricezioni non concordate con il commissionario';
													|pl = 'Niedobory przy przyjęciu nie zostały uzgodnione z komisantem';
													|tr = 'Konsinye ile mutabık kalınmayan makbuz eksiklikleri'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.DrawUpAShortfallDecoration.Title 
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ người nhận ký gửi (điều chỉnh)';
						|ru = 'На недопоставленный товар оформляется поступление от комиссионера (исправление)';
						|en = 'For underdelivered goods, a receipt from consignee (correction) is registered'; fa = 'For underdelivered goods, a receipt from consignee (correction) is registered';
						|it = 'For underdelivered goods, a receipt from consignee (correction) is registered';
						|pl = 'For underdelivered goods, a receipt from consignee (correction) is registered';
						|tr = 'Eksik teslim edilen ürünleriçin komisyon temsilcisinden makbuz alınır (yama)'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ người nhận ký gửi (điều chỉnh), sau đó lập chứng từ tiếp nhận mới đối với mặt hàng giao thiếu';
						|ru = 'На недопоставленный товар оформляется поступление от комиссионера (исправление) с последующим оформлением нового поступления недопоставленного товара';
						|en = 'For underdelivered goods, a receipt from consignee (correction) is registered, and a new underdelivered goods receipt is registered'; fa = 'For underdelivered goods, a receipt from consignee (correction) is registered, and a new underdelivered goods receipt is registered';
						|it = 'For underdelivered goods, a receipt from consignee (correction) is registered, and a new underdelivered goods receipt is registered';
						|pl = 'For underdelivered goods, a receipt from consignee (correction) is registered, and a new underdelivered goods receipt is registered';
						|tr = 'Eksik teslim edilen ürünler için komisyon temsilcisinden bir makbuz alınır ve sonrasında ise eksik teslim edilen ürünler için yeni bir makbuz alınır (yama)'");
		Else
			Items.DrawUpAShortfallDecoration.Title 
				= NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi ít hơn hàng hóa chưa giao';
						|ru = 'Поступление товаров от комиссионера уменьшается на недопоставленный товар';
						|en = 'Receipt of goods from the consignee is reduced by underdelivered goods'; fa = 'Receipt of goods from the consignee is reduced by underdelivered goods';
						|it = 'La ricezione articoli dal commissionario diminuisce con l''articolo non consegnato';
						|pl = 'Przyjęcie towarów od komisanta zmniejsza się na niedostarczone towar';
						|tr = 'Konsinyeden alınan mal makbuzu, teslim edilmeyen mallar nedeniyle azaltılır'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng từ người nhận ký gửi bị giảm bởi hàng hóa chưa được giao có lập chứng từ tiếp nhận mới gần nhất đối với hàng hóa chưa được giao';
						|ru = 'Поступление товаров от комиссионера уменьшается на недопоставленный товар с последующим оформлением нового поступления недопоставленного товара';
						|en = 'Goods receipt from the consignee is reduced by underdelivered goods, and new receipt of underdelivered goods is registered'; fa = 'Goods receipt from the consignee is reduced by underdelivered goods, and new receipt of underdelivered goods is registered';
						|it = 'La ricezione degli articoli dal commissionario diminuisce per l''articolo non consegnato con ultima registrazione di nuova ricezione dell''articolo non consegnato';
						|pl = 'Przyjęcie zewnętrzne od komisanta zostaje pomniejszone na niedostarczony towar z późniejszym utworzeniem nowego przyjęcia zewnętrznego niedostarczonego towaru';
						|tr = 'Konsinyeden alınan mal makbuzu teslim edilmeyen mallar kadar azaltılır ve teslim edilmeyen mallar için yeni bir makbuz düzenlenir'");
		EndIf;
		
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title = NStr("vi = 'Đang đợi tiếp nhận mặt hàng giao thiếu, không lập lại chứng từ nhập hàng';
																				|ru = 'Ожидается поступление недопоставленного товара, документ приемки не переоформляется';
																				|en = 'Pending receipt of underdelivered goods. The receipt document is not reregistered'; fa = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|it = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|pl = 'Pending receipt of underdelivered goods. The receipt document is not reregistered';
																				|tr = 'Teslim edilmeyen ürünlerin alınması beklenir, kabul belgesi yeniden düzenlenmez'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title = NStr("vi = 'Hàng thừa khi tiếp nhận được thỏa thuận với người nhận ký gửi';
												|ru = 'Излишки при поступлении согласованы с комиссионером';
												|en = 'Surplus upon receipt are approved by the consignee'; fa = 'Surplus upon receipt are approved by the consignee';
												|it = 'Eccedenze alle ricezioni concordate con il commissionario';
												|pl = 'Nadwyżki przy przyjęciu są uzgodnioneodnione z komisantem';
												|tr = 'Konsinye ile mutabık kalınan makbuz fazlalıkları'");
		Items.GroupSurplusesNotAgreed.Title  = NStr("vi = 'Hàng thừa khi tiếp nhận không được thỏa thuận với người nhận ký gửi';
													|ru = 'Излишки при возврате не согласованы с комиссионером';
													|en = 'Surplus upon return is not approved by the consignee'; fa = 'Surplus upon return is not approved by the consignee';
													|it = 'Eccedenze al reso non concordate con il commissionario';
													|pl = 'Nadwyżki przy zwrocie nie są uzgodnione z komisantem';
													|tr = 'Konsinye ile mutabık kalınmayan makbuz fazlalıkları'");
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title
			= NStr("vi = 'Hàng tiếp nhận thừa từ người nhận ký gửi được ghi tăng vào thu nhập khác, chưa lập lại chứng từ';
					|ru = 'Излишки поступления товаров от комиссионера оприходуются, относятся на прочие доходы, документы не переоформляются';
					|en = 'Surplus of the goods from the consignee are recognized and allocated to other income; the documents are not reregistered'; fa = 'Surplus of the goods from the consignee are recognized and allocated to other income; the documents are not reregistered';
					|it = 'Le eccedenze di ricezione articoli dal commissionario sono accettate, riferite ad altre entrate, i documenti non vanno registrati nuovamente';
					|pl = 'Nadwyżki przyjęcia zewnętrznego towarów od komisanta są przyjmowane na stan, należą do innych dochodów, dokumenty nie są tworzone ponownie';
					|tr = 'Konsinyeden alınan mal makbuzu fazlalıkları kaydedilir, diğer gelirlere yansıtılır, belgeler yeniden düzenlenmez'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ người nhận ký gửi (điều chỉnh), sau đó lập chứng từ tiếp nhận mặt hàng giao lại';
						|ru = 'На перепоставленный товар оформляется поступление от комиссионера (исправление) с последующим оформлением поступления перепоставленного товара';
						|en = 'For overdelivered goods, a receipt from the consignee (correction) is registered, and a new receipt of overdelivered goods is registered'; fa = 'For overdelivered goods, a receipt from the consignee (correction) is registered, and a new receipt of overdelivered goods is registered';
						|it = 'For overdelivered goods, a receipt from the consignee (correction) is registered, and a new receipt of overdelivered goods is registered';
						|pl = 'For overdelivered goods, a receipt from the consignee (correction) is registered, and a new receipt of overdelivered goods is registered';
						|tr = 'Yeniden teslim edilen ürünler için komisyon acentesinden alınan makbuz, yeniden teslim edilen ürünlerin teslim alındığına dair müteakip kayıt beraberinde resmileştirilir (yama)'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ người nhận ký gửi (điều chỉnh)';
						|ru = 'На перепоставленный товар оформляется поступление от комиссионера (исправление)';
						|en = 'For overdelivered goods, a receipt from the consignee (correction) is registered'; fa = 'For overdelivered goods, a receipt from the consignee (correction) is registered';
						|it = 'For overdelivered goods, a receipt from the consignee (correction) is registered';
						|pl = 'For overdelivered goods, a receipt from the consignee (correction) is registered';
						|tr = 'Yeniden teslim edilen ürünler için komisyon acentesinden alınan makbuz oluşturulur (yama)'");
		Else
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi tăng lên bởi hàng hóa đã giao lại có lập chứng từ tiếp nhận gần nhất đối với hàng hóa đã giao lại';
						|ru = 'Поступление товаров от комиссионера увеличивается на перепоставленный товар с последующим оформлением поступления перепоставленного товара';
						|en = 'Receipt of goods from the consignee is increased by the overdelivered goods, receipt of overdelivered goods will be registered'; fa = 'Receipt of goods from the consignee is increased by the overdelivered goods, receipt of overdelivered goods will be registered';
						|it = 'La ricezione articoli dal commissionario aumenta con l''articolo riconsegnato con l''ultima registrazione di ricezione articolo riconsegnato';
						|pl = 'Przyjęcie zewnętrzne od komisantów zwiększa się na nadwyżkę towaru z późniejszym utworzeniem przyjęcia zewnętrznego nadwyżki towaru';
						|tr = 'Konsinyeden alınan mal makbuzu, yeniden teslim edilen mallarla artırılır ve yeniden teslim edilmeyen mallar için bir makbuz düzenlenir'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi tăng lên bởi hàng hóa đã giao lại';
						|ru = 'Поступление товаров от комиссионера увеличивается на перепоставленный товар';
						|en = 'Receipt of goods from the consignee is increased by overdelivered goods'; fa = 'Receipt of goods from the consignee is increased by overdelivered goods';
						|it = 'La ricezione articoli dal commissionario aumenta con l''articolo riconsegnato';
						|pl = 'Przyjęcie towarów od komisanta zwiększa się o nadwyżkę towaru';
						|tr = 'Konsinyeden alınan mal makbuzu, fazla tedarik edilen mallar nedeniyle artırılır'");
		EndIf;
		
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title = NStr("vi = 'Hàng hóa được vận chuyển lại được vận chuyển từ kho, chứng từ không được xuất lại';
																			|ru = 'Перепоставленный товар отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered goods are shipped from the warehouse. The documents are not registered'; fa = 'Overdelivered goods are shipped from the warehouse. The documents are not registered';
																			|it = 'Il prodotto riconsegnato viene spedito dal magazzino, i documenti non sono eseguiti nuovamente';
																			|pl = 'Nadmiar towaru wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
																			|tr = 'Yeniden tedarik edilen mallar depodan sevk edilir, belgeler yeniden düzenlenmez'");
	ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Hàng thiếu khi tiếp nhận được sự thống nhất với bên nhận gia công';
														|ru = 'Недостачи при поступлении согласованы с переработчиком';
														|en = 'Shortage upon receipt is approved by the subcontractor'; fa = 'Shortage upon receipt is approved by the subcontractor';
														|it = 'Ammanchi in ricezione concordati con l''elaboratore';
														|pl = 'Niedobory przy wpływie są uzgodnione z przetwórcą';
														|tr = 'Fason üretici ile mutabık kalınan makbuz eksiklikleri'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Hàng thiếu khi tiếp nhận không được thống nhất với bên nhận gia công';
													|ru = 'Недостачи при поступлении не согласованы с переработчиком';
													|en = 'Shortage upon receipt is not approved by the subcontractor'; fa = 'Shortage upon receipt is not approved by the subcontractor';
													|it = 'Ammanchi in ricezione non concordati con l''elaboratore';
													|pl = 'Niedobory przy wpływie nie są uzgodnione z przetwórcą';
													|tr = 'Fason üretici ile mutabık kalınmayan makbuz eksiklikleri'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.DrawUpAShortfallDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ bên nhận gia công (điều chỉnh)';
						|ru = 'На недопоставленный товар оформляется поступление от переработчика (исправление)';
						|en = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered'; fa = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered';
						|it = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered';
						|pl = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered';
						|tr = 'Eksik teslim edilen ürünler için fason üreticiden makbuz alınır (yama)'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ bên nhận gia công (điều chỉnh), sau đó lập chứng từ tiếp nhận mới đối với mặt hàng giao thiếu';
						|ru = 'На недопоставленный товар оформляется поступление от переработчика (исправление) с последующим оформлением нового поступления недопоставленного товара';
						|en = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered, and a new underdelivered goods receipt is registered'; fa = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered, and a new underdelivered goods receipt is registered';
						|it = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered, and a new underdelivered goods receipt is registered';
						|pl = 'For underdelivered goods, a receipt from the subcontractor (correction) is registered, and a new underdelivered goods receipt is registered';
						|tr = 'Eksik teslim edilen ürünler için, fason üreticiden bir makbuz alınır ve sonrasında ise eksik teslim edilen ürünler için yeni bir makbuz alınır (yama)'");
		Else
			Items.DrawUpAShortfallDecoration.Title
				= NStr("vi = 'Việc tiếp nhận hàng hóa từ bên nhận gia công bị giảm bởi hàng hóa chưa giao';
						|ru = 'Поступление товаров от переработчика уменьшается на недопоставленный товар';
						|en = 'Receipt of goods from the subcontractor is reduced by underdelivered goods'; fa = 'Receipt of goods from the subcontractor is reduced by underdelivered goods';
						|it = 'La ricezione articoli dall''elaboratore meno gli articoli non consegnati';
						|pl = 'Wpływ towarów od przetwórcy zostaje zmniejszony o niedostarczony towar';
						|tr = 'Fason üreticiden alınan mal makbuzu, teslim edilmeyen mallar nedeniyle azaltılır'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Việc tiếp nhận hàng hóa từ bên nhận gia công bị giảm bởi hàng hóa chưa giao có lập chứng từ tiếp nhận hàng chưa giao sau';
						|ru = 'Поступление товаров от переработчика уменьшается на недопоставленный товар с последующим оформлением нового поступления недопоставленного товара';
						|en = 'Goods receipt from the subcontractor is reduced by underdelivered goods, a new receipt of underdelivered goods is registered'; fa = 'Goods receipt from the subcontractor is reduced by underdelivered goods, a new receipt of underdelivered goods is registered';
						|it = 'La ricezione degli articoli dall''elaboratore risulterà diminuita con la successiva formalizzazione di nuova ricezione dell''articolo non ricollocato';
						|pl = 'Wpływ towarów od przetwórcy zmniejsza się o niedostarczone towary z późniejszą rejestracją nowego wpływu niedostarczonych towarów';
						|tr = 'Fason üreticiden alınan mal makbuzu, teslim edilmeyen mallar kadar azaltılır ve teslim edilmeyen mallar için yeni bir makbuz oluşturulur'");
		EndIf;
		
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title = NStr("vi = 'Hàng hóa không được giao được tiếp nhận tại kho, chứng từ không được xuất lại';
																				|ru = 'Недопоставленный товар принимается на склад, документы не переоформляются';
																				|en = 'The underdelivered goods are received at the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are received at the warehouse; the documents are not reregistered.';
																				|it = 'Le merci non consegnate vengono ricevute nel magazzino, i documenti non si emettono nuovamente';
																				|pl = 'Niedostarczone towary są przyjmowane do magazynu, dokumenty nie są sporządzane ponownie';
																				|tr = 'Teslim edilmeyen mallar stokta kabul edilir, belgeler yeniden düzenlenmez'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title    = NStr("vi = 'Hàng thừa khi tiếp nhận được sự thống nhất với bên nhận gia công';
													|ru = 'Излишки при поступлении согласованы с переработчиком';
													|en = 'Surplus upon receipt is approved by the subcontractor'; fa = 'Surplus upon receipt is approved by the subcontractor';
													|it = 'Eccedenze alla ricezione concordate con l''elaboratore';
													|pl = 'Nadwyżki przy wpływie są uzgodnione z przetwórcą';
													|tr = 'Fason üretici ile mutabık kalınan makbuz fazlalıkları'");
		Items.GroupSurplusesNotAgreed.Title  = NStr("vi = 'Hàng thừa khi tiếp nhận mà không thống nhất với bên nhận gia công';
													|ru = 'Излишки при поступлении не согласованы с переработчиком';
													|en = 'Surplus upon receipt is not approved by the subcontractor'; fa = 'Surplus upon receipt is not approved by the subcontractor';
													|it = 'Surplus upon receipt is not approved by the subcontractor';
													|pl = 'Surplus upon receipt is not approved by the subcontractor';
													|tr = 'Fason üretici ile mutabık kalınmayan makbuz fazlası'");
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title
			= NStr("vi = 'Ghi tăng hàng thừa khi tiếp nhận hàng hóa từ bên nhận gia công, theo thu nhập khác, chứng từ chưa được lập lại';
					|ru = 'Излишки поступления товаров от переработчика оприходуются, относятся на прочие доходы, документы не переоформляются';
					|en = 'Surplus of goods from the subcontractor are received and allocated to other income; the documents are not reissued'; fa = 'Surplus of goods from the subcontractor are received and allocated to other income; the documents are not reissued';
					|it = 'Eccedenze di ricezione articoli dall''elaboratore registrate in contabilità, si riferiscono ad altre entrate, i documenti non vengono riformalizzati';
					|pl = 'Nadwyżki wpływu towarów od przetwórcy są rejestrowane, należą do innych dochodów, dokumenty nie są tworzone ponownie';
					|tr = 'Fason üreticiden alınan mal makbuzu fazlalıkları kaydedilir, diğer gelirlere yansıtılır, belgeler yeniden düzenlenmez'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ bên nhận gia công (điều chỉnh),  sau đó lập chứng từ chuyển giao mặt hàng giao lại';
						|ru = 'На перепоставленный товар оформляется поступление от переработчика (исправление) с последующим оформлением передачи перепоставленного товара';
						|en = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered, and a new transfer of overdelivered goods is registered'; fa = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered, and a new transfer of overdelivered goods is registered';
						|it = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered, and a new transfer of overdelivered goods is registered';
						|pl = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered, and a new transfer of overdelivered goods is registered';
						|tr = 'Yeniden teslim edilen ürünler için fason üreticiden makbuz alınır ve sonrasında yeniden teslim edilen ürünlerin transferi kaydedilir (yama)'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ bên nhận gia công (điều chỉnh)';
						|ru = 'На перепоставленный товар оформляется поступление от переработчика (исправление)';
						|en = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered'; fa = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered';
						|it = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered';
						|pl = 'For overdelivered goods, a receipt from the subcontractor (correction) is registered';
						|tr = 'Fason üreticiden alınan makbuz yeniden teslim edilen ürünler için oluşturulur (yama)'");
		Else
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng hóa từ bên nhận gia công tăng bởi hàng hóa giao lại có lập chứng từ chuyển giao hàng giao lại sau';
						|ru = 'Поступление товаров от переработчика увеличивается на перепоставленный товар с последующим оформлением передачи перепоставленного товара';
						|en = 'Receipt of goods from the subcontractor is increased by overdelivered goods, transfer of overdelivered goods will be registered'; fa = 'Receipt of goods from the subcontractor is increased by overdelivered goods, transfer of overdelivered goods will be registered';
						|it = 'La ricezione articoli dall''elaboratore risulterà aumentata con la successiva formalizzazione di trasferimento dell''articolo ricollocato';
						|pl = 'Wpływ towarów od przetwórcy zwiększa się o nadwyżkę towaru z późniejszą rejestracją przekazania nadwyżki towaru';
						|tr = 'Fason üreticiden alınan mal makbuzu, fazla tedarik edilen mallar nedeniyle artar ve ardından fazla tedarik edilen malların devri yapılır'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Tiếp nhận hàng hóa từ bên nhận gia công tăng bởi hàng hóa giao lại';
						|ru = 'Поступление товаров от переработчика увеличивается на перепоставленный товар';
						|en = 'Receipt of goods from the subcontractor is increased by overdelivered goods'; fa = 'Receipt of goods from the subcontractor is increased by overdelivered goods';
						|it = 'Ricezione degli articoli dall''elaboratore più articolo ricollocato';
						|pl = 'Wpływ towarów od przetwórcy zwiększa się o nadwyżkę towaru';
						|tr = 'Fason üreticiden alınan mal makbuzu, fazla tedarik edilen mallar nedeniyle artırılır'");
		EndIf;
		
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title = NStr("vi = 'Hàng hóa được vận chuyển lại được vận chuyển từ kho, chứng từ không được xuất lại';
																			|ru = 'Перепоставленный товар отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered goods are shipped from the warehouse. The documents are not registered'; fa = 'Overdelivered goods are shipped from the warehouse. The documents are not registered';
																			|it = 'Il prodotto riconsegnato viene spedito dal magazzino, i documenti non sono eseguiti nuovamente';
																			|pl = 'Nadmiar towaru wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
																			|tr = 'Yeniden tedarik edilen mallar depodan sevk edilir, belgeler yeniden düzenlenmez'");
		
	ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Hàng thiếu khi trả lại có thống nhất với bên nhận gia công';
														|ru = 'Недостачи при возврате согласованы с переработчиком';
														|en = 'Shortages on return are approved by the subcontractor'; fa = 'Shortages on return are approved by the subcontractor';
														|it = 'Shortages on return are approved by the subcontractor';
														|pl = 'Shortages on return are approved by the subcontractor';
														|tr = 'Eksikler, iade esnasında fason üretici ile kararlaştırıldı'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Hàng thiếu khi trả lại mà không có thống nhất với bên nhận gia công';
													|ru = 'Недостачи при возврате не согласованы с переработчиком';
													|en = 'Shortages on return are not approved by the subcontractor'; fa = 'Shortages on return are not approved by the subcontractor';
													|it = 'Shortages on return are not approved by the subcontractor';
													|pl = 'Shortages on return are not approved by the subcontractor';
													|tr = 'Eksikler, iade esnasında fason üretici ile kararlaştırılmadı'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.DrawUpAShortfallDecoration.Title
				= NStr("vi = 'Đối với nguyên vật liệu giao thiếu, cần lập chứng từ nhận trả lại từ bên nhận gia công (điều chỉnh)';
						|ru = 'На недопоставленное сырье оформляется возврат от переработчика (исправление)';
						|en = 'For underdelivered raw materials, return from the subcontractor (correction) is registered'; fa = 'For underdelivered raw materials, return from the subcontractor (correction) is registered';
						|it = 'For underdelivered raw materials, return from the subcontractor (correction) is registered';
						|pl = 'For underdelivered raw materials, return from the subcontractor (correction) is registered';
						|tr = 'Eksik teslim edilen hammaddeler için malzemelerin fason üreticiden geri alma belgesi oluşturulur (yama)'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Đối với nguyên vật liệu giao thiếu, cần lập chứng từ nhận trả lại từ bên nhận gia công (điều chỉnh), sau đó lập chứng từ tiếp nhận mới đối với nguyên vật liệu giao thiếu';
						|ru = 'На недопоставленное сырье оформляется возврат от переработчика (исправление) с последующим оформлением нового поступления недопоставленного сырья';
						|en = 'For underdelivered raw materials, return from the subcontractor (correction) is registered, and a new receipt of underdelivered raw materials is registered'; fa = 'For underdelivered raw materials, return from the subcontractor (correction) is registered, and a new receipt of underdelivered raw materials is registered';
						|it = 'For underdelivered raw materials, return from the subcontractor (correction) is registered, and a new receipt of underdelivered raw materials is registered';
						|pl = 'For underdelivered raw materials, return from the subcontractor (correction) is registered, and a new receipt of underdelivered raw materials is registered';
						|tr = 'Eksik teslim edilen ham maddeler için malzemelerin fason üreticiden geri alma belgesi (düzeltme) kaydedilir ve ardından eksik teslim edilen ham maddeler için yeni bir giriş belgesi oluşturulur'");
		Else
			Items.DrawUpAShortfallDecoration.Title
				= NStr("vi = 'Việc tiếp nhận từ bên nhận gia công bị giảm bởi nguyên vật liệu giao thiếu';
						|ru = 'Поступление от переработчика уменьшается на недопоставленное сырье';
						|en = 'Receipt from the subcontractor is reduced by the underdelivered raw materials'; fa = 'Receipt from the subcontractor is reduced by the underdelivered raw materials';
						|it = 'Receipt from the subcontractor is reduced by the underdelivered raw materials';
						|pl = 'Receipt from the subcontractor is reduced by the underdelivered raw materials';
						|tr = 'Fason üreticiden alınan makbuzlar, hammaddelerin eksik teslim edilmesi sonucunda azalma gösterir'");
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Việc tiếp nhận từ bên nhận gia công bị giảm bởi nguyên vật liệu giao thiếu, sau đó lập mới chứng từ tiếp nhận nguyên vật liệu giao thiếu';
						|ru = 'Поступление от переработчика уменьшается на недопоставленное сырье с последующим оформлением нового поступления недопоставленного сырья';
						|en = 'Receipt from the subcontractor is reduced by the underdelivered raw materials, and a new receipt of underdelivered raw materials is registered'; fa = 'Receipt from the subcontractor is reduced by the underdelivered raw materials, and a new receipt of underdelivered raw materials is registered';
						|it = 'Receipt from the subcontractor is reduced by the underdelivered raw materials, and a new receipt of underdelivered raw materials is registered';
						|pl = 'Receipt from the subcontractor is reduced by the underdelivered raw materials, and a new receipt of underdelivered raw materials is registered';
						|tr = 'Fason üreticiden alınan makbuz, teslim edilmemiş hammaddelere göre azaltılır ve yeni bir teslim edilmemiş ham madde makbuzu alınır'");
		EndIf;
		
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title = NStr("vi = 'Nguyên vật liệu giao thiếu đang được tiếp nhận vào kho, không tạo lại chứng từ';
																				|ru = 'Недопоставленное сырье принимается на склад, документы не переоформляются';
																				|en = 'Underdelivered raw materials are received at the warehouse; the documents are not reregistered'; fa = 'Underdelivered raw materials are received at the warehouse; the documents are not reregistered';
																				|it = 'Underdelivered raw materials are received at the warehouse; the documents are not reregistered';
																				|pl = 'Underdelivered raw materials are received at the warehouse; the documents are not reregistered';
																				|tr = 'Teslim edilmeyen hammaddeler depoya kabul edilir, belgeler yeniden oluşturulmaz'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title    = NStr("vi = 'Hàng thừa khi trả lại không được thống nhất với bên nhận gia công';
													|ru = 'Излишки при возврате согласованы с переработчиком';
													|en = 'Surplus upon return is approved by the subcontractor'; fa = 'Surplus upon return is approved by the subcontractor';
													|it = 'Surplus upon return is approved by the subcontractor';
													|pl = 'Surplus upon return is approved by the subcontractor';
													|tr = 'Yeniden fason üretici ile anlaşılan makbuz fazlalık sayısı'");
		Items.GroupSurplusesNotAgreed.Title  = NStr("vi = 'Hàng thừa khi trả lại không thỏa thuận với bên nhận gia công';
													|ru = 'Излишки при возврате не согласованы с переработчиком';
													|en = 'Surplus upon return is not approved by the subcontractor'; fa = 'Surplus upon return is not approved by the subcontractor';
													|it = 'Eccedenze alla restituzione non concordate con l''elaboratore';
													|pl = 'Nadwyżki podczas zwrotu nie są uzgodnione z przetwórcą';
													|tr = 'Fason üretici ile mutabık kalınmayan makbuz fazlalıkları'");
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title
			= NStr("vi = 'Hàng thừa khi trả lại nguyên vật liệu từ bên nhận gia công đang được ghi tăng theo thu nhập khác, chứng từ chưa được lập lại';
					|ru = 'Излишки возврата сырья от переработчика оприходуются, относятся на прочие доходы, документы не переоформляются';
					|en = 'Surplus of goods from the subcontractor are received and allocated to other income; the documents are not reregistered'; fa = 'Surplus of goods from the subcontractor are received and allocated to other income; the documents are not reregistered';
					|it = 'Surplus of goods from the subcontractor are received and allocated to other income; the documents are not reregistered';
					|pl = 'Surplus of goods from the subcontractor are received and allocated to other income; the documents are not reregistered';
					|tr = 'Fason üreticiden gelen fazladan hammadde iadeleri kaydedilir, diğer gelirlere yansıtılır ve belgeler yeniden oluşturulmaz'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Đối với nguyên vật liệu giao lại, cần lập chứng từ nhận trả lại từ bên nhận gia công (điều chỉnh), sau đó lập chứng từ chuyển giao nguyên vật liệu giao lại';
						|ru = 'На перепоставленное сырье оформляется возврат от переработчика (исправление) с последующим оформлением передачи перепоставленного сырья';
						|en = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered, and a new transfer of overdelivered raw materials is registered'; fa = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered, and a new transfer of overdelivered raw materials is registered';
						|it = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered, and a new transfer of overdelivered raw materials is registered';
						|pl = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered, and a new transfer of overdelivered raw materials is registered';
						|tr = 'Fazladan teslim edilen hammaddeler için, malzemelerin fason üreticiden geri alınması (düzeltme) kaydedilir, ardından ise hammadde stok fazlasının transferi kaydedilir'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Đối với nguyên vật liệu giao lại, cần lập chứng từ nhận trả lại từ bên nhận gia công (điều chỉnh)';
						|ru = 'На перепоставленное сырье оформляется возврат от переработчика (исправление)';
						|en = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered'; fa = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered';
						|it = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered';
						|pl = 'For overdelivered raw materials, a return from the subcontractor (correction) is registered';
						|tr = 'Fazladan teslim edilen hammaddeler için malzemelerin fason üreticiden geri alınması (düzeltme) kaydedilir'");
		Else
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Tiếp nhận từ bên nhận gia công tăng bởi nguyên vật liệu giao lại, sau đó lập chứng từ chuyển giao nguyên vật liệu giao lại';
						|ru = 'Поступление от переработчика увеличивается на перепоставленное сырье с последующим оформлением передачи перепоставленного сырья';
						|en = 'Receipt from the subcontractor is increased by overdelivered raw materials, and a new transfer of overdelivered raw materials is registered'; fa = 'Receipt from the subcontractor is increased by overdelivered raw materials, and a new transfer of overdelivered raw materials is registered';
						|it = 'Receipt from the subcontractor is increased by overdelivered raw materials, and a new transfer of overdelivered raw materials is registered';
						|pl = 'Receipt from the subcontractor is increased by overdelivered raw materials, and a new transfer of overdelivered raw materials is registered';
						|tr = 'Fason üreticiden alınan makbuzlar, yeniden teslim edilen hammaddelerin transferinin sonradan kaydedilmesi üzerine yeniden teslim edilen hammaddelerce artırılır'");
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Tiếp nhận từ bên nhận gia công tăng bởi nguyên vật liệu giao lại';
						|ru = 'Поступление от переработчика увеличивается на перепоставленное сырье';
						|en = 'Receipt from the subcontractor is increased by the overdelivered raw materials'; fa = 'Receipt from the subcontractor is increased by the overdelivered raw materials';
						|it = 'Receipt from the subcontractor is increased by the overdelivered raw materials';
						|pl = 'Receipt from the subcontractor is increased by the overdelivered raw materials';
						|tr = 'Fason üreticiden alınan makbuzlar, yeniden teslim edilen hammaddelerce artırılır'");
		EndIf;
		
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title = NStr("vi = 'Nguyên vật liệu giao lại đang xuất từ kho, không lập lại chứng từ';
																			|ru = 'Перепоставленное сырье отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered raw materials are shipped from the warehouse. The documents are not reregistered'; fa = 'Overdelivered raw materials are shipped from the warehouse. The documents are not reregistered';
																			|it = 'Overdelivered raw materials are shipped from the warehouse. The documents are not reregistered';
																			|pl = 'Overdelivered raw materials are shipped from the warehouse. The documents are not reregistered';
																			|tr = 'Yeniden teslim edilen hammaddeler depodan gönderilir, belgeler yeniden oluşturulmaz'");
	ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		
		// Shortages
		Items.GroupShortagesAreApproved.Title   = NStr("vi = 'Hàng thiếu khi tiếp nhận được thỏa thuận với bên đặt gia công';
														|ru = 'Недостачи при поступлении согласованы с давальцем';
														|en = 'Shortage at receipt is agreed with the provider'; fa = 'Shortage at receipt is agreed with the provider';
														|it = 'Ammanchi alla ricezione concordati con il fornitore';
														|pl = 'Niedobory podczas wpływu są uzgodnione z właścicielem surowców';
														|tr = 'Sağlayıcı ile mutabık kalınan makbuz eksiklikleri'");
		Items.GroupShortfallsNotAgreed.Title = NStr("vi = 'Hàng thiếu khi tiếp nhận được thỏa thuận với bên đặt gia công';
													|ru = 'Недостачи при поступлении не согласованы с давальцем';
													|en = 'Shortage at receipt is not agreed with the provider'; fa = 'Shortage at receipt is not agreed with the provider';
													|it = 'Ammanchi alla ricezione non concordati con il fornitore';
													|pl = 'Niedobory podczas przyjęcia nie zostały uzgodnione z właścicielem surowców';
													|tr = 'Sağlayıcı ile mutabık kalınmayan makbuz eksiklikleri'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			If TheLineToOrder
				Or GroupUpdate And GetFunctionalOption("UseMaterialProviderOrder2_5") Then
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ nhập hàng từ người đặt gia công (chỉnh sửa), sau đó hủy các dòng giao thiếu trong đơn hàng';
							|ru = 'На недопоставленный товар оформляется поступление от давальца (исправление) с последующей отменой недопоставленных строк заказа';
							|en = 'For underdelivered goods, receipt from the provider (correction) is registered, followed by cancellation of the underdelivered order lines'; fa = 'For underdelivered goods, receipt from the provider (correction) is registered, followed by cancellation of the underdelivered order lines';
							|it = 'For underdelivered goods, receipt from the provider (correction) is registered, followed by cancellation of the underdelivered order lines';
							|pl = 'For underdelivered goods, receipt from the provider (correction) is registered, followed by cancellation of the underdelivered order lines';
							|tr = 'Eksik teslim edilen ürünler için Mal girişi — Verilen fason hizmetleri belgesi (düzeltme) oluşturulur ve ardından eksik teslim edilen sipariş satırları iptal edilir'");
			Else
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ bên đặt gia công (điều chỉnh)';
							|ru = 'На недопоставленный товар оформляется поступление от давальца (исправление)';
							|en = 'For underdelivered goods, goods receipt from the provider (correction) is registered'; fa = 'For underdelivered goods, goods receipt from the provider (correction) is registered';
							|it = 'For underdelivered goods, goods receipt from the provider (correction) is registered';
							|pl = 'For underdelivered goods, goods receipt from the provider (correction) is registered';
							|tr = 'Eksik teslim edilen ürünler için Mal girişi — Verilen fason hizmetleri belgesi (düzeltme) oluşturulur'");
			EndIf;
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao thiếu, cần lập chứng từ tiếp nhận từ bên đặt gia công (điều chỉnh), sau đó lập chứng từ tiếp nhận mới cho mặt hàng giao thiếu';
						|ru = 'На недопоставленный товар оформляется поступление от давальца (исправление) с последующим оформлением нового поступления недопоставленного товара';
						|en = 'For underdelivered goods, a receipt from the provider (correction) is registered, and a new underdelivered goods receipt is registered'; fa = 'For underdelivered goods, a receipt from the provider (correction) is registered, and a new underdelivered goods receipt is registered';
						|it = 'For underdelivered goods, a receipt from the provider (correction) is registered, and a new underdelivered goods receipt is registered';
						|pl = 'For underdelivered goods, a receipt from the provider (correction) is registered, and a new underdelivered goods receipt is registered';
						|tr = 'Eksik teslim edilen ürünler için Mal girişi — Verilen fason hizmetleri belgesi (düzeltme) oluşturulur ve ardından eksik teslim edilen ürünler için yeni bir mal giriş belgesi düzenlenir'");
		Else
			If TheLineToOrder
				Or GroupUpdate And GetFunctionalOption("UseMaterialProviderOrder2_5") Then
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Tiếp nhận được giảm bởi hàng hóa chưa được giao với việc hủy các dòng đơn hàng chưa được gửi sau đó';
							|ru = 'Поступление уменьшается на недопоставленный товар с последующей отменой недопоставленных строк заказа';
							|en = 'Receipt is reduced by underdelivered goods, underdelivered order lines will be canceled'; fa = 'Receipt is reduced by underdelivered goods, underdelivered order lines will be canceled';
							|it = 'L''entrata diminuisce a causa dei beni non consegnati con la conseguente cancellazione delle righe dell''ordine non consegnate.';
							|pl = 'Wpływ zmniejsza się o niedostarczone towary z późniejszym anulowaniem niedostarczonych wierszy zamówienia';
							|tr = 'Makbuz, teslim edilmeyen sipariş satırlarının daha sonra iptal edilmesiyle birlikte teslim edilmeyen mallar kadar azaltılır'");
			Else
				Items.DrawUpAShortfallDecoration.Title
					= NStr("vi = 'Thu nhập bị giảm bởi hàng hóa chưa được giao';
							|ru = 'Поступление уменьшается на недопоставленный товар';
							|en = 'Receipt reduces for underdelivered goods'; fa = 'Receipt reduces for underdelivered goods';
							|it = 'L''entrata diminuisce a causa dei beni non consegnati';
							|pl = 'Wpływ zmniejsza się o niedostarczone towary';
							|tr = 'Makbuzlar teslim edilmeyen mallar kadar azaltılır'");
			EndIf;
			Items.IssueAShortageAndExpectAdditionalDeliveryDecoration.Title
				= NStr("vi = 'Tiếp nhận được giảm bởi hàng hóa chưa được gửi, tiếp theo là đăng ký một biên nhận mới của hàng hóa chưa được giao';
						|ru = 'Поступление уменьшается на недопоставленный товар с последующим оформлением нового поступления недопоставленного товара';
						|en = 'Receipt is reduced by underdelivered goods, a new receipt of underdelivered goods is registered'; fa = 'Receipt is reduced by underdelivered goods, a new receipt of underdelivered goods is registered';
						|it = 'Le entrate diminuiscono a causa della merce non consegnata con la successiva registrazione della nuova fattura della merce non consegnata';
						|pl = 'Wpływ zmniejsza się o niedostarczone towary z późniejszym sporządzeniem nowego wpływu niedostarczonych towarów';
						|tr = 'Makbuz teslim edilmeyen mallar kadar azaltılır ve teslim edilmeyen mallar için yeni bir makbuz düzenlenir'");
		EndIf;
		
		Items.ExpectAdditionalDeliveryWithoutDecorationDecoration.Title = NStr("vi = 'Hàng hóa không được giao được tiếp nhận tại kho, chứng từ không được xuất lại';
																				|ru = 'Недопоставленный товар принимается на склад, документы не переоформляются';
																				|en = 'The underdelivered goods are received at the warehouse; the documents are not reregistered.'; fa = 'The underdelivered goods are received at the warehouse; the documents are not reregistered.';
																				|it = 'Le merci non consegnate vengono ricevute nel magazzino, i documenti non si emettono nuovamente';
																				|pl = 'Niedostarczone towary są przyjmowane do magazynu, dokumenty nie są sporządzane ponownie';
																				|tr = 'Teslim edilmeyen mallar stokta kabul edilir, belgeler yeniden düzenlenmez'");
		
		// Surpluses
		Items.GroupSurplusesAgreed.Title   = NStr("vi = 'Hàng thừa khi tiếp nhận được thống nhất với bên đặt gia công';
													|ru = 'Излишки при поступлении согласованы с давальцем';
													|en = 'Surplus at receipt is agreed with the provider'; fa = 'Surplus at receipt is agreed with the provider';
													|it = 'Eccedenze alla ricezione concordate con il fornitore';
													|pl = 'Nadmiar podczas przyjęcia jest uzgodniony z właścicielem surowców';
													|tr = 'Sağlayıcı ile mutabık kalınan makbuz fazlalıkları'");
		Items.GroupSurplusesNotAgreed.Title = NStr("vi = 'Hàng thừa khi tiếp nhận không được thống nhất với bên đặt gia công';
													|ru = 'Излишки при поступлении не согласованы с давальцем';
													|en = 'Surplus at receipt is not agreed with the provider'; fa = 'Surplus at receipt is not agreed with the provider';
													|it = 'Eccedenze alla ricezione non concordate con il fornitore';
													|pl = 'Nadmiar podczas przyjęcia nie został uzgodniony z właścicielem surowców';
													|tr = 'Sağlayıcı ile mutabık kalınmayan makbuz eksiklikleri'");
		
		If DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries Then
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ bên đặt gia công (điều chỉnh)';
						|ru = 'На перепоставленный товар оформляется поступление от давальца (исправление)';
						|en = 'For overdelivered goods, a receipt from the provider (correction) is registered'; fa = 'For overdelivered goods, a receipt from the provider (correction) is registered';
						|it = 'For overdelivered goods, a receipt from the provider (correction) is registered';
						|pl = 'For overdelivered goods, a receipt from the provider (correction) is registered';
						|tr = 'Fazla teslim edilen ürünler için Mal girişi — Verilen fason hizmetleri belgesi (düzeltme) oluşturulur'");
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Đối với mặt hàng giao lại, cần lập chứng từ tiếp nhận từ bên đặt gia công (điều chỉnh), sau đó lập chứng từ chuyển giao mặt hàng giao lại';
						|ru = 'На перепоставленный товар оформляется поступление от давальца (исправление) с последующим оформлением отгрузки перепоставленного товара';
						|en = 'For overdelivered goods, a receipt from the provider (correction) is registered, and a new shipment of overdelivered goods is registered'; fa = 'For overdelivered goods, a receipt from the provider (correction) is registered, and a new shipment of overdelivered goods is registered';
						|it = 'For overdelivered goods, a receipt from the provider (correction) is registered, and a new shipment of overdelivered goods is registered';
						|pl = 'For overdelivered goods, a receipt from the provider (correction) is registered, and a new shipment of overdelivered goods is registered';
						|tr = 'Fazla teslim edilen ürünler için Mal girişi — Verilen fason hizmetleri belgesi (düzeltme) oluşturulur ve ardından fazla teslim edilen ürünler için bir sevkiyat belgesi düzenlenir.'");
		Else
			Items.ArrangeTheRepostedDecoration.Title
				= NStr("vi = 'Tăng thu nhập cho hàng hóa giao lại';
						|ru = 'Поступление увеличивается на перепоставленный товар';
						|en = 'Receipt increases for overdelivered goods'; fa = 'Receipt increases for overdelivered goods';
						|it = 'Le entrate aumentano con la riconsegna dei prodotti';
						|pl = 'Wpływ powiększa się o nadmiar dostarczanego towaru';
						|tr = 'Fazla tedarik edilen mallar nedeniyle alımlar artar'");
			Items.ArrangeTheReDeliveredAndReturnTheDecoration.Title
				= NStr("vi = 'Việc tiếp nhận được tăng đối với hàng hóa giao lại, sau đó tạo chứng từ giao hàng của hàng hóa giao lại';
						|ru = 'Поступление увеличивается на перепоставленный товар с последующим оформлением отгрузки перепоставленного товара';
						|en = 'Receipt is increased by overdelivered goods, a shipment of overdelivered goods will be registered'; fa = 'Receipt is increased by overdelivered goods, a shipment of overdelivered goods will be registered';
						|it = 'La ricezione viene aumentata per la merce consegnata oltre l''ordine con la successiva formalizzazione della consegna della merce consegnata oltre l''ordine';
						|pl = 'Przekazanie zwiększa się na nadwyżkę towaru późniejszym sporządzeniem wysyłki nadwyżki towaru';
						|tr = 'Makbuzlar fazla tedarik edilen mallarla artar, bunu fazla tedarik edilen malların sevkiyatı izler'");
		EndIf;
		
		Items.AttributeTheOverDeliveredGoodsToOtherIncomeDecoration.Title = NStr("vi = 'Hàng hóa giao lại được ghi tăng, không cần tạo chứng từ';
																				|ru = 'Перепоставленный товар оприходуется, документы не переоформляются';
																				|en = 'Overdelivered goods will be received, documents are not reissued'; fa = 'Overdelivered goods will be received, documents are not reissued';
																				|it = 'La merce consegnata oltre l''ordine verrà registrata come ricevuta, i documenti non verranno riemessi';
																				|pl = 'Nadwyżka towaru przyjmuje się na stan, dokumenty nie są sporządzane ponownie';
																				|tr = 'Yeniden teslim edilen mallar kaydedilir, belgeler yeniden düzenlenmez'");
		Items.ReturnTheReDeliveredWithoutDecorationDecoration.Title  = NStr("vi = 'Hàng hóa được vận chuyển lại được vận chuyển từ kho, chứng từ không được xuất lại';
																			|ru = 'Перепоставленный товар отгружается со склада, документы не переоформляются';
																			|en = 'Overdelivered goods are shipped from the warehouse. The documents are not registered'; fa = 'Overdelivered goods are shipped from the warehouse. The documents are not registered';
																			|it = 'Il prodotto riconsegnato viene spedito dal magazzino, i documenti non sono eseguiti nuovamente';
																			|pl = 'Nadmiar towaru wysyła się z magazynu, dokumenty nie są sporządzane ponownie';
																			|tr = 'Yeniden tedarik edilen mallar depodan sevk edilir, belgeler yeniden düzenlenmez'");
	EndIf;
	
	CertificateOfAcceptanceForStorage = TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
							Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor
							Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor
							Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
							Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian
							Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent;
	
	If CertificateOfAcceptanceForStorage Then
		WriteOffValue = Items.AtOurExpense.ChoiceList.Get(0);
		WriteOffValue.Presentation = NStr("vi = 'Ghi giảm hàng thiếu';
											|ru = 'Списать недостачи';
											|en = 'Write off shortages'; fa = 'Write off shortages';
											|it = 'Stornare ammanchi';
											|pl = 'Rozchodować niedobory';
											|tr = 'Eksiklikleri gider yazın'");
	EndIf;
	
	If (TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
			And BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement)
		Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
			ResponsibleForShortages = NStr("vi = 'công ty bên thứ ba';
											|ru = 'стороннюю компанию';
											|en = 'third party'; fa = 'third party';
											|it = 'third party';
											|pl = 'third party';
											|tr = 'üçüncü taraf şirket'");
			WriteOffValue = Items.ThirdPartyIsGuilty.ChoiceList.Get(0);
			WriteOffValue.Presentation = NStr("vi = 'Ghi giảm vào tài khoản công ty bên thứ ba';
												|ru = 'Списать за счет сторонней компании';
												|en = 'Write off at the expense of the third party'; fa = 'Write off at the expense of the third party';
												|it = 'Stornare a spese di una società terza';
												|pl = 'Rozchodować na koszt firmy zewnętrznej';
												|tr = 'Üçüncü taraf şirketin hesabına yaz'");
	Else
		ResponsibleForShortages = NStr("vi = 'nhà cung cấp';
										|ru = 'поставщика';
										|en = 'vendor'; fa = 'تأمین‌کننده';
										|it = 'vendor';
										|pl = 'vendor';
										|tr = 'tedarikçi'");
	EndIf;

	If CertificateOfAcceptanceForStorage Then
		If TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian
			Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor
			Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
			Or TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
			TitleText = NStr("vi = 'Chênh lệch nhận lại được tính vào hàng thiếu';
							|ru = 'Расхождения приемки относятся на недостачи';
							|en = 'Receipt discrepancies are allocated to shortages'; fa = 'Receipt discrepancies are allocated to shortages';
							|it = 'Receipt discrepancies are allocated to shortages';
							|pl = 'Receipt discrepancies are allocated to shortages';
							|tr = 'Kabul tutarsızlıkları, eksikliklerden kaynaklanmaktadır'");
		ElsIf TypeOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor Then
			TitleText = NStr("vi = 'Chênh lệch trả lại được tính vào hàng thiếu';
							|ru = 'Расхождения возврата относятся на недостачи';
							|en = 'Return discrepancies are allocated to shortages'; fa = 'Return discrepancies are allocated to shortages';
							|it = 'Return discrepancies are allocated to shortages';
							|pl = 'Return discrepancies are allocated to shortages';
							|tr = 'İade tutarsızlıkları, eksikliklerden kaynaklanmaktadır'");
		Else // Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage
			TitleText = NStr("vi = 'Chênh lệch nhận lại được tính vào hàng thiếu';
							|ru = 'Расхождения приемки относятся на недостачи';
							|en = 'Receipt discrepancies are allocated to shortages'; fa = 'Receipt discrepancies are allocated to shortages';
							|it = 'Receipt discrepancies are allocated to shortages';
							|pl = 'Receipt discrepancies are allocated to shortages';
							|tr = 'Kabul tutarsızlıkları, eksikliklerden kaynaklanmaktadır'");
		EndIf;
		TitleOfRegistrationOfShortfallsAtOurExpense = TitleText;
	Else
		If ThisIsSeparatePurchase Then 
			TitleOfRegistrationOfShortfallsAtOurExpense = 
				NStr("vi = 'Chênh lệch giữa tiếp nhận và mua hàng có liên quan đến chi phí khác';
					|ru = 'Расхождения между поступлением и приобретением относятся на прочие расходы';
					|en = 'Discrepancies between receipt and purchase are allocated to other expenses'; fa = 'Discrepancies between receipt and purchase are allocated to other expenses';
					|it = 'Расхождения между поступлением и приобретением относятся на прочие расходы';
					|pl = 'Discrepancies between receipt and purchase are allocated to other expenses';
					|tr = 'Girişler ve edinimler arasındaki tutarsızlıklar diğer giderlere yansıtılır'");
		Else
			TitleOfRegistrationOfShortfallsAtOurExpense = 
				NStr("vi = 'Hàng thiếu sẽ được ghi tăng vào kho và ghi giảm vào chi phí khác.';
					|ru = 'Недостающий товар будет оприходован на склад и списан на прочие расходы';
					|en = 'Missing goods will be received to the warehouse and written off to other expenses'; fa = 'Missing goods will be received to the warehouse and written off to other expenses';
					|it = 'Недостающий товар будет оприходован на склад и списан на прочие расходы';
					|pl = 'Brakujący towar zostanie zaksięgowany do magazynu i zaliczony do innych wydatków, dokumenty nie są sporządzane ponownie';
					|tr = 'Eksik ürün envantere alınacak ve diğer giderler olarak kayıttan düşülecektir'");
		EndIf;
	EndIf;
	
	Items.AtOurExpenseDecoration.Title = TitleOfRegistrationOfShortfallsAtOurExpense;
	
	If ThisIsSeparatePurchase Then
		Items.ThroughTheFaultOfAThirdPartyCompanyDecoration.Title = StrTemplate(
			NStr("vi = 'Chênh lệch giữa tiếp nhận và mua hàng có liên quan đến chi phí khác. %1 chịu trách nhiệm về hàng thiếu';
				|ru = 'Расхождения между поступлением и приобретением относятся на прочие расходы. Ответственность за недостачи будет возложена на %1';
				|en = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages'; fa = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages';
				|it = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages';
				|pl = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages';
				|tr = 'Girişler ve edinimler arasındaki tutarsızlıklar diğer giderlere yansıtılmaktadır. %1, eksikliklerden sorumlu tutulacaktır'"),
			ResponsibleForShortages);
	Else
		Items.ThroughTheFaultOfAThirdPartyCompanyDecoration.Title = StrTemplate(
			NStr("vi = 'Chênh lệch giữa tiếp nhận và mua hàng có liên quan đến chi phí khác. %1 chịu trách nhiệm về hàng thiếu';
				|ru = 'Расхождения между поступлением и приобретением относятся на прочие расходы. Ответственность за недостачи будет возложена на %1';
				|en = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages'; fa = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages';
				|it = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages';
				|pl = 'Discrepancies between receipt and purchase are allocated to other expenses. The %1 bears the responsibility for shortages';
				|tr = 'Girişler ve edinimler arasındaki tutarsızlıklar diğer giderlere yansıtılmaktadır. %1, eksikliklerden sorumlu tutulacaktır'"),
			ResponsibleForShortages);
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

&AtClient
Function ThirdPartyIsGuilty()

	Return ?(ShortfallAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses"),
	                                                      ?(AtWhoseExpense = "ThirdPartyIsGuilty", True, False),
	                                                      False);

EndFunction

&AtClient
Procedure OptionToReflectWriteOffToOtherExpensesWhenChanging()
	
	ShortfallAction = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses");
	
EndProcedure

&AtClient
Procedure ActionOfShortageInCaseOfChange()
	
	AtWhoseExpense = "";
	
EndProcedure

#EndRegion

