#!/bin/bash
ORCADIR=/usr/local/orca
ORCABT="$ORCADIR"/lib
DBSTUB=/usr/local/panda/bin/dbstub
RENNUM=0
-------------------------------------------#
#    ����ɽ�ѥե��������
#        $1-${11} �����ģ��Ѹ������
#        ${12} SRYYM TERID SYSYMD
#        ${13} RECEKBN(����ɽ�μ���)
#           0:����  1:���ݡ�2:����
#        ${14} ���ŵ��أɣ� 
#        ${15} ���ݿ���������������ʬ
#        ${16} ����֣ɣ�
#        ${17} ������ɣ�
#        ${18} ���顼�ե�����̾ 
#        ${19} ����ǯ��
#-------------------------------------------#
#
##      ���顼�ե�������
	echo $#
	echo "echo " ${18}
        if  [ -e ${18} ]; then
            rm  ${18}
        fi 
        
        cd  $ORCABT

##      ����ɽ�ʼ��ݡ�
        if  [ ${13} -ne 2 ]; then
           RENNUM=$(expr $RENNUM + 1) 
           $DBSTUB  -record "$ORCADIR"/record/ -dir "$ORCADIR"/lddef/directory -bddir "$ORCADIR"/lddef -db orca  -bd orcabt ORCBM001 -parameter $1,$2,$3,$RENNUM,$5,$6,$7,$8,$9,${10},${11},${12},${14},${16},${17}
           if  [ -e ${18} ]; then
               exit
           fi
           
           if  [ $5 -ge '200210' ]; then
               RENNUM=$(expr $RENNUM + 1) 
               $DBSTUB  -record "$ORCADIR"/record/ -dir "$ORCADIR"/lddef/directory -bddir "$ORCADIR"/lddef -db orca  -bd orcabt ORCBM022 -parameter $1,$2,$3,$RENNUM,$5,$6,$7,$8,$9,${10},${11},${14},${16},${17}
               if  [ -e ${18} ]; then
                   exit
               fi
           fi    
        fi 
##      ����ɽ�ʹ��ݡ�
        if  [ ${13} -ne 1 ]; then
            RENNUM=$(expr $RENNUM + 1) 
            if  [ ${15} = 1 ]; then
                 $DBSTUB -record "$ORCADIR"/record/ -dir "$ORCADIR"/lddef/directory -bddir "$ORCADIR"/lddef -db orca  -bd orcabt ORCBM012 -parameter $1,$2,$3,$RENNUM,$5,$6,$7,$8,$9,${10},${11},${12},${14},${16},${17}
            else
                 $DBSTUB -record "$ORCADIR"/record/ -dir "$ORCADIR"/lddef/directory -bddir "$ORCADIR"/lddef -db orca  -bd orcabt ORCBM004 -parameter $1,$2,$3,$RENNUM,$5,$6,$7,$8,$9,${10},${11},${12},${14},${16},${17}
            fi	
            if  [ -e ${18} ]; then
                exit
            fi
            
            if  [ $5 -ge '200210' ]; then
               RENNUM=$(expr $RENNUM + 1) 
               $DBSTUB  -record "$ORCADIR"/record/ -dir "$ORCADIR"/lddef/directory -bddir "$ORCADIR"/lddef -db orca  -bd orcabt ORCBM025 -parameter $1,$2,$3,$RENNUM,$5,$6,$7,$8,$9,${10},${11},${14},${16},${17}
               if  [ -e ${18} ]; then
                   exit
               fi
           fi    
       fi
       $DBSTUB -record "$ORCADIR"/record/ -dir "$ORCADIR"/lddef/directory -bddir "$ORCADIR"/lddef -db orca  -bd orcabt ORCBJOB -parameter JBE${16}${17}

        exit 
