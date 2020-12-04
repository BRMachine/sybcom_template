class AcknowledgeTable
{
  private string m_tableShapeName;
  private int m_columnMode; // 0 = Ack. (Column: DPE), 1 = Ack. (Column: DPE, Time, Index, Acknowledgeable)
  private string m_dpeColumnName;
  private string m_timeColumnName;
  private string m_indexColumnName;
  private string m_confirmableColumnName;
  private int m_startRowToAck;
  private int m_endRowToAck;
  private int m_forcedMode;
  private mapping m_tableMultipleRowsMapping;

  private shape m_tableShape;
  private dyn_string m_columnNames;
  private int m_ackColumnIndex;
  private bool m_stopScrolling;
  private int m_ackType;
  private bool m_oldMechanism;
  private int m_topRowVisible;
  private int m_bottomRowVisible;
  private int m_fromRow;
  private int m_toRow;
  private dyn_string m_rowKeys;

  private string m_dpe;
  private anytype m_ackable;
  private int m_subRowNumber;
  private anytype m_alarmCount;
  private time m_alarmTime;
  private dyn_string m_alertClassDPs;
  private dyn_anytype m_alertClasses;
  private dyn_atime m_dpesToAck;
  private dyn_bool m_confirms;

  public AcknowledgeTable(
      string tableShapeName,
      int columnMode,
      string dpeColumnName,
      string timeColumnName = "",
      string indexColumnName = "",
      string confirmableColumnName = "",
      int startRowToAck = 0,
      int endRowToAck = -1,
      int forcedMode = 0,
      mapping tableMultipleRowsMapping = mEmptyMapping)
  {
    // set paramter to fields
    m_tableShapeName = tableShapeName;
    m_columnMode = columnMode;
    m_dpeColumnName = dpeColumnName;
    m_timeColumnName = timeColumnName;
    m_indexColumnName = indexColumnName;
    m_confirmableColumnName = confirmableColumnName;
    m_startRowToAck = startRowToAck;
    m_endRowToAck = endRowToAck;
    m_forcedMode = forcedMode;
    m_tableMultipleRowsMapping = tableMultipleRowsMapping;
  }

  public void execute()
  {
    if (handledByHooks())
      return;

    if (! initializeAndVerify())
      return;

    determineRowRangeAndAckType();
    collectAlarms();

    if (verifyPermission())
      acknowledgeAlarms();
  }

  private bool handledByHooks()
  {
    if (m_oldMechanism && isFunctionDefined("HOOK_ep_acknowledgeTableFunction") )
    {
      HOOK_ep_acknowledgeTableFunction(m_tableShapeName, m_columnMode, m_dpeColumnName, m_timeColumnName, m_indexColumnName, m_confirmableColumnName, m_startRowToAck, m_endRowToAck);
      return true;
    }
    else if (!m_oldMechanism && isFunctionDefined("HOOK_aes_acknowledgeTableFunction"))
    {
      bool shouldContinue;
      shouldContinue = HOOK_aes_acknowledgeTableFunction(m_tableShapeName, m_columnMode, m_tableMultipleRowsMapping);

      if (! shouldContinue)
        return true;
    }

    return false;
  }

  private bool initializeAndVerify()
  {
    m_tableShape = getShape(m_tableShapeName);
    int columnCount = m_tableShape.columnCount();

    m_columnNames = makeDynString();
    m_ackType = DPATTR_ACKTYPE_SINGLE;
    m_oldMechanism = false;

    if (mappinglen(m_tableMultipleRowsMapping) == 0)
      m_oldMechanism = true;

    for (int i = 0; i < columnCount; i++)
      dynAppend(m_columnNames, m_tableShape.columnToName(i));

    // new feature 'user depending alarm display' IM #117931
    m_ackColumnIndex = dynContains(m_columnNames, "ack"); // for StdLib Objects this column contains '< >'

    if (m_ackColumnIndex <= 0)
      m_ackColumnIndex = dynContains(m_columnNames, "acknowledge"); // for other than StdLib objects

    if (m_oldMechanism)
      return true;

    bool parameterError = false;

    if (dynContains(m_columnNames, m_dpeColumnName) <= 0)
      parameterError = true;

    if ( m_columnMode == 1 &&
         (dynContains(m_columnNames, m_timeColumnName) <= 0 ||
          dynContains(m_columnNames, m_indexColumnName) <= 0 ||
          dynContains(m_columnNames, m_confirmableColumnName) <= 0) )
    {
      parameterError = true;
    }

    if (m_columnMode != 0 && m_columnMode != 1)
      parameterError = true;

    if (parameterError)
    {
      if (m_tableShapeName != "table_bot" && m_tableShapeName != "table_top") // no warning in AES
      {
        throwError(makeError(0, 1, ERR_PARAM, 54, "", myUiNumber(), getUserId(), "Problem quitting table - Object: " + m_tableShapeName + ", Panel: " + myPanelName() + " - wrong column name!"));
        return false;
      }
    }

    m_stopScrolling = m_tableShape.stop();
    return true;
  }

  // determine start/end row and m_ackType and m_rowKeys for "multiple Row mode"
  private void determineRowRangeAndAckType()
  {
    if (m_oldMechanism)
    {
      getValue(m_tableShape, "lineRangeVisible", m_topRowVisible, m_bottomRowVisible);

      if (! m_stopScrolling)
        m_tableShape.stop(true);

      if (m_endRowToAck == -1) // no line given -> multiple
      {
        getValue(m_tableShape, "lineRangeVisible", m_startRowToAck, m_endRowToAck);
        m_ackType = DPATTR_ACKTYPE_MULTIPLE;
      }

      if (m_endRowToAck > m_startRowToAck) // more than one line -> multiple
        m_ackType = DPATTR_ACKTYPE_MULTIPLE;

      // TFS 29657
      if (m_columnMode == 1 && m_startRowToAck != m_endRowToAck)
      {
        if (m_endRowToAck < m_startRowToAck)
          m_tableShape.sortPart(m_endRowToAck, m_startRowToAck, m_timeColumnName, m_indexColumnName);
        else
          m_tableShape.sortPart(m_startRowToAck, m_endRowToAck, m_timeColumnName, m_indexColumnName);
      }

      m_fromRow = m_startRowToAck;
      m_toRow = m_endRowToAck;
    }
    else
    {
      // check mapping length for acktype - assume that on row of data means single ACK
      int length = mappinglen(m_tableMultipleRowsMapping);

      if (length > 1)
        m_ackType = DPATTR_ACKTYPE_MULTIPLE;

      m_rowKeys = mappingKeys(m_tableMultipleRowsMapping);
      dynSortAsc(m_rowKeys);  // must go through in row order, mapping isnot ordered

      m_fromRow = 1;
      m_toRow = length;
    }

    if (m_forcedMode != 0)
      m_ackType = m_forcedMode;
  }

  private void collectAlarms()
  {
    string dpeAck;

    if (m_fromRow == -1 || m_toRow == -1)
      return;

    for (int row = m_fromRow; row <= m_toRow; row++)
    {
      mapping rowContent;

      if (m_oldMechanism)
      {
        m_dpe = m_tableShape.cellValueRC(row, m_dpeColumnName);

        // new feature 'user depending alarm display' IM #117931
        if (m_ackColumnIndex)
        {
          if (UDA_noAck_Token == m_tableShape.cellValueRC(row, m_columnNames[m_ackColumnIndex]))
            continue; // do not acknowledge this row
        }
      }
      else
      {
        m_subRowNumber = m_rowKeys[row];
        m_dpe = m_tableMultipleRowsMapping[m_subRowNumber][_DPID_];
        rowContent = m_tableMultipleRowsMapping[m_subRowNumber];

        // new feature 'userdepending alarm display' IM #117931
        // check if mapping has the key "acknowledge"
        if (mappingHasKey(rowContent,"acknowledge"))
        {
          if (UDA_noAck_Token == m_tableMultipleRowsMapping[m_subRowNumber]["acknowledge"]) // TODO: also check for "ack"?
            continue; // do not acknowledge this row
        }
      }

      if (m_columnMode == 1)
      {
        if (m_oldMechanism)
          m_ackable = m_tableShape.cellValueRC(row, m_confirmableColumnName);
        else
          m_ackable = m_tableMultipleRowsMapping[m_subRowNumber][_ACKABLE_];

        if (m_ackable < 1)
          continue;

        if (m_oldMechanism)
        {
          m_alarmTime = m_tableShape.cellValueRC(row, m_timeColumnName);
          m_alarmCount = m_tableShape.cellValueRC(row, m_indexColumnName);
        }
        else
        {
          m_alarmTime = m_tableMultipleRowsMapping[m_subRowNumber][_TIME_];
          m_alarmCount = m_tableMultipleRowsMapping[m_subRowNumber][_COUNT_];
        }

        // do some magic ...
        dpeAck = dpSubStr(m_dpe, DPSUB_CONF_DET);

        if (dpeAck == dpSubStr(m_dpe, DPSUB_CONF))
          dpeAck = dpeAck + ".";

        dpeAck += "._ack_state";

        // read the referenced _alert_class from the mapping
        if (mappingHasKey(rowContent, "__alertClass"))
        {
          string alertClass = m_tableMultipleRowsMapping[m_subRowNumber]["__alertClass"];
          dynAppend(m_alertClasses, alertClass);
        }
        else // mapping is not available
        {
          dynAppend(m_alertClassDPs, getAlarmClassNames(m_dpe, ":_alert_hdl.?._class"));
        }

        m_dpe = dpSubStr(m_dpe, DPSUB_SYS_DP_EL);
      }
      else if (m_columnMode == 0)
      {
        m_ackable = true;
        dpeAck = ":_alert_hdl.._ack";

        dynAppend(m_alertClassDPs, getAlarmClassNames(m_dpe, ":_alert_hdl.?._class"));

        m_alarmTime = 0;
        m_alarmCount = 0;
      }

      if (m_ackable)
      {
        atime alarmTime = makeATime(m_alarmTime, m_alarmCount, m_dpe + dpeAck);

        dynAppend(m_dpesToAck, alarmTime);
        dynAppend(m_confirms, true);
      }
    }
  }

  private dyn_string getAlarmClassNames(string dpe, string config)
  {
    dyn_string result;
    int ranges;
    dpGet(dpe + "._num_ranges", ranges);

    for (int i = 1; i <= ranges; i++)
    {
      string config_i = config;
      strreplace(config_i, ".?.", "." + i + ".");

      string alarmClassName_i;
      dpGet(dpe + config_i, alarmClassName_i);

      if (alarmClassName_i != "")
        dynAppend(result, dpe + config_i);
    }

    return result;
  }

  // IM 63416
  private bool verifyPermission()
  {
    if (dynlen(m_alertClassDPs) <= 0 && dynlen(m_alertClasses) <= 0)
      return true; // nothing in the table to acknowledge

    // mapping is not available - alert classes need to be read with a dpGet()
    if (dynlen(m_alertClassDPs) > 0)
    {
      dynSort(m_alertClassDPs);
      dynUnique(m_alertClassDPs);

      dpGetSystemSeparated(m_alertClassDPs, m_alertClasses); // get all alert classes
    }

    // create a unique list of _alert_class names
    dynSort(m_alertClasses);
    dynUnique(m_alertClasses);

    // get permissions needed IM 63416
    for (int i = 1; i <= dynlen (m_alertClasses); i++)
    {
      m_alertClasses[i] += ":_alert_class.._perm";
    }

    dyn_anytype permissions;

    if (isDistributed())
    {
      // in a distributed system the information needs to be read for every system in an own dpGet()
      dyn_string systemsNames;
      dyn_uint systemIDs;

      getSystemNames(systemsNames, systemIDs);

      for (int i = 1; i <= dynlen(systemsNames); i++)
      {
        dyn_string alertClassesSystem_i = dynPatternMatch(systemsNames[i] + ":*", (dyn_string)m_alertClasses);
        dyn_anytype permissionsSystem_i;

        if (dynlen(alertClassesSystem_i) > 0)
        {
          dpGetSystemSeparated(alertClassesSystem_i, permissionsSystem_i);
          dynAppend(permissions, permissionsSystem_i);
        }
      }
    }
    else
    {
      dpGetSystemSeparated(m_alertClasses, permissions);
    }

    if (dynlen(permissions) > 0)
    {
      dyn_int permissionsAsDynInt = permissions;
      dynSortAsc(permissionsAsDynInt);

      int level = permissionsAsDynInt[dynlen(permissionsAsDynInt)];

      if (! getUserPermission(level))
      {
        ChildPanelOnCentralModal(
            "vision/MessageWarning",
            getCatStr("sc", "attention"),
            makeDynString("$1:" + getCatStr("sc","no_ack_perm_1") + getUserName() + getCatStr("sc","no_ack_perm_2") + "\n" + getCatStr("sc","no_ack_perm_3")));

        return false;
      }
    }

    return true;
  }

  private void acknowledgeAlarms()
  {
    dyn_atime dpesToAckCopy = m_dpesToAck; // copy because of deletion in isAckable()
    int ackable;
    isAckable(m_columnMode, dpesToAckCopy, ackable);

    if (ackable)
    {
      dynSort(m_dpesToAck, true);

      for (int i = dynlen(m_dpesToAck); i > 0; i--) // check and remove quittpermission of all dpes not in dsDpeAuEToQuitt
      {
        if (dynContains(dpesToAckCopy, m_dpesToAck[i]) < 1 ) // not in list -> remove because it is already acknowledged
        {
          m_confirms[i] = false;
        }
        else if (m_ackType == DPATTR_ACKTYPE_MULTIPLE)
        {
          // read the information if an alert must be single acknowledged with an alertGet
          bool singleAckRequired;

          alertGet((time)m_dpesToAck[i], getACount(m_dpesToAck[i]), getAIdentifier(m_dpesToAck[i]), singleAckRequired);

          if (singleAckRequired)
          {
            m_confirms[i] = false;

            // if there is at least one alert which needs to be single acknowledged open a message dialog for the user
            dyn_float returnedFloats;
            dyn_string returnedStrings;

            ChildPanelOnCentralModalReturn(
                "vision/MessageWarning2",
                getCatStr("sc", "Attention"),
                makeDynString(getCatStr("aes", "warning_singleAck"),
                              getCatStr("general", "yes"),
                              getCatStr("sc", "no")),
                returnedFloats, returnedStrings);

            if (returnedFloats[1] == 0)
            {
              // do not acknowledge alerts
              return;
            }
          }
        }
      }

      int tableAckable;
      isTableAckable(m_columnMode, m_dpesToAck, m_confirms, tableAckable);

      if ((m_columnMode == 1 || m_columnMode == 0) && tableAckable)
      {
        for (int i = 1; i <= dynlen(m_dpesToAck); i++)
        {
          if (m_confirms[i])
          {
            dyn_errClass errors;

            // acknowledge the alarm
            alertSet((time)m_dpesToAck[i], getACount(m_dpesToAck[i]), getAIdentifier(m_dpesToAck[i]), m_ackType);
            errors = getLastError();

            if (dynlen(errors) > 0)
              throwError(errors);
          }
        }
      }
    }

    if (m_oldMechanism)
    {
      if ( m_startRowToAck != m_endRowToAck)
        m_tableShape.sortUndo(0); // reset sorting

      if (! m_stopScrolling)
        m_tableShape.stop(false);

      if (m_topRowVisible >= 0)
        m_tableShape.lineVisible(m_topRowVisible); // lastest topline
    }
  }

  private void dpGetSystemSeparated(dyn_string dps, dyn_anytype &values)
  {
    dyn_anytype values_i;

    for (int i = 1; i <= dynlen(dps); i++)
    {
      dynClear(values_i);
      dpGet(dps[i], values_i);
      dynAppend(values, values_i);
    }
  }
};
