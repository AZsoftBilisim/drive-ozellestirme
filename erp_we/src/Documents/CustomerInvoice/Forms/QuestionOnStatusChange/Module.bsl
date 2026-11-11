
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DateOfTransferOfTitleToGoods = Parameters.DateOfTransferOfTitleToGoods;
	TheHighlightedLinesContainMoreThanJustTheShipment = Parameters.TheHighlightedLinesContainMoreThanJustTheShipment;
	
	If TheHighlightedLinesContainMoreThanJustTheShipment Then
		ExplanationText = NStr("vi = 'Trong các chứng từ đã chọn trong danh sách sẽ thiết lập trạng thái ""Đã giao hàng"".
			|Trong chứng từ giao hàng mà chưa chuyển giao quyền sở hữu sẽ thiết lập';
			|ru = 'У выделенных в списке документов будет установлен статус ""Реализовано"".
			|В документах отгрузки без перехода права собственности будет установлена';
			|en = 'Status of the documents selected in the list will be set to ""Sold"".
			|In shipping documents with deferred transfer of title of goods, the following will be set:'; fa = 'Status of the documents selected in the list will be set to ""Sold"".
			|In shipping documents with deferred transfer of title of goods, the following will be set:';
			|it = 'Per i documenti selezionati nell''elenco sarà impostato lo stato ""Venduto"". 
			| Nei documenti di spedizione senza passaggio di proprietà sarà impostato';
			|pl = 'Dla zaznaczonych na liście dokumentów zostanie ustawione status ""Zrealizowane"".
			|W dokumentach wysyłkowych bez prawa przeniesienia własności zostanie ustawiona';
			|tr = 'Listede seçili belgeler ""Gerçekleştirildi"" durumuna ayarlanacaktır.
			| Transfer hakkı olmayan sevkiyat belgeleri şu şekilde ayarlanacaktır'");
	Else		
		ExplanationText = NStr("vi = 'Trong các chứng từ giao hàng đã tách chọn trong danh sách sẽ đặt trạng thái ""Đã giao hàng"" và';
								|ru = 'У выделенных в списке документов реализации будут установлены статус ""Реализовано"" и';
								|en = 'Status ""Sold"" will be set for the sales documents selected in the list and'; fa = 'Status ""Sold"" will be set for the sales documents selected in the list and';
								|it = 'Per i documenti di vendita selezionati nell''elenco sarà impostato lo stato ""Venduto"" e';
								|pl = 'Dla zaznaczonych na liście dokumentów realizacji zostanie ustawione status ""Zrealizowane"" i';
								|tr = 'Listede seçili satış belgeleri ""Satıldı"" durumuna getirilecek ve'");
	EndIf;
		
	Items.DecorationNote.Title = ExplanationText;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetStatus(Command)
	
	If CheckFilling() Then
		Close(New Structure("NewDate", DateOfTransferOfTitleToGoods));
	EndIf;

EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
