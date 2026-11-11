// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If Count() = 0 Then
		Return;
	EndIf;
	
	ChangeDate = CurrentSessionDate();
	EmployeeResponsible = Users.CurrentUser();
	
	If DataExchange.Load Then
		
		For Each CurrRow In ThisObject Do

			CurrRow.LockUntil = BegOfMonth(CurrRow.LockUntil);
			
			If Not ValueIsFilled(CurrRow.ChangeDate) Then
				CurrRow.ChangeDate = ChangeDate;
			EndIf;
			If Not ValueIsFilled(CurrRow.EmployeeResponsible) Then
				CurrRow.EmployeeResponsible = EmployeeResponsible;
			EndIf;
			If IsBlankString(CurrRow.Comment) Then
				CurrRow.Comment = NStr("vi = 'Đã thiết lập khi trao đổi dữ liệu';
										|ru = 'Установлено при обмене данным';
										|en = 'Set upon data exchange'; fa = 'Set upon data exchange';
										|it = 'Установлено при обмене данным';
										|pl = 'Set upon data exchange';
										|tr = 'Veri değişimi sırasında ayarlandı'")
			EndIf;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	For Each CurrRow In ThisObject Do
		
		CurrRow.LockUntil = BegOfMonth(CurrRow.LockUntil);
		CurrRow.ChangeDate = ChangeDate;
		CurrRow.EmployeeResponsible = EmployeeResponsible;
		
		If IsBlankString(CurrRow.Comment) Then
			CurrRow.Comment = NStr("vi = 'Chưa chỉ ra phương thức thiết lập phong tỏa';
									|ru = 'Способ установки блокировки не указан';
									|en = 'A method to set the lock is not specified'; fa = 'A method to set the lock is not specified';
									|it = 'Способ установки блокировки не указан';
									|pl = 'A method to set the lock is not specified';
									|tr = 'Kilitlemenin ayarlama yöntemi belirtilmedi'")
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
