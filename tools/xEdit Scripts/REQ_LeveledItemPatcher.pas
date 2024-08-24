unit LeveledItemPatcher;

uses REQ_Util;

var
  leveled_items: TStringList;
  re_ignore, re_leveled_equipment, re_leveled_equipset, re_leveled_potion: TPerlRegEx;


function Initialize: Integer;
begin
  leveled_items := TStringList.Create;
  leveled_items.LoadFromFile('Edit Scripts\REQ_LeveledItemPatcher.txt');

  re_ignore := TPerlRegEx.Create;
  re_ignore.RegEx := '^[^_]+_(?:DEPRECATED|LEGACY|NULL)_.+$';

  re_leveled_equipment := TPerlRegEx.Create;
  re_leveled_equipment.RegEx := '^[^_]+_LI_([^_]+_(?:Heavy|Light|Weapon)_\D+)\d*$';

  re_leveled_equipset := TPerlRegEx.Create;
  re_leveled_equipset.RegEx := '^[^_]+_LI_(EquipSet_[^_]+_\d{2}_.+)$';

  re_leveled_potion := TPerlRegEx.Create;
  re_leveled_potion.RegEx := '^[^_]+_LI_(VendorApothecary_\D+)\d*$';
end;

function Process(e: IInterface): integer;
var
  key: String;
begin
  if Signature(e) <> 'LVLI' then Exit;
  re_ignore.Subject := EditorID(e);
  if re_ignore.Match then Exit;

  re_leveled_equipment.Subject := EditorID(e);
  re_leveled_equipset.Subject := EditorID(e);
  re_leveled_potion.Subject := EditorID(e);
  if re_leveled_equipment.Match then
    key := re_leveled_equipment.Groups[1]
  else if re_leveled_equipset.Match then
    key := re_leveled_equipset.Groups[1]
  else if re_leveled_potion.Match then
    key := re_leveled_potion.Groups[1]
  else begin
    AddMessage('EditorID ' + EditorID(e) + ' is invalid');
    Exit;
  end;

  if leveled_items.IndexOfName(key) = -1 then begin
    AddMessage('EditorID ' + EditorID(e) + ' is not recognized');
    Exit;
  end;
  SetItems(e, key);
end;

function Finalize: Integer;
begin
  leveled_items.Free;
  re_ignore.Free;
  re_leveled_equipment.Free;
end;

procedure SetItems(e: IInterface; leveled_item: String);
var
  entries, entry: IInterface;
  i: Integer;
  items: TStringList;
begin
  items := TStringList.Create;
  items.StrictDelimiter := True;
  items.DelimitedText := leveled_items.Values[leveled_item];
  for i := 0 to Pred(items.Count div 3) do
    items[3 * i + 1] := IntToHex(PairToLoadOrderFormID(items[3 * i + 1]), 8);

  entries := ElementByPath(e, 'Leveled List Entries');
  if SerializeItems(entries) <> items.DelimitedText then begin
    RemoveElement(e, entries);
    entries := Add(e, 'Leveled List Entries', True);
    RemoveElement(entries, 0);
    for i := 0 to Pred(items.Count div 3) do begin
      entry := ElementAssign(entries, HighInteger, nil, False);
      SetElementEditValues(entry, 'LVLO - Base Data\Level', items[3 * i]);
      SetElementEditValues(entry, 'LVLO - Base Data\Reference', items[3 * i + 1]);
      SetElementEditValues(entry, 'LVLO - Base Data\Count', items[3 * i + 2]);
    end;
  end;
  items.Free;
end;

function SerializeItems(items: IInterface): String;
var
  entry: IInterface;
  i, nativeFormID: Integer;
begin
  for i := 0 to Pred(ElementCount(items)) do begin
    entry := ElementByIndex(items, i);
    Result := Result + ',' + GetElementEditValues(entry, 'LVLO - Base Data\Level');
    Result := Result + ',' + IntToHex(FileFormIDtoLoadOrderFormID(GetFile(items), GetElementNativeValues(entry, 'LVLO - Base Data\Reference')), 8);
    Result := Result + ',' + GetElementEditValues(entry, 'LVLO - Base Data\Count');
    if ElementExists(entry, 'COED - Extra Data') then
      Result := 'COED';
  end;
  Result := Delete(Result, 1, 1);
end;

end.
