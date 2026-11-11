
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ValueTable = GetFromTempStorage(Parameters.AddressInTempStorage);
	ClarificationOfTheValueOfTheDiscountMarkUp.Load(ValueTable);
	OnlyViewItems = Parameters.ReadOnly Or Not AccessRight("Update", Metadata.Catalogs.DiscountsMarkups);
	Items.ClarificationOfTheValueOfTheDiscountMarkUp.ReadOnly = OnlyViewItems;
	Items.FormCompleteEditing.Enabled = Not OnlyViewItems;
	
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	ClearMessages();
	
	Cancel = False;
	For Each TSRow In ClarificationOfTheValueOfTheDiscountMarkUp Do
		LineNumber = ClarificationOfTheValueOfTheDiscountMarkUp.IndexOf(TSRow) + 1;
		If Not ValueIsFilled(TSRow.PriceGroup) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền cột ""Nhóm giá"" trong dòng %1 của danh sách ""Làm rõ giá trị chiết khấu (phụ thu)""';
					|ru = 'Не заполнена колонка ""Ценовая группа"" в строке %1 списка ""Уточнения значения скидки (наценки)""';
					|en = 'Column ""Price group"" in line %1 of list ""Discount (markup) value specifications"" is not filled in'; fa = 'Column ""Price group"" in line %1 of list ""Discount (markup) value specifications"" is not filled in';
					|it = 'La colonna ""Il gruppo dei prezzi"" nella riga %1 dell''elenco ""Puntualizzazione del valore di sconto (sovrapprezzo)"" non è compilata';
					|pl = 'Nie wypełniono kolumny ""Grupa cenowa"" w wierszu %1 listy ""Uściślenie wartości rabatu (marży)""';
					|tr = '""İndirim (Zam) Değerinin İyileştirilmesi"" listesinin %1 satırındaki ""Fiyat Grubu"" sütunu doldurulmadı'"), LineNumber);
			CommonClientServer.MessageToUser(
				MessageText,,CommonClientServer.PathToTabularSection("ClarificationOfTheValueOfTheDiscountMarkUp", LineNumber, "DeliveryMethod"),, Cancel);
		EndIf;
		
	EndDo;
	
	If Cancel Then
		Return;
	EndIf;
	
	Close(AddressOfTablePartOfPriceGroupConstraintInTemporaryStorage());
	
EndProcedure

&AtServer
Function AddressOfTablePartOfPriceGroupConstraintInTemporaryStorage()

	Return PutToTempStorage(ClarificationOfTheValueOfTheDiscountMarkUp.Unload(), UUID);

EndFunction
