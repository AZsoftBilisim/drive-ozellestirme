#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	FillInStartEndDates();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not TypeOf(FillingData) = Type("Structure") Or Not FillingData.Property("Owner") Then
		Owner = SettingsValueCached.GetDefaultOrganization(Owner);
	EndIf;
	
	FillInStartEndDates();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckIntersectionOfValidityPeriod(Cancel);
	
	NotCheckedAttributeArray = New Array;
	
	If GetFunctionalOption("BaseVersion") Then
		
		NotCheckedAttributeArray.Add("Individual");
		
		If Not ValueIsFilled(Individual) Then
			
			CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Nhân viên""';
				|ru = 'Поле ""Сотрудник"" не заполнено';
				|en = '""Employee"" is required'; fa = '""Employee"" is required';
				|it = 'Il campo ""Dipendente"" non è compilato';
				|pl = 'Pole ""Pracownik"" nie jest wypełnione.';
				|tr = '""Çalışan"" alanı doldurulmadı'"),
				ThisObject,
				"Individual",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not SignatureRight And ValueIsFilled(SignatureRightBasis) Then
		SignatureRightBasis = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckIntersectionOfValidityPeriod(Cancel)
	
	If Not ValueIsFilled(StartDate)
	 Or Not ValueIsFilled(EmployeeInCharge_)
	 Or Not ValueIsFilled(Owner) Then
		Return; // search fields are not filled in
	EndIf;
	
	If SignatureRight Then
		Return; // intersections of periods are allowed
	EndIf;
	
	If ValueIsFilled(EndDate) And StartDate > EndDate Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Ngày kết thúc kỳ không thể nhỏ hơn ngày bắt đầu';
				|ru = 'Дата окончания периода не может быть меньше даты начала';
				|en = 'Period end date cannot be less than start date'; fa = 'Period end date cannot be less than start date';
				|it = 'La data di fine periodo non può essere inferiore alla data d''inizio';
				|pl = 'Data zakończenia okresu nie może być mniejsza od daty rozpoczęcia';
				|tr = 'Dönemin bitiş tarihi, başlangıç ​​tarihinden önce olamaz'"),
			Ref,
			"Object.EndDate",,
			Cancel);
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("CurrentItem", 	Ref);
	Query.SetParameter("Owner", 			Owner);
	Query.SetParameter("EmployeeInCharge_", 	EmployeeInCharge_);
	Query.SetParameter("StartDate", 		StartDate);
	Query.SetParameter("EndDate", 		EndDate);
	
	Query.Text =
	"SELECT
	|	Cat.Description,
	|	Cat.StartDate AS StartDate,
	|	Cat.EndDate AS EndDate
	|FROM
	|	Catalog.PersonsResponsibleAndCompanies AS Cat
	|WHERE
	|	Cat.Ref <> &CurrentItem
	|	AND Cat.Owner = &Owner
	|	AND Cat.EmployeeInCharge_ = &EmployeeInCharge_
	|	AND NOT Cat.SignatureRight
	|	AND (Cat.StartDate <= &StartDate
	|				AND (Cat.EndDate >= &StartDate
	|					OR Cat.EndDate = DATETIME(1, 1, 1))
	|			OR Cat.StartDate <= &EndDate
	|				AND (Cat.EndDate >= &EndDate
	|					OR Cat.EndDate = DATETIME(1, 1, 1))
	|			OR Cat.StartDate >= &StartDate
	|				AND (Cat.StartDate <= &EndDate
	|					OR &EndDate = DATETIME(1, 1, 1)))
	|
	|ORDER BY
	|	StartDate";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Trong kỳ %1
		|đã nhập thông tin về người chịu trách nhiệm:';
		|ru = 'За период %1
		|уже введена информация по ответственным лицам:';
		|en = 'Data on responsible persons 
		|is already entered for the period of %1:'; fa = 'Data on responsible persons 
		|is already entered for the period of %1:';
		|it = 'Per il periodo %1
		|le informazioni sulle persone responsabili sono già state inserite:';
		|pl = 'Za okres %1
		|wprowadzono już informację o osobach odpowiedzialnych:';
		|tr = '%1
		| dönemi için, sorumlu kişilere ilişkin bilgiler zaten girilmiş:'"), PeriodPresentation(StartDate, EndDate));
	
	Selection = Result.Select();
	While Selection.Next() Do
		MessageText = MessageText + "
		|" + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1';
					|ru = '%1';
					|en = '%1'; fa = '%1';
					|it = '%1';
					|pl = '%1';
					|tr = '%1'"), Selection.Description);
	EndDo;
	
	CommonClientServer.MessageToUser(
		MessageText,
		Ref,
		,
		,
		Cancel);
	
EndProcedure

Procedure FillInStartEndDates()
	
	StartDate = CurrentSessionDate();
	If EndDate < StartDate Then
		EndDate = Date(1,1,1);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
