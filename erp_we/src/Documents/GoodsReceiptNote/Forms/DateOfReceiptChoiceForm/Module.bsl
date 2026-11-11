
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	DateOfReceipt = BegOfDay(CurrentSessionDate());
	CurrentDateDayStart = DateOfReceipt;

	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsToReceiveBalanceAndTurnovers.Period AS Period,
	|	GoodsToReceiveBalanceAndTurnovers.Products AS Products,
	|	GoodsToReceiveBalanceAndTurnovers.Characteristic AS Characteristic,
	|	GoodsToReceiveBalanceAndTurnovers.GoodsReceiptNotesToRegisterClosingBalance - GoodsToReceiveBalanceAndTurnovers.AcceptsClosingBalance AS Expected_
	|FROM
	|	AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(
	|			,
	|			,
	|			Recorder,
	|			RegisterRecords,
	|			DocumentInflow = &ReferenceOrder
	|				AND Warehouse = &Warehouse) AS GoodsToReceiveBalanceAndTurnovers
	|WHERE
	|	GoodsToReceiveBalanceAndTurnovers.GoodsReceiptNotesToRegisterClosingBalance - GoodsToReceiveBalanceAndTurnovers.AcceptsClosingBalance > 0
	|	AND GoodsToReceiveBalanceAndTurnovers.Recorder <> &CurrentDocument
	|
	|ORDER BY
	|	Period DESC
	|TOTALS BY
	|	Products,
	|	Characteristic";
	
	Query.SetParameter("ReferenceOrder", Parameters.ReferenceOrder);
	Query.SetParameter("CurrentDocument", Parameters.CurrentDocument);
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	
	SelectionByProductType_ = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	ReceiptDates = New Map;
	
	While SelectionByProductType_.Next() Do
		
		SelectionByCharacteristics = SelectionByProductType_.Select(QueryResultIteration.ByGroups);

		While SelectionByCharacteristics.Next() Do
			
			SelectionByDate = SelectionByCharacteristics.Select(QueryResultIteration.ByGroups);
			
			FirstDateOfReceipt = Undefined;
			
			While SelectionByDate.Next() Do
				
				If SelectionByDate.Expected_ <= 0 Then
					Break;
				EndIf;
				
				FirstDateOfReceipt = BegOfDay(SelectionByDate.Period);
				
				If ReceiptDates.Get(FirstDateOfReceipt) = Undefined Then
					ReceiptDates.Insert(FirstDateOfReceipt,0);
				EndIf;
				
			EndDo;
			
			If FirstDateOfReceipt <> Undefined Then 
				ReceiptDates[FirstDateOfReceipt] = ReceiptDates[FirstDateOfReceipt] + 1;
			EndIf;
						
		EndDo;
				
	EndDo;
	
	For Each KeyValue In ReceiptDates Do
		
		Items.DateOfReceipt.ChoiceList.Add(KeyValue.Key,Format(KeyValue.Value,"NZ=0; NG="));
		
	EndDo;
	
	Items.DateOfReceipt.ChoiceList.SortByValue(SortDirection.Asc);
	
	SummingUp = 0;
	
	ArrayOfValuesToDelete   = New Array;
	YouNeedToAddCurDate  = False;
	NumberOfItemsAsOfCurDate = 0;
	
	For Each RowSP In Items.DateOfReceipt.ChoiceList Do
		
		SummingUp = SummingUp + Number(RowSP.Presentation);
		
		If RowSP.Value <= DateOfReceipt Then
			ArrayOfValuesToDelete.Add(RowSP);
			YouNeedToAddCurDate = True;
		Else
			
			If YouNeedToAddCurDate Then
				NumberOfItemsAsOfCurDate = SummingUp;
				YouNeedToAddCurDate  = False;
			EndIf;
			
			PresentationOfReceiptDate = NStr("vi = '%Date% (%Count% vị trí)';
											|ru = '%Date% (%Count% поз.)';
											|en = '%Date% (%Count% of items)'; fa = '%Date% (%Count% of items)';
											|it = '%Date% (%Count% pos.)';
											|pl = '%Date% (%Count% poz.)';
											|tr = '%Date% (%Count% pozisyon.)'");	
			
			PresentationOfReceiptDate = StrReplace(PresentationOfReceiptDate,"%Date%",Format(RowSP.Value,"DLF=D"));
			PresentationOfReceiptDate = StrReplace(PresentationOfReceiptDate,"%Count%",SummingUp);
			
			RowSP.Presentation = PresentationOfReceiptDate;
		EndIf;
		
	EndDo;
	
	If YouNeedToAddCurDate Then
		NumberOfItemsAsOfCurDate = SummingUp;
	EndIf;
	
	If NumberOfItemsAsOfCurDate <> 0 Then
		PresentationOfReceiptDate = NStr("vi = '%Date% (%Count% vị trí)';
										|ru = '%Date% (%Count% поз.)';
										|en = '%Date% (%Count% of items)'; fa = '%Date% (%Count% of items)';
										|it = '%Date% (%Count% pos.)';
										|pl = '%Date% (%Count% poz.)';
										|tr = '%Date% (%Count% pozisyon.)'");	
		
		PresentationOfReceiptDate = StrReplace(PresentationOfReceiptDate,"%Date%",Format(DateOfReceipt,"DLF=D"));
		PresentationOfReceiptDate = StrReplace(PresentationOfReceiptDate,"%Count%",NumberOfItemsAsOfCurDate);
		
		Items.DateOfReceipt.ChoiceList.Insert(0,  BegOfDay(DateOfReceipt), PresentationOfReceiptDate);
		
	EndIf;
	
	For Each ArrRow In ArrayOfValuesToDelete Do
		Items.DateOfReceipt.ChoiceList.Delete(ArrRow);		
	EndDo;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
		
	If DateOfReceipt < CurrentDateDayStart Then
		WarningText = NStr("vi = 'Hãy chỉ ra ngày không nhỏ hơn ngày hiện tại (%Date%).';
							|ru = 'Укажите дату, не меньше текущей даты (%Date%).';
							|en = 'Specify the date which is not less than the current date (%Date%).'; fa = 'Specify the date which is not less than the current date (%Date%).';
							|it = 'Inserire la data, non inferiore alla data corrente (%Date%).';
							|pl = 'Wprowadź datę, nie mniejszą niż bieżąca datę (%Date%).';
							|tr = 'Mevcut tarihten daha az olmayan bir tarih belirt (%Date%).'");
		
		WarningText = StrReplace(WarningText, "%Date%", Format(CurrentDateDayStart,"DLF=D"));
		
		ShowMessageBox(Undefined, WarningText);
		
		Return;	
	EndIf;
		
	Close(DateOfReceipt);
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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
