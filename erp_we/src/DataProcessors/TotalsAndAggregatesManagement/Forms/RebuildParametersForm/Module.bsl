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
	
	RelativeSize = Parameters.RelativeSize;
	MinimumEffect = Parameters.MinimumEffect;
	Items.MinimumEffect.Visible = Parameters.RebuildMode;
	Title = ?(Parameters.RebuildMode,
	              NStr("vi = 'Tham số xây dựng lại';
						|ru = 'Параметры перестроения';
						|en = 'Rebuild parameters'; fa = 'پارامترهای بازسازی';
						|it = 'Parametri reimpostazione';
						|pl = 'Parametry przebudowy';
						|tr = 'Yeniden oluşturma seçenekleri'"),
	              NStr("vi = 'Tham số tính toán phần tổng kết tối ưu';
						|ru = 'Параметр расчета оптимальных агрегатов';
						|en = 'Parameter of optimal aggregate calculation'; fa = 'Parameter of optimal aggregate calculation';
						|it = 'Parametro di calcolo di aggregati ottimali';
						|pl = 'Parametr rozliczenia optymalnych agregatów';
						|tr = 'En uygun toplamları hesaplamak için parametre'"));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure("RelativeSize, MinimumEffect");
	FillPropertyValues(SelectionResult, ThisObject);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
