
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		FillingData.Property("Date",          Date);
		FillingData.Property("Department", Department);
		FillingData.Property("Shift",         Shift);
		FillingData.Property("ProductionArea",       ProductionArea);
		
		If FillingData.Property("FillInPerformersFromPreviousShift")
			And FillingData.FillInPerformersFromPreviousShift Then
			
			Query = New Query(
				"SELECT TOP 1
				|	ShiftTaskAssignees.Ref AS Ref
				|INTO TTLink
				|FROM
				|	Document.ShiftTask AS ShiftTask
				|		INNER JOIN Document.ShiftTask.Assignees AS ShiftTaskAssignees
				|		ON ShiftTask.Ref = ShiftTaskAssignees.Ref
				|WHERE
				|	ShiftTask.Department = &Department
				|	AND ShiftTask.Shift = &Shift
				|	AND ShiftTask.ProductionArea = &ProductionArea
				|	AND ShiftTask.Date < &Date
				|	AND ShiftTask.DeletionMark = FALSE
				|
				|ORDER BY
				|	ShiftTask.Date DESC
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ShiftTaskAssignees.Performer AS Performer
				|FROM
				|	TTLink AS TTLink
				|		INNER JOIN Document.ShiftTask.Assignees AS ShiftTaskAssignees
				|		ON TTLink.Ref = ShiftTaskAssignees.Ref");
			Query.SetParameter("Department", Department);
			Query.SetParameter("Shift", Shift);
			Query.SetParameter("Date", Date);
			Query.SetParameter("ProductionArea", ProductionArea);
			
			Assignees.Load(Query.Execute().Unload());
			
		EndIf;
		
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	
	If Not DivisionParameters.UseShifts Then
		NotCheckedAttributeArray.Add("Shift");
	EndIf;
	
	If Not DivisionParameters.UseAreas Then
		NotCheckedAttributeArray.Add("ProductionArea");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DataBeforeChange = DocumentDataBeforeModification();
	
	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	AdditionalProperties.Insert("DataBeforeChange", DataBeforeChange);
	
	// Control: you can cancel the event only in the status being formed
	If WriteMode = DocumentWriteMode.UndoPosting
		And Status <> Enums.ShiftTaskStatuses.BeingGenerated Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Để thực hiện một hành động, chứng từ phải có trạng thái ""Được tạo thành.""';
				|ru = 'Для выполнения действия документ должен иметь статус ""Формируется"".';
				|en = 'To perform the action, the document must be in the ""Generating"" status.'; fa = 'To perform the action, the document must be in the ""Generating"" status.';
				|it = 'Per l''esecuzione dell''azione il documento deve avere lo stato ""Generazione in corso"".';
				|pl = 'Dla wykonania czynności dokument powinien mieć status ""Tworzony""';
				|tr = 'Eylemin gerçekleştirilmesi için belgenin ""Oluşturuluyor"" durumunda olması gerekmektedir.'"),
			ThisObject,,,
			Cancel);
		
	EndIf;
	
	// Control: according to the shift-day-site combination, there should be only one document
	If WriteMode = DocumentWriteMode.Posting Then
		
		Query = New Query(
			"SELECT TOP 1
			|	TRUE AS Field1
			|FROM
			|	Document.ShiftTask AS ShiftTask
			|WHERE
			|	ShiftTask.Ref <> &Ref
			|	AND ShiftTask.Department = &Department
			|	AND ShiftTask.Shift = &Shift
			|	AND ShiftTask.ProductionArea = &ProductionArea
			|	AND BEGINOFPERIOD(ShiftTask.Date, DAY) = &Date
			|	AND ShiftTask.Posted");
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Department", Department);
		Query.SetParameter("Shift", Shift);
		Query.SetParameter("ProductionArea", ProductionArea);
		Query.SetParameter("Date", BegOfDay(Date));
		
		If Not Query.Execute().IsEmpty() Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Hệ thống đã có một nhiệm vụ thay đổi cho ngày được chỉ định.';
					|ru = 'В системе уже имеется сменное задание за указанную дату.';
					|en = 'Shift task for the specified date already exists in the system.'; fa = 'Shift task for the specified date already exists in the system.';
					|it = 'Nel sistema esiste già task del turno per la data indicata.';
					|pl = 'W systemie już istnieje zadanie zmianowe na podaną datę.';
					|tr = 'Sistemde belirtilen tarih için zaten vardiya görev mevcut.'"),
				ThisObject,,,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// Control: the department can be changed if there are no assigned operations
	If DataBeforeChange.Department <> Department Then
		
		Query = New Query(
			"SELECT TOP 1
			|	TRUE AS Field1
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS Register
			|WHERE
			|	Register.ShiftTask = &ShiftTask
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	Document.ProductionOperation2_2 AS Document
			|WHERE
			|	Document.ShiftTask = &ShiftTask");
		Query.SetParameter("ShiftTask", Ref);
		
		If Not Query.Execute().IsEmpty() Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Có các hoạt động được giao cho công việc thay đổi. Thay đổi đơn vị bị cấm.';
					|ru = 'Имеются операции, назначенные сменному заданию. Изменять подразделение запрещено.';
					|en = 'There are operations assigned to the shift task. You cannot change the business unit.'; fa = 'There are operations assigned to the shift task. You cannot change the business unit.';
					|it = 'Esistono operazioni associate al task del turno. Non è consentito modificare il reparto.';
					|pl = 'Istnieją operacje, wyznaczone dla zadania zmiany. Modyfikowanie działu jest zabronione.';
					|tr = 'Vardiyalı göreve atanan işlemler mevcuttur. Departmanın değiştirilmesine izin verilmemektedir.'"),
				ThisObject,,,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// Control: the status of production operations (a document in the status is being formed)
	If Status = Enums.ShiftTaskStatuses.BeingGenerated And Not IsNew() Then
		
		Query = New Query(
			"SELECT TOP 1
			|	TRUE AS Field1
			|FROM
			|	Document.ProductionOperation2_2 AS ProductionOperation2_2
			|WHERE
			|	ProductionOperation2_2.ShiftTask = &ShiftTask
			|	AND ProductionOperation2_2.Status <> &Status
			|	AND ProductionOperation2_2.Posted");
		
		Query.SetParameter("ShiftTask", Ref);
		Query.SetParameter("Status", Enums.ProductionOperationStatuses.CreatedOn_);
		
		If Not Query.Execute().IsEmpty() Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Có các hoạt động sản xuất trong một trạng thái khác ngoài ""Đã tạo"".';
					|ru = 'Имеются производственные операции в статусе отличном от ""Создана"".';
					|en = 'There are routing operations in the status other than Created.'; fa = 'There are routing operations in the status other than Created.';
					|it = 'Esistono operazioni di produzione nello stato diverso da ""Creato"".';
					|pl = 'Istnieją operacje produkcyjne ze statusem różniącym się od ""Utworzona"".';
					|tr = '""Oluşturuldu"" durumundan farklı rota işlemleri mevcuttur.'"),
				ThisObject,,,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// Control: status of production operations (document in the Closed status)
	If Status = Enums.ShiftTaskStatuses.Closed And Not IsNew() Then
		
		Query = New Query(
			"SELECT TOP 1
			|	TRUE AS ErrorStatus_1,
			|	FALSE AS ErrorConducting
			|FROM
			|	Document.ProductionOperation2_2 AS ProductionOperation2_2
			|WHERE
			|	ProductionOperation2_2.ShiftTask = &ShiftTask
			|	AND NOT ProductionOperation2_2.Status IN (&Statuses)
			|	AND ProductionOperation2_2.Posted
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	FALSE,
			|	TRUE
			|FROM
			|	Document.ProductionOperation2_2 AS ProductionOperation2_2
			|WHERE
			|	ProductionOperation2_2.ShiftTask = &ShiftTask
			|	AND NOT ProductionOperation2_2.Posted
			|	AND NOT ProductionOperation2_2.DeletionMark");
		
		Query.SetParameter("ShiftTask", Ref);
			
		Statuses = New Array;
		Statuses.Add(Enums.ProductionOperationStatuses.Executed);
		Statuses.Add(Enums.ProductionOperationStatuses.NotExecuted);
		Statuses.Add(Enums.ProductionOperationStatuses.IsSkipped);
		Query.SetParameter("Statuses", Statuses);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			If Selection.ErrorStatus_1 Then
				MessageText = NStr("vi = 'Có các hoạt động sản xuất trong một trạng thái khác ngoài ""Đã hoàn thành"", ""Chưa hoàn thành"" và ""Mất tích"".';
									|ru = 'Имеются производственные операции в статусе отличном от ""Выполнена"", ""Не выполнена"" и ""Пропущена"".';
									|en = 'There are routing operations in the status other than ""Performed"", ""Not performed"", and ""Skipped"".'; fa = 'There are routing operations in the status other than ""Performed"", ""Not performed"", and ""Skipped"".';
									|it = 'Esistono operazioni di produzione nello stato diverso da ""Eseguito"", ""Non eseguito"" e ""Omesso"".';
									|pl = 'Istnieją operacje produkcyjne o statusie innym niż ""Zakończone"", ""Niezakończone"" i ""Pominięte"".';
									|tr = '""Gerçekleştirildi"", ""Gerçekleştirilmedi"" ve ""Atlandı"" durumlarından farklı rota işlemleri mevcuttur.'");
			Else
				MessageText = NStr("vi = 'Có hoạt động sản xuất ngoài kế hoạch.';
									|ru = 'Имеются непроведенные производственные операции.';
									|en = 'There are unposted routing operations.'; fa = 'There are unposted routing operations.';
									|it = 'Esistono operazioni di produzione non registrate.';
									|pl = 'Istnieją niezaksięgowane operacje produkcyjne.';
									|tr = 'Doğrulanmamış rota işlemleri mevcuttur.'");
			EndIf;
			
			CommonClientServer.MessageToUser(MessageText, ThisObject,,, Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Updating related data
	If AdditionalProperties.WriteMode = DocumentWriteMode.Posting
		And Not AdditionalProperties.IsNew
		And AdditionalProperties.DataBeforeChange.Date <> Date Then
		
		Query = New Query(
			"SELECT DISTINCT
			|	Register.Stage AS Stage
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS Register
			|WHERE
			|	Register.ShiftTask = &ShiftTask
			|
			|UNION
			|
			|SELECT DISTINCT
			|	Document.Stage
			|FROM
			|	Document.ProductionOperation2_2 AS Document
			|WHERE
			|	Document.ShiftTask = &ShiftTask
			|	AND Document.Posted
			|	AND Document.Status <> VALUE(Enum.ProductionOperationStatuses.NotExecuted)");
		Query.SetParameter("ShiftTask", Ref);
		
		InformationRegisters.OperationsToCreateShiftTasks.CalculateOperations(
			Query.Execute().Unload().UnloadColumn("Stage"), Ref);
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InformationRegisters.OperationsToCreateShiftTasks.DeleteJobOperations(Ref);
	
EndProcedure

#EndRegion

#Region Private

Function DocumentDataBeforeModification()
	
	AttributeSet = "Date,Department,Shift";
	
	If Not IsNew() Then
		DataBeforeChange = Common.ObjectAttributesValues(Ref, AttributeSet);
	Else
		DataBeforeChange = New Structure(AttributeSet);
		FillPropertyValues(DataBeforeChange, ThisObject);
	EndIf;
	
	Return DataBeforeChange;
	
EndFunction

#EndRegion

#EndIf
