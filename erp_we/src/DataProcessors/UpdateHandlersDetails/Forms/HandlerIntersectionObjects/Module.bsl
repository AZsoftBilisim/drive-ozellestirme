///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.DataAddress) Then
		If Parameters.AreLowPriorityHandlers Then
			Data = GetFromTempStorage(Parameters.DataAddress);
			LowPriorityHandlers.Load(Data);
			Items.TablesPages.CurrentPage = Items.PageLowPriorityHandlers;
			Title = NStr("vi = 'Hàm sự kiện có mức độ ưu tiên thấp';
						|ru = 'Обработчики с низким приоритетом';
						|en = 'Handlers with low priority'; fa = 'رویدادگردان‌های با اولویت پایین';
						|it = 'Обработчики с низким приоритетом';
						|pl = 'Handlers with low priority';
						|tr = 'Düşük öncelikli işleyici'");
		Else
			Data = GetFromTempStorage(Parameters.DataAddress);
			Intersections.Load(Data);
			Items.TablesPages.CurrentPage = Items.IntersectionsPage;
			Title = NStr("vi = 'Đối tượng giao nhau hàm sự kiện';
						|ru = 'Объекты пересечения обработчика';
						|en = 'Handler intersection objects'; fa = 'اشیای تقاطع رویدادگردان';
						|it = 'Oggetti di intersezione di elaboratore';
						|pl = 'Obiekty przecięcia programu przetwarzania';
						|tr = 'İşleyici kesişim nesneleri'");
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion