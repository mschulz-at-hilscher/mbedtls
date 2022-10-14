#!/bin/sh

# tls13-kex-modes.sh
#
# Copyright The Mbed TLS Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

get_srv_psk_list ()
{
    case $(( TESTS % 3 )) in
        0) echo "psk_list=abc,dead,def,beef,Client_identity,6162636465666768696a6b6c6d6e6f70";;
        1) echo "psk_list=abc,dead,Client_identity,6162636465666768696a6b6c6d6e6f70,def,beef";;
        2) echo "psk_list=Client_identity,6162636465666768696a6b6c6d6e6f70,abc,dead,def,beef";;
    esac
}

requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_DEBUG_C
# SOME_ECDHE_ENABLED?
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: PSK: No valid ciphersuite. G->m" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-CIPHER-ALL:+AES-256-GCM:+AEAD:+SHA384:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched ciphersuite"

requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_DEBUG_C
# SOME_ECDHE_ENABLED?
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: PSK: No valid ciphersuite. O->m" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg -allow_no_dhe_kex -ciphersuites TLS_AES_256_GCM_SHA384\
                         -psk_identity Client_identity -psk 6162636465666768696a6b6c6d6e6f70" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched ciphersuite"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Multiple PSKs: valid ticket, reconnect with ticket" \
         "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70 tickets=8" \
         "$P_CLI force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 2" \
         -s "sent selected_identity: 0" \
         -s "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -S "key exchange mode: ephemeral$" \
         -S "ticket is not authentic"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Multiple PSKs: invalid ticket, reconnect with PSK" \
         "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70 tickets=8 dummy_ticket=1" \
         "$P_CLI force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 2" \
         -s "sent selected_identity: 1" \
         -s "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -S "key exchange mode: ephemeral$" \
         -s "ticket is not authentic"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Session resumption failure, ticket authentication failed." \
         "$P_SRV debug_level=4 crt_file=data_files/server5.crt key_file=data_files/server5.key force_version=tls13 tickets=8 dummy_ticket=1" \
         "$P_CLI debug_level=4 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 1" \
         -S "sent selected_identity:" \
         -s "key exchange mode: ephemeral" \
         -S "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -s "ticket is not authentic" \
         -S "ticket is expired" \
         -S "Invalid ticket start time" \
         -S "Ticket age exceeds limitation" \
         -S "Ticket age outside tolerance window"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Session resumption failure, ticket expired." \
         "$P_SRV debug_level=4 crt_file=data_files/server5.crt key_file=data_files/server5.key force_version=tls13 tickets=8 dummy_ticket=2" \
         "$P_CLI debug_level=4 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 1" \
         -S "sent selected_identity:" \
         -s "key exchange mode: ephemeral" \
         -S "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -S "ticket is not authentic" \
         -s "ticket is expired" \
         -S "Invalid ticket start time" \
         -S "Ticket age exceeds limitation" \
         -S "Ticket age outside tolerance window"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Session resumption failure, invalid start time." \
         "$P_SRV debug_level=4 crt_file=data_files/server5.crt key_file=data_files/server5.key force_version=tls13 tickets=8 dummy_ticket=3" \
         "$P_CLI debug_level=4 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 1" \
         -S "sent selected_identity:" \
         -s "key exchange mode: ephemeral" \
         -S "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -S "ticket is not authentic" \
         -S "ticket is expired" \
         -s "Invalid ticket start time" \
         -S "Ticket age exceeds limitation" \
         -S "Ticket age outside tolerance window"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Session resumption failure, ticket expired. too old" \
         "$P_SRV debug_level=4 crt_file=data_files/server5.crt key_file=data_files/server5.key force_version=tls13 tickets=8 dummy_ticket=4" \
         "$P_CLI debug_level=4 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 1" \
         -S "sent selected_identity:" \
         -s "key exchange mode: ephemeral" \
         -S "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -S "ticket is not authentic" \
         -S "ticket is expired" \
         -S "Invalid ticket start time" \
         -s "Ticket age exceeds limitation" \
         -S "Ticket age outside tolerance window"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Session resumption failure, age outside tolerance window, too young." \
         "$P_SRV debug_level=4 crt_file=data_files/server5.crt key_file=data_files/server5.key force_version=tls13 tickets=8 dummy_ticket=5" \
         "$P_CLI debug_level=4 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 1" \
         -S "sent selected_identity:" \
         -s "key exchange mode: ephemeral" \
         -S "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -S "ticket is not authentic" \
         -S "ticket is expired" \
         -S "Invalid ticket start time" \
         -S "Ticket age exceeds limitation" \
         -s "Ticket age outside tolerance window"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_SESSION_TICKETS MBEDTLS_SSL_SRV_C \
                             MBEDTLS_SSL_CLI_C MBEDTLS_DEBUG_C MBEDTLS_HAVE_TIME
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test "TLS 1.3 m->m: Session resumption failure, age outside tolerance window, too old." \
         "$P_SRV debug_level=4 crt_file=data_files/server5.crt key_file=data_files/server5.key force_version=tls13 tickets=8 dummy_ticket=6" \
         "$P_CLI debug_level=4 reco_mode=1 reconnect=1" \
         0 \
         -c "Pre-configured PSK number = 1" \
         -S "sent selected_identity:" \
         -s "key exchange mode: ephemeral" \
         -S "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: psk$" \
         -S "ticket is not authentic" \
         -S "ticket is expired" \
         -S "Invalid ticket start time" \
         -S "Ticket age exceeds limitation" \
         -s "Ticket age outside tolerance window"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk, fail, no common kex mode" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -s "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -s "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk_ephemeral, fail, no common kex mode" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk_all, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_all, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -s "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk_all, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/ephemeral_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/ephemeral_all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/ephemeral_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/ephemeral_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/ephemeral_all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/ephemeral_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/ephemeral_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername wrong_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: ephemeral_all/psk_or_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_or_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: all/psk_or_ephemeral, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk_or_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_or_ephemeral/psk_or_ephemeral, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:-ECDHE-PSK:-DHE-PSK:+PSK:+VERS-TLS1.3 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f71 \
                         localhost" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -S "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_ephemeral group(secp256r1) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3:-GROUP-ALL:+GROUP-SECP256R1 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "write selected_group: secp256r1" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_ephemeral group(secp384r1) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3:-GROUP-ALL:+GROUP-SECP384R1 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "write selected_group: secp384r1" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_ephemeral group(secp521r1) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3:-GROUP-ALL:+GROUP-SECP521R1 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "write selected_group: secp521r1" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_ephemeral group(x25519) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3:-GROUP-ALL:+GROUP-X25519 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "write selected_group: x25519" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_gnutls_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: G->m: psk_ephemeral group(x448) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$G_NEXT_CLI -d 10 --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3:-GROUP-ALL:+GROUP-X448 \
                         --pskusername Client_identity --pskkey=6162636465666768696a6b6c6d6e6f70 \
                         localhost" \
            0 \
            -s "write selected_group: x448" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk, fail, no common kex mode" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -s "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk_all, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_all, fail, key id mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/ephemeral_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/ephemeral_all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/ephemeral_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/ephemeral_all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/ephemeral_all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/ephemeral_all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=ephemeral_all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/all, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/all, good, key id mismatch, dhe." \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity wrong_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/all, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=all debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: ephemeral_all/psk_or_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg   \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -S "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_or_ephemeral, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Pre shared key found" \
            -S "No matched PSK or ticket" \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -s "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: all/psk_or_ephemeral, fail, key material mismatch" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_or_ephemeral debug_level=5 $(get_srv_psk_list)" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f71" \
            1 \
            -s "found psk key exchange modes extension" \
            -s "found pre_shared_key extension" \
            -s "Found PSK_EPHEMERAL KEX MODE" \
            -s "Found PSK KEX MODE" \
            -s "Invalid binder." \
            -S "key exchange mode: psk$"  \
            -S "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: psk_ephemeral group(secp256r1) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex -groups P-256 \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "write selected_group: secp256r1" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: psk_ephemeral group(secp384r1) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex -groups secp384r1 \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "write selected_group: secp384r1" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: psk_ephemeral group(secp521r1) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex -groups secp521r1 \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "write selected_group: secp521r1" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: psk_ephemeral group(x25519) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex -groups X25519 \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "write selected_group: x25519" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_openssl_tls1_3
requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: O->m: psk_ephemeral group(x448) check, good" \
            "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_identity=Client_identity psk=6162636465666768696a6b6c6d6e6f70" \
            "$O_NEXT_CLI -tls1_3 -msg  -allow_no_dhe_kex -groups X448 \
                         -psk_identity Client_identity  -psk 6162636465666768696a6b6c6d6e6f70" \
            0 \
            -s "write selected_group: x448" \
            -S "key exchange mode: psk$"  \
            -s "key exchange mode: psk_ephemeral"  \
            -S "key exchange mode: ephemeral"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_openssl_tls1_3
run_test "TLS 1.3 O->m: psk_ephemeral group(secp256r1->secp384r1) check, good" \
         "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_list=Client_identity,6162636465666768696a6b6c6d6e6f70,abc,dead,def,beef curves=secp384r1" \
         "$O_NEXT_CLI_NO_CERT -tls1_3 -msg -allow_no_dhe_kex -psk_identity Client_identity -psk 6162636465666768696a6b6c6d6e6f70 -groups P-256:P-384" \
         0 \
         -s "write selected_group: secp384r1" \
         -s "HRR selected_group: secp384r1" \
         -S "key exchange mode: psk$" \
         -s "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: ephemeral"

requires_all_configs_enabled MBEDTLS_SSL_PROTO_TLS1_3 MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE MBEDTLS_SSL_SRV_C MBEDTLS_DEBUG_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_gnutls_tls1_3
requires_gnutls_next_no_ticket
requires_gnutls_next_disable_tls13_compat
run_test "TLS 1.3 G->m: psk_ephemeral group(secp256r1->secp384r1) check, good" \
         "$P_SRV force_version=tls13 tls13_kex_modes=psk_ephemeral debug_level=5 psk_list=Client_identity,6162636465666768696a6b6c6d6e6f70,abc,dead,def,beef curves=secp384r1" \
         "$G_NEXT_CLI_NO_CERT --debug=4 --single-key-share --priority NORMAL:-VERS-ALL:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+VERS-TLS1.3:-GROUP-ALL:+GROUP-SECP256R1:+GROUP-SECP384R1 --pskusername Client_identity --pskkey 6162636465666768696a6b6c6d6e6f70 localhost" \
         0 \
         -s "write selected_group: secp384r1" \
         -s "HRR selected_group: secp384r1" \
         -S "key exchange mode: psk$" \
         -s "key exchange mode: psk_ephemeral" \
         -S "key exchange mode: ephemeral"


# Add psk test cases for mbedtls client code

# MbedTls->MbedTLS kinds of tls13_kex_modes
# PSK mode in client
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/psk, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/psk, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/psk, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk_identity=0a0b0c psk=040506 tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/psk_ephemeral, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/ephemeral, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/ephemeral_all, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/psk_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/psk_all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/psk_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk_identity=0a0b0c psk=040506 tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk/all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c psk=040506 tls13_kex_modes=psk" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

# psk_ephemeral mode in client
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/psk, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/psk_ephemeral, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c psk=040506 tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->m: psk_ephemeral/ephemeral, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/ephemeral_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_RSA_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_DHE_PSK_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->m: psk_ephemeral/ephemeral_all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/ephemeral_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c psk=040506 tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/psk_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/psk_all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/psk_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_ephemeral/all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

# ephemeral mode in client
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral/psk, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            1 \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral/psk_ephemeral, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            1 \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral/ephemeral, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            0 \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral/ephemeral_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            0 \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral/psk_all, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            1 \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral/all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            0 \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

# ephemeral_all mode in client
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/psk, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/psk_ephemeral, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=ephemeral_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/ephemeral, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "key exchange mode: ephemeral" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/ephemeral_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/ephemeral_all,good,key id mismatch,fallback" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=ephemeral_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "key exchange mode: ephemeral"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/ephemeral_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/psk_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/psk_all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=ephemeral_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/psk_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/all, good, key id mismatch, fallback" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=ephemeral_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "key exchange mode: ephemeral"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: ephemeral_all/all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

# psk_all mode in client
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk_ephemeral, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/ephemeral, fail - no common kex mode" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/ephemeral_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/ephemeral_all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/ephemeral_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk_all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/psk_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: psk_all/all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

# all mode in client
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk_ephemeral, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk_ephemeral, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk_ephemeral, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/ephemeral, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/ephemeral_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/ephemeral_all, good, key id mismatch, fallback" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/ephemeral_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk_all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk_all, fail, key id mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "ClientHello message misses mandatory extensions."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/psk_all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/all, good" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/all, good, key id mismatch, fallback" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=010203 psk_identity=0d0e0f tls13_kex_modes=all" \
            0 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "No matched PSK or ticket" \
            -s "key exchange mode: ephemeral"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_SRV_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->m: all/all, fail, key material mismatch" \
            "$P_SRV nbio=2 debug_level=5 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            "$P_CLI nbio=2 debug_level=5 psk=040506 psk_identity=0a0b0c tls13_kex_modes=all" \
            1 \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Invalid binder."

#OPENSSL-SERVER psk mode
requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: psk/all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203 -allow_no_dhe_kex -nocert" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 ok"

requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: psk/ephemeral_all, fail - no common kex mode" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203" \
            "$P_CLI debug_level=4 sig_algs=ecdsa_secp256r1_sha256 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            1 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "<= write client hello" \
            -c "Last error was: -0x7780 - SSL - A fatal alert message was received from our peer"

#OPENSSL-SERVER psk_all mode
requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: psk_all/all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203 -allow_no_dhe_kex -nocert" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 ok"

requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: psk_all/ephemeral_all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203" \
            "$P_CLI debug_level=4 sig_algs=ecdsa_secp256r1_sha256 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 ok"

#OPENSSL-SERVER psk_ephemeral mode
requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: psk_ephemeral/all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203 -allow_no_dhe_kex -nocert" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 ok"

requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: psk_ephemeral/ephemeral_all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203" \
            "$P_CLI debug_level=4 sig_algs=ecdsa_secp256r1_sha256 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 ok"

#OPENSSL-SERVER ephemeral mode
requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: ephemeral/all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203 -allow_no_dhe_kex" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "skip psk_key_exchange_modes extension" \
            -c "<= write client hello" \
            -c "found key_shares extension" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 ok"

requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: ephemeral/ephemeral_all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203" \
            "$P_CLI debug_level=4 sig_algs=ecdsa_secp256r1_sha256 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "skip psk_key_exchange_modes extension" \
            -c "<= write client hello" \
            -c "found key_shares extension" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 ok"

#OPENSSL-SERVER ephemeral_all mode
requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: ephemeral_all/all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203 -allow_no_dhe_kex -nocert" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "<= write client hello" \
            -c "HTTP/1.0 200 ok"

requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: ephemeral_all/ephemeral_all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203" \
            "$P_CLI debug_level=4 sig_algs=ecdsa_secp256r1_sha256 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "<= write client hello" \
            -c "HTTP/1.0 200 ok"

#OPENSSL-SERVER all mode
requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: all/all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203 -allow_no_dhe_kex -nocert" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "<= write client hello" \
            -c "HTTP/1.0 200 ok"

requires_openssl_tls1_3
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
requires_any_configs_enabled MBEDTLS_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED \
                             MBEDTLS_KEY_EXCHANGE_ECDHE_PSK_ENABLED
run_test    "TLS 1.3: m->O: all/ephemeral_all, good" \
            "$O_NEXT_SRV -msg -debug -tls1_3 -psk_identity 0a0b0c -psk 010203" \
            "$P_CLI debug_level=4 sig_algs=ecdsa_secp256r1_sha256 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "<= write client hello" \
            -c "HTTP/1.0 200 ok"

#GNUTLS-SERVER psk mode
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: psk/all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: psk/ephemeral_all, fail - no common kex mode" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk" \
            1 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Last error was: -0x7780 - SSL - A fatal alert message was received from our peer"

#GNUTLS-SERVER psk_all mode
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: psk_all/all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: psk_all/ephemeral_all, fail - no fallback" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_all" \
            1 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Last error was: -0x7780 - SSL - A fatal alert message was received from our peer"

#GNUTLS-SERVER psk_ephemeral mode
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: psk_ephemeral/all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: psk_ephemeral/ephemeral_all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=psk_ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

#GNUTLS-SERVER ephemeral mode
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: ephemeral/all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "skip psk_key_exchange_modes extension" \
            -s "Not sending extension (PSK Key Exchange Modes/45)" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: ephemeral/ephemeral_all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral" \
            0 \
            -c "=> write client hello" \
            -c "skip psk_key_exchange_modes extension" \
            -s "Not sending extension (PSK Key Exchange Modes/45)" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"

#GNUTLS-SERVER ephemeral_all mode
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: ephemeral_all/all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: ephemeral_all/ephemeral_all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=ephemeral_all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk_ephemeral" \
            -c "HTTP/1.0 200 OK"

#GNUTLS-SERVER all mode
requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: all/all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:+PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: psk$" \
            -c "HTTP/1.0 200 OK"

requires_config_enabled MBEDTLS_SSL_PROTO_TLS1_3
requires_gnutls_tls1_3
requires_config_enabled MBEDTLS_SSL_TLS1_3_COMPATIBILITY_MODE
requires_config_enabled MBEDTLS_DEBUG_C
requires_config_enabled MBEDTLS_SSL_CLI_C
run_test    "TLS 1.3: m->G: all/ephemeral_all, good" \
            "$G_NEXT_SRV -d 4 --priority=NORMAL:-VERS-ALL:+VERS-TLS1.3:-KX-ALL:+ECDHE-PSK:+DHE-PSK:-PSK:+CIPHER-ALL --pskpasswd=data_files/simplepass.psk" \
            "$P_CLI debug_level=4 force_version=tls13 psk=010203 psk_identity=0a0b0c tls13_kex_modes=all" \
            0 \
            -c "=> write client hello" \
            -c "client hello, adding pre_shared_key extension, omitting PSK binder list" \
            -c "client hello, adding psk_key_exchange_modes extension" \
            -c "client hello, adding PSK binder list" \
            -s "Parsing extension 'PSK Key Exchange Modes/45'" \
            -s "Parsing extension 'Pre Shared Key/41'" \
            -c "<= write client hello" \
            -c "Selected key exchange mode: ephemeral" \
            -c "HTTP/1.0 200 OK"