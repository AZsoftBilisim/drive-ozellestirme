#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	VATLocal = Parameters.VATLocal;
	SumCompl = Parameters.SumCompl;
	TempStorageAddress = Parameters.TempStorageAddress;
	Organization = Parameters.Organization;
	Date = Parameters.Date;
	BusinessOperation = Parameters.BusinessOperation;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI Then
		
		SettingsArray = New Array;
		SettingsArray.Add(Enums.SourceDocumentTypes.PurchaseFromVendor);
		SettingsArray.Add(Enums.SourceDocumentTypes.InternalInvoice);
		ChoiceParameter = New ChoiceParameter("Filter.SourceDocumentType",New FixedArray(SettingsArray));
		ParametersArray = New Array;
		ParametersArray.Add(ChoiceParameter);
		Items.LotDetailsDocumentInflow.ChoiceParameters = New FixedArray(ParametersArray);
		
	EndIf;
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.Vendor", True));
	If GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		ParametersArray.Add(New ChoiceParameter("SetSelectionByPartnerTypeAsOR", True));
		ParametersArray.Add(New ChoiceParameter("Filter.OurEnterprise", True));
	EndIf;
	Items.LotDetailsPartner.ChoiceParameters = New FixedArray(ParametersArray);
	
	CurrenciesOfManAndLocalAccountingMatch = Constants.CurrenciesOfManAndLocalAccountingMatch.Get();
	
	LotDetails.Load(GetFromTempStorage(TempStorageAddress));
	
	SetTextBatchData();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit And Modified Then
		Cancel = True;
		WarningText = NStr("vi = 'Không chuyển dữ liệu đến số dư đầu vào. Sau khi đóng, những thay đổi được thực hiện sẽ không được lưu.';
							|ru = 'Данные не были перенесены в ввод остатков. После закрытия, сделанные изменения сохранены не будут.';
							|en = 'Data was not transferred to entering balance. Changes will not be saved after the form is closed.'; fa = 'Data was not transferred to entering balance. Changes will not be saved after the form is closed.';
							|it = 'I dati non sono stati trasferiti nell''immissione delle rimanenze. Dopo la chiusura, le modifiche apportate non saranno salvate.';
							|pl = 'Dane nie zostały przeniesione do wprowadzenia ostatków. Po zamknięciu nie zostaną zapisane.';
							|tr = 'Veriler bakiye girişine transfer edilmedi. Kapattıktan sonra, yapılan değişiklikler kaydedilmeyecektir.'");
		Return;
	EndIf;
	
	If Modified Then
		Cancel = True;
		CallbackDescription = New CallbackDescription("HandlerAlertIssueBeforeClosing", ThisObject);
		QueryText = NStr("vi = 'Không chuyển dữ liệu đến mục nhập số dư. Chuyển?';
						|ru = 'Данные не перенесены в ввод остатков. Перенести?';
						|en = 'Data is not transferred to entering balance. Transfer?'; fa = 'Data is not transferred to entering balance. Transfer?';
						|it = 'I dati non sono stati trasferiti nell''immissione delle rimanenze. Trasferire?';
						|pl = 'Dane nie zostały przeniesione do do wprowadzenia ostatków. Przenieść?';
						|tr = 'Veriler bakiye girişine aktarılmadı. Transfer et?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLotDetails

&AtClient
Procedure LotDetailsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		CurrentData = Items.LotDetails.CurrentData;
		CurrentData.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
		CurrentData.AssetTaxClass = PredefinedValue("Enum.AssetKinds.Goods");
		CurrentData.VATRate = VATAccountingERPServerCall.DefaultVATRate(Organization, Date);
	EndIf;
	
EndProcedure

&AtClient
Procedure LotDetailsOnEditEnd(Item, NewRow, CancelEdit)
	
	SetTextBatchData();
	
EndProcedure

&AtClient
Procedure LotDetailsSumComplOnChange(Item)
	
	CalculateVATLocal();
		
	If CurrenciesOfManAndLocalAccountingMatch Then
		CurrentRow = Items.LotDetails.CurrentData;
		CurrentRow.SumMan = CurrentRow.SumCompl;
		CalculateVATMan();
	EndIf;
	
EndProcedure

&AtClient
Procedure LotDetailsVATRateOnChange(Item)
	
	CalculateVATLocal();
	CalculateVATMan();
	
EndProcedure

&AtClient
Procedure LotDetailsPartnerOnChange(Item)
	
	CurrentData = Items.LotDetails.CurrentData;
	IDCurrentRow = CurrentData.GetID();
	PartnerOnChange(CurrentData.Partner, CurrentData.Counterparty, IDCurrentRow);
	
EndProcedure

&AtClient
Procedure LotDetailsSumManOnChange(Item)
	
	CalculateVATMan();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	Cancel = False;
	
	ClearMessages();
	CheckFillingOfTablePart(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	Close(PutResultInTemporaryStorage());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CheckFillingOfTablePart(Cancel)
	
	For CurIndex__ = 0 To LotDetails.Count()-1 Do
		
		If Not ValueIsFilled(LotDetails[CurIndex__].Counterparty) Then
			ErrorText = NStr("vi = 'Chưa điền bạn hàng trong dòng %LineNumber%';
							|ru = 'Не заполнен партнер в строке %LineNumber%';
							|en = 'Partner is required in line %LineNumber%'; fa = 'Partner is required in line %LineNumber%';
							|it = 'Il partner non è compilato nella riga%LineNumber%';
							|pl = 'Nie wypełniono partneru w wierszu %LineNumber%';
							|tr = 'İş ortağı satırda doldurulmadı %LineNumber%'");
			ErrorText = StrReplace(ErrorText,"%LineNumber%",CurIndex__+1);
			Common.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("LotDetails", CurIndex__ + 1, "Partner"),
				,
				Cancel);
		EndIf;

		If Not ValueIsFilled(LotDetails[CurIndex__].Counterparty) Then
			ErrorText = NStr("vi = 'Chưa điền đối tác trong dòng %LineNumber%';
							|ru = 'Не заполнен контрагент в строке %LineNumber%';
							|en = 'Counterparty is required in line %LineNumber%'; fa = 'Counterparty is required in line %LineNumber%';
							|it = 'Il contraente non è compilato nella riga%LineNumber%';
							|pl = 'Nie wypełniono kontrahenta w wierszu %LineNumber%';
							|tr = 'Cari hesap satırda doldurulmadı %LineNumber%'");
			ErrorText = StrReplace(ErrorText,"%LineNumber%",CurIndex__+1);
			Common.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("LotDetails", CurIndex__ + 1, "Counterparty"),
				,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(LotDetails[CurIndex__].DocumentInflow) Then
			ErrorText = NStr("vi = 'Chưa điền chứng từ tiếp nhận trong dòng %LineNumber%';
							|ru = 'Не заполнен документ поступления в строке %LineNumber%';
							|en = 'Receipt document is required in line %LineNumber%'; fa = 'Receipt document is required in line %LineNumber%';
							|it = 'Il documento dell''arrivo non è compilato nella riga%LineNumber%';
							|pl = 'Nie wypełniono dolkuentu wpłaty w wierszu %LineNumber%';
							|tr = 'Tahsilat belgesi satırda doldurulmadı %LineNumber%'");
			ErrorText = StrReplace( ErrorText,"%LineNumber%",CurIndex__+1);
			Common.MessageToUser(
				ErrorText ,
				,
				CommonClientServer.PathToTabularSection("LotDetails", CurIndex__ + 1, "DocumentInflow"),
				,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(LotDetails[CurIndex__].AssetTaxClass) Then
			ErrorText = NStr("vi = 'Chưa điền Dạng giá trị trong dòng %LineNumber%';
							|ru = 'Не заполнен Вид ценности в строке %LineNumber%';
							|en = 'Asset tax class is required in line %LineNumber%'; fa = 'Asset tax class is required in line %LineNumber%';
							|it = 'Il Tipo di valori non è compilato nella riga%LineNumber%';
							|pl = 'Nie wypełniono rodzaju wartości w wierszu %LineNumber%';
							|tr = 'Değer türü satırda doldurulmadı %LineNumber%'");
			ErrorText = StrReplace( ErrorText,"%LineNumber%",CurIndex__+1);
			Common.MessageToUser(
				ErrorText ,
				,
				CommonClientServer.PathToTabularSection("LotDetails", CurIndex__ + 1, "AssetTaxClass"),
				,
				Cancel);
		EndIf;
		
		If Not ValueIsFilled(LotDetails[CurIndex__].VATRate) Then
			ErrorText = NStr("vi = 'Chưa điền thuế suất Thuế GTGT trong dòng %LineNumber%';
							|ru = 'Не заполнен Ставка НДС в строке %LineNumber%';
							|en = 'VAT Rate is required in line %LineNumber%'; fa = 'VAT Rate is required in line %LineNumber%';
							|it = 'Aliquota IVA non è compilata nella riga%LineNumber%';
							|pl = 'Nie wypełniono stawki VAT w wierszu %LineNumber%';
							|tr = 'KDV oranı satırda doldurulmadı %LineNumber%'");
			ErrorText = StrReplace( ErrorText,"%LineNumber%",CurIndex__+1);
			Common.MessageToUser(
				ErrorText ,
				,
				CommonClientServer.PathToTabularSection("LotDetails", CurIndex__ + 1, "VATRate"),
				,
				Cancel);
		EndIf;
		
		If LotDetails[CurIndex__].SumCompl = 0
			And LotDetails[CurIndex__].VATLocal = 0
			And LotDetails[CurIndex__].VATManag = 0 Then
			ErrorText = NStr("vi = 'Chưa điền chỉ số tổng trong dòng %LineNumber%';
							|ru = 'Не заполнены суммовые показатели в строке %LineNumber%';
							|en = 'Amount indicators are required in line %LineNumber%'; fa = 'Amount indicators are required in line %LineNumber%';
							|it = 'Il dati degli importi totali non sono compilati nella riga%LineNumber%';
							|pl = 'Nie wypełniono wskaźniki wartościowe w wierszu %LineNumber%';
							|tr = 'Toplam tutar göstergeleri satırda doldurulmadı %LineNumber%'");
			ErrorText = StrReplace( ErrorText,"%LineNumber%",CurIndex__+1);
			Common.MessageToUser(
				ErrorText ,
				,
				CommonClientServer.PathToTabularSection("LotDetails", CurIndex__ + 1, "SumCompl"),
				,
				Cancel);
		EndIf;
		
	EndDo;
	
	If TotalAmountRegl > SumCompl Then
		ErrorText = NStr("vi = 'Số tiền tiếp nhận không được vượt quá giá trị của hàng hóa';
						|ru = 'Сумма поступлений не может превышать стоимость товара';
						|en = 'Receipt amount cannot exceed goods cost'; fa = 'Receipt amount cannot exceed goods cost';
						|it = 'L''ammontare degli arrivi non può superare il costo della merce';
						|pl = 'Wartość wpłat nie może przekraczać wartość towaru';
						|tr = 'Tahsilatların tutarı ürünlerin maliyetini aşamaz'");
		Common.MessageToUser(
			ErrorText,
			,
			"LotDetails",
			,
			Cancel);
	EndIf;
	
	If SummaryNdseg > VATLocal Then
		ErrorText = NStr("vi = 'Thuế GTGT không được vượt quá tổng số thuế Thuế GTGT trên sản phẩm';
						|ru = 'Сумма НДС поступлений не может превышать итоговую суммы НДС по товару';
						|en = 'The amount of VAT receipts cannot exceed the total VAT amount for goods'; fa = 'The amount of VAT receipts cannot exceed the total VAT amount for goods';
						|it = 'L''importo IVA degli arrivi non può superare l''importo totale dell''IVA della merce';
						|pl = 'Wartość wpat VAT nie może przekrazać wynikowej wartości VAT według towaru';
						|tr = 'Tahsilatların KDV tutarı, ürünler üzerindeki toplam KDV tutarını aşamaz'");
		Common.MessageToUser(
			ErrorText,
			,
			"LotDetails",
			,
			Cancel);
	EndIf;
	
EndProcedure

&AtServer
Function PutResultInTemporaryStorage()
	
	Return PutToTempStorage(LotDetails.Unload(), TempStorageAddress);
	
EndFunction

&AtClient
Procedure HandlerAlertIssueBeforeClosing(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Cancel = False;
		CheckFillingOfTablePart(Cancel);
		If Not Cancel Then
			Modified = False;
			Close(PutResultInTemporaryStorage());
		EndIf;
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTextBatchData()
	
	SummaryNdseg = LotDetails.Total("VATLocal");
	TotalAmountRegl = LotDetails.Total("SumCompl");
	
	If VATLocal <> 0 Then
		Template = NStr("vi = 'Đối với lô nhập số dư, sẽ phản ánh số tiền (quy định) %1 Thuế GTGT (quy định) %2';
						|ru = 'По партии ввода остатков будет отражена сумма (регл.) %1 НДС (регл.) %2';
						|en = 'Amount (local) %1 VAT (local) %2 will be recorded by balance input lot'; fa = 'Amount (local) %1 VAT (local) %2 will be recorded by balance input lot';
						|it = 'Per il lotto inserito delle rimanenze verrà riportato l''importo (reg.) %1 IVA (reg.) %2';
						|pl = 'Według partii wprowadzenia ostatków będzie odzwieciedlona wartość (regl.) %1 VAT (regl.) %2';
						|tr = 'KDV (yerel) %1 tutarı (yerel) %2 bakiye giriş lotuna göre yansıtılacaktır'");
	Else
		Template = NStr("vi = 'Đối với lô nhập số dư, sẽ phản ánh số tiền (quy định) %1';
						|ru = 'По партии ввода остатков будет отражена сумма (регл.) %1';
						|en = 'Amount (local) %1 will be recorded by balance input lot'; fa = 'Amount (local) %1 will be recorded by balance input lot';
						|it = 'Per il lotto inserito delle rimanenze verrà riportato l''importo (reg.) %1';
						|pl = 'Według partii wprowadzenia ostatków będzie odzwierciedlona wartość (regl.) %1';
						|tr = 'Tutar (yerel) bakiye giriş lotuna göre yansıtılacaktır %1'");
	EndIf;
	
	If SummaryNdseg > VATLocal Or TotalAmountRegl > SumCompl Then
		Color = StyleColors.ErrorNoteText;
	Else
		Color = StyleColors.NoteText;
	EndIf;
	
	If VATLocal <> 0 Then
		TheTextDataOfTheParty = New FormattedString(
						StrTemplate(Template, Format(SumCompl - TotalAmountRegl, "NFD=2"), Format(VATLocal - SummaryNdseg, "NFD=2")), 
						, 
						Color);
	Else
		TheTextDataOfTheParty = New FormattedString(
						StrTemplate(Template, Format(SumCompl - TotalAmountRegl, "NFD=2")), 
						, 
						Color);
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerOnChange(Partner, Counterparty, RowID)
	
	If Partner = Catalogs.Partners.OurEnterprise 
		And TypeOf(Counterparty) <> Type("CatalogRef.Companies") Then
		Counterparty = Catalogs.Companies.EmptyRef();
	Else
		RefillingCounterparty = (TypeOf(Counterparty) <> Type("CatalogRef.Counterparties"));
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty, RefillingCounterparty);
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateVATLocal()
	
	CurrentRow = Items.LotDetails.CurrentData;
	CurrentRow.VATLocal = PriceManagementSystemClientServer.CalculateVATAmount(CurrentRow.SumCompl, CurrentRow.VATRate, False);
	
	SetTextBatchData();
	
EndProcedure

&AtClient
Procedure CalculateVATMan()
	
	CurrentRow = Items.LotDetails.CurrentData;
	CurrentRow.VATManag = PriceManagementSystemClientServer.CalculateVATAmount(CurrentRow.SumMan, CurrentRow.VATRate, False);
	
	SetTextBatchData();
	
EndProcedure

#EndRegion