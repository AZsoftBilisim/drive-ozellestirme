
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Status     = Parameters.Status;
	StartDate = Parameters.StartDate;
	If Not ValueIsFilled(StartDate) Then
		StartDate = CurrentSessionDate();
	EndIf;
	
	If TypeOf(Parameters.Source) = Type("Array") Then
		For Each Source In Parameters.Source Do
			NewRow = Sources.Add();
			NewRow.Ref = Source;
		EndDo;
	Else
		NewRow = Sources.Add();
		NewRow.Ref = Parameters.Source;
	EndIf;
	
	If ValueIsFilled(Parameters.DiscountMarkup) Then
		If TypeOf(Parameters.DiscountMarkup) = Type("Array") Then
			For Each Source In Parameters.DiscountMarkup Do
				NewRow = DiscountsMarkups.Add();
				NewRow.Ref = Source;
			EndDo;
		Else
			NewRow = DiscountsMarkups.Add();
			NewRow.Ref = Parameters.DiscountMarkup;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Parameters.ItemItemPosition) Then
		If TypeOf(Parameters.ItemItemPosition) = Type("Array") Then
			For Each ItemItemPosition In Parameters.ItemItemPosition Do
				FillPropertyValues(Goods.Add(), ItemItemPosition);
			EndDo;
		Else
			FillPropertyValues(Goods.Add(), Parameters.ItemItemPosition);
		EndIf;
	EndIf;
	
	If ValueIsFilled(Status) Then
		Items.Status.Visible = False;
	Else
		Items.Status.Visible = True;
	EndIf;
	
	CustomizeForm();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure TheStatusIsValidUntilTheMaximumDateOnChange(Item)
	OptionToSelectEndDateWhenChanging(ThisForm);
EndProcedure

&AtClient
Procedure ValidUntilTheDateOnChange(Item)
	OptionToSelectEndDateWhenChanging(ThisForm);
EndProcedure

&AtClient
Procedure TheMaximumDateIsNotDefinedTheStatusIsValidIndefinitelyOnChange(Item)
	OptionToSelectEndDateWhenChanging(ThisForm);
EndProcedure

&AtClient
Procedure TheMaximumDateIsNotDefinedValidUntilTheDateOnChange(Item)
	OptionToSelectEndDateWhenChanging(ThisForm);
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	CustomizeForm();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	ClearMessages();
	
	Cancel = False;
	If Not ValueIsFilled(Status) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Trạng thái""';
				|ru = 'Не заполнено поле ""Статус""';
				|en = '""Status"" is required'; fa = '""Status"" is required';
				|it = 'Il campo ""Stato"" non è compilato';
				|pl = 'Nie wypełniono pola ""Status""';
				|tr = '""Durum"" alanı doldurulmadı'"), ,"Status",,Cancel);
	EndIf;
	If Not ValueIsFilled(StartDate) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Ngày bắt đầu""';
				|ru = 'Не заполнено поле ""Дата начала""';
				|en = '""Start date"" is required'; fa = '""Start date"" is required';
				|it = 'Il campo ""Data dell''inizio"" non è compilato';
				|pl = 'Nie wypełniono pola ""Data rozpoczęcia""';
				|tr = '""Başlangıç Tarihi"" alanı doldurulmadı'"), ,"StartDate",,Cancel);
	EndIf;
	
	If MaxDateIsDetermined Then
		
		If Not ValueIsFilled(EndDate)
			And EndDateSelectionOption = 0
			And Status = PredefinedValue("Enum.DiscountValidityStatuses.Valid") Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Chưa điền trường ""Ngày kết thúc""';
					|ru = 'Не заполнено поле ""Дата окончания""';
					|en = '""End date"" is required'; fa = '""End date"" is required';
					|it = 'Il capo ""Data del termine"" non è compilato';
					|pl = 'Nie wypełniono pola ""Data zakończenia""';
					|tr = '""Bitiş Tarihi"" alanı doldurulmadı'"), ,"EndDate",,Cancel);
		EndIf;
	
		If EndDate > MaxDateOfANewStatus
			And EndDateSelectionOption = 0 Then
			
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Ngày kết thúc hiệu lực không thể sau %1';
						|ru = 'Дата окончания действия не может быть позже %1';
						|en = 'The action expiration date cannot be later than %1'; fa = 'The action expiration date cannot be later than %1';
						|it = 'La data del termine di validità non può essere superiore %1';
						|pl = 'Data wygaśnięcia nie może być późniejsza niż %1';
						|tr = 'Geçerlilik bitiş tarihi, %1 tarihinden sonra olamaz'"),
					Format(MaxDateOfANewStatus, "DLF=D")),
					,
					"EndDate",
					,
					Cancel);
		EndIf;
	
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	RecordChangeOnServer();
	
	If DiscountsMarkups.Count() > 0 Then
	
		ArrayDiscountsMargins = New Array;
		ArraySources = New Array;
		
		For Each TSRow In DiscountsMarkups Do
			ArrayDiscountsMargins.Add(TSRow.Ref);
		EndDo;
		For Each TSRow In Sources Do
			ArraySources.Add(TSRow.Ref);
		EndDo;
		
		Parameter = New Structure;
		Parameter.Insert("DiscountMarkup", ArrayDiscountsMargins);
		Parameter.Insert("Source", ArraySources);
		
		Notify("Write_ValidityOfDiscountsMarkups", Parameter, ThisForm);
	
	EndIf;
	
	If Goods.Count() > 0 Then
	
		ArraySources = New Array;
		For Each TSRow In Sources Do
			ArraySources.Add(TSRow.Ref);
		EndDo;
		
		Parameter = New Structure;
		Parameter.Insert("Source", ArraySources);
		
		Notify("Write_ValidityOfDiscountsMarkupsByItems", Parameter, ThisForm);
	
	EndIf;
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeForm()
	
	If DiscountsMarkups.Count() > 0 Then
		
		QueryText = 
		"SELECT
		|	MIN(T.Period) AS Period
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups AS T
		|WHERE
		|	T.Period > &StartDate
		|	AND T.Source IN (&Sources)
		|	AND T.DiscountMarkup IN (&Table)";
		
		Table = DiscountsMarkups.Unload().UnloadColumn("Ref");
		
	EndIf;
	
	If Goods.Count() > 0 Then
		
		QueryText = 
		"SELECT
		|	T.Products,
		|	T.Characteristic
		|INTO Goods
		|FROM
		|	&Table AS T
		|;
		|
		|SELECT
		|	MIN(T.Period) AS Period
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkupsByItems AS T
		|WHERE
		|	T.Period > &StartDate
		|	AND T.Source IN (&Sources)
		|	AND (T.Products, T.Characteristic) IN (SELECT T.Products, T.Characteristic FROM Goods AS T)";
		
		Table = Goods.Unload();
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("Sources", Sources.Unload().UnloadColumn("Ref"));
	Query.SetParameter("Table", Table);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	MaxDateOfANewStatus = '00010101';
	EndDateSelectionOption = 0;
	If Selection.Next() And ValueIsFilled(Selection.Period) Then
		MaxDateOfANewStatus = BegOfDay(Selection.Period - 1);
	EndIf;
	
	If ValueIsFilled(MaxDateOfANewStatus) Then
		EndDateSelectionOption = 1;
	EndIf;
	
	If Status = Enums.DiscountValidityStatuses.NotValid Then
		Items.Pages.CurrentPage = Items.Pages.ChildItems.NotValid;
	Else
		If ValueIsFilled(MaxDateOfANewStatus) Then
			Items.Pages.CurrentPage = Items.Pages.ChildItems.MaxDateIsDetermined;
			MaxDateIsDetermined = True;
		Else
			Items.Pages.CurrentPage = Items.Pages.ChildItems.MaxDateIsNotDetermined;
			MaxDateIsDetermined = False;
		EndIf;
	EndIf;
	
	Items.TheStatusIsValidUntilTheMaximumDate.ChoiceList[0].Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		"on %1", Format(MaxDateOfANewStatus, "DLF=D"));
	
	OptionToSelectEndDateWhenChanging(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure OptionToSelectEndDateWhenChanging(Form)

	Form.Items.MaximumDateNotDefinedEndDate.Enabled = (Form.EndDateSelectionOption = 1);
	Form.Items.EndDate.Enabled = (Form.EndDateSelectionOption = 0);

EndProcedure

&AtServer
Procedure RecordChangeOnServer()
	
	SetPrivilegedMode(True);
	
	ValidityEndDate = Undefined;
	If MaxDateIsDetermined Then
		
		If EndDateSelectionOption = 0 Then
			ValidityEndDate = EndDate;
		Else
			ValidityEndDate = MaxDateOfANewStatus;
		EndIf;
		
	Else
		
		If EndDateSelectionOption = 1 Then
			ValidityEndDate = EndDate;
		EndIf;
		
	EndIf;
	
	BeginTransaction();
	Try
		
		For Each SourceRow In Sources Do
			
			For Each DiscountMarkUpLine In DiscountsMarkups Do
				
				RecordManager = InformationRegisters.ValidityOfDiscountsMarkups.CreateRecordManager();
				RecordManager.Period        = StartDate;
				RecordManager.Source      = SourceRow.Ref;
				RecordManager.DiscountMarkup = DiscountMarkUpLine.Ref;
				RecordManager.Status        = Status;
				RecordManager.EmployeeResponsible = Users.CurrentUser();
				RecordManager.Comment   = Comment;
				RecordManager.Write(True);
				
				If ValueIsFilled(ValidityEndDate) And Status = Enums.DiscountValidityStatuses.Valid Then
					RecordManager = InformationRegisters.ValidityOfDiscountsMarkups.CreateRecordManager();
					RecordManager.Period        = EndOfDay(ValidityEndDate) + 1;
					RecordManager.Source      = SourceRow.Ref;
					RecordManager.DiscountMarkup = DiscountMarkUpLine.Ref;
					RecordManager.Status        = Enums.DiscountValidityStatuses.NotValid;
					RecordManager.EmployeeResponsible = Users.CurrentUser();
					RecordManager.Write(True);
				EndIf;
				
			EndDo;
			
			For Each ItemItemPosition In Goods Do
				
				RecordManager = InformationRegisters.ValidityOfDiscountsMarkupsByItems.CreateRecordManager();
				RecordManager.Period         = StartDate;
				RecordManager.Source       = SourceRow.Ref;
				RecordManager.Products   = ItemItemPosition.Products;
				RecordManager.Characteristic = ItemItemPosition.Characteristic;
				RecordManager.Status         = Status;
				RecordManager.EmployeeResponsible  = Users.CurrentUser();
				RecordManager.Comment    = Comment;
				RecordManager.Write(True);
				
				If ValueIsFilled(ValidityEndDate) And Status = Enums.DiscountValidityStatuses.Valid Then
				RecordManager = InformationRegisters.ValidityOfDiscountsMarkupsByItems.CreateRecordManager();
				RecordManager.Period         = EndOfDay(ValidityEndDate) + 1;
				RecordManager.Source       = SourceRow.Ref;
				RecordManager.Products   = ItemItemPosition.Products;
				RecordManager.Characteristic = ItemItemPosition.Characteristic;
				RecordManager.Status         = Enums.DiscountValidityStatuses.NotValid;
				RecordManager.EmployeeResponsible  = Users.CurrentUser();
				RecordManager.Write(True);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
			
	EndTry;
	
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
	If Item.Name = "sh_ShamsiInput_F_StartDate" Then
		StartDateOnChange(Items.MaximumDateDefinedStartDate);
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
