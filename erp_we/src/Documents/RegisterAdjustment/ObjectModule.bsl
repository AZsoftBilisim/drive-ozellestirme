#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	Operation = Enums.RegisterAdjustmentOperations.ManualAdjustment;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Operation <> Enums.RegisterAdjustmentOperations.ManualAdjustment And Not Users.RolesAvailable("FullAccess") Then
		ErrorText = NStr("vi = 'Người sử dụng hiện tại không được phép thay đổi điều chỉnh các biểu ghi đã tạo tự động.';
						|ru = 'Текущему пользователю запрещено изменять корректировки регистров, сформированные автоматически.';
						|en = 'The current user is not allowed to change register adjustments generated automatically.'; fa = 'The current user is not allowed to change register adjustments generated automatically.';
						|it = 'All''utente corrente non è permesso modificare le rettifiche dei registri formate automaticamente.';
						|pl = 'Bieżącemu użytkownikowi zabroniona jest zmiana korekt rejestrów, sporządzonych automatycznie.';
						|tr = 'Mevcut kullanıcının, otomatik olarak oluşturulan kayıt düzeltmelerini değiştirmesine izin verilmiyor.'");
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,,,
			Cancel);
	EndIf;
	
	If Not IsNew() And Common.ObjectAttributeValue(Ref, "DeletionMark") <> DeletionMark Then
		// The tagging feature of the document has changed, it is necessary to synchronize the Activity property of its movements.
		SetMotionActivity(Not DeletionMark);
	ElsIf DeletionMark Then
		// A document marked for deletion should not have movements with the property Activity = True.
		SetMotionActivity(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetMotionActivity(ActivityFlag)
	
	// When writing from the document form, its movements have already been read.
	YouMustReadRegisteredRecords = Not AdditionalProperties.Property("WritingDocumentFromForm");
	
	For Each Movement In RegisterRecords Do
		
		If YouMustReadRegisteredRecords Then
			Movement.Read();
		EndIf;
		
		Movement.SetActive(ActivityFlag);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
#EndIf
